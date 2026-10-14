import 'dart:math';

import '../core/compatibilidade.dart';
import '../core/config.dart';
import '../core/veiculos_config.dart';
import '../modelos/modelos.dart';
import 'repositorio.dart';
import 'repositorio_api.dart' show ErroApi;

/// Implementacao em memoria: espelha as regras da API para o prototipo
/// rodar sem backend. Mesmo motor de preco do servidor.
class RepositorioMock implements Repositorio {
  RepositorioMock() {
    _semear();
  }

  final _rnd = Random(7);
  int _proximoId = 100;

  late List<CategoriaVeiculo> _veiculos;
  final List<Endereco> _enderecos = [];
  final List<Pedido> _pedidos = [];
  final List<MotoristaFavorito> _favoritos = [];
  final List<Notificacao> _operacionais = [];
  final List<Notificacao> _promocionais = [];
  double _saldo = 120.00;
  final List<TransacaoCarteira> _transacoes = [];

  // ---------------------------------------------------------------- preco
  static const _tarifas = {
    // codigo: (base, porKm, porParada, minimo, hora) - mesmos valores do seed (tabela_preco)
    'moto': (8.0, 1.90, 4.0, 14.0, 38.0),
    'carro': (16.0, 2.70, 6.0, 26.0, 58.0),
    'utilitario': (28.0, 3.60, 10.0, 45.0, 78.0),
    'van': (38.0, 4.30, 10.0, 62.0, 92.0),
    'vuc': (65.0, 5.80, 10.0, 105.0, 125.0),
    'caminhao_34': (90.0, 7.40, 10.0, 140.0, 160.0),
    'caminhao_toco': (140.0, 9.80, 10.0, 210.0, 220.0),
    'caminhao_truck': (190.0, 12.50, 10.0, 280.0, 290.0),
    'carreta': (320.0, 18.00, 10.0, 480.0, 480.0),
  };

