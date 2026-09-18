import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/novo_pedido.dart';
import '../modelos/modelos.dart';
import 'detalhes_carga.dart';
import 'revisao.dart';
import 'selecao_endereco.dart';

/// Tela de montagem do pedido: roteiro, horario, veiculo, servicos e cotacao.
class TelaNovoPedido extends StatefulWidget {
  const TelaNovoPedido({super.key});

  @override
  State<TelaNovoPedido> createState() => _TelaNovoPedidoState();
}

class _TelaNovoPedidoState extends State<TelaNovoPedido> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NovoPedido>().carregarCatalogo();
    });
  }

  Future<void> _escolherEndereco({required bool coleta, int? indiceEntrega}) async {
    final rascunho = context.read<NovoPedido>();
    final endereco = await Navigator.of(context).push<Endereco>(
      MaterialPageRoute(
        builder: (_) => TelaSelecaoEndereco(
          titulo: coleta ? 'Local de coleta' : 'Local de entrega',
          ehColeta: coleta,
        ),
      ),
    );
    if (endereco == null) return;
    if (coleta) {
      rascunho.definirColeta(endereco);
    } else if (indiceEntrega != null) {
      rascunho.substituirEntrega(indiceEntrega, endereco);
    } else {
      rascunho.adicionarEntrega(endereco);
    }
  }

  Future<void> _escolherHorario() async {
    final rascunho = context.read<NovoPedido>();
    final escolha = await showModalBottomSheet<String>(
      context: context,
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TituloSecao('Horario de retirada'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bolt_outlined, color: Cores.primaria),
              title: const Text('Agora'),
              subtitle: const Text('Buscamos um parceiro imediatamente'),
              trailing: rascunho.agendado
                  ? null
                  : const Icon(Icons.check_circle, color: Cores.primaria),
              onTap: () => Navigator.of(contexto).pop('agora'),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined, color: Cores.primaria),
              title: const Text('Agendar'),
              subtitle: const Text('Escolha a data e a hora da coleta'),
              trailing: rascunho.agendado
                  ? const Icon(Icons.check_circle, color: Cores.primaria)
                  : null,
              onTap: () => Navigator.of(contexto).pop('agendar'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (escolha == 'agora') {
      rascunho.definirAgendamento(false);
    } else if (escolha == 'agendar') {
      if (!mounted) return;
      final data = await showDatePicker(
        context: context,
        helpText: 'Data da coleta',
        initialDate: DateTime.now().add(const Duration(hours: 2)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      if (data == null || !mounted) return;
      final hora = await showTimePicker(
        context: context,
        helpText: 'Hora da coleta',
        initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2))),
      );
      if (hora == null) return;
      rascunho.definirAgendamento(
        true,
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute),
      );
    }
  }

  Future<void> _aplicarCupom() async {
    final rascunho = context.read<NovoPedido>();
    final campo = TextEditingController(text: rascunho.cupom ?? '');
    final codigo = await showDialog<String>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Aplicar cupom'),
        content: TextField(
          controller: campo,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
              labelText: 'Codigo', hintText: 'SOLUS10 ou MUDANCA15'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(''),
            child: const Text('Remover'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(campo.text.trim()),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    campo.dispose();
    if (codigo != null) rascunho.definirCupom(codigo);
  }

  @override
  Widget build(BuildContext context) {
    final rascunho = context.watch<NovoPedido>();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
          children: [
            if (rascunho.roteiroCompleto)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MapaSimulado(
                  pontos: [
                    for (final p in rascunho.paradas)
                      if (p.latitude != null && p.longitude != null)
                        (lat: p.latitude!, lng: p.longitude!),
                  ],
                ),
              ),
            _PainelRoteiro(
              rascunho: rascunho,
              onColeta: () => _escolherEndereco(coleta: true),
              onEntrega: (indice) =>
                  _escolherEndereco(coleta: false, indiceEntrega: indice),
              onAdicionarParada: () => _escolherEndereco(coleta: false),
              onHorario: _escolherHorario,
            ),
            const SizedBox(height: 16),
            const TituloSecao('Veiculos disponiveis'),
            if (rascunho.catalogo.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else
              _GradeVeiculos(rascunho: rascunho),
            if (rascunho.avisoCapacidade != null) ...[
              const SizedBox(height: 12),
              _Aviso(texto: rascunho.avisoCapacidade!, cor: Cores.alerta),
            ],
            if (rascunho.categoria != null) ...[
              const SizedBox(height: 16),
              _ServicosAdicionais(rascunho: rascunho),
              const SizedBox(height: 16),
              _Periodo(rascunho: rascunho),
              const SizedBox(height: 16),
              _DetalhesPedido(
                rascunho: rascunho,
                onCarga: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TelaDetalhesCarga()),
                ),
                onCupom: _aplicarCupom,
              ),
            ],
          ],
        ),
        if (rascunho.roteiroCompleto && rascunho.categoria != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: _FolhaCotacao(rascunho: rascunho),
          ),
      ],
    );
  }
}

