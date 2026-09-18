import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema.dart';
import '../estado/sessao.dart';
import 'cadastro_cliente.dart';
import 'cadastro_motorista.dart';
import 'cadastro_transportadora.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _telefone = TextEditingController(text: '11940135904');
  final _senha = TextEditingController(text: 'solus123');
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _telefone.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final sessao = context.read<Sessao>();
    final ok = await sessao.entrar(_telefone.text, _senha.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sessao.erro ?? 'Nao foi possivel entrar')),
      );
    }
  }

  void _abrir(Widget tela) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final carregando = context.select<Sessao, bool>((s) => s.carregando);

    return Scaffold(
      backgroundColor: Cores.primaria,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icone_app.png',
                      width: 54,
                      height: 54,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Solus Frete',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Fretes com motoristas parceiros e transportadoras,\nagora ou agendado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFBFD3E8), height: 1.4),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Entrar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _telefone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Celular',
                        prefixText: '+55 ',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _senha,
                      obscureText: !_mostrarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_mostrarSenha
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _mostrarSenha = !_mostrarSenha),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: carregando ? null : _entrar,
                      child: carregando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _abrir(const TelaCadastroCliente()),
                      child: const Text('Criar conta de cliente'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Quer trabalhar com a gente?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFBFD3E8))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CartaoPerfil(
                      icone: Icons.two_wheeler_rounded,
                      titulo: 'Sou motorista',
                      descricao: 'Cadastre CNH e veiculo',
                      onTap: () => _abrir(const TelaCadastroMotorista()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CartaoPerfil(
                      icone: Icons.apartment_rounded,
                      titulo: 'Sou transportadora',
                      descricao: 'Cadastre CNPJ e frota',
                      onTap: () => _abrir(const TelaCadastroTransportadora()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Prototipo academico - TCC Sistemas de Informacao',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF7FA3C7), fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoPerfil extends StatelessWidget {
  const _CartaoPerfil({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Cores.primariaEscura,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2B5C8C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: Cores.destaque, size: 26),
            const SizedBox(height: 10),
            Text(titulo,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 3),
            Text(descricao,
                style: const TextStyle(color: Color(0xFFBFD3E8), fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