  void _semear() {
    const servicos = [
      ServicoAdicional(id: 1, codigo: 'ajuda_motorista', nome: 'Ajuda do motorista',
          descricao: 'Carga e descarga porta a porta feita pelo motorista.', preco: 70),
      ServicoAdicional(id: 2, codigo: 'ajudante_extra', nome: 'Ajudante extra',
          descricao: 'Motorista mais um ajudante para carga e descarga.', preco: 140),
      ServicoAdicional(id: 3, codigo: 'mudanca_completa', nome: 'Mudanca completa',
          descricao: 'Motorista e ajudante com manuseio de moveis.', preco: 190),
      ServicoAdicional(id: 4, codigo: 'tempo_espera', nome: 'Tempo de espera',
          descricao: 'Espera adicional de ate 60 minutos no local.', preco: 45),
      ServicoAdicional(id: 5, codigo: 'embalagem', nome: 'Embalagem e protecao',
          descricao: 'Plastico bolha e cinta para itens frageis.', preco: 35),
      ServicoAdicional(id: 6, codigo: 'coleta_agendada', nome: 'Janela de coleta garantida',
          descricao: 'Compromisso de coleta dentro de uma hora especifica.', preco: 25),
    ];

    List<ServicoAdicional> para(String codigo) {
      final lista = <ServicoAdicional>[servicos[3], servicos[5]];
      if (codigo != 'moto') lista.add(servicos[4]);
      const grandes = ['vuc', 'caminhao_34', 'caminhao_toco', 'caminhao_truck', 'carreta'];
      if (['utilitario', 'van', ...grandes].contains(codigo)) lista.add(servicos[0]);
      if (['van', ...grandes].contains(codigo)) lista.add(servicos[1]);
      if (['vuc', 'caminhao_34', 'caminhao_toco', 'caminhao_truck'].contains(codigo)) {
        lista.add(servicos[2]);
      }
      return lista;
    }

    _veiculos = [
      for (final e in veiculosConfig)
        CategoriaVeiculo(
          id: e.id,
          codigo: e.codigo,
          nome: e.nome,
          descricao: e.descricao,
          comprimentoM: e.comprimentoM,
          larguraM: e.larguraM,
          alturaM: e.alturaM,
          pesoMaxKg: e.pesoMaxKg,
          aceitaRefrigerada: e.aceitaRefrigerada,
          aceitaPerigosa: e.aceitaPerigosa,
          valorHora: _tarifas[e.codigo]!.$5,
          servicos: para(e.codigo),
        ),
    ];

    _enderecos.addAll(const [
      Endereco(id: 1, apelido: 'Casa', logradouro: 'Rua Salvador Nunes', numero: '120',
          complemento: 'Casa 2', referencia: 'Em frente a praca', bairro: 'Jardim Piratininga',
          cidade: 'Osasco', uf: 'SP', latitude: -23.5320, longitude: -46.7920,
          contatoNome: 'Danilo', contatoTelefone: '11940135904', favorito: true),
      Endereco(id: 2, apelido: 'Trabalho', logradouro: 'Avenida Paulista', numero: '1159',
          complemento: '9o andar', referencia: 'Proximo ao MASP', bairro: 'Bela Vista',
          cidade: 'Sao Paulo', uf: 'SP', latitude: -23.5660, longitude: -46.6520,
          contatoNome: 'Recepcao', contatoTelefone: '1133334444', favorito: true),
      Endereco(id: 3, logradouro: 'Rua Pastoril de Nanuque', numero: '196',
          bairro: 'Ponte Rasa', cidade: 'Sao Paulo', uf: 'SP',
          latitude: -23.5170, longitude: -46.4780),
      Endereco(id: 4, logradouro: 'Rua 25 de Marco', numero: '800', bairro: 'Centro',
          cidade: 'Sao Paulo', uf: 'SP', latitude: -23.5430, longitude: -46.6330),
      Endereco(id: 5, logradouro: 'Rua Cabo Diogo Oliveira', numero: '45',
          bairro: 'Vila Leopoldina', cidade: 'Sao Paulo', uf: 'SP',
          latitude: -23.5290, longitude: -46.7360),
    ]);

    _favoritos.add(const MotoristaFavorito(motoristaId: 1, nome: 'Jose Bezerra',
        telefone: '11977776666', avaliacao: 4.85, totalCorridas: 312,
        disponivel: true, veiculos: 'Van'));

    _transacoes.addAll([
      TransacaoCarteira(tipo: 'recarga', valor: 150, descricao: 'Recarga via Pix',
          quando: DateTime.now().subtract(const Duration(days: 8))),
      TransacaoCarteira(tipo: 'pagamento', valor: -30, descricao: 'Pedido SF-000001',
          quando: DateTime.now().subtract(const Duration(days: 7))),
    ]);

    _promocionais.add(Notificacao(id: 900, titulo: 'Cupom SOLUS10',
        mensagem: 'Use SOLUS10 e ganhe R\$ 10 no proximo frete.',
        quando: DateTime.now().subtract(const Duration(days: 2))));

    // Pedido concluido de exemplo
    _pedidos.add(Pedido(
      id: 1, codigo: 'SF-000001', situacao: 'concluido', nivelServico: 'padrao',
      tipoRetirada: 'imediata', categoriaNome: 'Moto', distanciaKm: 7.4,
      valorFrete: 25.60, valorTotal: 25.60, formaPagamento: 'carteira',
      motoristaNome: 'Aline Souza', motoristaAvaliacao: 4.92, veiculoPlaca: 'XYZ9K88',
      criadoEm: DateTime.now().subtract(const Duration(days: 7)),
      paradas: [
        Parada(tipo: 'coleta', endereco: _enderecos[0], situacao: 'concluida'),
        Parada(tipo: 'entrega', endereco: _enderecos[2], situacao: 'concluida'),
      ],
      carga: const Carga(tipoCarga: 'caixas_pacotes', volumes: 1, pesoKg: 0.5,
          comprimentoCm: 30, larguraCm: 22, alturaCm: 3,
          observacoes: 'Envelope com contratos'),
      eventos: [
        EventoPedido(situacao: 'cotado', descricao: 'Cotacao gerada',
            quando: DateTime.now().subtract(const Duration(days: 7, minutes: 50))),
        EventoPedido(situacao: 'alocado', descricao: 'Aline Souza aceitou',
            quando: DateTime.now().subtract(const Duration(days: 7, minutes: 45))),
        EventoPedido(situacao: 'em_transito', descricao: 'Coleta realizada',
            quando: DateTime.now().subtract(const Duration(days: 7, minutes: 30))),
        EventoPedido(situacao: 'concluido', descricao: 'Entrega confirmada',
            quando: DateTime.now().subtract(const Duration(days: 7))),
      ],
    ));

    // Pedido em transito de exemplo
    _pedidos.add(Pedido(
      id: 2, codigo: 'SF-000002', situacao: 'em_transito', nivelServico: 'padrao',
      tipoRetirada: 'imediata', categoriaNome: 'Van', distanciaKm: 18.6,
      valorFrete: 148.72, valorAdicionais: 70, valorTotal: 218.72,
      formaPagamento: 'pix',
      motoristaNome: 'Jose Bezerra', motoristaAvaliacao: 4.85, veiculoPlaca: 'ABC1D23',
      criadoEm: DateTime.now().subtract(const Duration(hours: 1)),
      paradas: [
        Parada(tipo: 'coleta', endereco: _enderecos[0], situacao: 'concluida'),
        Parada(tipo: 'entrega', endereco: _enderecos[1]),
      ],
      carga: const Carga(tipoCarga: 'fragil', volumes: 4, pesoKg: 320,
          comprimentoCm: 180, larguraCm: 90, alturaCm: 75, naoEmpilhar: true,
          observacoes: 'Uma mesa de vidro, favor nao empilhar'),
      servicos: const [
        ServicoAdicional(id: 1, codigo: 'ajuda_motorista',
            nome: 'Ajuda do motorista', preco: 70),
      ],
      eventos: [
        EventoPedido(situacao: 'cotado', descricao: 'Cotacao gerada',
            quando: DateTime.now().subtract(const Duration(hours: 1))),
        EventoPedido(situacao: 'aguardando_alocacao',
            descricao: 'Ofertado aos seus motoristas favoritos',
            quando: DateTime.now().subtract(const Duration(minutes: 55))),
        EventoPedido(situacao: 'alocado', descricao: 'Jose Bezerra aceitou',
            quando: DateTime.now().subtract(const Duration(minutes: 50))),
        EventoPedido(situacao: 'carregando', descricao: 'Chegou na coleta',
            quando: DateTime.now().subtract(const Duration(minutes: 35))),
        EventoPedido(situacao: 'em_transito', descricao: 'Carga coletada',
            quando: DateTime.now().subtract(const Duration(minutes: 25))),
      ],
    ));

    _operacionais.add(Notificacao(id: 901, titulo: 'Carga coletada',
        mensagem: 'Seu pedido SF-000002 saiu para entrega.',
        quando: DateTime.now().subtract(const Duration(minutes: 25))));
  }

