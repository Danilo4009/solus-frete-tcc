import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/tema.dart';
import 'estado/novo_pedido.dart';
import 'estado/sessao.dart';
import 'telas/home.dart';
import 'telas/login.dart';

void main() {
  initializeDateFormatting('pt_BR');
  runApp(const AppSolusFrete());
}

class AppSolusFrete extends StatelessWidget {
  const AppSolusFrete({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Sessao(),
      child: Builder(
        builder: (context) {
          final sessao = context.read<Sessao>();
          return ChangeNotifierProvider(
            create: (_) => NovoPedido(sessao.repo),
            child: MaterialApp(
              title: 'Solus Frete',
              debugShowCheckedModeBanner: false,
              theme: construirTema(),
              home: const Porta(),
            ),
          );
        },
      ),
    );
  }
}

/// Decide entre login e area logada.
class Porta extends StatelessWidget {
  const Porta({super.key});

  @override
  Widget build(BuildContext context) {
    final autenticado = context.select<Sessao, bool>((s) => s.autenticado);
    return autenticado ? const TelaHome() : const TelaLogin();
  }
}
