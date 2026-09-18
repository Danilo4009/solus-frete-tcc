import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/novo_pedido.dart';
import '../modelos/modelos.dart';

/// Tipo de item, volumes, faixa de peso e instrucoes de manuseio.
class TelaDetalhesCarga extends StatefulWidget {
  const TelaDetalhesCarga({super.key});

  @override
  State<TelaDetalhesCarga> createState() => _TelaDetalhesCargaState();
}

class _TelaDetalhesCargaState extends State<TelaDetalhesCarga> {
  late Carga _carga;
  late final TextEditingController _observacoes;
  late final TextEditingController _notaMotorista;

  static const _tipos = [
    'alimentos',
    'material_construcao',
    'roupas_pessoais',
    'moveis_eletrodomesticos',
    'fragil',
    'outros',
  ];

  static const _faixas = ['ate_50', 'ate_300', 'de_300_a_750', 'acima_750'];

  @override
  void initState() {
    super.initState();
    final rascunho = context.read<NovoPedido>();
    _carga = rascunho.carga;
    _observacoes = TextEditingController(text: _carga.observacoes ?? '');
    _notaMotorista = TextEditingController(text: rascunho.observacaoMotorista ?? '');
  }

  @override
  void dispose() {
    _observacoes.dispose();
    _notaMotorista.dispose();
    super.dispose();
  }

  void _salvar() {
    final rascunho = context.read<NovoPedido>();
    rascunho.definirCarga(_carga.copiarCom(observacoes: _observacoes.text.trim()));
    rascunho.definirObservacao(_notaMotorista.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoria = context.select<NovoPedido, CategoriaVeiculo?>((n) => n.categoria);
    final excede = categoria != null &&
        (const {'ate_50': 50, 'ate_300': 300, 'de_300_a_750': 750, 'acima_750': 3500}[
                _carga.faixaPeso] ??
            0) >
            categoria.pesoMaxKg;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da carga')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Tipo de item'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _tipos)
                      ChoiceChip(
                        label: Text(rotuloTipoItem(t)),
                        selected: _carga.tipoItem == t,
                        onSelected: (_) =>
                            setState(() => _carga = _carga.copiarCom(tipoItem: t)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: Row(
              children: [
                const Expanded(
                  child: Text('Numero de volumes',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: () => setState(() => _carga = _carga.copiarCom(
                      volumes: _carga.volumes > 1 ? _carga.volumes - 1 : 1)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${_carga.volumes}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () => setState(
                      () => _carga = _carga.copiarCom(volumes: _carga.volumes + 1)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Peso total estimado'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in _faixas)
                      ChoiceChip(
                        label: Text(rotuloFaixaPeso(f)),
                        selected: _carga.faixaPeso == f,
                        onSelected: (_) =>
                            setState(() => _carga = _carga.copiarCom(faixaPeso: f)),
                      ),
                  ],
                ),
                if (excede) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Cores.alerta.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Este peso excede a capacidade do ${categoria!.nome} '
                      '(${categoria.pesoMaxKg} kg). Volte e escolha um veiculo maior.',
                      style: const TextStyle(fontSize: 12.5, color: Cores.alerta),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Instrucoes de manuseio'),
                CheckboxListTile(
                  value: _carga.fragil,
                  onChanged: (v) =>
                      setState(() => _carga = _carga.copiarCom(fragil: v ?? false)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Fragil - manusear com cuidado'),
                ),
                CheckboxListTile(
                  value: _carga.naoEmpilhar,
                  onChanged: (v) =>
                      setState(() => _carga = _carga.copiarCom(naoEmpilhar: v ?? false)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Nao empilhar'),
                ),
                CheckboxListTile(
                  value: _carga.refrigerado,
                  onChanged: (v) =>
                      setState(() => _carga = _carga.copiarCom(refrigerado: v ?? false)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Precisa de refrigeracao'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TituloSecao('Descricao e notas'),
                TextField(
                  controller: _observacoes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'O que esta sendo transportado',
                    hintText: 'Ex.: uma mesa de vidro e 3 caixas',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notaMotorista,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Informacoes que ajudam o motorista',
                    hintText: 'Ex.: portaria libera das 8h as 17h, use a entrada de servico',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _salvar, child: const Text('Salvar detalhes')),
        ],
      ),
    );
  }
}