  Future<T> _demora<T>(T valor) =>
      Future.delayed(const Duration(milliseconds: 350), () => valor);

  double _distancia(List<Endereco> paradas) {
    double total = 0;
    for (var i = 1; i < paradas.length; i++) {
      final a = paradas[i - 1];
      final b = paradas[i];
      if (a.latitude == null || b.latitude == null) continue;
      final dLat = (b.latitude! - a.latitude!) * pi / 180;
      final dLon = (b.longitude! - a.longitude!) * pi / 180;
      final h = pow(sin(dLat / 2), 2) +
          cos(a.latitude! * pi / 180) * cos(b.latitude! * pi / 180) * pow(sin(dLon / 2), 2);
      total += 2 * 6371 * asin(sqrt(h.toDouble()));
    }
    return double.parse((total * 1.35).toStringAsFixed(2));
  }

  // ---------------------------------------------------------------- auth
  @override
  Future<({String token, Usuario usuario})> login(String telefone, String senha) =>
      _demora((
        token: 'mock-token',
        usuario: const Usuario(id: 1, tipo: 'cliente_pf', nome: 'Danilo',
            sobrenome: 'Lopes', telefone: '11940135904',
            email: 'danilo@solusfrete.dev', setor: 'Tecnologia'),
      ));

  @override
  Future<({String token, Usuario usuario})> cadastrarCliente({
    required String nome,
    String? sobrenome,
    required String telefone,
    String? email,
    required String senha,
    String? setor,
  }) =>
      _demora((
        token: 'mock-token',
        usuario: Usuario(id: ++_proximoId, tipo: 'cliente_pf', nome: nome,
            sobrenome: sobrenome, telefone: telefone, email: email, setor: setor),
      ));

  @override
  Future<String> cadastrarMotorista(Map<String, dynamic> dados) => _demora(
      'Cadastro enviado para homologacao da operacao Solus. Voce recebera um aviso quando for aprovado.');

  @override
  Future<String> cadastrarTransportadora(Map<String, dynamic> dados) => _demora(
      'Transportadora enviada para homologacao. Apos a aprovacao voce podera cadastrar a frota.');

  // ------------------------------------------------------------- catalogo
  @override
  Future<List<CategoriaVeiculo>> veiculos({String cidade = Config.cidadePadrao}) =>
      _demora(_veiculos);

  // ------------------------------------------------------------ enderecos
  @override
  Future<({List<Endereco> favoritos, List<Endereco> recentes})> enderecos() => _demora((
        favoritos: _enderecos.where((e) => e.favorito).toList(),
        recentes: _enderecos.where((e) => !e.favorito).take(5).toList(),
      ));

  @override
  Future<List<Endereco>> buscarEnderecos(String termo) {
    final t = termo.toLowerCase();
    final encontrados = _enderecos
        .where((e) =>
            e.logradouro.toLowerCase().contains(t) ||
            (e.bairro ?? '').toLowerCase().contains(t) ||
            (e.apelido ?? '').toLowerCase().contains(t))
        .toList();
    if (encontrados.isEmpty && t.length > 3) {
      // simula retorno do geocodificador
      encontrados.add(Endereco(
        id: null,
        logradouro: termo,
        cidade: Config.cidadePadrao,
        uf: 'SP',
        latitude: -23.55 + _rnd.nextDouble() * 0.06 - 0.03,
        longitude: -46.65 + _rnd.nextDouble() * 0.12 - 0.06,
      ));
    }
    return _demora(encontrados);
  }

  @override
  Future<Endereco> salvarEndereco(Endereco endereco) {
    final novo = Endereco(
      id: ++_proximoId,
      apelido: endereco.apelido,
      logradouro: endereco.logradouro,
      numero: endereco.numero,
      complemento: endereco.complemento,
      referencia: endereco.referencia,
      bairro: endereco.bairro,
      cidade: endereco.cidade,
      uf: endereco.uf,
      latitude: endereco.latitude,
      longitude: endereco.longitude,
      contatoNome: endereco.contatoNome,
      contatoTelefone: endereco.contatoTelefone,
      favorito: endereco.favorito,
    );
    _enderecos.insert(0, novo);
    return _demora(novo);
  }

  // ------------------------------------------------------------- parceiros
  static const _nomesMotoristas = [
    'Carlos Silva', 'Marcos Santos', 'Paulo Oliveira', 'Andre Souza', 'Bruno Pereira',
    'Diego Costa', 'Fabio Ribeiro', 'Gustavo Almeida', 'Henrique Carvalho', 'Igor Gomes',
    'Julio Martins', 'Leandro Rocha',
  ];

