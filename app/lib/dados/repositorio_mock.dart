import 'dart:math';

import '../core/config.dart';
import '../core/formato.dart';
import '../modelos/modelos.dart';
import 'repositorio.dart';

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

  static const _motoristas = [
    ('José Bezerra', 4.85, 312),
    ('Aline Souza', 4.92, 128),
    ('Rafael Nunes', 4.70, 64),
  ];

  // ---------------------------------------------------------------- preco
  static const _tarifas = {
    // codigo: (base, porKm, porParada, minimo, hora)
    'moto': (8.0, 1.90, 4.0, 14.0, 38.0),
    'carro_hatch': (14.0, 2.40, 6.0, 22.0, 52.0),
    'carro': (16.0, 2.70, 6.0, 26.0, 58.0),
    'utilitario': (28.0, 3.60, 10.0, 45.0, 78.0),
    'van': (38.0, 4.30, 10.0, 62.0, 92.0),
    'carreto': (52.0, 5.20, 10.0, 85.0, 110.0),
    'caminhao_35': (90.0, 7.40, 10.0, 140.0, 160.0),
    'caminhao_75': (140.0, 9.80, 10.0, 210.0, 220.0),
  };

  static const _fatores = {'expresso': 1.45, 'padrao': 1.00, 'economico': 0.74};

  void _semear() {
    const servicos = [
      ServicoAdicional(id: 1, codigo: 'ajuda_motorista', nome: 'Ajuda do motorista',
          descricao: 'Carga e descarga porta a porta feita pelo motorista.', preco: 70),
      ServicoAdicional(id: 2, codigo: 'ajudante_extra', nome: 'Ajudante extra',
          descricao: 'Motorista mais um ajudante para carga e descarga.', preco: 140),
      ServicoAdicional(id: 3, codigo: 'mudanca_completa', nome: 'Mudança completa',
          descricao: 'Motorista e ajudante com manuseio de móveis.', preco: 190),
      ServicoAdicional(id: 4, codigo: 'tempo_espera', nome: 'Tempo de espera',
          descricao: 'Espera adicional de até 60 minutos no local.', preco: 45),
      ServicoAdicional(id: 5, codigo: 'embalagem', nome: 'Embalagem e proteção',
          descricao: 'Plástico bolha e cinta para itens frágeis.', preco: 35),
      ServicoAdicional(id: 6, codigo: 'coleta_agendada', nome: 'Janela de coleta garantida',
          descricao: 'Compromisso de coleta dentro de uma hora específica.', preco: 25),
    ];

    List<ServicoAdicional> para(String codigo) {
      final lista = <ServicoAdicional>[servicos[3], servicos[5]];
      if (codigo != 'moto') lista.add(servicos[4]);
      if (['utilitario', 'van', 'carreto', 'caminhao_35', 'caminhao_75'].contains(codigo)) {
        lista.add(servicos[0]);
      }
      if (['van', 'carreto', 'caminhao_35', 'caminhao_75'].contains(codigo)) {
        lista.add(servicos[1]);
      }
      if (['carreto', 'caminhao_35', 'caminhao_75'].contains(codigo)) {
        lista.add(servicos[2]);
      }
      return lista;
    }

    _veiculos = [
      CategoriaVeiculo(id: 1, codigo: 'moto', nome: 'Moto',
          descricao: 'Documentos e encomendas pequenas.',
          comprimentoM: 0.4, larguraM: 0.35, alturaM: 0.3, pesoMaxKg: 20,
          valorHora: 38, servicos: para('moto')),
      CategoriaVeiculo(id: 2, codigo: 'carro_hatch', nome: 'Carro Hatch',
          descricao: 'Caixas pequenas e compras do dia.',
          comprimentoM: 1.0, larguraM: 0.8, alturaM: 0.6, pesoMaxKg: 150,
          valorHora: 52, servicos: para('carro_hatch')),
      CategoriaVeiculo(id: 3, codigo: 'carro', nome: 'Carro',
          descricao: 'Volumes médios no porta-malas e bancos.',
          comprimentoM: 1.2, larguraM: 0.9, alturaM: 0.7, pesoMaxKg: 200,
          valorHora: 58, servicos: para('carro')),
      CategoriaVeiculo(id: 4, codigo: 'utilitario', nome: 'Utilitário / Pick-Up',
          descricao: 'Cargas médias, obra leve e equipamentos.',
          comprimentoM: 1.8, larguraM: 1.4, alturaM: 1.0, pesoMaxKg: 700,
          valorHora: 78, servicos: para('utilitario')),
      CategoriaVeiculo(id: 5, codigo: 'van', nome: 'Van',
          descricao: 'Volume alto protegido da chuva.',
          comprimentoM: 2.4, larguraM: 1.5, alturaM: 1.4, pesoMaxKg: 1000,
          valorHora: 92, servicos: para('van')),
      CategoriaVeiculo(id: 6, codigo: 'carreto', nome: 'Carreto',
          descricao: 'Ideal para mudanças ou materiais grandes e pesados.',
          comprimentoM: 3.0, larguraM: 1.8, alturaM: 2.0, pesoMaxKg: 1500,
          valorHora: 110, servicos: para('carreto')),
      CategoriaVeiculo(id: 7, codigo: 'caminhao_35', nome: 'Caminhão 3/4',
          descricao: 'Cargas paletizadas e mudanças completas.',
          comprimentoM: 4.5, larguraM: 2.1, alturaM: 2.2, pesoMaxKg: 3500,
          valorHora: 160, servicos: para('caminhao_35')),
      CategoriaVeiculo(id: 8, codigo: 'caminhao_75', nome: 'Caminhão Toco',
          descricao: 'Carga fechada e transferências entre cidades.',
          comprimentoM: 6.0, larguraM: 2.4, alturaM: 2.5, pesoMaxKg: 7500,
          valorHora: 220, servicos: para('caminhao_75')),
    ];

    _enderecos.addAll(const [
      Endereco(id: 1, apelido: 'Casa', logradouro: 'Rua Salvador Nunes', numero: '120',
          complemento: 'Casa 2', referencia: 'Em frente à praça', bairro: 'Jardim Piratininga',
          cidade: 'Osasco', uf: 'SP', latitude: -23.5320, longitude: -46.7920,
          contatoNome: 'Danilo', contatoTelefone: '11940135904', favorito: true),
      Endereco(id: 2, apelido: 'Trabalho', logradouro: 'Avenida Paulista', numero: '1159',
          complemento: '9º andar', referencia: 'Próximo ao MASP', bairro: 'Bela Vista',
          cidade: 'São Paulo', uf: 'SP', latitude: -23.5660, longitude: -46.6520,
          contatoNome: 'Recepção', contatoTelefone: '1133334444', favorito: true),
      Endereco(id: 3, logradouro: 'Rua Pastoril de Nanuque', numero: '196',
          bairro: 'Ponte Rasa', cidade: 'São Paulo', uf: 'SP',
          latitude: -23.5170, longitude: -46.4780),
      Endereco(id: 4, logradouro: 'Rua 25 de Março', numero: '800', bairro: 'Centro',
          cidade: 'São Paulo', uf: 'SP', latitude: -23.5430, longitude: -46.6330),
      Endereco(id: 5, logradouro: 'Rua Cabo Diogo Oliveira', numero: '45',
          bairro: 'Vila Leopoldina', cidade: 'São Paulo', uf: 'SP',
          latitude: -23.5290, longitude: -46.7360),
    ]);

    _favoritos.add(const MotoristaFavorito(motoristaId: 1, nome: 'José Bezerra',
        telefone: '11977776666', avaliacao: 4.85, totalCorridas: 312,
        disponivel: true, veiculos: 'Carreto'));

    _transacoes.addAll([
      TransacaoCarteira(tipo: 'recarga', valor: 150, descricao: 'Recarga via Pix',
          quando: DateTime.now().subtract(const Duration(days: 8))),
      TransacaoCarteira(tipo: 'pagamento', valor: -30, descricao: 'Pedido SF-000001',
          quando: DateTime.now().subtract(const Duration(days: 7))),
    ]);

    _promocionais.add(Notificacao(id: 900, titulo: 'Cupom SOLUS10',
        mensagem: 'Use SOLUS10 e ganhe R\$ 10 no próximo frete.',
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
      carga: const Carga(tipoItem: 'outros', volumes: 1, faixaPeso: 'ate_50',
          observacoes: 'Envelope com contratos'),
      eventos: [
        EventoPedido(situacao: 'cotado', descricao: 'Cotação gerada',
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
      tipoRetirada: 'imediata', categoriaNome: 'Carreto', distanciaKm: 18.6,
      valorFrete: 148.72, valorAdicionais: 70, valorTotal: 218.72,
      formaPagamento: 'pix', favoritosPrimeiro: true,
      motoristaNome: 'José Bezerra', motoristaAvaliacao: 4.85, veiculoPlaca: 'ABC1D23',
      criadoEm: DateTime.now().subtract(const Duration(hours: 1)),
      paradas: [
        Parada(tipo: 'coleta', endereco: _enderecos[0], situacao: 'concluida'),
        Parada(tipo: 'entrega', endereco: _enderecos[1]),
      ],
      carga: const Carga(tipoItem: 'moveis_eletrodomesticos', volumes: 4,
          faixaPeso: 'de_300_a_750', fragil: true,
          observacoes: 'Uma mesa de vidro, favor não empilhar'),
      servicos: const [
        ServicoAdicional(id: 1, codigo: 'ajuda_motorista',
            nome: 'Ajuda do motorista', preco: 70),
      ],
      eventos: [
        EventoPedido(situacao: 'cotado', descricao: 'Cotação gerada',
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
      'Cadastro enviado para homologação da operação Solus. Você receberá um aviso quando for aprovado.');

  @override
  Future<String> cadastrarTransportadora(Map<String, dynamic> dados) => _demora(
      'Transportadora enviada para homologação. Após a aprovação você poderá cadastrar a frota.');

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
        cidade: 'São Paulo',
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

  // -------------------------------------------------------------- cotacao
  @override
  Future<Cotacao> cotar({
    required int categoriaId,
    required List<Endereco> paradas,
    List<int> servicos = const [],
    int? horas,
    String? cupom,
  }) {
    final categoria = _veiculos.firstWhere((v) => v.id == categoriaId);
    final tarifa = _tarifas[categoria.codigo]!;
    final km = _distancia(paradas);
    final extras = categoria.servicos
        .where((s) => servicos.contains(s.id))
        .fold<double>(0, (soma, s) => soma + s.preco);

    final opcoes = <OpcaoCotacao>[];
    const rotulos = {
      'expresso': ('Expresso', 'Alocação prioritária para entregas urgentes.'),
      'padrao': ('Padrão', 'Equilíbrio entre prazo e preço.'),
      'economico': ('Econômico', 'Carga agrupada, sem urgência. Mais barato.'),
    };

    for (final nivel in const ['expresso', 'padrao', 'economico']) {
      final f = _fatores[nivel]!;
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
      opcoes.add(OpcaoCotacao(
        nivel: nivel,
        nome: rotulos[nivel]!.$1,
        descricao: rotulos[nivel]!.$2,
        valorFrete: frete,
        valorAdicionais: extras,
        desconto: desconto,
        total: double.parse((frete + extras - desconto).toStringAsFixed(2)),
        recomendado: nivel == 'padrao',
      ));
    }

    return _demora(Cotacao(
      distanciaKm: km,
      paradas: paradas.length,
      opcoes: opcoes,
      cupomAplicado: opcoes.any((o) => o.desconto > 0) ? cupom?.toUpperCase() : null,
      avisos: const [
        'Pedágio e estacionamento não estão inclusos e são acertados direto com o parceiro.',
        'O peso declarado não pode exceder a capacidade do veículo escolhido.',
      ],
    ));
  }

  // --------------------------------------------------- motoristas proximos
  static const _nomesMotoristas = [
    'Carlos Almeida', 'Fernanda Lima', 'Marcos Ribeiro', 'Juliana Costa',
    'Paulo Henrique', 'Renata Dias', 'Thiago Martins', 'Patrícia Gomes',
    'André Santos', 'Camila Rocha', 'Eduardo Freitas', 'Larissa Pereira',
    'Rodrigo Barbosa', 'Vanessa Moura', 'Lucas Teixeira', 'Sérgio Cardoso',
  ];

  static const _modelos = {
    'moto': ['Honda CG 160 Cargo', 'Yamaha Factor 150', 'Honda Pop 110i'],
    'carro_hatch': ['Fiat Mobi', 'Renault Kwid', 'VW Gol'],
    'carro': ['Chevrolet Onix', 'Hyundai HB20', 'Fiat Argo'],
    'utilitario': ['Fiat Strada', 'VW Saveiro', 'Fiat Fiorino'],
    'van': ['Renault Master', 'Fiat Ducato', 'Mercedes Sprinter'],
    'carreto': ['Mercedes Sprinter Chassi', 'Iveco Daily', 'Kia Bongo'],
    'caminhao_35': ['VW Delivery 9.170', 'Mercedes Accelo', 'Iveco Tector'],
    'caminhao_75': ['VW Constellation', 'Mercedes Atego', 'Volvo VM'],
  };

  @override
  Future<List<MotoristaProximo>> motoristasProximos({
    required int categoriaId,
    required double latitude,
    required double longitude,
    int limite = 10,
  }) {
    final categoria = _veiculos.firstWhere((v) => v.id == categoriaId);
    // Mesma coleta e veiculo geram sempre a mesma lista.
    final rnd = Random(categoriaId * 7919 +
        (latitude * 1000).round() * 31 +
        (longitude * 1000).round());

    // Veiculos pequenos sao mais comuns na rua do que caminhoes.
    final quantidade = switch (categoria.codigo) {
      'moto' || 'carro_hatch' || 'carro' => 8 + rnd.nextInt(5),
      'utilitario' || 'van' || 'carreto' => 4 + rnd.nextInt(5),
      _ => 1 + rnd.nextInt(4),
    };
    final nomes = List.of(_nomesMotoristas)..shuffle(rnd);
    final modelos = _modelos[categoria.codigo] ?? const ['Veículo cadastrado'];

    final lista = <MotoristaProximo>[
      // Favoritos com essa categoria de veiculo aparecem se estiverem livres.
      for (final f in _favoritos)
        if (f.disponivel && f.veiculos == categoria.nome)
          MotoristaProximo(
            motoristaId: f.motoristaId,
            nome: f.nome,
            avaliacao: f.avaliacao,
            totalCorridas: f.totalCorridas,
            distanciaKm: double.parse((0.8 + rnd.nextDouble() * 5).toStringAsFixed(1)),
            veiculo: modelos.first,
            favorito: true,
          ),
      for (var i = 0; i < quantidade; i++)
        MotoristaProximo(
          motoristaId: 500 + categoriaId * 100 + i,
          nome: nomes[i % nomes.length],
          avaliacao: double.parse((4.3 + rnd.nextDouble() * 0.7).toStringAsFixed(2)),
          totalCorridas: 15 + rnd.nextInt(600),
          distanciaKm: double.parse((0.3 + rnd.nextDouble() * 7.5).toStringAsFixed(1)),
          veiculo: modelos[rnd.nextInt(modelos.length)],
        ),
    ]..sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));

    return _demora(lista.take(limite).toList());
  }

  // -------------------------------------------------------------- pedidos
  static const _fluxo = [
    'aguardando_alocacao', 'alocado', 'em_deslocamento_coleta',
    'carregando', 'em_transito', 'entregue', 'concluido',
  ];

  @override
  Future<Pedido> criarPedido(Map<String, dynamic> corpo) {
    final categoria = _veiculos.firstWhere((v) => v.id == corpo['categoriaId'] as int);
    final paradas = (corpo['paradas'] as List<Endereco>);
    final servicosIds = (corpo['servicos'] as List<int>?) ?? const [];
    final id = ++_proximoId;
    final favoritosPrimeiro = corpo['favoritosPrimeiro'] == true;

    final pedido = Pedido(
      id: id,
      codigo: 'SF-${id.toString().padLeft(6, '0')}',
      situacao: 'aguardando_alocacao',
      nivelServico: corpo['nivelServico'] as String,
      tipoRetirada: corpo['tipoRetirada'] as String,
      agendadoPara: corpo['agendadoPara'] as DateTime?,
      categoriaNome: categoria.nome,
      distanciaKm: (corpo['distanciaKm'] as num).toDouble(),
      valorFrete: (corpo['valorFrete'] as num).toDouble(),
      valorAdicionais: (corpo['valorAdicionais'] as num?)?.toDouble() ?? 0,
      valorDesconto: (corpo['valorDesconto'] as num?)?.toDouble() ?? 0,
      valorTotal: (corpo['valorTotal'] as num).toDouble(),
      formaPagamento: corpo['formaPagamento'] as String?,
      pagador: (corpo['pagador'] ?? 'remetente') as String,
      favoritosPrimeiro: favoritosPrimeiro,
      observacaoMotorista: corpo['observacaoMotorista'] as String?,
      criadoEm: DateTime.now(),
      paradas: [
        for (var i = 0; i < paradas.length; i++)
          Parada(tipo: i == 0 ? 'coleta' : 'entrega', endereco: paradas[i]),
      ],
      carga: corpo['carga'] as Carga?,
      servicos: categoria.servicos.where((s) => servicosIds.contains(s.id)).toList(),
      eventos: [
        EventoPedido(situacao: 'cotado', descricao: 'Pedido criado e cotado',
            quando: DateTime.now()),
        EventoPedido(
            situacao: 'aguardando_alocacao',
            descricao: favoritosPrimeiro && _favoritos.isNotEmpty
                ? 'Ofertado aos seus motoristas favoritos (${_favoritos.length})'
                : 'Ofertado a 6 parceiros da base',
            quando: DateTime.now()),
      ],
    );

    _pedidos.insert(0, pedido);
    _operacionais.insert(0, Notificacao(id: ++_proximoId, titulo: 'Pedido criado',
        mensagem: 'Estamos buscando um parceiro para o pedido ${pedido.codigo}.',
        quando: DateTime.now()));

    if (pedido.formaPagamento == 'carteira') {
      _saldo -= pedido.valorTotal;
      _transacoes.insert(0, TransacaoCarteira(tipo: 'pagamento',
          valor: -pedido.valorTotal, descricao: 'Pedido ${pedido.codigo}',
          quando: DateTime.now()));
    }

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

  @override
  Future<Pedido> obterPedido(int id) =>
      _demora(_pedidos.firstWhere((p) => p.id == id));

  @override
  Future<Pedido> avancarPedido(int id) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    final atual = _pedidos[indice];
    final posicao = _fluxo.indexOf(atual.situacao);
    if (posicao < 0 || posicao + 1 >= _fluxo.length) return _demora(atual);
    final proxima = _fluxo[posicao + 1];

    final motorista = _motoristas[_rnd.nextInt(_motoristas.length)];
    final atualizado = Pedido(
      id: atual.id, codigo: atual.codigo, situacao: proxima,
      nivelServico: atual.nivelServico, tipoRetirada: atual.tipoRetirada,
      agendadoPara: atual.agendadoPara, categoriaNome: atual.categoriaNome,
      distanciaKm: atual.distanciaKm, valorFrete: atual.valorFrete,
      valorAdicionais: atual.valorAdicionais, valorDesconto: atual.valorDesconto,
      valorTotal: atual.valorTotal, formaPagamento: atual.formaPagamento,
      pagador: atual.pagador, favoritosPrimeiro: atual.favoritosPrimeiro,
      motoristaNome: atual.motoristaNome ??
          (proxima == 'alocado' ? motorista.$1 : null),
      motoristaAvaliacao: atual.motoristaAvaliacao ??
          (proxima == 'alocado' ? motorista.$2 : null),
      veiculoPlaca: atual.veiculoPlaca ?? (proxima == 'alocado' ? 'ABC1D23' : null),
      observacaoMotorista: atual.observacaoMotorista,
      criadoEm: atual.criadoEm,
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
      carga: atual.carga, servicos: atual.servicos,
      eventos: [
        ...atual.eventos,
        EventoPedido(situacao: proxima,
            descricao: proxima == 'alocado'
                ? '${motorista.$1} aceitou o pedido'
                : 'Atualização de etapa',
            quando: DateTime.now()),
      ],
    );

    _pedidos[indice] = atualizado;
    _operacionais.insert(0, Notificacao(id: ++_proximoId,
        titulo: 'Pedido ${atual.codigo}',
        mensagem: 'Nova etapa: ${rotuloSituacao(proxima)}',
        quando: DateTime.now()));
    return _demora(atualizado);
  }

  @override
  Future<double> cancelarPedido(int id, String motivo) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    final atual = _pedidos[indice];
    final taxa = ['alocado', 'em_deslocamento_coleta', 'carregando']
            .contains(atual.situacao)
        ? double.parse((atual.valorTotal * 0.15).toStringAsFixed(2))
        : 0.0;

    _pedidos[indice] = Pedido(
      id: atual.id, codigo: atual.codigo, situacao: 'cancelado',
      nivelServico: atual.nivelServico, tipoRetirada: atual.tipoRetirada,
      agendadoPara: atual.agendadoPara, categoriaNome: atual.categoriaNome,
      distanciaKm: atual.distanciaKm, valorFrete: atual.valorFrete,
      valorAdicionais: atual.valorAdicionais, valorDesconto: atual.valorDesconto,
      valorTotal: atual.valorTotal, formaPagamento: atual.formaPagamento,
      pagador: atual.pagador, motoristaNome: atual.motoristaNome,
      criadoEm: atual.criadoEm, paradas: atual.paradas, carga: atual.carga,
      servicos: atual.servicos,
      eventos: [
        ...atual.eventos,
        EventoPedido(situacao: 'cancelado',
            descricao: taxa > 0
                ? 'Cancelado com taxa de R\$ ${taxa.toStringAsFixed(2)}'
                : 'Cancelado sem taxa',
            quando: DateTime.now()),
      ],
    );
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
