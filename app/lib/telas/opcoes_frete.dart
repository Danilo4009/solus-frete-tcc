import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ajuda_pedido.dart';
import '../core/compatibilidade.dart';
import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/ajuda.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/progresso_pedido.dart';
import '../estado/novo_pedido.dart';
import '../modelos/modelos.dart';
import 'cotacoes.dart';
import 'detalhes_carga.dart';
import 'revisao.dart';
import 'selecao_endereco.dart';

/// Terceira etapa do pedido: roteiro (editavel), resumo da carga, veiculo (so os que
/// comportam a carga), servicos, periodo e o parceiro (escolhido em [TelaCotacoes]).
class TelaOpcoesFrete extends StatefulWidget {
  const TelaOpcoesFrete({super.key});

  @override
  State<TelaOpcoesFrete> createState() => _TelaOpcoesFreteState();
}

class _TelaOpcoesFreteState extends State<TelaOpcoesFrete> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NovoPedido>().carregarCatalogo();
    });
  }

  Future<void> _escolherEndereco(
      {required bool coleta, int? indiceEntrega}) async {
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
                child: TituloSecao('Horário de retirada'),
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
        initialTime: TimeOfDay.fromDateTime(
            DateTime.now().add(const Duration(hours: 2))),
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
              labelText: 'Código', hintText: 'SOLUS10 ou MUDANCA15'),
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
    final mostraFolha = rascunho.categoria != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veículo e parceiro'),
        bottom: const ProgressoPedido(etapa: 3),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, mostraFolha ? 220 : 88),
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
              _ResumoCarga(
                carga: rascunho.carga,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TelaDetalhesCarga()),
                ),
              ),
              const SizedBox(height: 16),
              const TituloSecao(
                'Veículo para este frete',
                acao: IconeInfoSecao(secao: SecaoAjuda.veiculo),
              ),
              if (!rascunho.cargaValida) ...[
                const _Aviso(
                  texto:
                      'Preencha o peso e as dimensões da carga para ver quais veículos '
                      'comportam a sua carga.',
                  cor: Cores.primaria,
                ),
                const SizedBox(height: 10),
              ],
              if (rascunho.catalogo.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else
                _GradeVeiculos(rascunho: rascunho),
              if (rascunho.avisoVeiculoDesmarcado != null) ...[
                const SizedBox(height: 12),
                _Aviso(
                    texto: rascunho.avisoVeiculoDesmarcado!, cor: Cores.alerta),
              ],
              if (rascunho.nenhumVeiculoCompativel) ...[
                const SizedBox(height: 12),
                const _Aviso(
                  texto:
                      'Nenhum veículo comporta esta carga. Divida a carga em mais de um '
                      'pedido ou entre em contato com a gente.',
                  cor: Cores.alerta,
                ),
              ],
              if (rascunho.categoria != null) ...[
                const SizedBox(height: 16),
                _ServicosAdicionais(rascunho: rascunho),
                const SizedBox(height: 16),
                _Periodo(rascunho: rascunho),
                const SizedBox(height: 16),
                _DetalhesPedido(rascunho: rascunho, onCupom: _aplicarCupom),
              ],
            ],
          ),
          // O botao de ajuda fica logo acima da folha de cotacao, para nao cobrir o
          // botao "Proximo passo".
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 12, 12),
                  child: BotaoAjuda(),
                ),
                if (mostraFolha) _FolhaCotacao(rascunho: rascunho),
              ],
            ),
          ),
        ],
      ),
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

/// Cartao com o resumo da carga ja informada na etapa anterior; toque para editar.
class _ResumoCarga extends StatelessWidget {
  const _ResumoCarga({required this.carga, required this.onTap});