class _PainelRoteiro extends StatelessWidget {
  const _PainelRoteiro({
    required this.rascunho,
    required this.onColeta,
    required this.onEntrega,
    required this.onAdicionarParada,
    required this.onHorario,
  });

  final NovoPedido rascunho;
  final VoidCallback onColeta;
  final void Function(int) onEntrega;
  final VoidCallback onAdicionarParada;
  final VoidCallback onHorario;

  @override
  Widget build(BuildContext context) {
    return Bloco(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          _LinhaEndereco(
            icone: Icons.trip_origin,
            cor: Cores.primaria,
            titulo: rascunho.coleta?.linhaPrincipal ?? 'De onde vamos retirar?',
            subtitulo: rascunho.coleta?.linhaSecundaria,
            vazio: rascunho.coleta == null,
            onTap: onColeta,
            acao: rascunho.roteiroCompleto
                ? IconButton(
                    tooltip: 'Inverter roteiro',
                    icon: const Icon(Icons.swap_vert, color: Cores.primaria),
                    onPressed: rascunho.inverterRoteiro,
                  )
                : null,
          ),
          for (var i = 0; i < rascunho.entregas.length; i++) ...[
            const Divider(),
            _LinhaEndereco(
              icone: Icons.place,
              cor: Cores.destaque,
              titulo: rascunho.entregas[i].linhaPrincipal,
              subtitulo: rascunho.entregas[i].linhaSecundaria,
              vazio: false,
              onTap: () => onEntrega(i),
              acao: rascunho.entregas.length > 1
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Cores.textoFraco),
                      onPressed: () => rascunho.removerEntrega(i),
                    )
                  : null,
            ),
          ],
          if (rascunho.entregas.isEmpty) ...[
            const Divider(),
            _LinhaEndereco(
              icone: Icons.place_outlined,
              cor: Cores.destaque,
              titulo: 'Para onde?',
              subtitulo: null,
              vazio: true,
              onTap: onAdicionarParada,
            ),
          ],
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onAdicionarParada,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                  label: const Text('Adicionar parada'),
                ),
              ),
              TextButton.icon(
                onPressed: onHorario,
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(
                  rascunho.agendado && rascunho.quando != null
                      ? dataHora(rascunho.quando)
                      : 'Retirar agora',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinhaEndereco extends StatelessWidget {
  const _LinhaEndereco({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.subtitulo,
    required this.vazio,
    required this.onTap,
    this.acao,
  });

  final IconData icone;
  final Color cor;
  final String titulo;
  final String? subtitulo;
  final bool vazio;
  final VoidCallback onTap;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icone, size: 18, color: cor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: vazio ? FontWeight.w400 : FontWeight.w600,
                      color: vazio ? Cores.textoFraco : null,
                    ),
                  ),
                  if (subtitulo != null && subtitulo!.isNotEmpty)
                    Text(subtitulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: Cores.textoFraco)),
                ],
              ),
            ),
            if (acao != null) acao!,
          ],
        ),
      ),
    );
  }
}

class _GradeVeiculos extends StatelessWidget {
  const _GradeVeiculos({required this.rascunho});

  final NovoPedido rascunho;

  IconData _icone(String codigo) {
    switch (codigo) {
      case 'moto':
        return Icons.two_wheeler;
      case 'carro_hatch':
      case 'carro':
        return Icons.directions_car_filled_outlined;
      case 'utilitario':
        return Icons.airport_shuttle_outlined;
      case 'van':
        return Icons.local_shipping_outlined;
      default:
        return Icons.fire_truck_outlined;
    }
  }

