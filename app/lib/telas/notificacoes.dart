import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';

class TelaNotificacoes extends StatefulWidget {
  const TelaNotificacoes({super.key});

  @override
  State<TelaNotificacoes> createState() => _TelaNotificacoesState();
}

class _TelaNotificacoesState extends State<TelaNotificacoes> {
  List<Notificacao> _operacionais = [];
  List<Notificacao> _promocionais = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final repo = context.read<Sessao>().repo;
    final r = await repo.notificacoes();
    if (!mounted) return;
    setState(() {
      _operacionais = r.operacionais;
      _promocionais = r.promocionais;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Caixa de entrada'),
          bottom: const TabBar(
            labelColor: Cores.primaria,
            unselectedLabelColor: Cores.textoFraco,
            indicatorColor: Cores.primaria,
            tabs: [Tab(text: 'Notificacoes'), Tab(text: 'Promocoes')],
          ),
        ),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _Lista(itens: _operacionais, icone: Icons.local_shipping_outlined),
                  _Lista(itens: _promocionais, icone: Icons.local_offer_outlined),
                ],
              ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.itens, required this.icone});

  final List<Notificacao> itens;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) {
      return const Vazio(
        icone: Icons.notifications_none_rounded,
        titulo: 'Nada por aqui',
        descricao: 'Avisos sobre seus pedidos aparecem nesta caixa.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => Bloco(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: Cores.primaria, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itens[i].titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 4),
                  Text(itens[i].mensagem, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(dataHora(itens[i].quando),
                      style: const TextStyle(fontSize: 11.5, color: Cores.textoFraco)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
