import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/progresso_pedido.dart';
import '../estado/novo_pedido.dart';
import '../modelos/modelos.dart';
import 'detalhes_carga.dart';
import 'revisao.dart';
import 'selecao_endereco.dart';

/// Segunda etapa do pedido, aberta depois que o roteiro foi escolhido:
/// horario, veiculo, servicos e cotacao.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monte seu frete'),
        bottom: const ProgressoPedido(etapa: 3),
      ),
      // Com o painel fechado, uma barra lembra o veiculo e reabre o painel.
      bottomNavigationBar: rascunho.categoria == null
          ? null
          : _BarraVeiculo(rascunho: rascunho, onAbrir: _abrirPainelVeiculo),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
          const TituloSecao('Escolha o veículo'),
          if (rascunho.catalogo.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else
            _GradeVeiculos(
              rascunho: rascunho,
              onSelecionado: _abrirPainelVeiculo,
            ),
          if (rascunho.avisoCapacidade != null) ...[
            const SizedBox(height: 12),
            _Aviso(texto: rascunho.avisoCapacidade!, cor: Cores.alerta),
          ],
        ],
      ),
    );
  }

  /// Painel do veiculo escolhido: preco, motoristas proximos, extras e
  /// preferencias ficam todos dentro dele, com o botao de avancar fixo.
  void _abrirPainelVeiculo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Cores.fundo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (contexto, rolagem) => _PainelVeiculo(
          rolagem: rolagem,
          onCupom: _aplicarCupom,
        ),
      ),
    );
  }
}

/// Barra no rodape com o veiculo escolhido e o preco; reabre o painel.
class _BarraVeiculo extends StatelessWidget {
  const _BarraVeiculo({required this.rascunho, required this.onAbrir});

