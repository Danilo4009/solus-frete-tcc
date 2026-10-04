import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema.dart';
import '../estado/sessao.dart';
import 'cadastro_cliente.dart';
import 'cadastro_motorista.dart';
import 'cadastro_transportadora.dart';

/// Cores do layout de login no Figma.
class _Figma {
  static const marinho = Color(0xFF0F2A55);
  static const laranja = Color(0xFFEA8D16); // cor do caminhao da marca d'agua
  static const campo = Color(0xFFF2F2F2);
}

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
      _avisar(sessao.erro ?? 'Não foi possível entrar');
    }
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _abrir(Widget tela) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
  }

  /// O Figma tem um unico "Cadastre-se"; aqui o usuario escolhe o tipo de conta.
  void _escolherCadastro() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (contexto) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Criar conta',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _Figma.marinho)),
              const SizedBox(height: 8),
              for (final (icone, titulo, descricao, tela) in [
                (
                  Icons.person_outline_rounded,
                  'Sou cliente',
                  'Quero enviar cargas e fazer fretes',
                  const TelaCadastroCliente() as Widget,
                ),
                (
                  Icons.two_wheeler_rounded,
                  'Sou motorista',
                  'Cadastre CNH e veículo',
                  const TelaCadastroMotorista(),
                ),
                (
                  Icons.apartment_rounded,
                  'Sou transportadora',
                  'Cadastre CNPJ e frota',
                  const TelaCadastroTransportadora(),
                ),
              ])
                ListTile(
                  leading: Icon(icone, color: _Figma.laranja),
                  title: Text(titulo,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(descricao),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(contexto).pop();
                    _abrir(tela);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carregando = context.select<Sessao, bool>((s) => s.carregando);
    final topo = MediaQuery.of(context).padding.top;

    final base = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // O azul aparece atras dos cantos arredondados do cartao.
      backgroundColor: _Figma.marinho,
      // A tela ocupa exatamente a altura do aparelho: o cabecalho e os
      // espacos entre os elementos encolhem em telas menores. So rola se
      // nem o minimo couber (ex.: teclado aberto).
      body: LayoutBuilder(builder: (context, limites) {
        final minimoCartao = _alturaMinimaCartao + base;
        final altura = max(limites.maxHeight, topo + 110 + minimoCartao);
        final alturaCabecalho = min(altura * 0.36, altura - minimoCartao)
            .clamp(topo + 110, topo + 246);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: altura,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cabecalho(topo: topo, altura: alturaCabecalho.toDouble()),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(46)),
                    ),
                    padding: EdgeInsets.fromLTRB(56, 18, 56, 8 + base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        const Text('Entrar',
                            style: TextStyle(
                                fontSize: 38,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                color: _Figma.marinho)),
                        const SizedBox(height: 8),
                        const Spacer(flex: 3),
                        TextField(
                          controller: _telefone,
                          keyboardType: TextInputType.phone,
                          decoration:
                              _campo('Celular').copyWith(prefixText: '+55 '),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _senha,
                          obscureText: !_mostrarSenha,
                          decoration: _campo('Senha').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarSenha
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Cores.textoFraco,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _mostrarSenha = !_mostrarSenha),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: _Figma.marinho,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 6),
                              minimumSize: const Size(0, 32),
                            ),
                            onPressed: () => _avisar(
                                'A recuperação de senha chega na próxima versão.'),
                            child: const Text('Esqueci minha senha',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Spacer(flex: 1),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _Figma.marinho,
                            minimumSize: const Size.fromHeight(47),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          onPressed: carregando ? null : _entrar,
                          child: carregando
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4, color: Colors.white),
                                )
                              : const Text('Continuar'),
                        ),
                        const SizedBox(height: 8),
                        const Spacer(flex: 2),
                        const _Separador(),
                        const SizedBox(height: 8),
                        const Spacer(flex: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _BotaoSocial(
                              rotulo: 'Google',
                              onTap: () => _avisar(
                                  'Login com Google fica fora do protótipo.'),
                              child: const _LogoGoogle(tamanho: 24),
                            ),
                            const SizedBox(width: 22),
                            _BotaoSocial(
                              rotulo: 'Facebook',
                              onTap: () => _avisar(
                                  'Login com Facebook fica fora do protótipo.'),
                              child: const Icon(Icons.facebook,
                                  size: 28, color: Color(0xFF1877F2)),
                            ),
                            const SizedBox(width: 22),
                            _BotaoSocial(
                              rotulo: 'Apple',
                              onTap: () => _avisar(
                                  'Login com Apple fica fora do protótipo.'),
                              child: const Icon(Icons.apple,
                                  size: 28, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Spacer(flex: 3),
                        Center(
                          child: GestureDetector(
                            onTap: _escolherCadastro,
                            child: const Text.rich(
                              TextSpan(
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _Figma.marinho),
                                children: [
                                  TextSpan(text: 'Não tem conta? '),
                                  TextSpan(
                                    text: 'Cadastre-se',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Altura do cartao branco com todos os espacos flexiveis zerados
  /// (conferida no teste test/login_cabe_na_tela_test.dart).
  static const _alturaMinimaCartao = 424.0;

  /// Campo em pilula cinza, sem borda, como no Figma.
  InputDecoration _campo(String dica) {
    final pilula = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: Color(0xFFB0B5BC), fontSize: 14),
      filled: true,
      fillColor: _Figma.campo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      border: pilula,
      enabledBorder: pilula,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: _Figma.marinho, width: 1.4),
      ),
    );
  }
}

/// Topo azul: marca d'agua (pino com caminhao) e a saudacao.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.topo, required this.altura});

  final double topo;

  /// Altura total, incluindo a area da barra de status ([topo]).
  final double altura;

  @override
  Widget build(BuildContext context) {
    final util = altura - topo;
    final largura = MediaQuery.of(context).size.width;
    // No Figma o pino ocupa ~52% da largura e o cartao corta a ponta dele.
    // Em telas baixas ele encolhe para nao ser cortado tambem no topo.
    const corte = 16.0;
    final alturaImagem =
        min(largura * 0.52 / _MarcaDagua.proporcao, util - 12 + corte);
    return SizedBox(
      height: altura,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Centralizado; a ponta do pino passa [corte] px para baixo do
          // cabecalho e fica escondida atras do cartao branco.
          Positioned(
            top: altura - alturaImagem + corte,
            left: (largura - alturaImagem * _MarcaDagua.proporcao) / 2,
            child: _MarcaDagua(altura: alturaImagem),
          ),
          // A saudacao fica sempre logo acima do cartao, como no Figma.
          Positioned(
            left: 32,
            bottom: min(40, util - 96).clamp(8, 40).toDouble(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        height: 1.1,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(text: 'Bem-vindo a Solus-'),
                      TextSpan(
                          text: 'Frete',
                          style: TextStyle(color: _Figma.laranja)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Imagem do Figma (pino com caminhao) ao fundo, com 10% de opacidade.
class _MarcaDagua extends StatelessWidget {
  const _MarcaDagua({required this.altura});

  final double altura;

  /// Proporcao do arquivo original (221 x 249 px).
  static const proporcao = 221 / 249;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.10,
      child: Image.asset(
        'assets/marca_dagua_login.png',
        height: altura,
        width: altura * proporcao,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Linha fina com "OU" no meio.
class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: _Figma.marinho, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('OU',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _Figma.marinho)),
        ),
        Expanded(child: Divider(color: _Figma.marinho, thickness: 1)),
      ],
    );
  }
}

class _BotaoSocial extends StatelessWidget {
  const _BotaoSocial({
    required this.rotulo,
    required this.onTap,
    required this.child,
  });

  final String rotulo;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Entrar com $rotulo',
      child: Material(
        color: _Figma.campo,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 49, height: 49, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// "G" colorido do Google, desenhado em canvas (o Material nao tem esse icone).
class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle({required this.tamanho});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(tamanho),
      painter: _PintorGoogle(),
    );
  }
}

class _PintorGoogle extends CustomPainter {
  static const _azul = Color(0xFF4285F4);
  static const _verde = Color(0xFF34A853);
  static const _amarelo = Color(0xFFFBBC05);
  static const _vermelho = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final traco = size.width * 0.2;
    final centro = size.center(Offset.zero);
    final raio = size.width / 2 - traco / 2;
    final circulo = Rect.fromCircle(center: centro, radius: raio);

    Paint cor(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = traco;

    double graus(double g) => g * pi / 180;

    // Angulos a partir das 3h, no sentido horario; a abertura fica em cima a direita.
    canvas.drawArc(circulo, graus(0), graus(45), false, cor(_azul));
    canvas.drawArc(circulo, graus(45), graus(90), false, cor(_verde));
    canvas.drawArc(circulo, graus(135), graus(90), false, cor(_amarelo));
    canvas.drawArc(circulo, graus(225), graus(95), false, cor(_vermelho));

    // barra horizontal azul do "G"
    canvas.drawRect(
      Rect.fromLTRB(centro.dx, centro.dy - traco / 2,
          centro.dx + raio + traco / 2, centro.dy + traco / 2),
      Paint()..color = _azul,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
