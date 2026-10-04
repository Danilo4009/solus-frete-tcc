import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
      // Material transparente por baixo do fundo: ListTile e InkWell pintam o toque nele,
      // senao o fundo do Container esconde o efeito (e o Flutter reclama em debug).
      child: Material(
        type: MaterialType.transparency,
        child:
            onTap == null ? conteudo : InkWell(onTap: onTap, child: conteudo),
      ),
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
        style:
            TextStyle(color: _cor, fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class Vazio extends StatelessWidget {
  const Vazio(
      {super.key,
      required this.icone,
      required this.titulo,
      this.descricao,
      this.acao});

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
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
/// Centro padrao quando nao ha nenhum ponto ainda (regiao de Sao Paulo, onde
/// ficam os enderecos de exemplo do prototipo).
const _centroPadrao = LatLng(-23.5505, -46.6333);

/// Mapa com tiles reais do OpenStreetMap. Mostra os pontos do roteiro com
/// marcadores (coleta em azul, entregas em laranja), liga-os com uma linha e,
/// se [progresso] for informado, desenha o veiculo nessa posicao da rota.
class MapaSimulado extends StatelessWidget {
  const MapaSimulado({
    super.key,
    this.altura = 220,
    this.pontos = const [],
    this.progresso,
    this.interativo = false,
  });

  final double altura;

  /// Pares (latitude, longitude) do roteiro.
  final List<({double lat, double lng})> pontos;

  /// 0..1 indicando o avanco do veiculo na rota.
  final double? progresso;

  /// Permite arrastar/dar zoom no mapa. Falso para os mapas-resumo (so exibicao).
  final bool interativo;

  List<LatLng> get _coordenadas =>
      pontos.map((p) => LatLng(p.lat, p.lng)).toList();

  @override
  Widget build(BuildContext context) {
    final coordenadas = _coordenadas;
    final veiculo = _posicaoDoVeiculo(coordenadas, progresso);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: coordenadas.length < 2
                ? null
                : CameraFit.coordinates(
                    coordinates: coordenadas,
                    padding: const EdgeInsets.all(36),
                  ),
            initialCenter:
                coordenadas.isEmpty ? _centroPadrao : coordenadas.first,
            initialZoom: coordenadas.isEmpty ? 12 : 15,
            interactionOptions: InteractionOptions(
              flags: interativo ? InteractiveFlag.all : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.danilo4009.solusFrete',
            ),
            if (coordenadas.length > 1)
              PolylineLayer(polylines: [
                Polyline(
                    points: coordenadas, color: Cores.primaria, strokeWidth: 4),
              ]),
            MarkerLayer(markers: [
              for (var i = 0; i < coordenadas.length; i++)
                Marker(
                  point: coordenadas[i],
                  width: 30,
                  height: 30,
                  child: Icon(
                    i == 0 ? Icons.trip_origin : Icons.place,
                    color: i == 0 ? Cores.primaria : Cores.destaque,
                    size: 30,
                  ),
                ),
              if (veiculo != null)
                Marker(
                  point: veiculo,
                  width: 26,
                  height: 26,
                  child: const Icon(Icons.local_shipping,
                      color: Cores.sucesso, size: 26),
                ),
            ]),
            const Padding(
              padding: EdgeInsets.all(4),
              child: Align(
                alignment: Alignment.bottomRight,
                child: _CreditoOsm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interpola a posicao do veiculo ao longo dos segmentos do roteiro conforme
/// o progresso (0..1 do total da rota, nao so do primeiro ao ultimo ponto).
LatLng? _posicaoDoVeiculo(List<LatLng> coordenadas, double? progresso) {
  if (progresso == null || coordenadas.length < 2) return null;
  final distancia = Distance();
  final comprimentos = <double>[];
  var total = 0.0;
  for (var i = 1; i < coordenadas.length; i++) {
    final d = distancia(coordenadas[i - 1], coordenadas[i]);
    comprimentos.add(d);
    total += d;
  }
  if (total <= 0) return coordenadas.first;

  var alvo = total * progresso.clamp(0, 1);
  for (var i = 0; i < comprimentos.length; i++) {
    if (alvo <= comprimentos[i] || i == comprimentos.length - 1) {
      final fracao =
          comprimentos[i] == 0 ? 0.0 : (alvo / comprimentos[i]).clamp(0, 1);
      return LatLng(
        coordenadas[i].latitude +
            (coordenadas[i + 1].latitude - coordenadas[i].latitude) * fracao,
        coordenadas[i].longitude +
            (coordenadas[i + 1].longitude - coordenadas[i].longitude) * fracao,
      );
    }
    alvo -= comprimentos[i];
  }
  return coordenadas.last;
}

/// Atribuicao exigida pela licenca de uso dos tiles do OpenStreetMap.
class _CreditoOsm extends StatelessWidget {
  const _CreditoOsm();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('© OpenStreetMap',
          style: TextStyle(fontSize: 11, color: Cores.textoFraco)),
    );
  }
}

/// Linha do tempo vertical das etapas do pedido.
class LinhaDoTempo extends StatelessWidget {
  const LinhaDoTempo({super.key, required this.itens});

  final List<
          ({String titulo, String? detalhe, DateTime? quando, bool concluido})>
      itens;

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
                        color: itens[i].concluido
                            ? Cores.sucesso
                            : Cores.textoFraco,
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
                                fontSize: 11, color: Cores.textoFraco)),
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
