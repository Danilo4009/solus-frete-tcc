import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dataHora = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
final _dataCurta = DateFormat('dd/MM/yyyy', 'pt_BR');

String moeda(num valor) => _moeda.format(valor);

String dataHora(DateTime? d) => d == null ? '-' : _dataHora.format(d);

String dataCurta(DateTime? d) => d == null ? '-' : _dataCurta.format(d);

String km(num valor) => '${valor.toStringAsFixed(1).replaceAll('.', ',')} km';

String rotuloSituacao(String situacao) {
  switch (situacao) {
    case 'rascunho':
      return 'Rascunho';
    case 'cotado':
      return 'Cotado';
    case 'aguardando_alocacao':
      return 'Buscando parceiro';
    case 'alocado':
      return 'Parceiro confirmado';
    case 'em_deslocamento_coleta':
      return 'A caminho da coleta';
    case 'carregando':
      return 'Carregando';
    case 'em_transito':
      return 'Em trânsito';
    case 'entregue':
      return 'Entregue';
    case 'concluido':
      return 'Concluído';
    case 'cancelado':
      return 'Cancelado';
    default:
      return situacao;
  }
}

String rotuloTipoItem(String tipo) {
  switch (tipo) {
    case 'alimentos':
      return 'Alimentos / mercado';
    case 'material_construcao':
      return 'Material de construção';
    case 'roupas_pessoais':
      return 'Roupas e itens pessoais';
    case 'moveis_eletrodomesticos':
      return 'Móveis e eletrodomésticos';
    case 'fragil':
      return 'Itens frágeis';
    default:
      return 'Outros';
  }
}

String rotuloFaixaPeso(String faixa) {
  switch (faixa) {
    case 'ate_50':
      return 'Até 50 kg';
    case 'ate_300':
      return 'Até 300 kg';
    case 'de_300_a_750':
      return 'De 300 a 750 kg';
    default:
      return 'Acima de 750 kg';
  }
}

String rotuloPagamento(String forma) {
  switch (forma) {
    case 'carteira':
      return 'Carteira Solus';
    case 'pix':
      return 'Pix';
    case 'cartao':
      return 'Cartão de crédito';
    case 'dinheiro':
      return 'Dinheiro';
    default:
      return forma;
  }
}
