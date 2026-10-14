import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/novo_pedido.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';

enum _Filtro { todos, motoristas, transportadoras }

enum _Ordem { preco, prazo, nota }

/// Lista as ofertas de motoristas parceiros e transportadoras da região para o
/// cliente comparar (preço, prazo e avaliação) e escolher uma.
///
/// Sem [pedidoId], a escolha vai para o rascunho do pedido. Com [pedidoId], o
/// cliente escolhe outro parceiro para um pedido que voltou a "cotado" porque o
/// anterior recusou, e a tela devolve o [Pedido] atualizado.
class TelaCotacoes extends StatefulWidget {
  const TelaCotacoes({super.key, this.pedidoId});

  final int? pedidoId;

  @override
  State<TelaCotacoes> createState() => _TelaCotacoesState();
}

class _TelaCotacoesState extends State<TelaCotacoes> {
  _Filtro _filtro = _Filtro.todos;
  _Ordem _ordem = _Ordem.preco;
  Cotacao? _cotacaoDoPedido;
  String? _erro;
  String? _selecionada;
  bool _enviando = false;

  bool get _modoPedido => widget.pedidoId != null;

  @override
  void initState() {
    super.initState();
    if (_modoPedido) {
      _carregar();
    } else {
      _selecionada = context.read<NovoPedido>().ofertaEscolhida?.chave;
    }
  }

  Future<void> _carregar() async {
    try {
      final c = await context.read<Sessao>().repo.cotarPedido(widget.pedidoId!);
      if (!mounted) return;
      setState(() => _cotacaoDoPedido = c);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    }
  }

  Future<void> _confirmar(Cotacao cotacao) async {
    final oferta = cotacao.ofertas.firstWhere((o) => o.chave == _selecionada);
    if (!_modoPedido) {
      context.read<NovoPedido>().escolherOferta(oferta);
      Navigator.of(context).pop();
      return;
    }
    setState(() => _enviando = true);
    try {
      final pedido = await context
          .read<Sessao>()
          .repo
          .trocarParceiro(widget.pedidoId!, oferta);
      if (!mounted) return;
      Navigator.of(context).pop(pedido);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<OfertaParceiro> _visiveis(List<OfertaParceiro> ofertas) {
    final lista = ofertas.where((o) {
      switch (_filtro) {
        case _Filtro.todos:
          return true;
        case _Filtro.motoristas:
          return o.ehMotorista;
        case _Filtro.transportadoras:
          return !o.ehMotorista;
      }
    }).toList();
    lista.sort((a, b) {
      switch (_ordem) {
        case _Ordem.preco:
          return a.total.compareTo(b.total);
        case _Ordem.prazo:
          return a.prazoEntregaMin.compareTo(b.prazoEntregaMin);
        case _Ordem.nota:
          final porNota = b.nota.compareTo(a.nota);
          return porNota != 0 ? porNota : a.total.compareTo(b.total);
      }
    });
    return lista;
  }

  /// Selo de destaque: menor preco, mais rapido ou melhor avaliado da lista inteira.
  Map<String, String> _selos(List<OfertaParceiro> ofertas) {
    if (ofertas.isEmpty) return const {};
    final menorPreco = ofertas.map((o) => o.total).reduce((a, b) => a < b ? a : b);
    final menorPrazo = ofertas.map((o) => o.prazoEntregaMin).reduce((a, b) => a < b ? a : b);
    final melhorNota = ofertas.map((o) => o.nota).reduce((a, b) => a > b ? a : b);
    final selos = <String, String>{};
    for (final o in ofertas) {
      if (o.total == menorPreco) {
        selos[o.chave] = 'Menor preço';
      } else if (o.prazoEntregaMin == menorPrazo) {
        selos[o.chave] = 'Mais rápido';
      } else if (melhorNota > 0 && o.nota == melhorNota) {
        selos[o.chave] = 'Melhor avaliado';
      }
    }
    return selos;
  }

  @override
  Widget build(BuildContext context) {
    final cotacao =
        _modoPedido ? _cotacaoDoPedido : context.watch<NovoPedido>().cotacao;

    return Scaffold(
      appBar: AppBar(
        title: Text(_modoPedido ? 'Escolha outro parceiro' : 'Escolha seu parceiro'),
      ),
      body: cotacao == null
          ? Center(
              child: _erro != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_erro!, textAlign: TextAlign.center),
                    )
                  : const CircularProgressIndicator(),
            )
          : _corpo(cotacao),
    );
  }

