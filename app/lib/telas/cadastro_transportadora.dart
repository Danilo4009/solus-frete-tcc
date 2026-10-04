import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/formulario.dart';
import '../estado/novo_pedido.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';

/// Cadastro de transportadora: empresa, responsavel legal e frota inicial
/// (RF04, RF05, RF06).
class TelaCadastroTransportadora extends StatefulWidget {
  const TelaCadastroTransportadora({super.key});

  @override
  State<TelaCadastroTransportadora> createState() =>
      _TelaCadastroTransportadoraState();
}

class _VeiculoFrota {
  _VeiculoFrota({required this.categoria, required this.placa, this.quantidade = 1});

  CategoriaVeiculo categoria;
  String placa;
  int quantidade;
}

class _TelaCadastroTransportadoraState extends State<TelaCadastroTransportadora> {
  final _formEmpresa = GlobalKey<FormState>();
  final _formResponsavel = GlobalKey<FormState>();

  int _passo = 0;

  final _cnpj = TextEditingController();
  final _razao = TextEditingController();
  final _fantasia = TextEditingController();
  final _antt = TextEditingController();
  final _cidade = TextEditingController(text: 'São Paulo');
  final _uf = TextEditingController(text: 'SP');
  final _telEmpresa = TextEditingController();
  final _emailEmpresa = TextEditingController();

  final _respNome = TextEditingController();
  final _respSobrenome = TextEditingController();
  final _respTelefone = TextEditingController();
  final _respEmail = TextEditingController();
  final _respSenha = TextEditingController();

  final List<_VeiculoFrota> _frota = [];
  bool _contratoSocial = false;
  bool _comprovanteAntt = false;
  bool _aceite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NovoPedido>().carregarCatalogo();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _cnpj, _razao, _fantasia, _antt, _cidade, _uf, _telEmpresa, _emailEmpresa,
      _respNome, _respSobrenome, _respTelefone, _respEmail, _respSenha,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _avancar() {
    if (_passo == 0) {
      if (!_formEmpresa.currentState!.validate()) return;
      if (!_contratoSocial) {
        _avisar('Anexe o contrato social');
        return;
      }
    }
    if (_passo == 1 && !_formResponsavel.currentState!.validate()) return;
    if (_passo < 2) {
      setState(() => _passo++);
    } else {
      _finalizar();
    }
  }

