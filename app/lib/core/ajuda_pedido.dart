import 'veiculos_config.dart';

/// Textos de ajuda da tela "Pedir". Ficam aqui para editar sem mexer na tela.

class ItemAjuda {
  const ItemAjuda(this.titulo, this.texto);

  final String titulo;
  final String texto;
}

/// Identificadores das secoes que tem um icone "i" proprio.
class SecaoAjuda {
  static const carga = 'carga';
  static const veiculo = 'veiculo';
}

const _enderecos = ItemAjuda(
  'Como preencher origem e destino',
  'Toque em "De onde vamos retirar?" e busque o endereço de coleta pela rua, número ou '
      'nome de um local salvo. Depois toque em "Para onde?" para o endereço de entrega.\n\n'
  'Tem mais de uma entrega? Use "Adicionar parada". O botão com as setas inverte a '
      'coleta e a entrega. Para agendar, toque em "Retirar agora" e escolha a data e a hora.',
);

const _cargaMedidas = ItemAjuda(
  'Como medir e informar peso e dimensões',
  'Peso total: some o peso de todos os volumes, em kg. Se não souber ao certo, arredonde '
      'para cima: pesar a carga a mais evita problemas na coleta.\n\n'
      'Dimensões: meça apenas o MAIOR volume da carga (comprimento, largura e altura), em '
      'centímetros. Não precisa ser exato, mas não subestime. O volume pode ser girado para '
      'caber no baú.\n\n'
      'Quantidade de volumes: quantas caixas, pacotes ou peças separadas você vai enviar.',
);

const _desabilitados = ItemAjuda(
  'Por que alguns veículos aparecem desabilitados',
  'Quando você informa a carga, mostramos só o que cabe. Um veículo fica acinzentado, com '
      'o motivo logo abaixo, quando:\n'
      '- o peso total passa da capacidade dele;\n'
      '- o maior volume não cabe no baú;\n'
      '- a carga é refrigerada ou perigosa e o veículo não é habilitado para isso.\n\n'
      'Para liberar, escolha um veículo maior ou revise os valores informados. Se nenhum '
      'servir, divida a carga em mais de um pedido ou fale com a gente.',
);

const _depoisDoPedido = ItemAjuda(
  'O que acontece depois de enviar o pedido',
  'Depois de escolher o veículo, você compara as propostas de motoristas parceiros e de '
      'transportadoras da sua região (preço, prazo e avaliação) e escolhe uma. O parceiro '
      'escolhido recebe o pedido e aceita ou recusa. Se recusar, você volta à lista para '
      'escolher outro.\n\n'
      'Depois do aceite, você acompanha cada etapa da coleta e da entrega na aba Pedidos.',
);

/// Resumo dos veiculos gerado do config, para os numeros nunca ficarem desatualizados.
ItemAjuda _tiposDeVeiculo() {
  final linhas = [
    for (final v in veiculosConfig)
      '- ${v.nome}: até ${_kg(v.pesoMaxKg)} kg. ${v.descricao}',
  ];
  return ItemAjuda(
    'Diferença entre os tipos de veículo',
    'Do menor para o maior:\n${linhas.join('\n')}\n\n'
        'Carga refrigerada só vai em veículo com baú refrigerado, e carga perigosa só em '
        'veículo habilitado. Em caso de dúvida, escolha o menor veículo que comporta a carga: '
        'costuma sair mais barato.',
  );
}

String _kg(int n) => n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

/// Todas as dicas, na ordem em que aparecem no botao "?".
List<ItemAjuda> get todasAsDicas => [
      _enderecos,
      _cargaMedidas,
      _desabilitados,
      _tiposDeVeiculo(),
      _depoisDoPedido,
    ];

/// Dicas de uma secao especifica (icone "i" ao lado do titulo).
List<ItemAjuda> dicasDaSecao(String secao) {
  switch (secao) {
    case SecaoAjuda.carga:
      return [_cargaMedidas];
    case SecaoAjuda.veiculo:
      return [_desabilitados, _tiposDeVeiculo()];
    default:
      return todasAsDicas;
  }
}
