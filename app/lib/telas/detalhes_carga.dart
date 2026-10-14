import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/ajuda_pedido.dart';
import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/ajuda.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/progresso_pedido.dart';
import '../estado/novo_pedido.dart';
import '../modelos/modelos.dart';
import 'opcoes_frete.dart';

/// Peso, dimensões do maior volume, quantidade de volumes, tipo e observações da carga.
/// No fluxo do pedido vem antes da escolha do veículo ([etapaDoFluxo]); cada alteração
/// atualiza o rascunho na hora, e a lista de veículos da próxima etapa reage.
class TelaDetalhesCarga extends StatefulWidget {
  const TelaDetalhesCarga({super.key, this.etapaDoFluxo = false});

  final bool etapaDoFluxo;

  @override
  State<TelaDetalhesCarga> createState() => _TelaDetalhesCargaState();
}

class _TelaDetalhesCargaState extends State<TelaDetalhesCarga> {
  late final TextEditingController _peso;
  late final TextEditingController _comprimento;
  late final TextEditingController _largura;
  late final TextEditingController _altura;
  late final TextEditingController _observacoes;
  late final TextEditingController _notaMotorista;
  late String _tipo;
  late int _volumes;
  late bool _naoEmpilhar;

  @override
  void initState() {
    super.initState();
    final rascunho = context.read<NovoPedido>();
    final c = rascunho.carga;
    String texto(double? v) => v == null
        ? ''
        : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
    _peso = TextEditingController(text: texto(c.pesoKg));
    _comprimento = TextEditingController(text: texto(c.comprimentoCm));
    _largura = TextEditingController(text: texto(c.larguraCm));
    _altura = TextEditingController(text: texto(c.alturaCm));
    _observacoes = TextEditingController(text: c.observacoes ?? '');
    _notaMotorista =
        TextEditingController(text: rascunho.observacaoMotorista ?? '');
    _tipo = c.tipoCarga;
    _volumes = c.volumes;
    _naoEmpilhar = c.naoEmpilhar;
  }

  @override
  void dispose() {
    for (final c in [
      _peso,
      _comprimento,
      _largura,
      _altura,
      _observacoes,
      _notaMotorista
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "12,5" e "12.5" valem; vazio ou inválido vira null.
  double? _numero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  Carga get _carga {
    final observacoes = _observacoes.text.trim();
    return Carga(
      tipoCarga: _tipo,
      volumes: _volumes,
      pesoKg: _numero(_peso.text),
      comprimentoCm: _numero(_comprimento.text),
      larguraCm: _numero(_largura.text),
      alturaCm: _numero(_altura.text),
      naoEmpilhar: _naoEmpilhar,
      observacoes: observacoes.isEmpty ? null : observacoes,
    );
  }

  void _emitir() => context.read<NovoPedido>().definirCarga(_carga);

  void _salvar() {
    _emitir();
    context.read<NovoPedido>().definirObservacao(_notaMotorista.text.trim());
    if (widget.etapaDoFluxo) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TelaOpcoesFrete()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Só reclama de valor digitado: campo vazio não mostra erro (o asterisco já indica que
  /// é obrigatório e os veículos ficam bloqueados até preencher).
  String? _erro(TextEditingController controlador) {
    final texto = controlador.text.trim();
    if (texto.isEmpty) return null;
    final valor = _numero(texto);
    if (valor == null) return 'Número inválido';
    if (valor <= 0) return 'Informe um valor maior que zero';
    return null;
  }

  Widget _campoNumero(
    TextEditingController controlador,
    String rotulo, {
    String? sufixo,
  }) {
    return TextField(
      controller: controlador,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) {
        setState(() {}); // atualiza a mensagem de erro do proprio campo
        _emitir();
      },
      decoration: InputDecoration(
        labelText: rotulo,
        suffixText: sufixo,
        errorText: _erro(controlador),
        errorMaxLines: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.etapaDoFluxo ? 'O que vamos levar?' : 'Detalhes da carga'),
        bottom: widget.etapaDoFluxo ? const ProgressoPedido(etapa: 2) : null,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 4),
            child: IconeInfoSecao(secao: SecaoAjuda.carga),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (widget.etapaDoFluxo)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Conte o que será transportado. Com isso mostramos só os '
                  'veículos que comportam a sua carga.',
                  style: TextStyle(fontSize: 14, color: Cores.textoFraco),
                ),
              ),
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _campoNumero(_peso, 'Peso total *', sufixo: 'kg'),
                  const SizedBox(height: 16),
                  const Text('Dimensões do maior volume (em centímetros) *',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _campoNumero(_comprimento, 'Comprimento',
                              sufixo: 'cm')),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              _campoNumero(_largura, 'Largura', sufixo: 'cm')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _campoNumero(_altura, 'Altura', sufixo: 'cm')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Quantidade de volumes',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        tooltip: 'Menos um volume',
                        onPressed: _volumes > 1
                            ? () {
                                setState(() => _volumes--);
                                _emitir();
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_volumes',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      IconButton(
                        tooltip: 'Mais um volume',
                        onPressed: () {
                          setState(() => _volumes++);
                          _emitir();
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de carga *'),
                    items: [
                      for (final t in Carga.tipos)
                        DropdownMenuItem(
                            value: t, child: Text(rotuloTipoCarga(t))),
                    ],
                    onChanged: (t) {
                      if (t == null) return;
                      setState(() => _tipo = t);
                      _emitir();
                    },
                  ),
                  CheckboxListTile(
                    value: _naoEmpilhar,
                    onChanged: (v) {
                      setState(() => _naoEmpilhar = v ?? false);
                      _emitir();
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Não empilhar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _observacoes,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _emitir(),
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                    decoration: const InputDecoration(
                      labelText: 'O que está sendo transportado',
                      hintText: 'Ex.: uma geladeira e 3 caixas',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notaMotorista,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                    decoration: const InputDecoration(
                      labelText: 'Recado para o motorista (opcional)',
                      hintText:
                          'Ex.: portaria libera das 8h às 17h, use a entrada de serviço',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Cores.superficie,
            border: Border(top: BorderSide(color: Cores.borda)),
          ),
          child: FilledButton(
            onPressed: _salvar,
            child: Text(
                widget.etapaDoFluxo ? 'Escolher veículo' : 'Salvar detalhes'),
          ),
        ),
      ),
    );
  }
}