  final NovoPedido rascunho;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final opcao = rascunho.opcaoSelecionada;
    return Container(
      decoration: const BoxDecoration(
        color: Cores.superficie,
        border: Border(top: BorderSide(color: Cores.borda)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rascunho.categoria!.nome,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(
                      opcao == null
                          ? 'Calculando o preço...'
                          : '${opcao.nome} · ${moeda(opcao.total)}',
                      style: const TextStyle(
                          fontSize: 12.5, color: Cores.textoFraco),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 20)),
                onPressed: onAbrir,
                child: const Text('Ver opções'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conteudo do painel do veiculo. Le o rascunho direto do Provider para
/// atualizar sozinho quando o preco ou os motoristas mudam.
class _PainelVeiculo extends StatelessWidget {
  const _PainelVeiculo({required this.rolagem, required this.onCupom});

  final ScrollController rolagem;
  final VoidCallback onCupom;

  @override
  Widget build(BuildContext context) {
    final rascunho = context.watch<NovoPedido>();
    final categoria = rascunho.categoria;
    // O veiculo pode ser desmarcado (ex.: carga editada); nesse caso fecha.
    if (categoria == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }
    final cotacao = rascunho.cotacao;
    final opcao = rascunho.opcaoSelecionada;

    return Column(
      children: [
        // cabecalho fixo: alca, veiculo e botao de fechar
        Container(
          decoration: const BoxDecoration(
            color: Cores.superficie,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(bottom: BorderSide(color: Cores.borda)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Cores.borda,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(categoria.nome,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                          'Até ${categoria.pesoMaxKg} kg · ${categoria.dimensoes}',
                          style: const TextStyle(
                              fontSize: 12.5, color: Cores.textoFraco),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: rolagem,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const TituloSecao('Escolha o nível de serviço'),
              if (rascunho.cotando && cotacao == null)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (cotacao != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.route_outlined,
                          size: 16, color: Cores.textoFraco),
                      const SizedBox(width: 6),
                      Text(
                        '${km(cotacao.distanciaKm)} · ${cotacao.paradas} paradas',
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
                ),
                for (final o in cotacao.opcoes)
                  _OpcaoPreco(
                    opcao: o,
                    selecionada: rascunho.nivelSelecionado == o.nivel,
                    onTap: () => rascunho.definirNivel(o.nivel),
                    onDetalhe: () => _detalharPreco(context, o, cotacao.avisos),
                  ),
              ],
              const SizedBox(height: 20),
              _MotoristasProximos(rascunho: rascunho),
              const SizedBox(height: 20),
              _ServicosAdicionais(rascunho: rascunho),
              const SizedBox(height: 16),
              _Periodo(rascunho: rascunho),
              const SizedBox(height: 16),
              _DetalhesPedido(rascunho: rascunho, onCupom: onCupom),
            ],
          ),
        ),
        // rodape fixo: total e botao de avancar
        Container(
          decoration: const BoxDecoration(
            color: Cores.superficie,
            border: Border(top: BorderSide(color: Cores.borda)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opcao?.nome ?? 'Total',
                            style: const TextStyle(
                                fontSize: 12.5, color: Cores.textoFraco)),
                        Text(
                          opcao == null ? '—' : moeda(opcao.total),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 24)),
                    onPressed: opcao == null || rascunho.cotando
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const TelaRevisao()),
                            ),
                    child: const Text('Próximo passo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _detalharPreco(
    BuildContext context, OpcaoCotacao opcao, List<String> avisos) {
  showModalBottomSheet<void>(
    context: context,
    builder: (contexto) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TituloSecao('Detalhes do preço'),
            _FichaLinha(
                rotulo: 'Taxa de entrega', valor: moeda(opcao.valorFrete)),
            if (opcao.valorAdicionais > 0)
              _FichaLinha(
                  rotulo: 'Serviços adicionais',
                  valor: moeda(opcao.valorAdicionais)),
            if (opcao.desconto > 0)
              _FichaLinha(
                  rotulo: 'Desconto', valor: '- ${moeda(opcao.desconto)}'),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Total',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                    style:
                        const TextStyle(fontSize: 12, color: Cores.textoFraco)),
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
  const _GradeVeiculos({required this.rascunho, required this.onSelecionado});

  final NovoPedido rascunho;

  /// Chamado depois que um veiculo compativel e escolhido.
  final VoidCallback onSelecionado;

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
                Text(c.descricao!,
                    style: const TextStyle(color: Cores.textoFraco)),
              const SizedBox(height: 16),
              _FichaLinha(
                  rotulo: 'Capacidade de peso', valor: '${c.pesoMaxKg} kg'),
              _FichaLinha(
                  rotulo: 'Espaço útil (C x L x A)', valor: c.dimensoes),
              if (c.valorHora != null)
                _FichaLinha(
                    rotulo: 'Contratação por período',
                    valor: '${moeda(c.valorHora!)} / hora'),
              if (c.servicos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('${c.servicos.length} serviços disponíveis',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 8),
                for (final s in c.servicos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(s.nome,
                                style: const TextStyle(fontSize: 13.5))),
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
        final motivo = rascunho.motivoIndisponivel(c);
        return InkWell(
          onTap: motivo == null
              ? () {
                  rascunho.selecionarCategoria(c);
                  onSelecionado();
                }
              : () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text('${c.nome} não comporta sua carga: $motivo'),
                )),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: motivo == null ? Colors.white : Cores.fundo,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selecionado ? Cores.primaria : Cores.borda,
                width: selecionado ? 1.8 : 1,
              ),
            ),
            child: Stack(
              children: [
                Opacity(
                  opacity: motivo == null ? 1 : 0.45,
                  child: Row(
                    children: [
                      Icon(_icone(c.codigo),
                          size: 26,
                          color:
                              selecionado ? Cores.primaria : Cores.textoFraco),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(c.nome,
                                maxLines: motivo == null ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                            Text(motivo ?? '${c.pesoMaxKg} kg',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: motivo == null
                                        ? Cores.textoFraco
                                        : Cores.alerta)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: IconButton(
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    icon:
                        const Icon(Icons.info_outline, color: Cores.textoFraco),
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
                style:
                    const TextStyle(color: Cores.textoFraco, fontSize: 13.5)),
          ),
          Text(valor,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ],
      ),
    );
  }
}

/// Ate 10 motoristas do veiculo escolhido perto da coleta, em cartoes
/// que deslizam para o lado.
class _MotoristasProximos extends StatelessWidget {
  const _MotoristasProximos({required this.rascunho});

  final NovoPedido rascunho;

  @override
  Widget build(BuildContext context) {
    final lista = rascunho.motoristasProximos;
    final veiculo = rascunho.categoria!.nome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TituloSecao(
          'Motoristas perto da coleta',
          acao: rascunho.buscandoMotoristas || lista.isEmpty
              ? null
              : Text('${lista.length} disponíveis',
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: Cores.sucesso,
                      fontWeight: FontWeight.w600)),
        ),
        if (rascunho.buscandoMotoristas)
          const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (lista.isEmpty)
          Bloco(
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty, color: Cores.textoFraco),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhum motorista de $veiculo por perto agora. '
                    'Assim que você confirmar, ofertamos para quem ficar disponível.',
                    style: const TextStyle(
                        fontSize: 12.5, color: Cores.textoFraco),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _CartaoMotorista(motorista: lista[i]),
            ),
          ),
      ],
    );
  }
}

class _CartaoMotorista extends StatelessWidget {
  const _CartaoMotorista({required this.motorista});

  final MotoristaProximo motorista;

  /// "Carlos Almeida" -> "Carlos A."
  String get _nomeCurto {
    final partes = motorista.nome.split(' ');
    return partes.length < 2
        ? motorista.nome
        : '${partes.first} ${partes[1][0]}.';
  }

  String get _iniciais => motorista.nome
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0])
      .join();

