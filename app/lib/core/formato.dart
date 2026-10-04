import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dataHora = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
final _dataCurta = DateFormat('dd/MM/yyyy', 'pt_BR');
final _peso = NumberFormat('#,##0.##', 'pt_BR');

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

String rotuloTipoCarga(String tipo) {
  switch (tipo) {
    case 'caixas_pacotes':
      return 'Caixas / pacotes';
    case 'paletizada':
      return 'Paletizada';
    case 'granel':
      return 'Granel';
    case 'fragil':
      return 'Frágil';
    case 'refrigerada':
      return 'Refrigerada';
    case 'perigosa':
      return 'Perigosa';
    default:
      return tipo;
  }
}

/// 650 -> "650 kg"; 1250.5 -> "1.250,5 kg".
String pesoKg(num valor) => '${_peso.format(valor)} kg';

String _numeroCurto(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');

/// "120 x 100 x 150 cm" (comprimento x largura x altura).
String medidasCm(double? comprimento, double? largura, double? altura) {
  if (comprimento == null || largura == null || altura == null) return '-';
  return '${_numeroCurto(comprimento)} x ${_numeroCurto(largura)} x ${_numeroCurto(altura)} cm';
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