  void _verFicha(BuildContext context, CategoriaVeiculo c) {
    showModalBottomSheet<void>(
      context: context,
      builder: (contexto) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_icone(c.codigo), size: 34, color: Cores.primaria),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(c.nome,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (c.descricao != null)
                Text(c.descricao!, style: const TextStyle(color: Cores.textoFraco)),
              const SizedBox(height: 16),
              _FichaLinha(rotulo: 'Capacidade de peso', valor: '${c.pesoMaxKg} kg'),
              _FichaLinha(rotulo: 'Espaco util (C x L x A)', valor: c.dimensoes),
              if (c.valorHora != null)
                _FichaLinha(
                    rotulo: 'Contratacao por periodo',
                    valor: '${moeda(c.valorHora!)} / hora'),
              if (c.servicos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('${c.servicos.length} servicos disponiveis',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 8),
                for (final s in c.servicos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(s.nome, style: const TextStyle(fontSize: 13.5))),
                        Text(moeda(s.preco),
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(contexto).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: rascunho.catalogo.length,
      itemBuilder: (context, i) {
        final c = rascunho.catalogo[i];
        final selecionado = rascunho.categoria?.id == c.id;
        return InkWell(
          onTap: () => rascunho.selecionarCategoria(c),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selecionado ? Cores.primaria : Cores.borda,
                width: selecionado ? 1.8 : 1,
              ),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Icon(_icone(c.codigo),
                        size: 26,
                        color: selecionado ? Cores.primaria : Cores.textoFraco),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600)),
                          Text('${c.pesoMaxKg} kg',
                              style: const TextStyle(
                                  fontSize: 11.5, color: Cores.textoFraco)),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: IconButton(
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.info_outline, color: Cores.textoFraco),
                    onPressed: () => _verFicha(context, c),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FichaLinha extends StatelessWidget {
  const _FichaLinha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(rotulo,
                style: const TextStyle(color: Cores.textoFraco, fontSize: 13.5)),
          ),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ],
      ),
    );
  }
}

class _ServicosAdicionais extends StatelessWidget {
  const _ServicosAdicionais({required this.rascunho});

  final NovoPedido rascunho;

  @override
  Widget build(BuildContext context) {
    final servicos = rascunho.categoria!.servicos;
    if (servicos.isEmpty) return const SizedBox.shrink();

    return Bloco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloSecao('Servicos adicionais'),
          for (final s in servicos)
            CheckboxListTile(
              value: rascunho.servicosSelecionados.contains(s.id),
              onChanged: (_) => rascunho.alternarServico(s.id),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Row(
                children: [
                  Expanded(
                    child: Text(s.nome, style: const TextStyle(fontSize: 14)),
                  ),
                  Text(moeda(s.preco),
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                ],
              ),
              subtitle: s.descricao == null
                  ? null
                  : Text(s.descricao!,
                      style: const TextStyle(fontSize: 12, color: Cores.textoFraco)),
            ),
        ],
      ),
    );
  }
}

class _Periodo extends StatelessWidget {
  const _Periodo({required this.rascunho});

  final NovoPedido rascunho;

  @override
  Widget build(BuildContext context) {
    final valorHora = rascunho.categoria?.valorHora;
    if (valorHora == null) return const SizedBox.shrink();

    return Bloco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloSecao('Contratar por periodo'),
          const Text(
            'Veiculo e motorista a disposicao por um bloco de horas, '
            'em vez de cobranca por rota.',
            style: TextStyle(fontSize: 12.5, color: Cores.textoFraco),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Por rota'),
                selected: rascunho.horasContratadas == null,
                onSelected: (_) => rascunho.definirHoras(null),
              ),
              for (final h in const [4, 6, 8])
                ChoiceChip(
                  label: Text('${h}h'),
                  selected: rascunho.horasContratadas == h,
                  onSelected: (_) => rascunho.definirHoras(h),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetalhesPedido extends StatelessWidget {
  const _DetalhesPedido({
    required this.rascunho,
    required this.onCarga,
    required this.onCupom,
  });

  final NovoPedido rascunho;
  final VoidCallback onCarga;
  final VoidCallback onCupom;

  @override
  Widget build(BuildContext context) {
    final carga = rascunho.carga;
    return Bloco(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: Cores.primaria),
            title: const Text('Detalhes da carga'),
            subtitle: Text(
              '${rotuloTipoItem(carga.tipoItem)} - ${carga.volumes} volume(s) - '
              '${rotuloFaixaPeso(carga.faixaPeso)}',
              style: const TextStyle(fontSize: 12.5),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onCarga,
          ),
          const Divider(indent: 16, endIndent: 16),
          SwitchListTile(
            value: rascunho.favoritosPrimeiro,
            onChanged: rascunho.alternarFavoritosPrimeiro,
            secondary: const Icon(Icons.star_outline, color: Cores.primaria),
            title: const Text('Motoristas favoritos primeiro'),
            subtitle: const Text(
              'Seus parceiros de confianca recebem a oferta antes da base geral',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          SwitchListTile(
            value: rascunho.exigeComprovante,
            onChanged: rascunho.alternarComprovante,
            secondary: const Icon(Icons.assignment_turned_in_outlined,
                color: Cores.primaria),
            title: const Text('Exigir comprovante de entrega'),
            subtitle: const Text('Foto ou assinatura do recebedor',
                style: TextStyle(fontSize: 12)),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.local_offer_outlined, color: Cores.primaria),
            title: const Text('Cupom de desconto'),
            subtitle: Text(rascunho.cupom ?? 'Nenhum cupom aplicado',
                style: const TextStyle(fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right),
            onTap: onCupom,
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 12.5, color: cor)),
          ),
        ],
      ),
    );
  }
}

