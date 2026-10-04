import '../modelos/modelos.dart';

/// Regras de validacao da carga e de compatibilidade com o veiculo. Funcoes puras (sem
/// estado nem tela), para testar isoladas. A API repete a mesma regra em
/// api/src/compatibilidade.js: se mudar aqui, mude la tambem.

class ResultadoCompatibilidade {
  const ResultadoCompatibilidade.ok()
      : compativel = true,
        motivo = null;

  const ResultadoCompatibilidade.incompativel(String this.motivo) : compativel = false;

  final bool compativel;

  /// Por que o veiculo nao serve (null quando compativel).
  final String? motivo;
}

/// Erros por campo ('peso', 'comprimento', 'largura', 'altura', 'volumes'); vazio = carga valida.
Map<String, String> validarCarga(Carga carga) {
  final erros = <String, String>{};
  void exigir(String campo, double? valor, String rotulo) {
    if (valor == null) {
      erros[campo] = 'Informe $rotulo';
    } else if (valor <= 0) {
      erros[campo] = 'Informe um valor maior que zero';
    }
  }

  exigir('peso', carga.pesoKg, 'o peso total');
  exigir('comprimento', carga.comprimentoCm, 'o comprimento');
  exigir('largura', carga.larguraCm, 'a largura');
  exigir('altura', carga.alturaCm, 'a altura');
  if (carga.volumes < 1) erros['volumes'] = 'Informe pelo menos 1 volume';
  return erros;
}

/// Confere peso, tamanho do maior volume e tipo de carga contra o veiculo. Exige carga valida
/// (veja [validarCarga]). O volume pode ser girado: compara os lados do maior para o menor.
ResultadoCompatibilidade verificarCompatibilidade(Carga carga, CategoriaVeiculo veiculo) {
  assert(carga.completa, 'verificarCompatibilidade exige carga completa');

  if (carga.pesoKg! > veiculo.pesoMaxKg) {
    return ResultadoCompatibilidade.incompativel(
        'Excede a capacidade de ${_milhar(veiculo.pesoMaxKg)} kg');
  }

  final bau = [veiculo.comprimentoM, veiculo.larguraM, veiculo.alturaM]
      .map((m) => double.parse((m * 100).toStringAsFixed(1)))
      .toList();
  final volume = [carga.comprimentoCm!, carga.larguraCm!, carga.alturaCm!];
  final bauOrdenado = [...bau]..sort((a, b) => b.compareTo(a));
  final volumeOrdenado = [...volume]..sort((a, b) => b.compareTo(a));
  for (var i = 0; i < 3; i++) {
    if (volumeOrdenado[i] > bauOrdenado[i]) {
      return ResultadoCompatibilidade.incompativel(
          'O maior volume (${volume.map(_cm).join(' x ')} cm) '
          'nao cabe no bau de ${bau.map(_cm).join(' x ')} cm');
    }
  }

  if (!veiculo.aceitaTipo(carga.tipoCarga)) {
    return ResultadoCompatibilidade.incompativel(
        carga.tipoCarga == 'refrigerada'
            ? 'Nao comporta carga refrigerada'
            : 'Nao comporta carga perigosa');
  }

  return const ResultadoCompatibilidade.ok();
}

String _milhar(int n) => n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

String _cm(double v) {
  final texto = double.parse(v.toStringAsFixed(1)).toString();
  return (texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto)
      .replaceAll('.', ',');
}
