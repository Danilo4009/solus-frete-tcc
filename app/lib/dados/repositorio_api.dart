import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../modelos/modelos.dart';
import 'repositorio.dart';

class ErroApi implements Exception {
  final String mensagem;
  final int? status;
  ErroApi(this.mensagem, [this.status]);
  @override
  String toString() => mensagem;
}

class RepositorioApi implements Repositorio {
  String? _token;

  Map<String, String> get _cabecalhos => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _url(String caminho, [Map<String, String>? params]) =>
      Uri.parse('${Config.baseUrl}$caminho').replace(queryParameters: params);

  dynamic _decodificar(http.Response r) {
    final corpo = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 400) {
      final msg = corpo is Map && corpo['erro'] != null
          ? corpo['erro'] as String
          : 'Falha na requisição (${r.statusCode})';
      throw ErroApi(msg, r.statusCode);
    }
    return corpo;
  }

  Future<dynamic> _get(String caminho, [Map<String, String>? params]) async =>
      _decodificar(await http.get(_url(caminho, params), headers: _cabecalhos));

  Future<dynamic> _post(String caminho, [Map<String, dynamic>? corpo]) async =>
      _decodificar(await http.post(_url(caminho),
          headers: _cabecalhos, body: jsonEncode(corpo ?? const {})));

  Future<dynamic> _delete(String caminho) async =>
      _decodificar(await http.delete(_url(caminho), headers: _cabecalhos));

  @override
  Future<({String token, Usuario usuario})> login(String telefone, String senha) async {
    final j = await _post('/auth/login', {'telefone': telefone, 'senha': senha});
    _token = j['token'] as String;
    return (token: _token!, usuario: Usuario.doJson(j['usuario'] as Map<String, dynamic>));
  }

  @override
  Future<({String token, Usuario usuario})> cadastrarCliente({
    required String nome,
    String? sobrenome,
    required String telefone,
    String? email,
    required String senha,
    String? setor,
  }) async {
    final j = await _post('/auth/registro/cliente', {
      'nome': nome,
      'sobrenome': sobrenome,
      'telefone': telefone,
      'email': email,
      'senha': senha,
      'setor': setor,
    });
    _token = j['token'] as String;
    return (token: _token!, usuario: Usuario.doJson(j['usuario'] as Map<String, dynamic>));
  }

  @override
  Future<String> cadastrarMotorista(Map<String, dynamic> dados) async {
    final j = await _post('/auth/registro/motorista', dados);
    return (j['mensagem'] ?? 'Cadastro enviado') as String;
  }

  @override
  Future<String> cadastrarTransportadora(Map<String, dynamic> dados) async {
    final j = await _post('/auth/registro/transportadora', dados);
    return (j['mensagem'] ?? 'Cadastro enviado') as String;
  }

  @override
  Future<List<CategoriaVeiculo>> veiculos({String cidade = Config.cidadePadrao}) async {
    final j = await _get('/catalogo/veiculos', {'cidade': cidade}) as List;
    return j.map((e) => CategoriaVeiculo.doJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<MotoristaProximo>> motoristasProximos({
    required int categoriaId,
    required double latitude,
    required double longitude,
    int limite = 10,
  }) async {
    final j = await _get('/perfil/motoristas-proximos', {
      'categoriaId': '$categoriaId',
      'lat': '$latitude',
      'lng': '$longitude',
      'limite': '$limite',
    }) as List;
    return j.map((e) => MotoristaProximo.doJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<({List<Endereco> favoritos, List<Endereco> recentes})> enderecos() async {
    final j = await _get('/enderecos') as Map<String, dynamic>;
    List<Endereco> mapear(String chave) => ((j[chave] as List?) ?? const [])
        .map((e) => Endereco.doJson(e as Map<String, dynamic>))
        .toList();
    return (favoritos: mapear('favoritos'), recentes: mapear('recentes'));
  }

  @override
  Future<List<Endereco>> buscarEnderecos(String termo) async {
    final j = await _get('/enderecos/busca', {'q': termo}) as List;
    return j.map((e) => Endereco.doJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Endereco> salvarEndereco(Endereco endereco) async {
    final j = await _post('/enderecos', {
      'apelido': endereco.apelido,
      'logradouro': endereco.logradouro,
      'numero': endereco.numero,
      'complemento': endereco.complemento,
      'referencia': endereco.referencia,
      'bairro': endereco.bairro,
      'cidade': endereco.cidade,
      'uf': endereco.uf,
      'latitude': endereco.latitude,
      'longitude': endereco.longitude,
      'contatoNome': endereco.contatoNome,
      'contatoTelefone': endereco.contatoTelefone,
      'favorito': endereco.favorito,
    });
    return Endereco.doJson(j as Map<String, dynamic>);
  }

  @override
  Future<Cotacao> cotar({
    required int categoriaId,
    required List<Endereco> paradas,
    List<int> servicos = const [],
    int? horas,
    String? cupom,
  }) async {
    final j = await _post('/cotacao', {
      'cidade': Config.cidadePadrao,
      'categoriaId': categoriaId,
      'paradas': [
        for (var i = 0; i < paradas.length; i++)
          paradas[i].paraJson(tipo: i == 0 ? 'coleta' : 'entrega'),
      ],
      'servicos': servicos,
      'horas': horas,
      'cupom': cupom,
    });
    return Cotacao.doJson(j as Map<String, dynamic>);
  }

  @override
  Future<Pedido> criarPedido(Map<String, dynamic> corpo) async {
    // Normaliza os objetos de dominio do rascunho para JSON.
    final paradas = (corpo['paradas'] as List).cast<Endereco>();
    final carga = corpo['carga'] as Carga?;
    final agendado = corpo['agendadoPara'] as DateTime?;

    final j = await _post('/pedidos', {
      'cidade': Config.cidadePadrao,
      'categoriaId': corpo['categoriaId'],
      'nivelServico': corpo['nivelServico'],
      'tipoRetirada': corpo['tipoRetirada'],
      'agendadoPara': agendado?.toIso8601String(),
      'modalidade': corpo['modalidade'],
      'horasContratadas': corpo['horasContratadas'],
      'paradas': [
        for (var i = 0; i < paradas.length; i++)
          paradas[i].paraJson(tipo: i == 0 ? 'coleta' : 'entrega'),
      ],
      'servicos': (corpo['servicos'] as List?)?.cast<int>() ?? const <int>[],
      'carga': (carga ?? const Carga()).paraJson(),
      'formaPagamento': corpo['formaPagamento'],
      'pagador': corpo['pagador'],
      'favoritosPrimeiro': corpo['favoritosPrimeiro'],
      'exigeComprovante': corpo['exigeComprovante'],
      'observacaoMotorista': corpo['observacaoMotorista'],
      'contatoTelefone': corpo['contatoTelefone'],
      'cupom': corpo['cupom'],
      'aceiteItensProibidos': corpo['aceiteItensProibidos'] ?? true,
    });
    return Pedido.doJson(j as Map<String, dynamic>);
  }

  @override
  Future<List<Pedido>> listarPedidos({String situacao = 'em_andamento', String? busca}) async {
    final j = await _get('/pedidos', {
      'situacao': situacao,
      if (busca != null && busca.isNotEmpty) 'q': busca,
    }) as List;
    return j.map((e) => Pedido.doJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Pedido> obterPedido(int id) async =>
      Pedido.doJson(await _get('/pedidos/$id') as Map<String, dynamic>);

  @override
  Future<Pedido> avancarPedido(int id) async =>
      Pedido.doJson(await _post('/pedidos/$id/avancar') as Map<String, dynamic>);

  @override
  Future<double> cancelarPedido(int id, String motivo) async {
    final j = await _post('/pedidos/$id/cancelar', {'motivo': motivo});
    return ((j['taxaCancelamento'] as num?) ?? 0).toDouble();
  }

  @override
  Future<void> avaliarPedido(int id, int nota, String? comentario, bool favoritar) async {
    await _post('/pedidos/$id/avaliar', {
      'nota': nota,
      'comentario': comentario,
      'favoritar': favoritar,
    });
  }

  @override
  Future<List<MotoristaFavorito>> favoritos() async {
    final j = await _get('/perfil/favoritos') as List;
    return j.map((e) => MotoristaFavorito.doJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> convidarMotorista(String telefone, String? nome) async {
    final j = await _post('/perfil/favoritos/convite', {'telefone': telefone, 'nome': nome});
    return (j['mensagem'] ?? 'Convite enviado') as String;
  }

  @override
  Future<void> removerFavorito(int motoristaId) async {
    await _delete('/perfil/favoritos/$motoristaId');
  }

  @override
  Future<Carteira> carteira() async {
    final j = await _get('/perfil/carteira') as Map<String, dynamic>;
    return Carteira(
      saldo: ((j['saldo'] as num?) ?? 0).toDouble(),
      transacoes: ((j['transacoes'] as List?) ?? const [])
          .map((e) => TransacaoCarteira.doJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<double> recarregar(double valor) async {
    final j = await _post('/perfil/carteira/recarga', {'valor': valor});
    return ((j['saldo'] as num?) ?? 0).toDouble();
  }

  @override
  Future<({List<Notificacao> operacionais, List<Notificacao> promocionais})>
      notificacoes() async {
    final j = await _get('/perfil/notificacoes') as Map<String, dynamic>;
    List<Notificacao> mapear(String chave) => ((j[chave] as List?) ?? const [])
        .map((e) => Notificacao.doJson(e as Map<String, dynamic>))
        .toList();
    return (operacionais: mapear('operacionais'), promocionais: mapear('promocionais'));
  }
}
