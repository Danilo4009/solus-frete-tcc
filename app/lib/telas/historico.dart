import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';
import 'acompanhamento.dart';

/// Pedidos em andamento, concluidos e cancelados, com busca.
class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico>
    with SingleTickerProviderStateMixin {
  late final TabController _abas;
  final _busca = TextEditingController();

  static const _situacoes = ['em_andamento', 'concluido', 'cancelado'];

  @override
  void initState() {
    super.initState();
    _abas = TabController(length: 3, vsync: this);
    _abas.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _abas.dispose();
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _busca,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar por código ou endereço',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busca.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _busca.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              TabBar(
                controller: _abas,
                labelColor: Cores.primaria,
                unselectedLabelColor: Cores.textoFraco,
                indicatorColor: Cores.primaria,
                tabs: const [
                  Tab(text: 'Em andamento'),
                  Tab(text: 'Concluídos'),
                  Tab(text: 'Cancelados'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _ListaPedidos(
            key: ValueKey('${_situacoes[_abas.index]}-${_busca.text}'),
            situacao: _situacoes[_abas.index],
            busca: _busca.text,
          ),
        ),
      ],
    );
  }
}

class _ListaPedidos extends StatefulWidget {
  const _ListaPedidos({super.key, required this.situacao, required this.busca});

  final String situacao;
  final String busca;

  @override
  State<_ListaPedidos> createState() => _ListaPedidosState();
}

class _ListaPedidosState extends State<_ListaPedidos> {
  List<Pedido> _pedidos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final repo = context.read<Sessao>().repo;
    final lista =
        await repo.listarPedidos(situacao: widget.situacao, busca: widget.busca);
    if (!mounted) return;
    setState(() {
      _pedidos = lista;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pedidos.isEmpty) {
      return const Vazio(
        icone: Icons.inbox_outlined,
        titulo: 'Nenhum pedido aqui',
        descricao: 'Quando você solicitar um frete, ele aparece nesta lista.',
      );
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pedidos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = _pedidos[i];
          return Bloco(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => TelaAcompanhamento(pedidoId: p.id)),
              );
              _carregar();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.codigo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const Spacer(),
                    EtiquetaSituacao(p.situacao),
                  ],
                ),
                const SizedBox(height: 10),
                _LinhaParada(
                  icone: Icons.trip_origin,
                  cor: Cores.primaria,
                  texto: p.origem?.linhaPrincipal ?? '-',
                ),
                const SizedBox(height: 4),
                _LinhaParada(
                  icone: Icons.place,
                  cor: Cores.destaque,
                  texto: p.destino?.linhaPrincipal ?? '-',
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 15, color: Cores.textoFraco),
                    const SizedBox(width: 5),
                    Text(p.categoriaNome,
                        style: const TextStyle(
                            fontSize: 12.5, color: Cores.textoFraco)),
                    const SizedBox(width: 12),
                    if (p.tipoRetirada == 'agendada') ...[
                      const Icon(Icons.event, size: 15, color: Cores.textoFraco),
                      const SizedBox(width: 5),
                      Text(dataHora(p.agendadoPara),
                          style: const TextStyle(
                              fontSize: 12.5, color: Cores.textoFraco)),
                    ] else
                      Text(dataHora(p.criadoEm),
                          style: const TextStyle(
                              fontSize: 12.5, color: Cores.textoFraco)),
                    const Spacer(),
                    Text(moeda(p.valorTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LinhaParada extends StatelessWidget {
  const _LinhaParada({required this.icone, required this.cor, required this.texto});

  final IconData icone;
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 14, color: cor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5)),
        ),
      ],
    );
  }
}