  // nome, latitude, longitude, raio (km), fator de preco, nota, fretes
  static const _transportadoras = [
    ('RapidoSul', -23.5505, -46.6333, 80, 0.92, 4.60, 1240),
    ('Via Expressa', -23.4543, -46.5333, 70, 0.96, 4.40, 860),
    ('Metropole Cargas', -23.5329, -46.7917, 60, 1.00, 4.80, 2100),
    ('Grande SP Fretes', -23.6639, -46.5383, 70, 1.05, 4.20, 540),
    ('Barueri Log', -23.5057, -46.8790, 50, 0.89, 4.50, 730),
    ('TransPaulista', -23.5614, -46.6559, 90, 1.10, 4.90, 3300),
    ('Carga Certa', -23.6914, -46.5646, 60, 0.94, 4.10, 410),
    ('EntregaJa', -23.5200, -46.7300, 60, 1.02, 0.0, 0),
    ('Norte Sul', -23.4890, -46.6100, 75, 1.15, 4.70, 1500),
    ('Rota Segura', -23.5480, -46.8200, 25, 0.97, 4.30, 650),
  ];

  static const _modelos = {
    'moto': 'Honda CG 160 Cargo',
    'carro': 'Chevrolet Onix Plus',
    'utilitario': 'Fiat Fiorino',
    'van': 'Renault Master',
    'vuc': 'Volkswagen Delivery Express',
    'caminhao_34': 'Volkswagen Delivery 9.170',
    'caminhao_toco': 'Mercedes Accelo 1016',
    'caminhao_truck': 'Volkswagen Constellation 24.280',
    'carreta': 'Scania R 450 com carreta',
  };

  // Cada cotacao mostra ate 10 opcoes: 4 motoristas autonomos + 6 transportadoras.
  static const _vagasMotoristas = 4;
  static const _totalOfertas = 10;
  static const _velocidadeMediaKmh = 30;
  static const _minutosManuseio = 15;
  // No prototipo o parceiro escolhido aceita sozinho depois deste tempo.
  static const _aceiteAutomatico = Duration(seconds: 8);

  late final List<_Parceiro> _parceiros = _gerarParceiros();
  final Map<int, _ContextoCotacao> _contextos = {};

  List<_Parceiro> _gerarParceiros() {
    final lista = <_Parceiro>[];
    // 5 motoristas autonomos por categoria (mesma regra do seed da API)
    for (final c in _veiculos) {
      for (var k = 0; k < 5; k++) {
        final i = (c.id - 1) * 5 + k + 1;
        final semNota = i % 11 == 0;
        lista.add(_Parceiro(
          tipo: 'motorista',
          id: c.id * 100 + k,
          nome: _nomesMotoristas[i % _nomesMotoristas.length],
          categoriaId: c.id,
          lat: -23.55 + ((i * 7) % 13 - 6) * 0.014,
          lng: -46.65 + ((i * 11) % 17 - 8) * 0.016,
          raioKm: 40,
          fator: 1.0,
          nota: semNota ? 0 : 4.0 + ((i * 7) % 10) / 10,
          fretes: semNota ? 0 : 20 + (i * 37) % 400,
          disponivel: i % 9 != 0,
        ));
      }
    }
    lista.add(const _Parceiro(tipo: 'motorista', id: 1, nome: 'Jose Bezerra',
        categoriaId: 4, lat: -23.5489, lng: -46.6388, raioKm: 40, fator: 1.0,
        nota: 4.85, fretes: 312));
    lista.add(const _Parceiro(tipo: 'motorista', id: 2, nome: 'Aline Souza',
        categoriaId: 1, lat: -23.5320, lng: -46.7920, raioKm: 40, fator: 1.0,
        nota: 4.92, fretes: 128));
    for (var n = 0; n < _transportadoras.length; n++) {
      final t = _transportadoras[n];
      lista.add(_Parceiro(tipo: 'transportadora', id: n + 1, nome: t.$1, categoriaId: 0,
          lat: t.$2, lng: t.$3, raioKm: t.$4, fator: t.$5, nota: t.$6, fretes: t.$7));
    }
    return lista;
  }

  double _haversine(double la1, double lo1, double la2, double lo2) {
    final dLat = (la2 - la1) * pi / 180;
    final dLon = (lo2 - lo1) * pi / 180;
    final h = pow(sin(dLat / 2), 2) +
        cos(la1 * pi / 180) * cos(la2 * pi / 180) * pow(sin(dLon / 2), 2);
    return 2 * 6371 * asin(sqrt(h.toDouble()));
  }