  Widget _corpo(Cotacao cotacao) {
    final ofertas = cotacao.ofertas;
    final visiveis = _visiveis(ofertas);
    final selos = _selos(ofertas);
    final totalMotoristas = ofertas.where((o) => o.ehMotorista).length;
    final totalTransportadoras = ofertas.length - totalMotoristas;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.route_outlined, size: 16, color: Cores.textoFraco),
              const SizedBox(width: 6),
              Text('${km(cotacao.distanciaKm)} - ${cotacao.paradas} paradas',
                  style: const TextStyle(fontSize: 12.5, color: Cores.textoFraco)),
              const Spacer(),
              Text('${ofertas.length} opções na sua região',
                  style: const TextStyle(fontSize: 12.5, color: Cores.textoFraco)),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _chip('Todos (${ofertas.length})', _filtro == _Filtro.todos,
                  () => setState(() => _filtro = _Filtro.todos)),
              _chip('Motoristas ($totalMotoristas)', _filtro == _Filtro.motoristas,
                  () => setState(() => _filtro = _Filtro.motoristas)),
              _chip('Transportadoras ($totalTransportadoras)',
                  _filtro == _Filtro.transportadoras,
                  () => setState(() => _filtro = _Filtro.transportadoras)),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Ordenar por', style: TextStyle(fontSize: 12.5, color: Cores.textoFraco)),
              const SizedBox(width: 8),
              _chip('Menor preço', _ordem == _Ordem.preco,
                  () => setState(() => _ordem = _Ordem.preco)),
              _chip('Menor prazo', _ordem == _Ordem.prazo,
                  () => setState(() => _ordem = _Ordem.prazo)),
              _chip('Melhor avaliação', _ordem == _Ordem.nota,
                  () => setState(() => _ordem = _Ordem.nota)),
            ],
          ),
        ),
        Expanded(
          child: visiveis.isEmpty
              ? const Center(child: Text('Nenhum parceiro neste filtro'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    for (final oferta in visiveis)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CartaoOferta(
                          oferta: oferta,
                          selecionada: _selecionada == oferta.chave,
                          selo: selos[oferta.chave],
                          onTap: () => setState(() => _selecionada = oferta.chave),
                          onDetalhe: () =>
                              mostrarDetalhePreco(context, oferta, cotacao.avisos),
                        ),
                      ),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _selecionada == null || _enviando ? null : () => _confirmar(cotacao),
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text(_selecionada == null
                        ? 'Selecione um parceiro'
                        : 'Escolher este parceiro'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String texto, bool ativo, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(texto, style: const TextStyle(fontSize: 12.5)),
          selected: ativo,
          onSelected: (_) => onTap(),
          visualDensity: VisualDensity.compact,
        ),
      );
}

/// Cartao de uma oferta: quem e, avaliacao, prazo e preco.
class CartaoOferta extends StatelessWidget {
  const CartaoOferta({
    super.key,
    required this.oferta,
    required this.selecionada,
    required this.onTap,
    this.selo,
    this.onDetalhe,
    this.rotuloAcao,
  });

  final OfertaParceiro oferta;
  final bool selecionada;
  final VoidCallback onTap;
  final String? selo;
  final VoidCallback? onDetalhe;
  final String? rotuloAcao;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionada ? Cores.primaria.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: selecionada ? Cores.primaria : Cores.borda,
            width: selecionada ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Cores.fundo,
              child: Icon(
                oferta.ehMotorista ? Icons.person : Icons.local_shipping_outlined,
                color: Cores.primaria,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(oferta.nome,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      if (oferta.favorito) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 15, color: Cores.destaque),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${oferta.rotuloTipo} - ${oferta.veiculo}',
                      style: const TextStyle(fontSize: 12, color: Cores.textoFraco)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (oferta.nota > 0) ...[
                        const Icon(Icons.star, size: 14, color: Cores.destaque),
                        const SizedBox(width: 3),
                        Text(
                            '${oferta.nota.toStringAsFixed(2)} (${oferta.totalFretes} fretes)',
                            style: const TextStyle(fontSize: 12.5)),
                      ] else
                        const Text('Sem avaliacoes ainda',
                            style: TextStyle(fontSize: 12.5, color: Cores.textoFraco)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Cores.textoFraco),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Entrega em ~${duracao(oferta.prazoEntregaMin)}'
                          ' - coleta em ~${duracao(oferta.chegadaColetaMin)}',
                          style: const TextStyle(fontSize: 12, color: Cores.textoFraco),
                        ),
                      ),
                    ],
                  ),
                  if (selo != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Cores.destaque,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(selo!,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(moeda(oferta.total),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                if (onDetalhe != null)
                  InkWell(
                    onTap: onDetalhe,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('detalhes',
                          style: TextStyle(fontSize: 11.5, color: Cores.primaria)),
                    ),
                  ),
                if (rotuloAcao != null)
                  Text(rotuloAcao!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Cores.primaria,
                          fontWeight: FontWeight.w700))
                else if (selecionada)
                  const Icon(Icons.check_circle, size: 20, color: Cores.primaria),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Composicao do preco de uma oferta.
void mostrarDetalhePreco(BuildContext context, OfertaParceiro oferta, List<String> avisos) {
  Widget linha(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(rotulo, style: const TextStyle(fontSize: 13.5))),
            Text(valor, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  showModalBottomSheet<void>(
    context: context,
    builder: (contexto) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TituloSecao('Detalhes do preco'),
            linha(oferta.rotuloTipo, oferta.nome),
            linha('Taxa de entrega', moeda(oferta.valorFrete)),
            if (oferta.valorAdicionais > 0)
              linha('Servicos adicionais', moeda(oferta.valorAdicionais)),
            if (oferta.desconto > 0) linha('Desconto', '- ${moeda(oferta.desconto)}'),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Total',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text(moeda(oferta.total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            for (final aviso in avisos)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('- $aviso',
                    style: const TextStyle(fontSize: 12, color: Cores.textoFraco)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(contexto).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    ),
  );
}
