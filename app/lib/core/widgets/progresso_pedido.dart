import 'package:flutter/material.dart';

import '../tema.dart';

/// Barra de etapas do pedido. Mostra onde o cliente esta e quanto falta,
/// e anima o preenchimento a partir da etapa anterior ao abrir cada tela.
/// Pode ser usada como `AppBar.bottom` ou solta no corpo da tela.
class ProgressoPedido extends StatelessWidget implements PreferredSizeWidget {
  const ProgressoPedido({super.key, required this.etapa});

  /// Etapa atual, comecando em 1.
  final int etapa;

  static const etapas = ['Local', 'Carga', 'Veículo', 'Confirmar'];

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final total = etapas.length;
    final fim = (etapa - 1) / (total - 1);
    final inicio = etapa <= 1 ? 0.0 : (etapa - 2) / (total - 1);

    return Container(
      height: preferredSize.height,
      color: Cores.superficie,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: inicio, end: fim),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, preenchido, _) => LayoutBuilder(
          builder: (context, limites) {
            final largura = limites.maxWidth;
            final meiaColuna = largura / total / 2;
            final trilho = largura - meiaColuna * 2;
            return Stack(
              children: [
                // trilho cinza e parte preenchida, ligando os centros dos circulos
                Positioned(
                  top: 12,
                  left: meiaColuna,
                  width: trilho,
                  child: Container(height: 3, color: Cores.borda),
                ),
                Positioned(
                  top: 12,
                  left: meiaColuna,
                  width: trilho * preenchido,
                  child: Container(height: 3, color: Cores.primaria),
                ),
                Row(
                  children: [
                    for (var i = 0; i < total; i++)
                      Expanded(
                        child: _Marco(
                          numero: i + 1,
                          rotulo: etapas[i],
                          // o circulo acende quando a linha chega nele
                          alcancado: preenchido * (total - 1) >= i - 0.01,
                          concluido: i + 1 < etapa,
                          atual: i + 1 == etapa,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Marco extends StatelessWidget {
  const _Marco({
    required this.numero,
    required this.rotulo,
    required this.alcancado,
    required this.concluido,
    required this.atual,
  });

  final int numero;
  final String rotulo;
  final bool alcancado;
  final bool concluido;
  final bool atual;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: alcancado ? Cores.primaria : Cores.superficie,
            border: Border.all(
              color: alcancado ? Cores.primaria : Cores.borda,
              width: 2,
            ),
            boxShadow: atual && alcancado
                ? [
                    BoxShadow(
                      color: Cores.primaria.withOpacity(0.25),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: concluido
              ? const Icon(Icons.check, size: 15, color: Colors.white)
              : Text('$numero',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: alcancado ? Colors.white : Cores.textoFraco,
                  )),
        ),
        const SizedBox(height: 5),
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: atual ? FontWeight.w700 : FontWeight.w500,
            color: atual
                ? Cores.primariaEscura
                : (concluido ? Cores.primaria : Cores.textoFraco),
          ),
        ),
      ],
    );
  }
}