  @override
  Widget build(BuildContext context) {
    final m = motorista;
    return Container(
      width: 158,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: m.favorito ? Cores.destaque : Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Cores.primaria.withOpacity(0.1),
                child: Text(_iniciais,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Cores.primaria)),
              ),
              const Spacer(),
              if (m.favorito)
                const Tooltip(
                  message: 'Seu motorista favorito',
                  child: Icon(Icons.favorite, size: 18, color: Cores.destaque),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_nomeCurto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 15, color: Cores.destaque),
              const SizedBox(width: 2),
              Text(
                '${m.avaliacao.toStringAsFixed(1).replaceAll('.', ',')} · '
                '${m.totalCorridas} fretes',
                style: const TextStyle(fontSize: 11.5, color: Cores.textoFraco),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${km(m.distanciaKm)} · ${m.minutosAteColeta} min',
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Cores.primaria),
          ),
          if (m.veiculo != null && m.veiculo!.isNotEmpty)
            Text(m.veiculo!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Cores.textoFraco)),
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
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                ],
              ),
              subtitle: s.descricao == null
                  ? null
                  : Text(s.descricao!,
                      style: const TextStyle(
                          fontSize: 12, color: Cores.textoFraco)),
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

/// Carga informada na etapa anterior; toque para editar.
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
          '${rotuloTipoItem(carga.tipoItem)} - ${carga.volumes} volume(s) - '
          '${rotuloFaixaPeso(carga.faixaPeso)}',
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

class _DetalhesPedido extends StatelessWidget {
  const _DetalhesPedido({required this.rascunho, required this.onCupom});

  final NovoPedido rascunho;
  final VoidCallback onCupom;

  @override
  Widget build(BuildContext context) {
    return Bloco(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            value: rascunho.favoritosPrimeiro,
            onChanged: rascunho.alternarFavoritosPrimeiro,
            secondary: const Icon(Icons.star_outline, color: Cores.primaria),
            title: const Text('Motoristas favoritos primeiro'),
            subtitle: const Text(
              'Seus parceiros de confiança recebem a oferta antes da base geral',
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                          icon: const Icon(Icons.info_outline,
                              color: Cores.textoFraco),
                          onPressed: onDetalhe,
                        ),
                      ],
                    ),
                    Text(opcao.descricao,
                        style: const TextStyle(
                            fontSize: 12, color: Cores.textoFraco)),
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
