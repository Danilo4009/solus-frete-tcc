import 'package:flutter/material.dart';

import '../tema.dart';

/// Indicador de progresso por etapas dos cadastros.
class PassosIndicador extends StatelessWidget {
  const PassosIndicador({super.key, required this.atual, required this.rotulos});

  final int atual;
  final List<String> rotulos;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          for (var i = 0; i < rotulos.length; i++)
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= atual ? Cores.primaria : Cores.borda,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rotulos[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: i == atual ? FontWeight.w700 : FontWeight.w400,
                      color: i <= atual ? Cores.primaria : Cores.textoFraco,
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

/// Campo de data que abre o seletor nativo.
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onTap,
  });

  final String rotulo;
  final DateTime? valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: rotulo),
        child: Text(
          valor == null
              ? 'Selecionar'
              : '${valor!.day.toString().padLeft(2, '0')}/'
                  '${valor!.month.toString().padLeft(2, '0')}/${valor!.year}',
          style: TextStyle(color: valor == null ? Cores.textoFraco : null),
        ),
      ),
    );
  }
}

/// Placeholder de upload de documento. No app final, camera/galeria.
class AnexoSimulado extends StatelessWidget {
  const AnexoSimulado({
    super.key,
    required this.rotulo,
    required this.anexado,
    required this.onTap,
  });

  final String rotulo;
  final bool anexado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: anexado ? Cores.sucesso : Cores.borda),
          borderRadius: BorderRadius.circular(12),
          color: anexado ? Cores.sucesso.withOpacity(0.06) : null,
        ),
        child: Row(
          children: [
            Icon(anexado ? Icons.check_circle : Icons.upload_file_outlined,
                color: anexado ? Cores.sucesso : Cores.primaria),
            const SizedBox(width: 12),
            Expanded(
              child: Text(anexado ? '$rotulo - anexado' : rotulo,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
