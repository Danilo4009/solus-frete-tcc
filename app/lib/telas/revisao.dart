import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/novo_pedido.dart';
import 'acompanhamento.dart';

/// Pagamento, pagador e confirmacao final do pedido.
class TelaRevisao extends StatefulWidget {
  const TelaRevisao({super.key});

  @override
  State<TelaRevisao> createState() => _TelaRevisaoState();
}

class _TelaRevisaoState extends State<TelaRevisao> {
  bool _aceiteItens = false;
  bool _enviando = false;

  Future<void> _escolherPagamento() async {
    final rascunho = context.read<NovoPedido>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (contexto) => SafeArea(
        child: StatefulBuilder(
          builder: (contexto, refazer) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TituloSecao('Forma de pagamento'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Carteira Solus'),
                subtitle: const Text('Debita do saldo disponivel'),
                trailing: rascunho.formaPagamento == 'carteira'
                    ? const Icon(Icons.check_circle, color: Cores.primaria)
                    : null,
                onTap: () {
                  rascunho.definirPagamento('carteira', quemPaga: 'remetente');
                  Navigator.of(contexto).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.pix),
                title: const Text('Pix'),
                subtitle: const Text('Pagamento online no ato'),
                trailing: rascunho.formaPagamento == 'pix'
                    ? const Icon(Icons.check_circle, color: Cores.primaria)
                    : null,
                onTap: () {
                  rascunho.definirPagamento('pix', quemPaga: 'remetente');
                  Navigator.of(contexto).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Cartao de credito'),
                subtitle: const Text('Cadastre no app do cliente'),
                trailing: rascunho.formaPagamento == 'cartao'
                    ? const Icon(Icons.check_circle, color: Cores.primaria)
                    : null,
                onTap: () {
                  rascunho.definirPagamento('cartao', quemPaga: 'remetente');
                  Navigator.of(contexto).pop();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Dinheiro'),
                subtitle: const Text('Escolha quem vai pagar ao motorista'),
                trailing: rascunho.formaPagamento == 'dinheiro'
                    ? const Icon(Icons.check_circle, color: Cores.primaria)
                    : null,
                onTap: () => refazer(
                    () => rascunho.definirPagamento('dinheiro', quemPaga: rascunho.pagador)),
              ),
              if (rascunho.formaPagamento == 'dinheiro') ...[
                RadioListTile<String>(
                  value: 'remetente',
                  groupValue: rascunho.pagador,
                  onChanged: (v) => refazer(() =>
                      rascunho.definirPagamento('dinheiro', quemPaga: v ?? 'remetente')),
                  title: const Text('Remetente paga na coleta'),
                  subtitle: Text(rascunho.coleta?.linhaPrincipal ?? '',
                      style: const TextStyle(fontSize: 12)),
                ),
                RadioListTile<String>(
                  value: 'destinatario',
                  groupValue: rascunho.pagador,
                  onChanged: (v) => refazer(() =>
                      rascunho.definirPagamento('dinheiro', quemPaga: v ?? 'destinatario')),
                  title: const Text('Destinatario paga na entrega (frete a pagar)'),
                  subtitle: Text(
                      rascunho.entregas.isEmpty
                          ? ''
                          : rascunho.entregas.last.linhaPrincipal,
                      style: const TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () => Navigator.of(contexto).pop(),
                    child: const Text('Confirmar forma de pagamento'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmar() async {
    final rascunho = context.read<NovoPedido>();

    if (!_aceiteItens) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Confirme a declaracao de itens proibidos'),
      ));
      return;
    }
    final pendencias = rascunho.pendenciasParaConfirmar;
    if (pendencias.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pendencias.first)));
      return;
    }

    setState(() => _enviando = true);
    try {
      final pedido = await rascunho.confirmar();
      if (!mounted) return;
      if (pedido == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel criar o pedido')),
        );
        return;
      }
      rascunho.limpar();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TelaAcompanhamento(pedidoId: pedido.id)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rascunho = context.watch<NovoPedido>();
    final opcao = rascunho.opcaoSelecionada;

    return Scaffold(
      appBar: AppBar(title: const Text('Revisar e confirmar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Roteiro'),
                for (var i = 0; i < rascunho.paradas.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(i == 0 ? Icons.trip_origin : Icons.place,
                            size: 16,
                            color: i == 0 ? Cores.primaria : Cores.destaque),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rascunho.paradas[i].linhaPrincipal,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(rascunho.paradas[i].linhaSecundaria,
                                  style: const TextStyle(
                                      fontSize: 12, color: Cores.textoFraco)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 22),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Cores.textoFraco),
                    const SizedBox(width: 8),
                    Text(
                      rascunho.agendado
                          ? 'Coleta agendada para ${dataHora(rascunho.quando)}'
                          : 'Coleta imediata',
                      style: const TextStyle(fontSize: 13),
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
                const TituloSecao('Veiculo e carga'),
                _Linha(
                    rotulo: 'Veiculo',
                    valor: rascunho.categoria?.nome ?? '-'),
                _Linha(
                    rotulo: 'Nivel de servico',
                    valor: opcao?.nome ?? rascunho.nivelSelecionado),
                if (rascunho.horasContratadas != null)
                  _Linha(
                      rotulo: 'Contratacao',
                      valor: '${rascunho.horasContratadas}h por periodo'),
                _Linha(
                    rotulo: 'Carga',
                    valor:
                        '${rotuloTipoItem(rascunho.carga.tipoItem)}, ${rascunho.carga.volumes} volume(s)'),
                _Linha(
                    rotulo: 'Peso declarado',
                    valor: rotuloFaixaPeso(rascunho.carga.faixaPeso)),
                if (rascunho.servicosSelecionados.isNotEmpty)
                  _Linha(
                    rotulo: 'Servicos',
                    valor: rascunho.categoria!.servicos
                        .where((s) => rascunho.servicosSelecionados.contains(s.id))
                        .map((s) => s.nome)
                        .join(', '),
                  ),
                _Linha(
                    rotulo: 'Comprovante',
                    valor: rascunho.exigeComprovante ? 'Exigido' : 'Nao exigido'),
                _Linha(
                    rotulo: 'Favoritos primeiro',
                    valor: rascunho.favoritosPrimeiro ? 'Sim' : 'Nao'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.payments_outlined, color: Cores.primaria),
              title: Text(rascunho.formaPagamento == null
                  ? 'Selecione a forma de pagamento'
                  : rotuloPagamento(rascunho.formaPagamento!)),
              subtitle: Text(
                rascunho.formaPagamento == 'dinheiro'
                    ? (rascunho.pagador == 'destinatario'
                        ? 'Frete a pagar: destinatario paga na entrega'
                        : 'Remetente paga na coleta')
                    : 'Obrigatorio para confirmar o pedido',
                style: TextStyle(
                  fontSize: 12.5,
                  color: rascunho.formaPagamento == null ? Cores.alerta : null,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _escolherPagamento,
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: CheckboxListTile(
              value: _aceiteItens,
              onChanged: (v) => setState(() => _aceiteItens = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Declaro que a carga nao contem itens proibidos pela politica do Solus Frete.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          if (opcao != null) ...[
            const SizedBox(height: 12),
            Bloco(
              child: Column(
                children: [
                  _Linha(rotulo: 'Taxa de entrega', valor: moeda(opcao.valorFrete)),
                  if (opcao.valorAdicionais > 0)
                    _Linha(
                        rotulo: 'Servicos adicionais',
                        valor: moeda(opcao.valorAdicionais)),
                  if (opcao.desconto > 0)
                    _Linha(rotulo: 'Desconto', valor: '- ${moeda(opcao.desconto)}'),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Total',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      Text(moeda(opcao.total),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pedagio e estacionamento nao estao inclusos e sao acertados direto com o parceiro.',
                      style: TextStyle(fontSize: 11.5, color: Cores.textoFraco),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _enviando ? null : _confirmar,
            child: Text(_enviando ? 'Enviando pedido...' : 'Confirmar pedido'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(rotulo,
                style: const TextStyle(color: Cores.textoFraco, fontSize: 13.5)),
          ),
          Expanded(
            flex: 3,
            child: Text(valor,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