/// Folha fixa no rodape com as opcoes de preco e o botao de avancar.
class _FolhaCotacao extends StatefulWidget {
  const _FolhaCotacao({required this.rascunho});

  final NovoPedido rascunho;

  @override
  State<_FolhaCotacao> createState() => _FolhaCotacaoState();
}

class _FolhaCotacaoState extends State<_FolhaCotacao> {
  bool _expandida = true;

  @override
  Widget build(BuildContext context) {
    final rascunho = widget.rascunho;
    final cotacao = rascunho.cotacao;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: Cores.borda),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => setState(() => _expandida = !_expandida),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(_expandida ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: Cores.textoFraco),
                    if (!_expandida)
                      const Text('Ver todas as opcoes de preco',
                          style: TextStyle(fontSize: 12.5, color: Cores.textoFraco)),
                  ],
                ),
              ),
            ),
            if (rascunho.cotando)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(width: 12),
                    Text('Calculando a cotacao...'),
                  ],
                ),
              )
            else if (cotacao == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Complete o roteiro para ver o preco'),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.route_outlined, size: 16, color: Cores.textoFraco),
                    const SizedBox(width: 6),
                    Text(
                      '${km(cotacao.distanciaKm)} - ${cotacao.paradas} paradas',
                      style: const TextStyle(fontSize: 12.5, color: Cores.textoFraco),
                    ),
                    const Spacer(),
                    if (cotacao.cupomAplicado != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Cores.sucesso.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cotacao.cupomAplicado!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Cores.sucesso,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final opcao in _visiveis(cotacao.opcoes, rascunho))
                _OpcaoPreco(
                  opcao: opcao,
                  selecionada: rascunho.nivelSelecionado == opcao.nivel,
                  onTap: () => rascunho.definirNivel(opcao.nivel),
                  onDetalhe: () => _detalharPreco(context, opcao, cotacao.avisos),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TelaRevisao()),
                  ),
                  child: const Text('Proximo passo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<OpcaoCotacao> _visiveis(List<OpcaoCotacao> opcoes, NovoPedido rascunho) {
    if (_expandida) return opcoes;
    return opcoes.where((o) => o.nivel == rascunho.nivelSelecionado).toList();
  }

  void _detalharPreco(BuildContext context, OpcaoCotacao opcao, List<String> avisos) {
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
              _FichaLinha(rotulo: 'Taxa de entrega', valor: moeda(opcao.valorFrete)),
              if (opcao.valorAdicionais > 0)
                _FichaLinha(
                    rotulo: 'Servicos adicionais',
                    valor: moeda(opcao.valorAdicionais)),
              if (opcao.desconto > 0)
                _FichaLinha(rotulo: 'Desconto', valor: '- ${moeda(opcao.desconto)}'),
              const Divider(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text('Total',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  Text(moeda(opcao.total),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
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
}

class _OpcaoPreco extends StatelessWidget {
  const _OpcaoPreco({
    required this.opcao,
    required this.selecionada,
    required this.onTap,
    required this.onDetalhe,
  });

  final OpcaoCotacao opcao;
  final bool selecionada;
  final VoidCallback onTap;
  final VoidCallback onDetalhe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selecionada ? Cores.primaria.withOpacity(0.05) : null,
            border: Border.all(
              color: selecionada ? Cores.primaria : Cores.borda,
              width: selecionada ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(opcao.nome,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        if (opcao.recomendado) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Cores.destaque,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('recomendado',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                        const SizedBox(width: 4),
                        IconButton(
                          iconSize: 15,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.info_outline, color: Cores.textoFraco),
                          onPressed: onDetalhe,
                        ),
                      ],
                    ),
                    Text(opcao.descricao,
                        style: const TextStyle(fontSize: 12, color: Cores.textoFraco)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(moeda(opcao.total),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  if (opcao.desconto > 0)
                    Text(moeda(opcao.valorFrete + opcao.valorAdicionais),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Cores.textoFraco,
                          decoration: TextDecoration.lineThrough,
                        )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