  /// Mesma regra da API: motorista autonomo usa a tabela da plataforma e a
  /// transportadora tem preco proprio (fator sobre a tabela).
  Cotacao _montarCotacao({
    required int categoriaId,
    required List<Endereco> paradas,
    List<int> servicos = const [],
    int? horas,
    String? cupom,
    Set<String> excluir = const {},
  }) {
    final categoria = _veiculos.firstWhere((v) => v.id == categoriaId);
    final tarifa = _tarifas[categoria.codigo]!;
    final km = _distancia(paradas);
    final extras = categoria.servicos
        .where((s) => servicos.contains(s.id))
        .fold<double>(0, (soma, s) => soma + s.preco);
    final coleta = paradas.first;

    double distanciaAteColeta(_Parceiro p) =>
        coleta.latitude == null || coleta.longitude == null
            ? 0
            : _haversine(p.lat, p.lng, coleta.latitude!, coleta.longitude!) * 1.35;

    OfertaParceiro? montar(_Parceiro p) {
      if (excluir.contains(p.chave) || !p.disponivel) return null;
      if (p.tipo == 'motorista' && p.categoriaId != categoriaId) return null;
      final dist = distanciaAteColeta(p);
      if (dist > p.raioKm) return null;

      final f = p.fator;
      double base;
      if (horas != null && horas > 0) {
        base = tarifa.$5 * f * horas;
      } else {
        final extraParadas = max(0, paradas.length - 2);
        base = tarifa.$1 * f + tarifa.$2 * f * km + tarifa.$3 * f * extraParadas;
      }
      final frete = double.parse(max(base, tarifa.$4 * f).toStringAsFixed(2));
      double desconto = 0;
      if (cupom != null && cupom.toUpperCase() == 'SOLUS10' && frete >= 40) desconto = 10;
      if (cupom != null && cupom.toUpperCase() == 'MUDANCA15' && frete >= 150) {
        desconto = double.parse((frete * 0.15).toStringAsFixed(2));
      }
      final chegada = (dist / _velocidadeMediaKmh * 60).round();
      return OfertaParceiro(
        chave: p.chave,
        tipo: p.tipo,
        parceiroId: p.id,
        nome: p.nome,
        nota: p.nota,
        totalFretes: p.fretes,
        favorito: p.tipo == 'motorista' && _favoritos.any((fav) => fav.nome == p.nome),
        veiculo: _modelos[categoria.codigo]!,
        distanciaColetaKm: double.parse(dist.toStringAsFixed(1)),
        chegadaColetaMin: chegada,
        prazoEntregaMin:
            chegada + (km / _velocidadeMediaKmh * 60).round() + _minutosManuseio,
        valorFrete: frete,
        valorAdicionais: extras,
        desconto: desconto,
        total: double.parse((frete + extras - desconto).toStringAsFixed(2)),
      );
    }

    // favoritos primeiro, depois avaliados (maior nota), depois o mais proximo
    int ordenar(OfertaParceiro a, OfertaParceiro b) {
      final fav = (b.favorito ? 1 : 0) - (a.favorito ? 1 : 0);
      if (fav != 0) return fav;
      final avaliado = (b.nota > 0 ? 1 : 0) - (a.nota > 0 ? 1 : 0);
      if (avaliado != 0) return avaliado;
      final nota = b.nota.compareTo(a.nota);
      return nota != 0 ? nota : a.distanciaColetaKm.compareTo(b.distanciaColetaKm);
    }

    final motoristas = <OfertaParceiro>[];
    final transportadoras = <OfertaParceiro>[];
    for (final p in _parceiros) {
      final oferta = montar(p);
      if (oferta == null) continue;
      (p.tipo == 'motorista' ? motoristas : transportadoras).add(oferta);
    }
    motoristas.sort(ordenar);
    transportadoras.sort(ordenar);

    const vagasTransportadoras = _totalOfertas - _vagasMotoristas;
    final escolhidas = [
      ...motoristas.take(_vagasMotoristas),
      ...transportadoras.take(vagasTransportadoras),
    ];
    if (escolhidas.length < _totalOfertas) {
      final sobras = [
        ...motoristas.skip(_vagasMotoristas),
        ...transportadoras.skip(vagasTransportadoras),
      ]..sort(ordenar);
      escolhidas.addAll(sobras.take(_totalOfertas - escolhidas.length));
    }
    escolhidas.sort((a, b) => a.total.compareTo(b.total));

    return Cotacao(
      distanciaKm: km,
      paradas: paradas.length,
      ofertas: escolhidas,
      cupomAplicado: escolhidas.any((o) => o.desconto > 0) ? cupom?.toUpperCase() : null,
      avisos: const [
        'Pedagio e estacionamento nao estao inclusos e sao acertados direto com o parceiro.',
        'O peso declarado nao pode exceder a capacidade do veiculo escolhido.',
      ],
    );
  }

  // -------------------------------------------------------------- cotacao
  @override
  Future<Cotacao> cotar({
    required int categoriaId,
    required List<Endereco> paradas,
    List<int> servicos = const [],
    int? horas,
    String? cupom,
  }) =>
      _demora(_montarCotacao(
        categoriaId: categoriaId,
        paradas: paradas,
        servicos: servicos,
        horas: horas,
        cupom: cupom,
      ));

  // -------------------------------------------------------------- pedidos
  static const _fluxo = [
    'aguardando_alocacao', 'alocado', 'em_deslocamento_coleta',
    'carregando', 'em_transito', 'entregue', 'concluido',
  ];