  Future<void> _adicionarVeiculo() async {
    final catalogo = context.read<NovoPedido>().catalogo;
    if (catalogo.isEmpty) {
      _avisar('Catálogo de veículos ainda carregando');
      return;
    }
    CategoriaVeiculo selecionada = catalogo.first;
    final placa = TextEditingController();
    int quantidade = 1;

    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (contexto) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(contexto).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (contexto, refazer) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TituloSecao('Adicionar veículo à frota'),
              DropdownButtonFormField<CategoriaVeiculo>(
                value: selecionada,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  for (final c in catalogo)
                    DropdownMenuItem(
                      value: c,
                      child: Text('${c.nome} - ${c.pesoMaxKg} kg'),
                    ),
                ],
                onChanged: (v) => refazer(() => selecionada = v ?? catalogo.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: placa,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Placa', hintText: 'ABC1D23'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Quantidade'),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        refazer(() => quantidade = quantidade > 1 ? quantidade - 1 : 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$quantidade',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    onPressed: () => refazer(() => quantidade++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(contexto).pop(true),
                child: const Text('Adicionar'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (confirmou == true) {
      setState(() => _frota.add(_VeiculoFrota(
            categoria: selecionada,
            placa: placa.text.toUpperCase(),
            quantidade: quantidade,
          )));
    }
    placa.dispose();
  }

  Future<void> _finalizar() async {
    if (_frota.isEmpty) {
      _avisar('Cadastre ao menos um veículo da frota');
      return;
    }
    if (!_aceite) {
      _avisar('Aceite os termos de parceria');
      return;
    }

    final sessao = context.read<Sessao>();
    final mensagem = await sessao.cadastrarTransportadora({
      'cnpj': _cnpj.text,
      'razaoSocial': _razao.text.trim(),
      'nomeFantasia': _fantasia.text.trim(),
      'registroAntt': _antt.text.trim(),
      'cidade': _cidade.text.trim(),
      'uf': _uf.text.trim().toUpperCase(),
      'telefoneEmpresa': _telEmpresa.text,
      'emailEmpresa': _emailEmpresa.text.trim(),
      'responsavel': {
        'nome': _respNome.text.trim(),
        'sobrenome': _respSobrenome.text.trim(),
        'telefone': _respTelefone.text,
        'email': _respEmail.text.trim(),
        'senha': _respSenha.text,
      },
      'frota': [
        for (final v in _frota)
          {
            'categoriaCodigo': v.categoria.codigo,
            'placa': v.placa,
            'quantidade': v.quantidade,
          },
      ],
    });

    if (!mounted) return;
    if (mensagem == null) {
      _avisar(sessao.erro ?? 'Não foi possível enviar o cadastro');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.verified_outlined, color: Cores.sucesso, size: 40),
        title: const Text('Cadastro enviado'),
        content: Text(mensagem),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final carregando = context.select<Sessao, bool>((s) => s.carregando);

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de transportadora')),
      body: Column(
        children: [
          PassosIndicador(
            atual: _passo,
            rotulos: const ['Empresa', 'Responsável', 'Frota'],
          ),
          Expanded(
            child: IndexedStack(
              index: _passo,
              children: [_empresa(), _responsavel(), _frotaInicial()],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_passo > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _passo--),
                        child: const Text('Voltar'),
                      ),
                    ),
                  if (_passo > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: carregando ? null : _avancar,
                      child: Text(_passo == 2
                          ? (carregando ? 'Enviando...' : 'Enviar para análise')
                          : 'Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empresa() => Form(
        key: _formEmpresa,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Dados da empresa'),
                  TextFormField(
                    controller: _cnpj,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'CNPJ *', hintText: '00.000.000/0000-00'),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return d.length != 14 ? 'CNPJ deve ter 14 dígitos' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _razao,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Razão social *'),
                    validator: (v) =>
                        (v == null || v.trim().length < 3) ? 'Informe a razão social' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fantasia,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome fantasia'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _antt,
                    decoration: const InputDecoration(
                        labelText: 'Registro ANTT (RNTRC) *',
                        hintText: 'RNTRC 000000'),
                    validator: (v) => (v == null || v.trim().length < 5)
                        ? 'Informe o registro ANTT'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _cidade,
                          decoration: const InputDecoration(labelText: 'Cidade *'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Informe a cidade' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _uf,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 2,
                          decoration: const InputDecoration(
                              labelText: 'UF *', counterText: ''),
                          validator: (v) =>
                              (v == null || v.trim().length != 2) ? 'UF' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telEmpresa,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefone comercial'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailEmpresa,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail da operação'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Documentos'),
                  AnexoSimulado(
                    rotulo: 'Contrato social',
                    anexado: _contratoSocial,
                    onTap: () => setState(() => _contratoSocial = !_contratoSocial),
                  ),
                  const SizedBox(height: 10),
                  AnexoSimulado(
                    rotulo: 'Comprovante de registro ANTT',
                    anexado: _comprovanteAntt,
                    onTap: () => setState(() => _comprovanteAntt = !_comprovanteAntt),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _responsavel() => Form(
        key: _formResponsavel,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Responsável pela conta'),
                  const Text(
                    'Esta pessoa vai aceitar cargas e designar motoristas da frota.',
                    style: TextStyle(fontSize: 12.5, color: Cores.textoFraco),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _respNome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                    validator: (v) =>
                        (v == null || v.trim().length < 2) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _respSobrenome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Sobrenome'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _respTelefone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Celular *', prefixText: '+55 '),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return d.length < 10 ? 'Informe DDD e número' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _respEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail *'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Informe um e-mail válido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _respSenha,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha *'),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _frotaInicial() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TituloSecao(
                  'Frota (${_frota.length})',
                  acao: TextButton.icon(
                    onPressed: _adicionarVeiculo,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                  ),
                ),
                if (_frota.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Cadastre os veículos que a transportadora vai disponibilizar. '
                      'Você poderá vincular motoristas a cada veículo depois da homologação.',
                      style: TextStyle(color: Cores.textoFraco, fontSize: 13),
                    ),
                  )
                else
                  for (var i = 0; i < _frota.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.local_shipping_outlined,
                          color: Cores.primaria),
                      title: Text(_frota[i].categoria.nome),
                      subtitle: Text(
                        '${_frota[i].placa.isEmpty ? 'Placa a definir' : _frota[i].placa}'
                        ' - ${_frota[i].quantidade} veículo(s)'
                        ' - até ${_frota[i].categoria.pesoMaxKg} kg',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Cores.alerta),
                        onPressed: () => setState(() => _frota.removeAt(i)),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Como funciona'),
                const Text(
                  'Cargas compatíveis com sua frota são ofertadas à empresa. '
                  'Você aceita em nome da transportadora e depois designa qual motorista '
                  'vai executar. O repasse é consolidado no CNPJ da empresa.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: Cores.textoFraco),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: CheckboxListTile(
              value: _aceite,
              onChanged: (v) => setState(() => _aceite = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Declaro que as informações e documentos são verdadeiros e aceito os termos de parceria do Solus Frete.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      );
}
