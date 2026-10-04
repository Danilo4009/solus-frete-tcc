import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:solus_frete/core/tema.dart';
import 'package:solus_frete/dados/repositorio_mock.dart';
import 'package:solus_frete/estado/novo_pedido.dart';
import 'package:solus_frete/modelos/modelos.dart';
import 'package:solus_frete/telas/detalhes_carga.dart';
import 'package:solus_frete/telas/opcoes_frete.dart';

Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

/// Envolve a tela num MaterialApp com o rascunho ja disponivel via Provider,
/// numa tela alta o bastante para o ListView montar os cartoes de uma vez.
Future<NovoPedido> abrirTela(WidgetTester tester, Widget tela, {NovoPedido? rascunho}) async {
  tester.view.physicalSize = const Size(400, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final estado = rascunho ?? NovoPedido(RepositorioMock());
  await tester.pumpWidget(
    ChangeNotifierProvider<NovoPedido>.value(
      value: estado,
      child: MaterialApp(theme: construirTema(), home: tela),
    ),
  );
  await tester.pump(); // dispara o carregamento do catalogo
  await tester.pump(const Duration(seconds: 1));
  return estado;
}

Future<void> preencherCarga(
  WidgetTester tester, {
  String peso = '',
  String comprimento = '',
  String largura = '',
  String altura = '',
}) async {
  await tester.enterText(campo('Peso total *'), peso);
  await tester.enterText(campo('Comprimento'), comprimento);
  await tester.enterText(campo('Largura'), largura);
  await tester.enterText(campo('Altura'), altura);
  await tester.pump();
}

void main() {
  group('TelaDetalhesCarga', () {
    testWidgets('etapa do fluxo mostra o progresso da etapa 2 e o botao "Escolher veiculo"',
        (tester) async {
      await abrirTela(tester, const TelaDetalhesCarga(etapaDoFluxo: true));

      expect(find.text('O que vamos levar?'), findsOneWidget);
      expect(find.text('Escolher veículo'), findsOneWidget);
    });

    testWidgets('valor zero mostra aviso no campo', (tester) async {
      await abrirTela(tester, const TelaDetalhesCarga(etapaDoFluxo: true));
      await tester.enterText(campo('Peso total *'), '0');
      await tester.pump();

      expect(find.text('Informe um valor maior que zero'), findsOneWidget);
    });

    testWidgets('campo vazio nao mostra erro', (tester) async {
      await abrirTela(tester, const TelaDetalhesCarga(etapaDoFluxo: true));

      expect(find.text('Informe um valor maior que zero'), findsNothing);
      expect(find.text('Número inválido'), findsNothing);
    });

    testWidgets('selecionar "Refrigerada" no tipo de carga atualiza o rascunho',
        (tester) async {
      final rascunho =
          await abrirTela(tester, const TelaDetalhesCarga(etapaDoFluxo: true));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refrigerada').last);
      await tester.pumpAndSettle();

      expect(rascunho.carga.tipoCarga, 'refrigerada');
    });

    testWidgets('"Escolher veiculo" navega para a tela de opcoes de frete', (tester) async {
      await abrirTela(tester, const TelaDetalhesCarga(etapaDoFluxo: true));
      await preencherCarga(tester, peso: '500', comprimento: '100', largura: '80', altura: '80');

      await tester.tap(find.text('Escolher veículo'));
      // Não usa pumpAndSettle: o card do veículo recomendado pulsa em loop infinito.
      // Dois pumps: a transição de rota e o carregamento (assíncrono) do catálogo.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Veículo e parceiro'), findsOneWidget);
      expect(find.text('O que vamos levar?'), findsNothing);
    });

    testWidgets('fora do fluxo o botao salva e a tela fecha (sem navegar para veiculo)',
        (tester) async {
      final rascunho = NovoPedido(RepositorioMock());
      tester.view.physicalSize = const Size(400, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: ChangeNotifierProvider<NovoPedido>.value(
            value: rascunho,
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Builder(
                    builder: (contexto) => Center(
                      child: FilledButton(
                        onPressed: () => Navigator.of(contexto).push(MaterialPageRoute(
                          builder: (_) => const TelaDetalhesCarga(),
                        )),
                        child: const Text('abrir'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes da carga'), findsOneWidget);

      await tester.tap(find.text('Salvar detalhes'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes da carga'), findsNothing);
      expect(find.text('Veículo e parceiro'), findsNothing);
    });
  });

  group('TelaOpcoesFrete', () {
    testWidgets('sem a carga preenchida todos os veiculos ficam bloqueados', (tester) async {
      final rascunho = await abrirTela(tester, const TelaOpcoesFrete());

      expect(find.byKey(const ValueKey('veiculo-van')), findsOneWidget);
      expect(find.textContaining('Preencha o peso e as dimensões'), findsOneWidget);

      await tester.tap(find.text('Van'));
      await tester.pump();
      expect(rascunho.categoria, isNull);
    });

    testWidgets('nao existe mais Carro Hatch e Moto e Carro continuam', (tester) async {
      await abrirTela(tester, const TelaOpcoesFrete());

      expect(find.text('Carro Hatch'), findsNothing);
      expect(find.byKey(const ValueKey('veiculo-carro_hatch')), findsNothing);
      expect(find.byKey(const ValueKey('veiculo-moto')), findsOneWidget);
      expect(find.byKey(const ValueKey('veiculo-carro')), findsOneWidget);
      expect(find.byKey(const ValueKey('veiculo-carreta')), findsOneWidget);
    });

    testWidgets('veiculo incompativel por peso fica desabilitado com o motivo abaixo do card',
        (tester) async {
      final rascunho = await abrirTela(tester, const TelaOpcoesFrete());
      rascunho.definirCarga(const Carga(
        pesoKg: 700,
        comprimentoCm: 100,
        larguraCm: 50,
        alturaCm: 50,
      ));
      await tester.pump();

      expect(find.text('Excede a capacidade de 650 kg'), findsOneWidget); // utilitario
      expect(find.text('Excede a capacidade de 200 kg'), findsOneWidget); // carro
      expect(find.text('Excede a capacidade de 20 kg'), findsOneWidget); // moto

      await tester.tap(find.text('Utilitario'));
      await tester.pump();
      expect(rascunho.categoria, isNull);

      await tester.tap(find.text('Van'));
      await tester.pump();
      expect(rascunho.categoria?.codigo, 'van');
    });

    testWidgets('volume que nao cabe no bau tambem bloqueia', (tester) async {
      final rascunho = await abrirTela(tester, const TelaOpcoesFrete());
      rascunho.definirCarga(const Carga(
        pesoKg: 50,
        comprimentoCm: 250,
        larguraCm: 50,
        alturaCm: 50,
      ));
      await tester.pump();

      expect(find.textContaining('nao cabe no bau de 190 x 130 x 120 cm'), findsOneWidget);
    });

    testWidgets('carga refrigerada bloqueia veiculos sem bau refrigerado', (tester) async {
      final rascunho = await abrirTela(tester, const TelaOpcoesFrete());
      rascunho.definirCarga(const Carga(
        tipoCarga: 'refrigerada',
        pesoKg: 100,
        comprimentoCm: 100,
        larguraCm: 50,
        alturaCm: 50,
      ));
      await tester.pump();

      expect(find.text('Nao comporta carga refrigerada'), findsWidgets); // moto, carro, etc.
      expect(find.byKey(const ValueKey('veiculo-vuc')), findsOneWidget);
    });

    testWidgets('alterar a carga desmarca o veiculo que ficou incompativel e avisa',
        (tester) async {
      final rascunho = await abrirTela(tester, const TelaOpcoesFrete());
      rascunho.definirCarga(const Carga(
        pesoKg: 700,
        comprimentoCm: 100,
        larguraCm: 50,
        alturaCm: 50,
      ));
      await tester.pump();
      await tester.tap(find.text('Van'));
      await tester.pump();
      expect(rascunho.categoria?.codigo, 'van');

      rascunho.definirCarga(const Carga(
        pesoKg: 2000, // van so comporta 1.500 kg
        comprimentoCm: 100,
        larguraCm: 50,
        alturaCm: 50,
      ));
      await tester.pump();

      expect(rascunho.categoria, isNull);
      expect(find.textContaining('Van foi desmarcado'), findsOneWidget);
      expect(find.textContaining('Excede a capacidade de 1.500 kg'), findsWidgets);
    });

    testWidgets('sem nenhum veiculo compativel orienta a dividir a carga', (tester) async {
      final rascunho = await abrirTela(tester, const TelaOpcoesFrete());
      rascunho.definirCarga(const Carga(
        pesoKg: 30000,
        comprimentoCm: 100,
        larguraCm: 50,
        alturaCm: 50,
      ));
      await tester.pump();

      expect(find.textContaining('Nenhum veículo comporta esta carga'), findsOneWidget);
    });

    testWidgets('resumo da carga mostra tipo, volumes e peso, e o toque abre a edicao',
        (tester) async {
      final rascunho = await abrirTela(tester, const TelaOpcoesFrete());
      rascunho.definirCarga(const Carga(
        tipoCarga: 'fragil',
        volumes: 3,
        pesoKg: 120,
        comprimentoCm: 60,
        larguraCm: 40,
        alturaCm: 40,
      ));
      await tester.pump();

      expect(find.textContaining('Frágil - 3 volume(s) - 120 kg'), findsOneWidget);

      await tester.tap(find.text('Sua carga'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes da carga'), findsOneWidget);
    });

    testWidgets('botao "?" abre a ajuda completa e o icone "i" abre so a dica do veiculo',
        (tester) async {
      await abrirTela(tester, const TelaOpcoesFrete());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Como fazer um pedido'), findsOneWidget);
      expect(find.text('Por que alguns veiculos aparecem desabilitados'), findsOneWidget);
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();
      expect(find.text('Como fazer um pedido'), findsNothing);

      await tester.tap(find.byTooltip('Dicas desta etapa').first);
      await tester.pumpAndSettle();
      expect(find.text('Dicas desta etapa'), findsOneWidget);
      expect(find.textContaining('Do menor para o maior'), findsOneWidget);
    });
  });
}
