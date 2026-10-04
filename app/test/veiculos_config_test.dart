import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solus_frete/core/veiculos_config.dart';

/// Garante que o config do app e o seed do banco (categoria_veiculo) continuam iguais,
/// ja que os mesmos dados existem nos dois lugares.
void main() {
  test('veiculos_config.dart espelha o INSERT de categoria_veiculo do seed', () {
    final seed = File('../db/02_seed.sql').readAsStringSync();
    final inicio = seed.indexOf('INSERT INTO categoria_veiculo');
    expect(inicio, isNonNegative, reason: 'INSERT nao encontrado em db/02_seed.sql');
    final bloco = seed.substring(inicio, seed.indexOf(';', inicio));

    final linha = RegExp(
      r"\('([a-z_0-9]+)',\s*'([^']*)',\s*'([^']*)',\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),"
      r'\s*(\d+),\s*(\d+),\s*([01]),\s*([01])\)',
    );
    final linhas = linha.allMatches(bloco).toList();

    expect(linhas, hasLength(veiculosConfig.length));
    for (final m in linhas) {
      final codigo = m.group(1)!;
      final e = veiculosConfig.firstWhere((v) => v.codigo == codigo,
          orElse: () => throw TestFailure('$codigo esta no seed mas nao no config'));
      expect(m.group(2), e.nome, reason: '$codigo nome');
      expect(m.group(3), e.descricao, reason: '$codigo descricao');
      expect(double.parse(m.group(4)!), e.comprimentoM, reason: '$codigo comprimento');
      expect(double.parse(m.group(5)!), e.larguraM, reason: '$codigo largura');
      expect(double.parse(m.group(6)!), e.alturaM, reason: '$codigo altura');
      expect(int.parse(m.group(7)!), e.pesoMaxKg, reason: '$codigo peso');
      expect(int.parse(m.group(8)!), e.id, reason: '$codigo ordem/id');
      expect(m.group(9) == '1', e.aceitaRefrigerada, reason: '$codigo refrigerada');
      expect(m.group(10) == '1', e.aceitaPerigosa, reason: '$codigo perigosa');
    }
  });
}
