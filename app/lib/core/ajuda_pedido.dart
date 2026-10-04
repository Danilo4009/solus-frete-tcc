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
  'Toque em "De onde vamos retirar?" e busque o endereco de coleta pela rua, numero ou '
      'nome de um local salvo. Depois toque em "Para onde?" para o endereco de entrega.\n\n'
      'Tem mais de uma entrega? Use "Adicionar parada". O botao com as setas inverte a '
      'coleta e a entrega. Para agendar, toque em "Retirar agora" e escolha data e hora.',
);

const _cargaMedidas = ItemAjuda(
  'Como medir e informar peso e dimensoes',
  'Peso total: some o peso de todos os volumes, em kg. Se nao souber ao certo, arredonde '
      'para cima: pesar a carga a mais evita problemas na coleta.\n\n'
      'Dimensoes: meca apenas o MAIOR volume da carga (comprimento, largura e altura), em '
      'centimetros. Nao precisa ser exato, mas nao subestime. O volume pode ser girado para '
      'caber no bau.\n\n'
      'Quantidade de volumes: quantas caixas, pacotes ou pecas separadas voce vai enviar.',
);

const _desabilitados = ItemAjuda(
  'Por que alguns veiculos aparecem desabilitados',
  'Quando voce informa a carga, mostramos so o que cabe. Um veiculo fica acinzentado, com '
      'o motivo logo abaixo, quando:\n'
      '- o peso total passa da capacidade dele;\n'
      '- o maior volume nao cabe no bau;\n'
      '- a carga e refrigerada ou perigosa e o veiculo nao e habilitado para isso.\n\n'
      'Para liberar, escolha um veiculo maior ou revise os valores informados. Se nenhum '
      'servir, divida a carga em mais de um pedido ou fale com a gente.',
);

const _depoisDoPedido = ItemAjuda(
  'O que acontece depois de enviar o pedido',
  'Depois de escolher o veiculo, voce compara as propostas de motoristas parceiros e de '
      'transportadoras da sua regiao (preco, prazo e avaliacao) e escolhe uma. O parceiro '
      'escolhido recebe o pedido e aceita ou recusa. Se recusar, voce volta a lista para '
      'escolher outro.\n\n'
      'Depois do aceite, voce acompanha cada etapa da coleta e da entrega na aba Pedidos.',
);

/// Resumo dos veiculos gerado do config, para os numeros nunca ficarem desatualizados.
ItemAjuda _tiposDeVeiculo() {
  final linhas = [
    for (final v in veiculosConfig)
      '- ${v.nome}: ate ${_kg(v.pesoMaxKg)} kg. ${v.descricao}',
  ];
  return ItemAjuda(
    'Diferenca entre os tipos de veiculo',
    'Do menor para o maior:\n${linhas.join('\n')}\n\n'
        'Carga refrigerada so vai em veiculo com bau refrigerado, e carga perigosa so em '
        'veiculo habilitado. Em caso de duvida, escolha o menor veiculo que comporta a carga: '
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
