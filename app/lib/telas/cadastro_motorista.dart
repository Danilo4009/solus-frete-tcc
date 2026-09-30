import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/formulario.dart';
import '../estado/novo_pedido.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';

/// Cadastro de motorista parceiro em tres passos: dados pessoais,
/// habilitacao e veiculo. Resultado vai para homologacao (RF03, RF06).
class TelaCadastroMotorista extends StatefulWidget {
  const TelaCadastroMotorista({super.key});

  @override
  State<TelaCadastroMotorista> createState() => _TelaCadastroMotoristaState();
}

class _TelaCadastroMotoristaState extends State<TelaCadastroMotorista> {
  final _formPessoal = GlobalKey<FormState>();
  final _formCnh = GlobalKey<FormState>();
  final _formVeiculo = GlobalKey<FormState>();

  int _passo = 0;

  final _nome = TextEditingController();
  final _sobrenome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _cpf = TextEditingController();

  final _cnhNumero = TextEditingController();
  String _cnhCategoria = 'B';
  DateTime? _cnhValidade;
  bool _cnhAnexada = false;

  final _placa = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _ano = TextEditingController();
  CategoriaVeiculo? _categoria;
  DateTime? _crlvValidade;
  bool _crlvAnexado = false;
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
      _nome, _sobrenome, _telefone, _email, _senha, _cpf,
      _cnhNumero, _placa, _marca, _modelo, _ano,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _escolherData(String titulo) => showDatePicker(
        context: context,
        helpText: titulo,
        initialDate: DateTime.now().add(const Duration(days: 365)),
        firstDate: DateTime.now(),
        lastDate: DateTime(DateTime.now().year + 15),
      );

  void _avancar() {
    if (_passo == 0 && !_formPessoal.currentState!.validate()) return;
    if (_passo == 1) {
      if (!_formCnh.currentState!.validate()) return;
      if (_cnhValidade == null) {
        _avisar('Informe a validade da CNH');
        return;
      }
      if (!_cnhAnexada) {
        _avisar('Anexe a foto da CNH');
        return;
      }
    }
    if (_passo < 2) {
      setState(() => _passo++);
    } else {
      _finalizar();
    }
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _finalizar() async {
    if (!_formVeiculo.currentState!.validate()) return;
    if (_categoria == null) {
      _avisar('Selecione a categoria do veículo');
      return;
    }
    if (!_crlvAnexado) {
      _avisar('Anexe o documento do veículo');
      return;
    }
    if (!_aceite) {
      _avisar('Aceite os termos de parceria');
      return;
    }

    final sessao = context.read<Sessao>();
    final mensagem = await sessao.cadastrarMotorista({
      'nome': _nome.text.trim(),
      'sobrenome': _sobrenome.text.trim(),
      'telefone': _telefone.text,
      'email': _email.text.trim(),
      'senha': _senha.text,
      'cpf': _cpf.text,
      'cnhNumero': _cnhNumero.text,
      'cnhCategoria': _cnhCategoria,
      'cnhValidade': _cnhValidade?.toIso8601String().substring(0, 10),
      'veiculo': {
        'categoriaCodigo': _categoria!.codigo,
        'placa': _placa.text.toUpperCase(),
        'marca': _marca.text,
        'modelo': _modelo.text,
        'ano': int.tryParse(_ano.text),
        'documentoValidade': _crlvValidade?.toIso8601String().substring(0, 10),
      },
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
    final catalogo = context.select<NovoPedido, List<CategoriaVeiculo>>((n) => n.catalogo);

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de motorista parceiro')),
      body: Column(
        children: [
          PassosIndicador(atual: _passo, rotulos: const ['Dados', 'Habilitação', 'Veículo']),
          Expanded(
            child: IndexedStack(
              index: _passo,
              children: [
                _dadosPessoais(),
                _habilitacao(),
                _dadosVeiculo(catalogo),
              ],
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

  Widget _dadosPessoais() => Form(
        key: _formPessoal,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Quem vai dirigir'),
                  TextFormField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                    validator: (v) =>
                        (v == null || v.trim().length < 2) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sobrenome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Sobrenome *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o sobrenome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cpf,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'CPF *', hintText: '000.000.000-00'),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return d.length != 11 ? 'CPF deve ter 11 dígitos' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefone,
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
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senha,
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

  Widget _habilitacao() => Form(
        key: _formCnh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Carteira de habilitação'),
                  TextFormField(
                    controller: _cnhNumero,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Número de registro *'),
                    validator: (v) => (v == null || v.trim().length < 9)
                        ? 'Informe o número da CNH'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _cnhCategoria,
                    decoration: const InputDecoration(labelText: 'Categoria *'),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('A - moto')),
                      DropdownMenuItem(value: 'B', child: Text('B - carro e utilitário')),
                      DropdownMenuItem(value: 'AB', child: Text('AB - moto e carro')),
                      DropdownMenuItem(value: 'C', child: Text('C - carga')),
                      DropdownMenuItem(value: 'D', child: Text('D - passageiros')),
                      DropdownMenuItem(value: 'E', child: Text('E - carreta')),
                    ],
                    onChanged: (v) => setState(() => _cnhCategoria = v ?? 'B'),
                  ),
                  const SizedBox(height: 12),
                  CampoData(
                    rotulo: 'Validade da CNH *',
                    valor: _cnhValidade,
                    onTap: () async {
                      final d = await _escolherData('Validade da CNH');
                      if (d != null) setState(() => _cnhValidade = d);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Documento digitalizado'),
                  AnexoSimulado(
                    rotulo: 'Foto da CNH aberta',
                    anexado: _cnhAnexada,
                    onTap: () => setState(() => _cnhAnexada = !_cnhAnexada),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No protótipo o anexo é simulado. Na versão final, câmera e galeria com upload para armazenamento com acesso restrito.',
                    style: TextStyle(fontSize: 12, color: Cores.textoFraco),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _dadosVeiculo(List<CategoriaVeiculo> catalogo) => Form(
        key: _formVeiculo,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Categoria do veículo'),
                  if (catalogo.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in catalogo)
                          ChoiceChip(
                            label: Text(c.nome),
                            selected: _categoria?.id == c.id,
                            onSelected: (_) => setState(() => _categoria = c),
                          ),
                      ],
                    ),
                  if (_categoria != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Cores.fundo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Capacidade: ${_categoria!.pesoMaxKg} kg - '
                        'Baú ${_categoria!.dimensoes}',
                        style: const TextStyle(fontSize: 12.5, color: Cores.textoFraco),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Dados do veículo'),
                  TextFormField(
                    controller: _placa,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                        labelText: 'Placa *', hintText: 'ABC1D23'),
                    validator: (v) => (v == null || v.trim().length < 7)
                        ? 'Informe a placa completa'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _marca,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Marca'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _modelo,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Modelo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ano,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ano'),
                  ),
                  const SizedBox(height: 12),
                  CampoData(
                    rotulo: 'Validade do CRLV',
                    valor: _crlvValidade,
                    onTap: () async {
                      final d = await _escolherData('Validade do CRLV');
                      if (d != null) setState(() => _crlvValidade = d);
                    },
                  ),
                  const SizedBox(height: 12),
                  AnexoSimulado(
                    rotulo: 'Documento do veículo (CRLV)',
                    anexado: _crlvAnexado,
                    onTap: () => setState(() => _crlvAnexado = !_crlvAnexado),
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
                  'Declaro que os dados e documentos são verdadeiros e aceito os termos de parceria do Solus Frete.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
}