  Pedido _comOferta(Pedido pedido, OfertaParceiro oferta, List<EventoPedido> eventos,
          {String? situacao}) =>
      pedido.copiarCom(
        situacao: situacao,
        valorFrete: oferta.valorFrete,
        valorAdicionais: oferta.valorAdicionais,
        valorDesconto: oferta.desconto,
        valorTotal: oferta.total,
        motoristaNome: oferta.ehMotorista ? oferta.nome : null,
        motoristaAvaliacao: oferta.ehMotorista ? oferta.nota : null,
        transportadoraNome: oferta.ehMotorista ? null : oferta.nome,
        transportadoraAvaliacao: oferta.ehMotorista ? null : oferta.nota,
        veiculoPlaca: 'SOL${(oferta.parceiroId % 10000).toString().padLeft(4, '0')}',
        eventos: eventos,
      );

  void _debitarCarteira(Pedido pedido, double valor, String descricao) {
    if (pedido.formaPagamento != 'carteira') return;
    _saldo -= valor;
    _transacoes.insert(0, TransacaoCarteira(tipo: 'pagamento', valor: -valor,
        descricao: descricao, quando: DateTime.now()));
  }

  @override
  Future<Pedido> criarPedido(Map<String, dynamic> corpo) async {
    final categoriaId = corpo['categoriaId'] as int;
    final categoria = _veiculos.firstWhere((v) => v.id == categoriaId);
    final paradas = corpo['paradas'] as List<Endereco>;
    final servicosIds = (corpo['servicos'] as List<int>?) ?? const <int>[];
    final horas = corpo['horasContratadas'] as int?;
    final cupom = corpo['cupom'] as String?;
    final chave = '${corpo['parceiroTipo']}-${corpo['parceiroId']}';

    // mesma validacao da API (POST /pedidos): carga valida e compativel com o veiculo
    final carga = corpo['carga'] as Carga?;
    if (carga == null || validarCarga(carga).isNotEmpty) {
      throw ErroApi('Preencha os detalhes da carga', 400);
    }
    final compat = verificarCompatibilidade(carga, categoria);
    if (!compat.compativel) {
      throw ErroApi('Carga incompatível com o veículo escolhido: ${compat.motivo}', 422);
    }

    final cotacao = _montarCotacao(
        categoriaId: categoriaId, paradas: paradas, servicos: servicosIds,
        horas: horas, cupom: cupom);
    final oferta = cotacao.ofertas.where((o) => o.chave == chave).firstOrNull;
    if (oferta == null) {
      throw ErroApi('Este parceiro não está mais disponível. Escolha outra opção.', 422);
    }

    final id = ++_proximoId;
    final agora = DateTime.now();
    final base = Pedido(
      id: id,
      codigo: 'SF-${id.toString().padLeft(6, '0')}',
      situacao: 'aguardando_alocacao',
      nivelServico: 'padrao',
      tipoRetirada: corpo['tipoRetirada'] as String,
      agendadoPara: corpo['agendadoPara'] as DateTime?,
      categoriaNome: categoria.nome,
      distanciaKm: cotacao.distanciaKm,
      valorFrete: oferta.valorFrete,
      valorTotal: oferta.total,
      formaPagamento: corpo['formaPagamento'] as String?,
      pagador: (corpo['pagador'] ?? 'remetente') as String,
      observacaoMotorista: corpo['observacaoMotorista'] as String?,
      criadoEm: agora,
      paradas: [
        for (var i = 0; i < paradas.length; i++)
          Parada(tipo: i == 0 ? 'coleta' : 'entrega', endereco: paradas[i]),
      ],
      carga: corpo['carga'] as Carga?,
      servicos: categoria.servicos.where((s) => servicosIds.contains(s.id)).toList(),
    );
    final pedido = _comOferta(base, oferta, [
      EventoPedido(situacao: 'cotado', descricao: 'Pedido criado com ${oferta.nome}',
          quando: agora),
      EventoPedido(situacao: 'aguardando_alocacao',
          descricao: 'Aguardando aceite de ${oferta.nome}', quando: agora),
    ]);

    _pedidos.insert(0, pedido);
    _contextos[id] = _ContextoCotacao(
        categoriaId: categoriaId, paradas: paradas, servicos: servicosIds,
        horas: horas, cupom: cupom)
      ..parceiroAtual = chave;
    _operacionais.insert(0, Notificacao(id: ++_proximoId, titulo: 'Pedido criado',
        mensagem: 'Enviamos o pedido ${pedido.codigo} para ${oferta.nome}. Aguarde o aceite.',
        quando: agora));
    _debitarCarteira(pedido, pedido.valorTotal, 'Pedido ${pedido.codigo}');

    return _demora(pedido);
  }

  @override
  Future<List<Pedido>> listarPedidos({String situacao = 'em_andamento', String? busca}) {
    Iterable<Pedido> lista = _pedidos;
    if (situacao == 'concluido') {
      lista = lista.where((p) => p.situacao == 'concluido');
    } else if (situacao == 'cancelado') {
      lista = lista.where((p) => p.situacao == 'cancelado');
    } else {
      lista = lista.where((p) => p.emAndamento);
    }
    if (busca != null && busca.isNotEmpty) {
      final t = busca.toLowerCase();
      lista = lista.where((p) =>
          p.codigo.toLowerCase().contains(t) ||
          (p.origem?.logradouro ?? '').toLowerCase().contains(t) ||
          (p.destino?.logradouro ?? '').toLowerCase().contains(t));
    }
    return _demora(lista.toList());
  }

