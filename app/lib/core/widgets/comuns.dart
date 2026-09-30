import 'dart:math';

import 'package:flutter/material.dart';

import '../formato.dart';
import '../tema.dart';

/// Cartao branco com borda, usado como bloco padrao das telas.
class Bloco extends StatelessWidget {
  const Bloco({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final conteudo = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
    return Container(
      decoration: BoxDecoration(
        color: Cores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? conteudo
          : InkWell(onTap: onTap, child: conteudo),
    );
  }
}

class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.acao});

  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Cores.primariaEscura,
              ),
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

class EtiquetaSituacao extends StatelessWidget {
  const EtiquetaSituacao(this.situacao, {super.key});

  final String situacao;

  Color get _cor {
    switch (situacao) {
      case 'concluido':
      case 'entregue':
        return Cores.sucesso;
      case 'cancelado':
        return Cores.alerta;
      case 'aguardando_alocacao':
      case 'cotado':
        return Cores.destaque;
      default:
        return Cores.primaria;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rotuloSituacao(situacao),
        style: TextStyle(color: _cor, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class Vazio extends StatelessWidget {
  const Vazio({super.key, required this.icone, required this.titulo, this.descricao, this.acao});

  final IconData icone;
  final String titulo;
  final String? descricao;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 56, color: Cores.borda),
            const SizedBox(height: 16),
            Text(titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (descricao != null) ...[
              const SizedBox(height: 8),
              Text(descricao!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Cores.textoFraco)),
            ],
            if (acao != null) ...[const SizedBox(height: 20), acao!],
          ],
        ),
      ),
    );
  }
}

/// Mapa esquematico desenhado em canvas: roda sem chave de API.
/// Quando o Google Maps for configurado, troque este widget pelo GoogleMap.
class MapaSimulado extends StatelessWidget {
  const MapaSimulado({
    super.key,
    this.altura = 220,
    this.pontos = const [],
    this.progresso,
  });

  final double altura;

  /// Pares (latitude, longitude) do roteiro.
  final List<({double lat, double lng})> pontos;

  /// 0..1 indicando o avanco do veiculo na rota.
  final double? progresso;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: altura,
        width: double.infinity,
        color: const Color(0xFFE8EDF2),
        child: CustomPaint(
          painter: _PintorMapa(pontos: pontos, progresso: progresso),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('mapa esquemático',
                    style: TextStyle(fontSize: 10, color: Cores.textoFraco)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorMapa extends CustomPainter {
  _PintorMapa({required this.pontos, this.progresso});

  final List<({double lat, double lng})> pontos;
  final double? progresso;

  @override
  void paint(Canvas canvas, Size size) {
    final ruas = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    // malha viaria decorativa
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), ruas);
    }
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), ruas);
    }

    if (pontos.length < 2) return;

    // normaliza as coordenadas para o retangulo disponivel
    final lats = pontos.map((p) => p.lat).toList();
    final lngs = pontos.map((p) => p.lng).toList();
    final minLat = lats.reduce(min), maxLat = lats.reduce(max);
    final minLng = lngs.reduce(min), maxLng = lngs.reduce(max);
    final margem = 34.0;

    Offset projetar(({double lat, double lng}) p) {
      final dx = (maxLng - minLng).abs() < 1e-9
          ? 0.5
          : (p.lng - minLng) / (maxLng - minLng);
      final dy = (maxLat - minLat).abs() < 1e-9
          ? 0.5
          : 1 - (p.lat - minLat) / (maxLat - minLat);
      return Offset(
        margem + dx * (size.width - margem * 2),
        margem + dy * (size.height - margem * 2),
      );
    }

    final posicoes = pontos.map(projetar).toList();

    final rota = Paint()
      ..color = Cores.primaria
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final caminho = Path()..moveTo(posicoes.first.dx, posicoes.first.dy);
    for (var i = 1; i < posicoes.length; i++) {
      final anterior = posicoes[i - 1];
      final atual = posicoes[i];
      final meio = Offset(atual.dx, anterior.dy); // traco em L, estilo malha urbana
      caminho.lineTo(meio.dx, meio.dy);
      caminho.lineTo(atual.dx, atual.dy);
    }
    canvas.drawPath(caminho, rota);

    // marcadores
    for (var i = 0; i < posicoes.length; i++) {
      final ehColeta = i == 0;
      canvas.drawCircle(posicoes[i], 9,
          Paint()..color = ehColeta ? Cores.primaria : Cores.destaque);
      canvas.drawCircle(posicoes[i], 4, Paint()..color = Colors.white);
    }

    // veiculo na rota
    if (progresso != null) {
      final metrica = caminho.computeMetrics().first;
      final ponto = metrica.getTangentForOffset(metrica.length * progresso!.clamp(0, 1));
      if (ponto != null) {
        canvas.drawCircle(ponto.position, 12, Paint()..color = Colors.white);
        canvas.drawCircle(ponto.position, 9, Paint()..color = Cores.sucesso);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PintorMapa anterior) =>
      anterior.pontos != pontos || anterior.progresso != progresso;
}

/// Linha do tempo vertical das etapas do pedido.
class LinhaDoTempo extends StatelessWidget {
  const LinhaDoTempo({super.key, required this.itens});

  final List<({String titulo, String? detalhe, DateTime? quando, bool concluido})> itens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < itens.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: itens[i].concluido ? Cores.sucesso : Cores.borda,
                      border: Border.all(
                        color: itens[i].concluido ? Cores.sucesso : Cores.textoFraco,
                        width: 2,
                      ),
                    ),
                  ),
                  if (i < itens.length - 1)
                    Container(width: 2, height: 38, color: Cores.borda),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itens[i].titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: itens[i].concluido
                                ? Cores.primariaEscura
                                : Cores.textoFraco,
                          )),
                      if (itens[i].detalhe != null)
                        Text(itens[i].detalhe!,
                            style: const TextStyle(
                                fontSize: 12.5, color: Cores.textoFraco)),
                      if (itens[i].quando != null)
                        Text(dataHora(itens[i].quando),
                            style: const TextStyle(
                                fontSize: 11.5, color: Cores.textoFraco)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
