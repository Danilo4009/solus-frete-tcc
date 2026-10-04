import 'package:flutter_test/flutter_test.dart';
import 'package:solus_frete/core/compatibilidade.dart';
import 'package:solus_frete/core/veiculos_config.dart';
import 'package:solus_frete/modelos/modelos.dart';

CategoriaVeiculo veiculo(String codigo) {
  final e = veiculosConfig.firstWhere((v) => v.codigo == codigo);
  return CategoriaVeiculo(
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
  );
}

Carga carga({
  String tipo = 'caixas_pacotes',
  double peso = 100,
  double c = 100,
  double l = 50,
  double a = 50,
}) =>
    Carga(tipoCarga: tipo, pesoKg: peso, comprimentoCm: c, larguraCm: l, alturaCm: a);

void main() {
  group('validarCarga', () {
    test('carga vazia pede peso e dimensoes', () {
      final erros = validarCarga(const Carga());
      expect(erros.keys, containsAll(['peso', 'comprimento', 'largura', 'altura']));
    });

    test('zero e negativo sao invalidos', () {
      expect(validarCarga(carga(peso: 0))['peso'], 'Informe um valor maior que zero');
      expect(validarCarga(carga(peso: -3))['peso'], isNotNull);
      expect(validarCarga(carga(a: 0))['altura'], isNotNull);
    });

    test('carga completa e valida', () {
      expect(validarCarga(carga()), isEmpty);
    });

    test('volumes precisa ser pelo menos 1', () {
      const invalida = Carga(
          pesoKg: 1, comprimentoCm: 1, larguraCm: 1, alturaCm: 1, volumes: 0);
      expect(validarCarga(invalida)['volumes'], isNotNull);
    });
  });

  group('verificarCompatibilidade', () {
    test('peso acima da capacidade', () {
      final r = verificarCompatibilidade(carga(peso: 700), veiculo('utilitario'));
      expect(r.compativel, isFalse);
      expect(r.motivo, 'Excede a capacidade de 650 kg');
    });

    test('peso exatamente na capacidade e aceito', () {
      expect(verificarCompatibilidade(carga(peso: 650), veiculo('utilitario')).compativel,
          isTrue);
    });

    test('capacidade com milhar usa ponto', () {
      final r = verificarCompatibilidade(carga(peso: 7000), veiculo('caminhao_toco'));
      expect(r.motivo, 'Excede a capacidade de 6.000 kg');
    });

    test('maior volume que nao cabe no bau', () {
      final r = verificarCompatibilidade(carga(c: 250), veiculo('utilitario'));
      expect(r.compativel, isFalse);
      expect(r.motivo, contains('nao cabe no bau de 190 x 130 x 120 cm'));
    });

    test('o volume pode ser girado para caber', () {
      // 120 x 100 x 190 nao cabe na orientacao original (190 x 130 x 120), mas cabe girado
      final r =
          verificarCompatibilidade(carga(c: 120, l: 100, a: 190), veiculo('utilitario'));
      expect(r.compativel, isTrue);
    });

    test('refrigerada e perigosa so em veiculo habilitado', () {
      expect(verificarCompatibilidade(carga(tipo: 'refrigerada'), veiculo('utilitario')).motivo,
          'Nao comporta carga refrigerada');
      expect(verificarCompatibilidade(carga(tipo: 'perigosa'), veiculo('utilitario')).motivo,
          'Nao comporta carga perigosa');
      expect(verificarCompatibilidade(carga(tipo: 'refrigerada'), veiculo('vuc')).compativel,
          isTrue);
      expect(verificarCompatibilidade(carga(tipo: 'perigosa'), veiculo('vuc')).motivo,
          'Nao comporta carga perigosa');
      expect(verificarCompatibilidade(carga(tipo: 'perigosa'), veiculo('carreta')).compativel,
          isTrue);
    });

    test('o peso e checado antes das dimensoes', () {
      final r = verificarCompatibilidade(carga(peso: 9000, c: 900), veiculo('utilitario'));
      expect(r.motivo, startsWith('Excede a capacidade'));
    });

    test('os outros tipos de carga qualquer veiculo aceita', () {
      for (final tipo in ['caixas_pacotes', 'paletizada', 'granel', 'fragil']) {
        expect(verificarCompatibilidade(carga(tipo: tipo, peso: 10, c: 10, l: 10, a: 10), veiculo('moto')).compativel,
            isTrue,
            reason: tipo);
      }
    });
  });

  group('catalogo de veiculos', () {
    test('nao tem Carro hatch e mantem Moto e Carro', () {
      final codigos = veiculosConfig.map((v) => v.codigo).toList();
      expect(codigos, isNot(contains('carro_hatch')));
      expect(codigos, containsAll(['moto', 'carro']));
    });

    test('capacidades de referencia', () {
      int kg(String codigo) =>
          veiculosConfig.firstWhere((v) => v.codigo == codigo).pesoMaxKg;
      expect(kg('utilitario'), 650);
      expect(kg('van'), 1500);
      expect(kg('vuc'), 3000);
      expect(kg('caminhao_34'), 4000);
      expect(kg('caminhao_toco'), 6000);
      expect(kg('caminhao_truck'), 12000);
      expect(kg('carreta'), 25000);
    });

    test('volume em m3 e calculado das dimensoes', () {
      final utilitario = veiculosConfig.firstWhere((v) => v.codigo == 'utilitario');
      expect(utilitario.volumeM3, closeTo(2.964, 0.001));
    });

    test('ids sao unicos e seguem a ordem do seed', () {
      final ids = veiculosConfig.map((v) => v.id).toList();
      expect(ids, [for (var i = 1; i <= veiculosConfig.length; i++) i]);
    });
  });
}