  /// O parceiro aceitou: o pedido passa a "alocado".
  Pedido _aceitar(int indice) {
    final atual = _pedidos[indice];
    final agora = DateTime.now();
    final novo = atual.copiarCom(situacao: 'alocado', eventos: [
      ...atual.eventos,
      EventoPedido(situacao: 'alocado',
          descricao: '${atual.parceiroNome} aceitou o pedido', quando: agora),
    ]);
    _pedidos[indice] = novo;
    _operacionais.insert(0, Notificacao(id: ++_proximoId, titulo: 'Pedido ${atual.codigo}',
        mensagem: '${atual.parceiroNome} aceitou o seu pedido.', quando: agora));
    return novo;
  }

  @override
  Future<Pedido> obterPedido(int id) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    var pedido = _pedidos[indice];
    if (pedido.aguardandoAceite && pedido.parceiroNome != null && pedido.eventos.isNotEmpty) {
      final desde = pedido.eventos.last.quando;
      if (desde != null && DateTime.now().difference(desde) >= _aceiteAutomatico) {
        pedido = _aceitar(indice);
      }
    }
    return _demora(pedido);
  }

  @override
  Future<Pedido> avancarPedido(int id) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    final atual = _pedidos[indice];
    if (atual.aguardandoEscolha) return _demora(atual);
    final posicao = _fluxo.indexOf(atual.situacao);
    if (posicao < 0 || posicao + 1 >= _fluxo.length) return _demora(atual);
    final proxima = _fluxo[posicao + 1];
    if (proxima == 'alocado' && atual.parceiroNome != null) {
      return _demora(_aceitar(indice));
    }

    final atualizado = atual.copiarCom(
      situacao: proxima,
      paradas: [
        for (final p in atual.paradas)
          Parada(
            tipo: p.tipo,
            endereco: p.endereco,
            situacao: (proxima == 'em_transito' && p.tipo == 'coleta') ||
                    (['entregue', 'concluido'].contains(proxima))
                ? 'concluida'
                : p.situacao,
            concluidaEm: p.concluidaEm,
          ),
      ],
      eventos: [
        ...atual.eventos,
        EventoPedido(situacao: proxima, descricao: 'Atualizacao de etapa',
            quando: DateTime.now()),
      ],
    );

    _pedidos[indice] = atualizado;
    _operacionais.insert(0, Notificacao(id: ++_proximoId,
        titulo: 'Pedido ${atual.codigo}',
        mensagem: 'Nova etapa: ${proxima.replaceAll('_', ' ')}',
        quando: DateTime.now()));
    return _demora(atualizado);
  }

  @override
  Future<Cotacao> cotarPedido(int id) async {
    final ctx = _contextos[id];
    final pedido = _pedidos.firstWhere((p) => p.id == id);
    if (ctx == null || !pedido.aguardandoEscolha) {
      throw ErroApi('Este pedido não está aguardando a escolha de um parceiro', 409);
    }
    return _demora(_montarCotacao(
      categoriaId: ctx.categoriaId, paradas: ctx.paradas, servicos: ctx.servicos,
      horas: ctx.horas, cupom: ctx.cupom, excluir: ctx.recusados,
    ));
  }

  @override
  Future<Pedido> recusarParceiro(int id) async {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    final atual = _pedidos[indice];
    final ctx = _contextos[id];
    if (!atual.aguardandoAceite || atual.parceiroNome == null || ctx == null) {
      throw ErroApi('Só é possível simular a recusa enquanto o parceiro ainda não aceitou', 409);
    }
    final agora = DateTime.now();
    final nome = atual.parceiroNome!;
    if (ctx.parceiroAtual != null) ctx.recusados.add(ctx.parceiroAtual!);
    ctx.parceiroAtual = null;

    final novo = atual.copiarCom(situacao: 'cotado', limparParceiro: true, eventos: [
      ...atual.eventos,
      EventoPedido(situacao: 'cotado',
          descricao: '$nome recusou o pedido. Escolha outro parceiro.', quando: agora),
    ]);
    _pedidos[indice] = novo;
    if (atual.formaPagamento == 'carteira') {
      _saldo += atual.valorTotal;
      _transacoes.insert(0, TransacaoCarteira(tipo: 'estorno', valor: atual.valorTotal,
          descricao: 'Pedido ${atual.codigo} - parceiro recusou', quando: agora));
    }
    _operacionais.insert(0, Notificacao(id: ++_proximoId, titulo: 'Pedido ${atual.codigo}',
        mensagem: '$nome nao pode atender. Escolha outro parceiro para continuar.',
        quando: agora));
    return _demora(novo);
  }

  @override
  Future<Pedido> trocarParceiro(int id, OfertaParceiro oferta) async {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    final atual = _pedidos[indice];
    final ctx = _contextos[id];
    if (!atual.aguardandoEscolha || ctx == null) {
      throw ErroApi('Este pedido não está aguardando a escolha de um parceiro', 409);
    }
    // recalcula: o preco nunca vem da tela
    final nova = _montarCotacao(
      categoriaId: ctx.categoriaId, paradas: ctx.paradas, servicos: ctx.servicos,
      horas: ctx.horas, cupom: ctx.cupom, excluir: ctx.recusados,
    ).ofertas.where((o) => o.chave == oferta.chave).firstOrNull;
    if (nova == null) {
      throw ErroApi('Este parceiro não está mais disponível. Escolha outra opção.', 422);
    }

    final agora = DateTime.now();
    final novo = _comOferta(atual, nova, [
      ...atual.eventos,
      EventoPedido(situacao: 'aguardando_alocacao',
          descricao: 'Aguardando aceite de ${nova.nome}', quando: agora),
    ], situacao: 'aguardando_alocacao');
    _pedidos[indice] = novo;
    ctx.parceiroAtual = nova.chave;
    _debitarCarteira(novo, novo.valorTotal, 'Pedido ${novo.codigo}');
    return _demora(novo);
  }

  @override
  Future<double> cancelarPedido(int id, String motivo) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    final atual = _pedidos[indice];
    final taxa = ['alocado', 'em_deslocamento_coleta', 'carregando']
            .contains(atual.situacao)
        ? double.parse((atual.valorTotal * 0.15).toStringAsFixed(2))
        : 0.0;

    _pedidos[indice] = atual.copiarCom(situacao: 'cancelado', eventos: [
      ...atual.eventos,
      EventoPedido(situacao: 'cancelado',
          descricao: taxa > 0
              ? 'Cancelado com taxa de R\$ ${taxa.toStringAsFixed(2)}'
              : 'Cancelado sem taxa',
          quando: DateTime.now()),
    ]);
    return _demora(taxa);
  }

  @override
  Future<void> avaliarPedido(int id, int nota, String? comentario, bool favoritar) {
    if (favoritar) {
      final pedido = _pedidos.firstWhere((p) => p.id == id);
      final nome = pedido.motoristaNome ?? 'Parceiro Solus';
      if (!_favoritos.any((f) => f.nome == nome)) {
        _favoritos.add(MotoristaFavorito(motoristaId: ++_proximoId, nome: nome,
            telefone: '119${_rnd.nextInt(89999999) + 10000000}',
            avaliacao: pedido.motoristaAvaliacao ?? 5,
            totalCorridas: 40 + _rnd.nextInt(200), disponivel: true,
            veiculos: pedido.categoriaNome));
      }
    }
    return _demora(null);
  }

  // ------------------------------------------------------------ favoritos
  @override
  Future<List<MotoristaFavorito>> favoritos() => _demora(_favoritos);

  @override
  Future<String> convidarMotorista(String telefone, String? nome) {
    _favoritos.add(MotoristaFavorito(motoristaId: ++_proximoId,
        nome: nome == null || nome.isEmpty ? 'Convite pendente' : nome,
        telefone: telefone, avaliacao: 0, totalCorridas: 0, disponivel: false));
    return _demora(
        'Convite enviado por SMS. Quando ele concluir o cadastro e for homologado, entra nos seus favoritos.');
  }

  @override
  Future<void> removerFavorito(int motoristaId) {
    _favoritos.removeWhere((f) => f.motoristaId == motoristaId);
    return _demora(null);
  }

  // ------------------------------------------------------------- carteira
  @override
  Future<Carteira> carteira() =>
      _demora(Carteira(saldo: _saldo, transacoes: List.of(_transacoes)));

  @override
  Future<double> recarregar(double valor) {
    _saldo += valor;
    _transacoes.insert(0, TransacaoCarteira(tipo: 'recarga', valor: valor,
        descricao: 'Recarga de R\$ ${valor.toStringAsFixed(2)}',
        quando: DateTime.now()));
    return _demora(_saldo);
  }

  @override
  Future<({List<Notificacao> operacionais, List<Notificacao> promocionais})>
      notificacoes() =>
          _demora((operacionais: List.of(_operacionais), promocionais: List.of(_promocionais)));
}

class _Parceiro {
  const _Parceiro({
    required this.tipo,
    required this.id,
    required this.nome,
    required this.categoriaId,
    required this.lat,
    required this.lng,
    required this.raioKm,
    required this.fator,
    required this.nota,
    required this.fretes,
    this.disponivel = true,
  });

  final String tipo; // 'motorista' | 'transportadora'
  final int id;
  final String nome;
  final int categoriaId; // 0 = atende todas as categorias (transportadora)
  final double lat;
  final double lng;
  final int raioKm;
  final double fator;
  final double nota;
  final int fretes;
  final bool disponivel;

  String get chave => '$tipo-$id';
}

/// Dados necessarios para refazer a cotacao de um pedido depois da recusa do parceiro.
class _ContextoCotacao {
  _ContextoCotacao({
    required this.categoriaId,
    required this.paradas,
    required this.servicos,
    this.horas,
    this.cupom,
  });

  final int categoriaId;
  final List<Endereco> paradas;
  final List<int> servicos;
  final int? horas;
  final String? cupom;
  final Set<String> recusados = {};
  String? parceiroAtual;
}
