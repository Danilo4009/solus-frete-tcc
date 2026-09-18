import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/widgets/comuns.dart';
import '../estado/sessao.dart';

class TelaCadastroCliente extends StatefulWidget {
  const TelaCadastroCliente({super.key});

  @override
  State<TelaCadastroCliente> createState() => _TelaCadastroClienteState();
}

class _TelaCadastroClienteState extends State<TelaCadastroCliente> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _sobrenome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String? _setor;
  bool _aceite = false;

  static const _setores = [
    'Pessoa fisica',
    'Varejo',
    'Alimentacao',
    'Construcao',
    'Industria',
    'E-commerce',
    'Outro',
  ];

  @override
  void dispose() {
    for (final c in [_nome, _sobrenome, _telefone, _email, _senha]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    if (!_aceite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para continuar')),
      );
      return;
    }
    final sessao = context.read<Sessao>();
    final ok = await sessao.cadastrarCliente(
      nome: _nome.text.trim(),
      sobrenome: _sobrenome.text.trim(),
      telefone: _telefone.text,
      email: _email.text.trim(),
      senha: _senha.text,
      setor: _setor,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sessao.erro ?? 'Nao foi possivel cadastrar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final carregando = context.select<Sessao, bool>((s) => s.carregando);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Bloco(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSecao('Seus dados'),
                  TextFormField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                    validator: (v) =>
                        (v == null || v.trim().length < 2) ? 'Informe seu nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sobrenome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Sobrenome'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Celular *', prefixText: '+55 '),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return d.length < 10 ? 'Informe DDD e numero' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      return v.contains('@') ? null : 'E-mail invalido';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha *'),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Minimo de 6 caracteres' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _setor,
                    decoration: const InputDecoration(labelText: 'Setor de atuacao'),
                    items: [
                      for (final s in _setores)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => setState(() => _setor = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Bloco(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _aceite,
                    onChanged: (v) => setState(() => _aceite = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Li e aceito os termos de uso, a politica de privacidade e a politica de itens proibidos.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: carregando ? null : _enviar,
              child: Text(carregando ? 'Enviando...' : 'Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
