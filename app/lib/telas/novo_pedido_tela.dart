import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/novo_pedido.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';
import 'detalhes_carga.dart';
import 'selecao_endereco.dart';

/// Primeira etapa do pedido: o cliente escolhe o destino a partir do mapa.
/// Com o roteiro completo, segue para os dados da carga ([TelaDetalhesCarga]),
/// depois para o veiculo e o parceiro ([TelaOpcoesFrete], aberta por ela).
class TelaNovoPedido extends StatefulWidget {
  const TelaNovoPedido({super.key});

  @override
  State<TelaNovoPedido> createState() => _TelaNovoPedidoState();
}

class _TelaNovoPedidoState extends State<TelaNovoPedido> {
  /// Localizacao atual do cliente. No prototipo e o primeiro endereco favorito.
  Endereco? _local;
  List<Endereco> _sugestoes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NovoPedido>().carregarCatalogo();
    });
  }

  Future<void> _carregar() async {
    final r = await context.read<Sessao>().repo.enderecos();
    if (!mounted) return;
    setState(() {
      _local = r.favoritos.isEmpty ? null : r.favoritos.first;
      _sugestoes = [...r.favoritos, ...r.recentes];
    });
  }

  Future<void> _trocarColeta() async {
    final rascunho = context.read<NovoPedido>();
    final endereco = await Navigator.of(context).push<Endereco>(
      MaterialPageRoute(
        builder: (_) => const TelaSelecaoEndereco(
          titulo: 'Local de coleta',
          ehColeta: true,
        ),
      ),
    );
    if (endereco != null) rascunho.definirColeta(endereco);
  }

  Future<void> _buscarDestino() async {
    final endereco = await Navigator.of(context).push<Endereco>(
      MaterialPageRoute(
        builder: (_) => const TelaSelecaoEndereco(
          titulo: 'Local de entrega',
          ehColeta: false,
        ),
      ),
    );
    if (endereco != null) _definirDestino(endereco);
  }

  void _definirDestino(Endereco destino) {
    final rascunho = context.read<NovoPedido>();
    final coleta = rascunho.coleta ?? _local;
    if (coleta == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Escolha primeiro o local de coleta'),
      ));
      return;
    }
    if (rascunho.coleta == null) rascunho.definirColeta(coleta);
    rascunho.adicionarEntrega(destino);
    _seguirParaCarga();
  }

  void _seguirParaCarga() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TelaDetalhesCarga(etapaDoFluxo: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rascunho = context.watch<NovoPedido>();
    final coleta = rascunho.coleta ?? _local;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Stack(
              children: [
                const MapaSimulado(altura: double.infinity),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(Icons.location_on,
                        size: 48, color: Cores.primaria),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Center(
                    child: _PontoColeta(endereco: coleta, onTap: _trocarColeta),
                  ),
                ),
              ],
            ),
          ),
        ),
        _PainelDestino(
          rascunho: rascunho,
          sugestoes: [
            for (final e in _sugestoes)
              if (coleta == null || e.id != coleta.id) e,
          ].take(4).toList(),
          onBuscar: _buscarDestino,
          onEscolher: _definirDestino,
          onContinuar: _seguirParaCarga,
        ),
      ],
    );
  }
}

/// Etiqueta sobre o mapa com o local de coleta; toque para trocar.
class _PontoColeta extends StatelessWidget {
  const _PontoColeta({required this.endereco, required this.onTap});

  final Endereco? endereco;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.primariaEscura,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ponto de coleta',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFFBFD3E8))),
                    Text(
                      endereco?.linhaPrincipal ?? 'Escolha onde retirar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painel inferior: busca do destino e atalhos para enderecos conhecidos.
class _PainelDestino extends StatelessWidget {
  const _PainelDestino({
    required this.rascunho,
    required this.sugestoes,
    required this.onBuscar,
    required this.onEscolher,
    required this.onContinuar,
  });

  final NovoPedido rascunho;
  final List<Endereco> sugestoes;
  final VoidCallback onBuscar;
  final void Function(Endereco) onEscolher;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Cores.superficie,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Cores.borda,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (rascunho.roteiroCompleto)
            _PedidoEmAndamento(rascunho: rascunho, onContinuar: onContinuar)
          else ...[
            Material(
              color: Cores.fundo,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onBuscar,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Cores.primariaEscura, size: 26),
                      SizedBox(width: 12),
                      Text('Para onde vamos levar?',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Cores.primariaEscura)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final e in sugestoes)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  e.favorito ? Icons.bookmark_outline : Icons.history,
                  color: Cores.textoFraco,
                ),
                title: Text(
                  e.apelido ?? e.linhaPrincipal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  e.apelido == null ? e.linhaSecundaria : e.linhaPrincipal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
                onTap: () => onEscolher(e),
              ),
          ],
        ],
      ),
    );
  }
}

/// Quando o cliente volta da segunda etapa, o roteiro fica guardado aqui.
class _PedidoEmAndamento extends StatelessWidget {
  const _PedidoEmAndamento({required this.rascunho, required this.onContinuar});

  final NovoPedido rascunho;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    final destino = rascunho.entregas.last;
    final extras = rascunho.entregas.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSecao('Pedido em andamento'),
        Row(
          children: [
            const Icon(Icons.place, color: Cores.destaque, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                extras > 0
                    ? '${destino.linhaPrincipal} (+$extras parada${extras > 1 ? 's' : ''})'
                    : destino.linhaPrincipal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
            onPressed: onContinuar, child: const Text('Continuar pedido')),
        TextButton(
          onPressed: rascunho.limpar,
          child: const Text('Começar de novo'),
        ),
      ],
    );
  }
}
