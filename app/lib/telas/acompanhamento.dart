import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';

/// Acompanhamento do pedido: mapa, etapas, parceiro e acoes.
class TelaAcompanhamento extends StatefulWidget {
  const TelaAcompanhamento({super.key, required this.pedidoId});

  final int pedidoId;

  @override
  State<TelaAcompanhamento> createState() => _TelaAcompanhamentoState();
}

class _TelaAcompanhamentoState extends State<TelaAcompanhamento> {
  Pedido? _pedido;
  bool _ocupado = true;

  static const _fluxo = [
    'aguardando_alocacao',
    'alocado',
    'em_deslocamento_coleta',
    'carregando',
    'em_transito',
    'entregue',
    'concluido',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final repo = context.read<Sessao>().repo;
    final p = await repo.obterPedido(widget.pedidoId);
    if (!mounted) return;
    setState(() {
      _pedido = p;
      _ocupado = false;
    });
  }

  Future<void> _avancar() async {
    setState(() => _ocupado = true);
    final repo = context.read<Sessao>().repo;
    final p = await repo.avancarPedido(widget.pedidoId);
    if (!mounted) return;
    setState(() {
      _pedido = p;
      _ocupado = false;
    });
  }

  Future<void> _cancelar() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text(
          'Antes da alocação o cancelamento é gratuito. '
          'Depois que um parceiro aceita, aplica-se taxa de 15%. '
          'Após a coleta o pedido não pode ser cancelado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Cores.alerta),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    setState(() => _ocupado = true);
    final repo = context.read<Sessao>().repo;
    final taxa = await repo.cancelarPedido(widget.pedidoId, 'Cancelado pelo cliente');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(taxa > 0
          ? 'Pedido cancelado. Taxa aplicada: ${moeda(taxa)}'
          : 'Pedido cancelado sem taxa.'),
    ));
    await _carregar();
  }

  Future<void> _avaliar() async {
    int nota = 5;
    bool favoritar = false;
    final comentario = TextEditingController();

    final enviou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (contexto) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(contexto).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (contexto, refazer) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TituloSecao('Como foi a entrega?'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      iconSize: 34,
                      onPressed: () => refazer(() => nota = i),
                      icon: Icon(i <= nota ? Icons.star : Icons.star_border,
                          color: Cores.destaque),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: comentario,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Comentário (opcional)'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: favoritar,
                onChanged: (v) => refazer(() => favoritar = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Adicionar ${_pedido?.motoristaNome ?? 'o motorista'} aos meus favoritos'),
                subtitle: const Text(
                  'Ele passa a receber suas ofertas antes da base geral',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(contexto).pop(true),
                child: const Text('Enviar avaliação'),
              ),
            ],
          ),
        ),
      ),
    );

    if (enviou == true) {
      final repo = context.read<Sessao>().repo;
      await repo.avaliarPedido(widget.pedidoId, nota, comentario.text.trim(), favoritar);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obrigado pela avaliação!')),
      );
    }
    comentario.dispose();
  }

  double? get _progresso {
    final p = _pedido;
    if (p == null) return null;
    final indice = _fluxo.indexOf(p.situacao);
    if (indice < 1) return null;
    if (p.situacao == 'cancelado') return null;
    return (indice / (_fluxo.length - 1)).clamp(0.05, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final p = _pedido;

    return Scaffold(
      appBar: AppBar(
        title: Text(p == null ? 'Pedido' : p.codigo),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _ocupado ? null : _carregar,
          ),
        ],
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MapaSimulado(
                  pontos: [
                    for (final parada in p.paradas)
                      if (parada.endereco.latitude != null)
                        (lat: parada.endereco.latitude!, lng: parada.endereco.longitude!),
                  ],
                  progresso: _progresso,
                ),
                const SizedBox(height: 12),
                Bloco(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(rotuloSituacao(p.situacao),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          EtiquetaSituacao(p.situacao),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.tipoRetirada == 'agendada'
                            ? 'Coleta agendada para ${dataHora(p.agendadoPara)}'
                            : 'Pedido criado em ${dataHora(p.criadoEm)}',
                        style: const TextStyle(fontSize: 12.5, color: Cores.textoFraco),
                      ),
                      if (p.favoritosPrimeiro) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.star, size: 15, color: Cores.destaque),
                            SizedBox(width: 6),
                            Text('Ofertado primeiro aos seus favoritos',
                                style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (p.motoristaNome != null) ...[
                  const SizedBox(height: 12),
                  Bloco(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Cores.fundo,
                          child: Icon(Icons.person, color: Cores.primaria),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.motoristaNome!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Cores.destaque),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${(p.motoristaAvaliacao ?? 0).toStringAsFixed(2)}'
                                    '${p.veiculoPlaca == null ? '' : ' - ${p.veiculoPlaca}'}'
                                    ' - ${p.categoriaNome}',
                                    style: const TextStyle(
                                        fontSize: 12.5, color: Cores.textoFraco),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Contato mediado pela plataforma',
                          icon: const Icon(Icons.chat_bubble_outline,
                              color: Cores.primaria),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No app final o contato é mediado, sem expor os números.'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Bloco(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TituloSecao('Etapas'),
                      LinhaDoTempo(
                        itens: [
                          for (final e in p.eventos)
                            (
                              titulo: rotuloSituacao(e.situacao),
                              detalhe: e.descricao,
                              quando: e.quando,
                              concluido: true,
                            ),
                          if (p.emAndamento)
                            for (final s in _fluxo.skip(_fluxo.indexOf(p.situacao) + 1))
                              (
                                titulo: rotuloSituacao(s),
                                detalhe: null,
                                quando: null,
                                concluido: false,
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Bloco(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TituloSecao('Roteiro'),
                      for (final parada in p.paradas)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                parada.situacao == 'concluida'
                                    ? Icons.check_circle
                                    : (parada.tipo == 'coleta'
                                        ? Icons.trip_origin
                                        : Icons.place),
                                size: 17,
                                color: parada.situacao == 'concluida'
                                    ? Cores.sucesso
                                    : (parada.tipo == 'coleta'
                                        ? Cores.primaria
                                        : Cores.destaque),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(parada.endereco.linhaPrincipal,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    Text(parada.endereco.linhaSecundaria,
                                        style: const TextStyle(
                                            fontSize: 12, color: Cores.textoFraco)),
                                    if (parada.endereco.contatoNome != null &&
                                        parada.endereco.contatoNome!.isNotEmpty)
                                      Text('Contato: ${parada.endereco.contatoNome}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Cores.textoFraco)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (p.carga != null) ...[
                  const SizedBox(height: 12),
                  Bloco(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TituloSecao('Carga'),
                        Text(
                          '${rotuloTipoItem(p.carga!.tipoItem)} - '
                          '${p.carga!.volumes} volume(s) - '
                          '${rotuloFaixaPeso(p.carga!.faixaPeso)}',
                          style: const TextStyle(fontSize: 13.5),
                        ),
                        if (p.carga!.fragil || p.carga!.naoEmpilhar)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                if (p.carga!.fragil)
                                  const Chip(
                                      label: Text('Frágil'),
                                      visualDensity: VisualDensity.compact),
                                if (p.carga!.naoEmpilhar)
                                  const Chip(
                                      label: Text('Não empilhar'),
                                      visualDensity: VisualDensity.compact),
                              ],
                            ),
                          ),
                        if (p.carga!.observacoes != null &&
                            p.carga!.observacoes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(p.carga!.observacoes!,
                                style: const TextStyle(
                                    fontSize: 12.5, color: Cores.textoFraco)),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Bloco(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total - ${rotuloPagamento(p.formaPagamento ?? '-')}'
                              '${p.pagador == 'destinatario' ? ' (frete a pagar)' : ''}',
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          ),
                          Text(moeda(p.valorTotal),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${km(p.distanciaKm)} - ${p.categoriaNome}',
                            style: const TextStyle(
                                fontSize: 12, color: Cores.textoFraco)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (p.situacao == 'concluido')
                  FilledButton.icon(
                    onPressed: _avaliar,
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Avaliar o parceiro'),
                  )
                else if (p.situacao != 'cancelado') ...[
                  FilledButton.icon(
                    onPressed: _ocupado ? null : _avancar,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Simular próxima etapa'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Cores.alerta,
                      side: const BorderSide(color: Cores.alerta),
                    ),
                    onPressed: _ocupado ? null : _cancelar,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar pedido'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'O botão de simular etapa existe apenas no protótipo, para demonstrar '
                    'a máquina de estados sem depender do app do motorista.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: Cores.textoFraco),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
