import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/progresso_pedido.dart';
import '../estado/novo_pedido.dart';
import '../modelos/modelos.dart';
import 'opcoes_frete.dart';

/// Categoria, tamanho, cuidados no transporte e observacoes da carga.
/// No fluxo do pedido vem antes da escolha do veiculo ([etapaDoFluxo]),
/// e depois pode ser reaberta para editar.
class TelaDetalhesCarga extends StatefulWidget {
  const TelaDetalhesCarga({super.key, this.etapaDoFluxo = false});

  final bool etapaDoFluxo;

  @override
  State<TelaDetalhesCarga> createState() => _TelaDetalhesCargaState();
}

class _TelaDetalhesCargaState extends State<TelaDetalhesCarga> {
  late Carga _carga;
  late final TextEditingController _observacoes;
  late final TextEditingController _notaMotorista;

  /// Fragilidade e uma instrucao de manuseio, nao uma categoria:
  /// por isso 'fragil' nao aparece aqui.
  static const _categorias = [
    (
      tipo: 'moveis_eletrodomesticos',
      icone: Icons.chair_outlined,
      exemplos: 'Geladeira, sofá, cama, máquina de lavar',
    ),
    (
      tipo: 'material_construcao',
      icone: Icons.construction_outlined,
      exemplos: 'Cimento, tijolos, madeira, ferramentas',
    ),
    (
      tipo: 'alimentos',
      icone: Icons.shopping_basket_outlined,
      exemplos: 'Compras, bebidas, mercadorias de loja',
    ),
    (
      tipo: 'roupas_pessoais',
      icone: Icons.checkroom_outlined,
      exemplos: 'Malas, roupas, caixas de mudança',
    ),
    (
      tipo: 'outros',
      icone: Icons.inventory_2_outlined,
      exemplos: 'Documentos, encomendas, itens diversos',
    ),
  ];

  static const _faixas = [
    (faixa: 'ate_50', exemplo: 'Caixas e sacolas'),
    (faixa: 'ate_300', exemplo: 'Alguns móveis'),
    (faixa: 'de_300_a_750', exemplo: 'Mudança pequena'),
    (faixa: 'acima_750', exemplo: 'Mudança completa'),
  ];

  @override
  void initState() {
    super.initState();
    final rascunho = context.read<NovoPedido>();
    _carga = rascunho.carga;
    if (_carga.tipoItem == 'fragil') {
      _carga = _carga.copiarCom(tipoItem: 'outros', fragil: true);
    }
    _observacoes = TextEditingController(text: _carga.observacoes ?? '');
    _notaMotorista =
        TextEditingController(text: rascunho.observacaoMotorista ?? '');
  }

  @override
  void dispose() {
    _observacoes.dispose();
    _notaMotorista.dispose();
    super.dispose();
  }

  void _alterar(Carga nova) => setState(() => _carga = nova);

