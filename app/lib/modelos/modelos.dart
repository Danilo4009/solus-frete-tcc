// Modelos de dominio do Solus Frete.

class Usuario {
  final int id;
  final String tipo;
  final String nome;
  final String? sobrenome;
  final String telefone;
  final String? email;
  final String? setor;
  final Empresa? empresa;

  const Usuario({
    required this.id,
    required this.tipo,
    required this.nome,
    this.sobrenome,
    required this.telefone,
    this.email,
    this.setor,
    this.empresa,
  });

  String get nomeCompleto => sobrenome == null ? nome : '$nome $sobrenome';

  factory Usuario.doJson(Map<String, dynamic> j) => Usuario(
        id: j['id'] as int,
        tipo: j['tipo'] as String,
        nome: j['nome'] as String,
        sobrenome: j['sobrenome'] as String?,
        telefone: j['telefone'] as String,
        email: j['email'] as String?,
        setor: j['setor_atuacao'] as String?,
        empresa: j['empresa'] == null
            ? null
            : Empresa.doJson(j['empresa'] as Map<String, dynamic>),
      );
}

class Empresa {
  final int id;
  final String tipo;
  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;

  const Empresa({
    required this.id,
    required this.tipo,
    required this.cnpj,
    required this.razaoSocial,
    this.nomeFantasia,
  });

  factory Empresa.doJson(Map<String, dynamic> j) => Empresa(
        id: j['id'] as int,
        tipo: j['tipo'] as String,
        cnpj: j['cnpj'] as String,
        razaoSocial: j['razao_social'] as String,
        nomeFantasia: j['nome_fantasia'] as String?,
      );
}

class Endereco {
  final int? id;
  final String? apelido;
  final String logradouro;
  final String? numero;
  final String? complemento;
  final String? referencia;
  final String? bairro;
  final String cidade;
  final String uf;
  final double? latitude;
  final double? longitude;
  final String? contatoNome;
  final String? contatoTelefone;
  final bool favorito;

  const Endereco({
    this.id,
    this.apelido,
    required this.logradouro,
    this.numero,
    this.complemento,
    this.referencia,
    this.bairro,
    required this.cidade,
    required this.uf,
    this.latitude,
    this.longitude,
    this.contatoNome,
    this.contatoTelefone,
    this.favorito = false,
  });

  String get linhaPrincipal =>
      numero == null || numero!.isEmpty ? logradouro : '$logradouro, $numero';

  String get linhaSecundaria {
    final partes = <String>[];
    if (complemento != null && complemento!.isNotEmpty) partes.add(complemento!);
    if (referencia != null && referencia!.isNotEmpty) partes.add(referencia!);
    if (partes.isEmpty && bairro != null) partes.add(bairro!);
    partes.add(cidade);
    return partes.join(' - ');
  }

  Endereco copiarCom({
    String? complemento,
    String? referencia,
    String? contatoNome,
    String? contatoTelefone,
    String? apelido,
    bool? favorito,
  }) =>
      Endereco(
        id: id,
        apelido: apelido ?? this.apelido,
        logradouro: logradouro,
        numero: numero,
        complemento: complemento ?? this.complemento,
        referencia: referencia ?? this.referencia,
        bairro: bairro,
        cidade: cidade,
        uf: uf,
        latitude: latitude,
        longitude: longitude,
        contatoNome: contatoNome ?? this.contatoNome,
        contatoTelefone: contatoTelefone ?? this.contatoTelefone,
        favorito: favorito ?? this.favorito,
      );

  factory Endereco.doJson(Map<String, dynamic> j) => Endereco(
        id: j['id'] as int?,
        apelido: j['apelido'] as String?,
        logradouro: j['logradouro'] as String,
        numero: j['numero'] as String?,
        complemento: j['complemento'] as String?,
        referencia: j['referencia'] as String?,
        bairro: j['bairro'] as String?,
        cidade: j['cidade'] as String,
        uf: j['uf'] as String,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        contatoNome: j['contato_nome'] as String?,
        contatoTelefone: j['contato_telefone'] as String?,
        favorito: (j['favorito'] ?? 0) == 1 || j['favorito'] == true,
      );

  Map<String, dynamic> paraJson({String? tipo}) => {
        if (tipo != null) 'tipo': tipo,
        if (id != null) 'enderecoId': id,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'referencia': referencia,
        'cidade': cidade,
        'uf': uf,
        'latitude': latitude,
        'longitude': longitude,
        'contatoNome': contatoNome,
        'contatoTelefone': contatoTelefone,
      };
}

