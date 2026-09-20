import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dataHora = DateFormat("dd/MM 'as' HH:mm", 'pt_BR');
final _dataCurta = DateFormat('dd/MM/yyyy', 'pt_BR');

String moeda(num valor) => _moeda.format(valor);

String dataHora(DateTime? d) => d == null ? '-' : _dataHora.format(d);

String dataCurta(DateTime? d) => d == null ? '-' : _dataCurta.format(d);

String km(num valor) => '${valor.toStringAsFixed(1).replaceAll('.', ',')} km';

/// 45 -> "45 min"; 75 -> "1h15".
String duracao(int minutos) {
  if (minutos < 60) return '$minutos min';
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

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
      return 'Em transito';
    case 'entregue':
      return 'Entregue';
    case 'concluido':
      return 'Concluido';
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
      return 'Material de construcao';
    case 'roupas_pessoais':
      return 'Roupas e itens pessoais';
    case 'moveis_eletrodomesticos':
      return 'Moveis e eletrodomesticos';
    case 'fragil':
      return 'Itens frageis';
    default:
      return 'Outros';
  }
}

String rotuloFaixaPeso(String faixa) {
  switch (faixa) {
    case 'ate_50':
      return 'Ate 50 kg';
    case 'ate_300':
      return 'Ate 300 kg';
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
      return 'Cartao de credito';
    case 'dinheiro':
      return 'Dinheiro';
    default:
      return forma;
  }
}