  final Carga carga;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bloco(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined, color: Cores.primaria),
        title: const Text('Sua carga'),
        subtitle: Text(
          carga.completa
              ? '${rotuloTipoCarga(carga.tipoCarga)} - ${carga.volumes} volume(s) - '
                  '${pesoKg(carga.pesoKg!)}'
              : 'Toque para informar peso e dimensões',
          style: const TextStyle(fontSize: 12.5),
        ),
        trailing: const Text('Editar',
            style:
                TextStyle(color: Cores.primaria, fontWeight: FontWeight.w600)),
        onTap: onTap,
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
                Text(c.descricao!,
                    style: const TextStyle(color: Cores.textoFraco)),
              const SizedBox(height: 16),
              _FichaLinha(
                  rotulo: 'Capacidade de peso', valor: pesoKg(c.pesoMaxKg)),
              _FichaLinha(
                  rotulo: 'Espaço útil (C x L x A)', valor: c.dimensoes),
              _FichaLinha(
                  rotulo: 'Volume do baú',
                  valor:
                      '${c.volumeM3.toStringAsFixed(1).replaceAll('.', ',')} m³'),
              _FichaLinha(
                  rotulo: 'Carga refrigerada',
                  valor: c.aceitaRefrigerada ? 'Aceita' : 'Não aceita'),
              _FichaLinha(
                  rotulo: 'Carga perigosa',
                  valor: c.aceitaPerigosa ? 'Aceita' : 'Não aceita'),
              if (c.valorHora != null)
                _FichaLinha(
                    rotulo: 'Contratação por período',
                    valor: '${moeda(c.valorHora!)} / hora'),
              if (c.servicos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('${c.servicos.length} serviços disponíveis',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                for (final s in c.servicos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(s.nome,
                                style: const TextStyle(fontSize: 14))),
                        Text(moeda(s.preco),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
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
    return LayoutBuilder(
      builder: (context, restricoes) {
        final largura = (restricoes.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in rascunho.catalogo)
              SizedBox(
                width: largura,
                child: _CartaoVeiculo(
                  key: ValueKey('veiculo-${c.codigo}'),
                  veiculo: c,
                  icone: _icone(c.codigo),
                  selecionado: rascunho.categoria?.id == c.id,
                  recomendado: rascunho.veiculoRecomendado?.id == c.id,
                  compatibilidade: rascunho.compatibilidadeDe(c),
                  onTap: () => rascunho.selecionarCategoria(c),
                  onFicha: () => _verFicha(context, c),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Card de um veiculo. Fica acinzentado e sem toque quando a carga nao cabe (ou ainda nao
/// foi informada); nesse caso o motivo aparece logo abaixo do card. O menor veiculo
/// compativel pulsa em amarelo com um selo "Recomendado", mas o cliente pode escolher
/// qualquer outro habilitado.
class _CartaoVeiculo extends StatefulWidget {
  const _CartaoVeiculo({
    super.key,
    required this.veiculo,
    required this.icone,
    required this.selecionado,
    required this.recomendado,
    required this.compatibilidade,
    required this.onTap,
    required this.onFicha,
  });

  final CategoriaVeiculo veiculo;
  final IconData icone;
  final bool selecionado;
  final bool recomendado;

  /// Null enquanto a carga esta incompleta.
  final ResultadoCompatibilidade? compatibilidade;
  final VoidCallback onTap;
  final VoidCallback onFicha;

  @override
  State<_CartaoVeiculo> createState() => _CartaoVeiculoState();
}

class _CartaoVeiculoState extends State<_CartaoVeiculo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _habilitado => widget.compatibilidade?.compativel ?? false;

  bool get _pulsando => widget.recomendado && _habilitado;

  @override
  void initState() {
    super.initState();
    if (_pulsando) _pulso.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_CartaoVeiculo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pulsando && !_pulso.isAnimating) {
      _pulso.repeat(reverse: true);
    } else if (!_pulsando && _pulso.isAnimating) {
      _pulso.stop();
      _pulso.value = 0;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motivo = widget.compatibilidade?.motivo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulso,
          builder: (context, filho) {
            final aceso = _pulsando ? _pulso.value : 0.0;
            final corBorda = widget.selecionado
                ? Cores.primaria
                : (_pulsando
                    ? Color.lerp(
                        Cores.destaque.withOpacity(0.55), Cores.destaque, aceso)
                    : Cores.borda);
            return Container(
              decoration: _pulsando
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Cores.destaque.withOpacity(0.18 + 0.22 * aceso),
                          blurRadius: 10,
                          spreadRadius: 1 + aceso,
                        ),
                      ],
                    )
                  : null,
              child: InkWell(
                onTap: _habilitado ? widget.onTap : null,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 66),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _habilitado ? Colors.white : Cores.fundo,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: corBorda ?? Cores.borda,
                      width: widget.selecionado ? 1.8 : (_pulsando ? 1.6 : 1),
                    ),
                  ),
                  child: filho,
                ),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Icon(widget.icone,
                      size: 26,
                      color: !_habilitado
                          ? Cores.borda
                          : (widget.selecionado
                              ? Cores.primaria
                              : Cores.textoFraco)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.veiculo.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _habilitado ? null : Cores.textoFraco)),
                        Text(pesoKg(widget.veiculo.pesoMaxKg),
                            style: const TextStyle(
                                fontSize: 11, color: Cores.textoFraco)),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -6,
                right: -6,
                child: IconButton(
                  tooltip: 'Ficha do veículo',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.info_outline, color: Cores.textoFraco),
                  onPressed: widget.onFicha,
                ),
              ),
              if (_habilitado && widget.recomendado)
                Positioned(
                  top: -10,
                  left: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Cores.destaque,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Recomendado',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
        if (motivo != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: Text(motivo,
                style: const TextStyle(fontSize: 11, color: Cores.alerta)),
          ),
      ],
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
                style: const TextStyle(color: Cores.textoFraco, fontSize: 14)),
          ),
          Text(valor,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
          const TituloSecao('Serviços adicionais'),
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
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              subtitle: s.descricao == null
                  ? null
                  : Text(s.descricao!,
                      style: const TextStyle(
                          fontSize: 12.5, color: Cores.textoFraco)),
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
          const TituloSecao('Contratar por período'),
          const Text(
            'Veículo e motorista à disposição por um bloco de horas, '
            'em vez de cobrança por rota.',
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
    required this.onCupom,
  });