  void _salvar() {
    final rascunho = context.read<NovoPedido>();
    rascunho
        .definirCarga(_carga.copiarCom(observacoes: _observacoes.text.trim()));
    rascunho.definirObservacao(_notaMotorista.text.trim());
    if (widget.etapaDoFluxo) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TelaOpcoesFrete()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoria =
        context.select<NovoPedido, CategoriaVeiculo?>((n) => n.categoria);
    final naoCabe = categoria != null &&
        NovoPedido.motivoIncompativel(_carga, categoria) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.etapaDoFluxo ? 'O que vamos levar?' : 'Detalhes da carga'),
        bottom: widget.etapaDoFluxo ? const ProgressoPedido(etapa: 2) : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (widget.etapaDoFluxo)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Conte o que será transportado. Com isso mostramos só os '
                'veículos que comportam a sua carga.',
                style: TextStyle(fontSize: 13.5, color: Cores.textoFraco),
              ),
            ),
          const _Cabecalho(numero: 1, titulo: 'Categoria'),
          for (final c in _categorias)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CartaoCategoria(
                icone: c.icone,
                titulo: rotuloTipoItem(c.tipo),
                exemplos: c.exemplos,
                selecionado: _carga.tipoItem == c.tipo,
                onTap: () => _alterar(_carga.copiarCom(tipoItem: c.tipo)),
              ),
            ),
          const SizedBox(height: 16),
          const _Cabecalho(numero: 2, titulo: 'Tamanho'),
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantidade de volumes',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14.5)),
                          Text('Caixas, sacolas ou peças separadas',
                              style: TextStyle(
                                  fontSize: 12, color: Cores.textoFraco)),
                        ],
                      ),
                    ),
                    _Contador(
                      valor: _carga.volumes,
                      onMenos: _carga.volumes > 1
                          ? () => _alterar(
                              _carga.copiarCom(volumes: _carga.volumes - 1))
                          : null,
                      onMais: () => _alterar(
                          _carga.copiarCom(volumes: _carga.volumes + 1)),
                    ),
                  ],
                ),
                const Divider(height: 28),
                const Text('Peso total estimado',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.4,
                  children: [
                    for (final f in _faixas)
                      _OpcaoPeso(
                        rotulo: rotuloFaixaPeso(f.faixa),
                        exemplo: f.exemplo,
                        selecionado: _carga.faixaPeso == f.faixa,
                        onTap: () =>
                            _alterar(_carga.copiarCom(faixaPeso: f.faixa)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (naoCabe) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Cores.alerta.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'O ${categoria.nome} não comporta esta carga. Ao salvar, '
                'você escolhe outro veículo.',
                style: const TextStyle(fontSize: 12.5, color: Cores.alerta),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _Cabecalho(numero: 3, titulo: 'Cuidados no transporte'),
          Bloco(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _Cuidado(
                  icone: Icons.wine_bar_outlined,
                  titulo: 'Frágil',
                  descricao: 'Vidro, porcelana, eletrônicos',
                  valor: _carga.fragil,
                  onChanged: (v) => _alterar(_carga.copiarCom(fragil: v)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _Cuidado(
                  icone: Icons.layers_clear_outlined,
                  titulo: 'Não empilhar',
                  descricao: 'Nada pode ser colocado por cima',
                  valor: _carga.naoEmpilhar,
                  onChanged: (v) => _alterar(_carga.copiarCom(naoEmpilhar: v)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _Cuidado(
                  icone: Icons.ac_unit,
                  titulo: 'Precisa de refrigeração',
                  descricao: 'Congelados e perecíveis',
                  valor: _carga.refrigerado,
                  onChanged: (v) => _alterar(_carga.copiarCom(refrigerado: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _Cabecalho(numero: 4, titulo: 'Descrição e observações'),
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _observacoes,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'O que está sendo transportado',
                    hintText: 'Ex.: uma geladeira e 3 caixas',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notaMotorista,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
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

/// Titulo numerado de cada bloco da tela.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.numero, required this.titulo});

  final int numero;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Cores.primaria,
            child: Text('$numero',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Cores.primariaEscura)),
        ],
      ),
    );
  }
}

class _CartaoCategoria extends StatelessWidget {
  const _CartaoCategoria({
    required this.icone,
    required this.titulo,
    required this.exemplos,
    required this.selecionado,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String exemplos;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? Cores.primaria.withOpacity(0.05) : Cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selecionado ? Cores.primaria : Cores.borda,
          width: selecionado ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selecionado ? Cores.primaria : Cores.fundo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone,
                    color: selecionado ? Colors.white : Cores.primaria),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(exemplos,
                        style: const TextStyle(
                            fontSize: 12, color: Cores.textoFraco)),
                  ],
                ),
              ),
              Icon(
                selecionado ? Icons.check_circle : Icons.circle_outlined,
                color: selecionado ? Cores.primaria : Cores.borda,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.valor, this.onMenos, required this.onMais});

  final int valor;
  final VoidCallback? onMenos;
  final VoidCallback onMais;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Cores.borda),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onMenos,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 28,
            child: Text('$valor',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onMais,
            icon: const Icon(Icons.add, color: Cores.primaria),
          ),
        ],
      ),
    );
  }
}

class _OpcaoPeso extends StatelessWidget {
  const _OpcaoPeso({
    required this.rotulo,
    required this.exemplo,
    required this.selecionado,
    required this.onTap,
  });

  final String rotulo;
  final String exemplo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? Cores.primaria : Cores.fundo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          selecionado ? Colors.white : Cores.primariaEscura)),
              Text(exemplo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: selecionado
                          ? const Color(0xFFBFD3E8)
                          : Cores.textoFraco)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cuidado extends StatelessWidget {
  const _Cuidado({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.onChanged,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: valor,
      onChanged: onChanged,
      secondary: Icon(icone, color: Cores.primaria),
      title: Text(titulo,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      subtitle: Text(descricao, style: const TextStyle(fontSize: 12)),
    );
  }
}
