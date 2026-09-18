import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema.dart';
import '../estado/sessao.dart';
import 'carteira.dart';
import 'favoritos.dart';
import 'historico.dart';
import 'notificacoes.dart';
import 'novo_pedido_tela.dart';
import 'perfil.dart';

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  int _aba = 0;

  static const _titulos = ['Solicitar frete', 'Meus pedidos', 'Motoristas parceiros', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    final usuario = context.select<Sessao, String>((s) => s.usuario?.nome ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_aba]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TelaNotificacoes()),
            ),
          ),
        ],
      ),
      drawer: _Menu(nome: usuario, onIr: (indice) {
        Navigator.of(context).pop();
        setState(() => _aba = indice);
      }),
      body: IndexedStack(
        index: _aba,
        children: const [
          TelaNovoPedido(),
          TelaHistorico(),
          TelaFavoritos(),
          TelaPerfil(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.add_road_outlined),
              selectedIcon: Icon(Icons.add_road),
              label: 'Pedir'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Pedidos'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Parceiros'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.nome, required this.onIr});

  final String nome;
  final void Function(int) onIr;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Cores.primaria,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Cores.destaque,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nome.isEmpty ? 'Cliente Solus' : nome,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        const Text('Conta cliente',
                            style: TextStyle(color: Color(0xFFBFD3E8), fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_road_outlined),
              title: const Text('Solicitar frete'),
              onTap: () => onIr(0),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Meus pedidos'),
              onTap: () => onIr(1),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Motoristas parceiros'),
              onTap: () => onIr(2),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Minha carteira'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TelaCarteira()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none_rounded),
              title: const Text('Notificacoes'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TelaNotificacoes()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil e configuracoes'),
              onTap: () => onIr(3),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Cores.alerta),
              title: const Text('Sair', style: TextStyle(color: Cores.alerta)),
              onTap: () {
                Navigator.of(context).pop();
                context.read<Sessao>().sair();
              },
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Solus Frete - prototipo TCC v1.0',
                  style: TextStyle(fontSize: 11.5, color: Cores.textoFraco)),
            ),
          ],
        ),
      ),
    );
  }
}