  final NovoPedido rascunho;
  final VoidCallback onCupom;

  @override
  Widget build(BuildContext context) {
    return Bloco(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            value: rascunho.exigeComprovante,
            onChanged: rascunho.alternarComprovante,
            secondary: const Icon(Icons.assignment_turned_in_outlined,
                color: Cores.primaria),
            title: const Text('Exigir comprovante de entrega'),
            subtitle: const Text('Foto ou assinatura do recebedor',
                style: TextStyle(fontSize: 12.5)),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading:
                const Icon(Icons.local_offer_outlined, color: Cores.primaria),
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

/// Folha fixa no rodape: resumo do roteiro, parceiro escolhido e botao de avancar.
class _FolhaCotacao extends StatelessWidget {
  const _FolhaCotacao({required this.rascunho});

  final NovoPedido rascunho;

  void _escolher(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TelaCotacoes()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cotacao = rascunho.cotacao;
    final oferta = rascunho.ofertaEscolhida;

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rascunho.cotando)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(width: 12),
                    Text('Buscando parceiros na sua região...'),
                  ],
                )
              else if (cotacao == null)
                const Text(
                    'Complete o roteiro e escolha o veículo para ver os parceiros',
                    textAlign: TextAlign.center)
              else ...[
                Row(
                  children: [
                    const Icon(Icons.route_outlined,
                        size: 16, color: Cores.textoFraco),
                    const SizedBox(width: 6),
                    Text(
                      '${km(cotacao.distanciaKm)} - ${cotacao.paradas} paradas',
                      style: const TextStyle(
                          fontSize: 12.5, color: Cores.textoFraco),
                    ),
                    const Spacer(),
                    if (cotacao.cupomAplicado != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
                const SizedBox(height: 10),
                if (cotacao.ofertas.isEmpty)
                  const Text(
                    'Nenhum parceiro disponível para este veículo na região da coleta. '
                    'Tente outra categoria.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Cores.alerta),
                  )
                else if (oferta == null) ...[
                  FilledButton.icon(
                    onPressed: () => _escolher(context),
                    icon: const Icon(Icons.groups_2_outlined),
                    label: Text(
                        'Escolher entre ${cotacao.ofertas.length} parceiros'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Motoristas parceiros e transportadoras da sua região, '
                    'a partir de ${moeda(cotacao.ofertas.map((o) => o.total).reduce((a, b) => a < b ? a : b))}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12.5, color: Cores.textoFraco),
                  ),
                ] else ...[
                  CartaoOferta(
                    oferta: oferta,
                    selecionada: true,
                    rotuloAcao: 'Trocar',
                    onTap: () => _escolher(context),
                    onDetalhe: () =>
                        mostrarDetalhePreco(context, oferta, cotacao.avisos),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TelaRevisao()),
                    ),
                    child: const Text('Próximo passo'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