class ServicoAdicional {
  final int id;
  final String codigo;
  final String nome;
  final String? descricao;
  final double preco;

  const ServicoAdicional({
    required this.id,
    required this.codigo,
    required this.nome,
    this.descricao,
    required this.preco,
  });

  factory ServicoAdicional.doJson(Map<String, dynamic> j) => ServicoAdicional(
        id: j['id'] as int,
        codigo: j['codigo'] as String,
        nome: j['nome'] as String,
        descricao: j['descricao'] as String?,
        preco: (j['preco'] as num).toDouble(),
      );
}

class CategoriaVeiculo {
  final int id;
  final String codigo;
  final String nome;
  final String? descricao;
  final double comprimentoM;
  final double larguraM;
  final double alturaM;
  final int pesoMaxKg;
  final double? valorHora;
  final List<ServicoAdicional> servicos;

  const CategoriaVeiculo({
    required this.id,
    required this.codigo,
    required this.nome,
    this.descricao,
    required this.comprimentoM,
    required this.larguraM,
    required this.alturaM,
    required this.pesoMaxKg,
    this.valorHora,
    this.servicos = const [],
  });

  String get dimensoes =>
      '${comprimentoM.toStringAsFixed(1)} x ${larguraM.toStringAsFixed(1)} x ${alturaM.toStringAsFixed(1)} m';

