import 'package:flutter/material.dart';

import '../ajuda_pedido.dart';
import '../tema.dart';

/// Botao flutuante de ajuda da tela Pedir: abre todas as dicas para quem nunca usou a
/// plataforma. Com texto visivel (nao so o icone) e na cor de destaque para chamar mais
/// atencao de quem esta vendo o app pela primeira vez.
class BotaoAjuda extends StatelessWidget {
  const BotaoAjuda({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'ajuda-pedir',
      tooltip: 'Precisa de ajuda?',
      backgroundColor: Cores.destaque,
      foregroundColor: Colors.white,
      onPressed: () => mostrarAjuda(context),
      icon: const Icon(Icons.help_outline),
      label: const Text('Ajuda', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// Icone "i" pequeno ao lado do titulo de uma secao: abre so a dica daquela etapa.
class IconeInfoSecao extends StatelessWidget {
  const IconeInfoSecao({super.key, required this.secao});

  final String secao;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Dicas desta etapa',
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline, color: Cores.textoFraco),
      onPressed: () => mostrarAjuda(context, secao: secao),
    );
  }
}

/// Bottom sheet de ajuda. Sem [secao], lista todas as dicas (recolhidas); com [secao],
/// mostra so as dicas daquela etapa, ja abertas.
Future<void> mostrarAjuda(BuildContext context, {String? secao}) {
  final itens = secao == null ? todasAsDicas : dicasDaSecao(secao);
  final abertas = secao != null;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (contexto) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(contexto).size.height * 0.85),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline, color: Cores.primaria),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      abertas ? 'Dicas desta etapa' : 'Como fazer um pedido',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Cores.primariaEscura,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final item in itens)
                Theme(
                  data: Theme.of(contexto).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey<String>('ajuda-${item.titulo}'),
                    initiallyExpanded: abertas,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: Text(
                      item.titulo,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    children: [
                      Text(
                        item.texto,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Cores.textoFraco,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(contexto).pop(),
                  child: const Text('Entendi'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
