import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:solus_frete/core/tema.dart';
import 'package:solus_frete/estado/sessao.dart';
import 'package:solus_frete/telas/login.dart';

/// Area visivel do Safari no iPhone (em pontos), ja descontando a barra de
/// endereco e a barra de ferramentas. A tela de login precisa caber inteira
/// em todas, sem rolagem e sem nada cortado.
const _telas = {
  'iPhone SE (Safari)': Size(375, 548),
  'iPhone 12/13/14 (Safari)': Size(390, 664),
  'iPhone 15/16 (Safari)': Size(393, 659),
  'iPhone Pro Max (Safari)': Size(430, 746),
  'iPhone 14 (tela cheia)': Size(390, 844),
};

void main() {
  for (final MapEntry(key: nome, value: tamanho) in _telas.entries) {
    testWidgets('login cabe sem rolagem: $nome', (tester) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => Sessao(),
          child: MaterialApp(theme: construirTema(), home: const TelaLogin()),
        ),
      );
      await tester.pumpAndSettle();

      // Nenhum "overflow" (faixa amarela e preta) ou outro erro de layout.
      expect(tester.takeException(), isNull);

      // Nada para rolar.
      final rolagem =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(rolagem.position.maxScrollExtent, 0,
          reason: 'A tela rola ${rolagem.position.maxScrollExtent}px');

      // O ultimo elemento ("Cadastre-se") aparece inteiro na tela.
      final rodape = tester.getRect(find.textContaining('Cadastre-se'));
      expect(rodape.bottom, lessThanOrEqualTo(tamanho.height));

      // A saudacao nao fica escondida atras do cartao.
      final ola = tester.getRect(find.text('Olá!'));
      final entrar = tester.getRect(find.text('Entrar'));
      expect(ola.bottom, lessThan(entrar.top));

      // Marca d'agua centralizada, com o topo visivel (so a ponta e cortada).
      final marca = tester.getRect(find.byType(Image));
      expect(marca.center.dx, closeTo(tamanho.width / 2, 1));
      expect(marca.top, greaterThanOrEqualTo(0));
    });
  }
}
