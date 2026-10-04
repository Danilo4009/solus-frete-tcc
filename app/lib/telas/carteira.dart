import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';

class TelaCarteira extends StatefulWidget {
  const TelaCarteira({super.key});

  @override
  State<TelaCarteira> createState() => _TelaCarteiraState();
}

class _TelaCarteiraState extends State<TelaCarteira> {
  Carteira? _carteira;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final repo = context.read<Sessao>().repo;
    final c = await repo.carteira();
    if (!mounted) return;
    setState(() => _carteira = c);
  }

  Future<void> _recarregar() async {
    final valor = await showModalBottomSheet<double>(
      context: context,
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TituloSecao('Recarregar carteira'),
              ),
            ),
            for (final v in const [50.0, 100.0, 200.0, 500.0])
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Cores.primaria),
                title: Text(moeda(v)),
                subtitle: const Text('Pagamento via Pix'),
                onTap: () => Navigator.of(contexto).pop(v),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (valor == null) return;
    final repo = context.read<Sessao>().repo;
    await repo.recarregar(valor);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recarga de ${moeda(valor)} concluída')),
    );
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final c = _carteira;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha carteira')),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Cores.primaria, Cores.primariaEscura],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo disponível',
                          style: TextStyle(color: Color(0xFFBFD3E8), fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(moeda(c.saldo),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Cores.destaque,
                          minimumSize: const Size(160, 44),
                        ),
                        onPressed: _recarregar,
                        icon: const Icon(Icons.add),
                        label: const Text('Recarregar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Bloco(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.credit_card, color: Cores.primaria),
                        title: const Text('Métodos de pagamento'),
                        subtitle: const Text('Nenhum cartão salvo',
                            style: TextStyle(fontSize: 12.5)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Cadastro de cartão fica fora do protótipo por segurança.'),
                          ),
                        ),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.local_offer_outlined,
                            color: Cores.primaria),
                        title: const Text('Cupons'),
                        subtitle: const Text('SOLUS10 e MUDANCA15 disponíveis',
                            style: TextStyle(fontSize: 12.5)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const TituloSecao('Extrato'),
                if (c.transacoes.isEmpty)
                  const Bloco(
                    child: Text('Nenhuma movimentação ainda.',
                        style: TextStyle(color: Cores.textoFraco)),
                  )
                else
                  Bloco(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < c.transacoes.length; i++) ...[
                          if (i > 0) const Divider(indent: 16, endIndent: 16, height: 1),
                          ListTile(
                            leading: Icon(
                              c.transacoes[i].valor >= 0
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: c.transacoes[i].valor >= 0
                                  ? Cores.sucesso
                                  : Cores.alerta,
                              size: 20,
                            ),
                            title: Text(c.transacoes[i].descricao ?? c.transacoes[i].tipo,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(dataHora(c.transacoes[i].quando),
                                style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              moeda(c.transacoes[i].valor),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: c.transacoes[i].valor >= 0
                                    ? Cores.sucesso
                                    : Cores.alerta,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