  factory CategoriaVeiculo.doJson(Map<String, dynamic> j) => CategoriaVeiculo(
        id: j['id'] as int,
        codigo: j['codigo'] as String,
        nome: j['nome'] as String,
        descricao: j['descricao'] as String?,
        comprimentoM: (j['comprimento_m'] as num?)?.toDouble() ?? 0,
        larguraM: (j['largura_m'] as num?)?.toDouble() ?? 0,
        alturaM: (j['altura_m'] as num?)?.toDouble() ?? 0,
        pesoMaxKg: (j['peso_max_kg'] as num).toInt(),
        valorHora: (j['valor_hora'] as num?)?.toDouble(),
        servicos: ((j['servicos'] as List?) ?? const [])
            .map((e) => ServicoAdicional.doJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class OpcaoCotacao {
  final String nivel;
  final String nome;
  final String descricao;
  final double valorFrete;
  final double valorAdicionais;
  final double desconto;
  final double total;
  final bool recomendado;

  const OpcaoCotacao({
    required this.nivel,
    required this.nome,
    required this.descricao,
    required this.valorFrete,
    required this.valorAdicionais,
    required this.desconto,
    required this.total,
    this.recomendado = false,
  });

  factory OpcaoCotacao.doJson(Map<String, dynamic> j) => OpcaoCotacao(
        nivel: j['nivel'] as String,
        nome: j['nome'] as String,
        descricao: j['descricao'] as String,
        valorFrete: (j['valorFrete'] as num).toDouble(),
        valorAdicionais: (j['valorAdicionais'] as num).toDouble(),
        desconto: (j['desconto'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
        recomendado: j['recomendado'] == true,
      );
}

class Cotacao {
  final double distanciaKm;
  final int paradas;
  final List<OpcaoCotacao> opcoes;
  final List<String> avisos;
  final String? cupomAplicado;

  const Cotacao({
    required this.distanciaKm,
    required this.paradas,
    required this.opcoes,
    this.avisos = const [],
    this.cupomAplicado,
  });

  factory Cotacao.doJson(Map<String, dynamic> j) => Cotacao(
        distanciaKm: (j['distanciaKm'] as num).toDouble(),
        paradas: (j['paradas'] as num).toInt(),
        opcoes: (j['opcoes'] as List)
            .map((e) => OpcaoCotacao.doJson(e as Map<String, dynamic>))
            .toList(),
        avisos: ((j['avisos'] as List?) ?? const []).map((e) => e as String).toList(),
        cupomAplicado: j['cupom'] == null ? null : j['cupom']['codigo'] as String?,
      );
}

class Carga {
  final String tipoItem;
  final int volumes;
  final String faixaPeso;
  final bool fragil;
  final bool naoEmpilhar;
  final bool refrigerado;
  final String? observacoes;

  const Carga({
    this.tipoItem = 'outros',
    this.volumes = 1,
    this.faixaPeso = 'ate_50',
    this.fragil = false,
    this.naoEmpilhar = false,
    this.refrigerado = false,
    this.observacoes,
  });

  Carga copiarCom({
    String? tipoItem,
    int? volumes,
    String? faixaPeso,
    bool? fragil,
    bool? naoEmpilhar,
    bool? refrigerado,
    String? observacoes,
  }) =>
      Carga(
        tipoItem: tipoItem ?? this.tipoItem,
        volumes: volumes ?? this.volumes,
        faixaPeso: faixaPeso ?? this.faixaPeso,
        fragil: fragil ?? this.fragil,
        naoEmpilhar: naoEmpilhar ?? this.naoEmpilhar,
        refrigerado: refrigerado ?? this.refrigerado,
        observacoes: observacoes ?? this.observacoes,
      );

  factory Carga.doJson(Map<String, dynamic> j) => Carga(
        tipoItem: (j['tipo_item'] ?? 'outros') as String,
        volumes: (j['volumes'] as num?)?.toInt() ?? 1,
        faixaPeso: (j['faixa_peso'] ?? 'ate_50') as String,
        fragil: (j['instrucao_fragil'] ?? 0) == 1,
        naoEmpilhar: (j['instrucao_nao_empilhar'] ?? 0) == 1,
        refrigerado: (j['instrucao_refrigerado'] ?? 0) == 1,
        observacoes: j['observacoes'] as String?,
      );

  Map<String, dynamic> paraJson() => {
        'tipoItem': tipoItem,
        'volumes': volumes,
        'faixaPeso': faixaPeso,
        'fragil': fragil,
        'naoEmpilhar': naoEmpilhar,
        'refrigerado': refrigerado,
        'observacoes': observacoes,
      };
}

class Parada {
  final String tipo; // coleta | entrega
  final Endereco endereco;
  final String situacao;
  final DateTime? concluidaEm;

  const Parada({
    required this.tipo,
    required this.endereco,
    this.situacao = 'pendente',
    this.concluidaEm,
  });

  factory Parada.doJson(Map<String, dynamic> j) => Parada(
        tipo: j['tipo'] as String,
        endereco: Endereco.doJson(j),
        situacao: (j['situacao'] ?? 'pendente') as String,
        concluidaEm: j['concluida_em'] == null
            ? null
            : DateTime.tryParse(j['concluida_em'] as String),
      );
}

class EventoPedido {
  final String situacao;
  final String? descricao;
  final DateTime? quando;

  const EventoPedido({required this.situacao, this.descricao, this.quando});

  factory EventoPedido.doJson(Map<String, dynamic> j) => EventoPedido(
        situacao: j['situacao'] as String,
        descricao: j['descricao'] as String?,
        quando: j['criado_em'] == null
            ? null
            : DateTime.tryParse(j['criado_em'] as String),
      );
}

class Pedido {
  final int id;
  final String codigo;
  final String situacao;
  final String nivelServico;
  final String tipoRetirada;
  final DateTime? agendadoPara;
  final String categoriaNome;
  final double distanciaKm;
  final double valorFrete;
  final double valorAdicionais;
  final double valorDesconto;
  final double valorTotal;
  final String? formaPagamento;
  final String pagador;
  final bool favoritosPrimeiro;
  final String? motoristaNome;
  final double? motoristaAvaliacao;
  final String? veiculoPlaca;
  final String? observacaoMotorista;
  final DateTime criadoEm;
  final List<Parada> paradas;
  final Carga? carga;
  final List<ServicoAdicional> servicos;
  final List<EventoPedido> eventos;

  const Pedido({
    required this.id,
    required this.codigo,
    required this.situacao,
    required this.nivelServico,
    required this.tipoRetirada,
    this.agendadoPara,
    required this.categoriaNome,
    required this.distanciaKm,
    required this.valorFrete,
    this.valorAdicionais = 0,
    this.valorDesconto = 0,
    required this.valorTotal,
    this.formaPagamento,
    this.pagador = 'remetente',
    this.favoritosPrimeiro = false,
    this.motoristaNome,
    this.motoristaAvaliacao,
    this.veiculoPlaca,
    this.observacaoMotorista,
    required this.criadoEm,
    this.paradas = const [],
    this.carga,
    this.servicos = const [],
    this.eventos = const [],
  });

  Endereco? get origem {
    for (final p in paradas) {
      if (p.tipo == 'coleta') return p.endereco;
    }
    return null;
  }

  Endereco? get destino {
    Endereco? ultimo;
    for (final p in paradas) {
      if (p.tipo == 'entrega') ultimo = p.endereco;
    }
    return ultimo;
  }

  bool get emAndamento => !['concluido', 'cancelado'].contains(situacao);

  factory Pedido.doJson(Map<String, dynamic> j) => Pedido(
        id: j['id'] as int,
        codigo: j['codigo'] as String,
        situacao: j['situacao'] as String,
        nivelServico: (j['nivel_servico'] ?? 'padrao') as String,
        tipoRetirada: (j['tipo_retirada'] ?? 'imediata') as String,
        agendadoPara: j['agendado_para'] == null
            ? null
            : DateTime.tryParse((j['agendado_para'] as String).replaceFirst(' ', 'T')),
        categoriaNome: (j['categoria_nome'] ?? '') as String,
        distanciaKm: (j['distancia_km'] as num?)?.toDouble() ?? 0,
        valorFrete: (j['valor_frete'] as num?)?.toDouble() ?? 0,
        valorAdicionais: (j['valor_adicionais'] as num?)?.toDouble() ?? 0,
        valorDesconto: (j['valor_desconto'] as num?)?.toDouble() ?? 0,
        valorTotal: (j['valor_total'] as num?)?.toDouble() ?? 0,
        formaPagamento: j['forma_pagamento'] as String?,
        pagador: (j['pagador'] ?? 'remetente') as String,
        favoritosPrimeiro: (j['favoritos_primeiro'] ?? 0) == 1,
        motoristaNome: j['motorista_nome'] as String?,
        motoristaAvaliacao: (j['motorista_avaliacao'] as num?)?.toDouble(),
        veiculoPlaca: j['veiculo_placa'] as String?,
        observacaoMotorista: j['observacao_motorista'] as String?,
        criadoEm: DateTime.tryParse(
                ((j['criado_em'] ?? '') as String).replaceFirst(' ', 'T')) ??
            DateTime.now(),
        paradas: ((j['paradas'] as List?) ?? const [])
            .map((e) => Parada.doJson(e as Map<String, dynamic>))
            .toList(),
        carga: j['carga'] == null
            ? null
            : Carga.doJson(j['carga'] as Map<String, dynamic>),
        servicos: ((j['servicos'] as List?) ?? const [])
            .map((e) => ServicoAdicional.doJson(e as Map<String, dynamic>))
            .toList(),
        eventos: ((j['eventos'] as List?) ?? const [])
            .map((e) => EventoPedido.doJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MotoristaFavorito {
  final int motoristaId;
  final String nome;
  final String telefone;
  final double avaliacao;
  final int totalCorridas;
  final bool disponivel;
  final String? veiculos;

  const MotoristaFavorito({
    required this.motoristaId,
    required this.nome,
    required this.telefone,
    required this.avaliacao,
    required this.totalCorridas,
    required this.disponivel,
    this.veiculos,
  });

  factory MotoristaFavorito.doJson(Map<String, dynamic> j) => MotoristaFavorito(
        motoristaId: j['motorista_id'] as int,
        nome: [j['nome'], j['sobrenome']]
            .where((e) => e != null && (e as String).isNotEmpty)
            .join(' '),
        telefone: (j['telefone'] ?? '') as String,
        avaliacao: (j['avaliacao_media'] as num?)?.toDouble() ?? 0,
        totalCorridas: (j['total_corridas'] as num?)?.toInt() ?? 0,
        disponivel: (j['disponivel'] ?? 0) == 1,
        veiculos: j['veiculos'] as String?,
      );
}

class Notificacao {
  final int id;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime? quando;

  const Notificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    this.lida = false,
    this.quando,
  });

  factory Notificacao.doJson(Map<String, dynamic> j) => Notificacao(
        id: j['id'] as int,
        titulo: j['titulo'] as String,
        mensagem: j['mensagem'] as String,
        lida: (j['lida'] ?? 0) == 1,
        quando: j['criada_em'] == null
            ? null
            : DateTime.tryParse((j['criada_em'] as String).replaceFirst(' ', 'T')),
      );
}

class Carteira {
  final double saldo;
  final List<TransacaoCarteira> transacoes;

  const Carteira({required this.saldo, this.transacoes = const []});
}

class TransacaoCarteira {
  final String tipo;
  final double valor;
  final String? descricao;
  final DateTime? quando;

  const TransacaoCarteira({
    required this.tipo,
    required this.valor,
    this.descricao,
    this.quando,
  });

  factory TransacaoCarteira.doJson(Map<String, dynamic> j) => TransacaoCarteira(
        tipo: j['tipo'] as String,
        valor: (j['valor'] as num).toDouble(),
        descricao: j['descricao'] as String?,
        quando: j['criada_em'] == null
            ? null
            : DateTime.tryParse((j['criada_em'] as String).replaceFirst(' ', 'T')),
      );
}
