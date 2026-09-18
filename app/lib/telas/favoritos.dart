import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';

/// Motoristas parceiros favoritos e convite por telefone.
class TelaFavoritos extends StatefulWidget {
  const TelaFavoritos({super.key});

  @override
  State<TelaFavoritos> createState() => _TelaFavoritosState();
}

class _TelaFavoritosState extends State<TelaFavoritos> {
  List<MotoristaFavorito> _lista = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final repo = context.read<Sessao>().repo;
    final lista = await repo.favoritos();
    if (!mounted) return;
    setState(() {
      _lista = lista;
      _carregando = false;
    });
  }

  Future<void> _convidar() async {
    final telefone = TextEditingController();
    final nome = TextEditingController();

    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (contexto) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(contexto).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TituloSecao('Convidar um motorista'),
            const Text(
              'Se voce ja trabalha com um motorista de confianca, informe o telefone. '
              'Enviamos um convite por SMS e, apos a homologacao, ele entra nos seus favoritos.',
              style: TextStyle(fontSize: 12.5, color: Cores.textoFraco, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Celular do motorista', prefixText: '+55 '),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(contexto).pop(true),
              child: const Text('Enviar convite'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (confirmou == true && telefone.text.trim().isNotEmpty) {
      final repo = context.read<Sessao>().repo;
      final mensagem =
          await repo.convidarMotorista(telefone.text.trim(), nome.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
      _carregar();
    }
    telefone.dispose();
    nome.dispose();
  }

  Future<void> _remover(MotoristaFavorito m) async {
    final repo = context.read<Sessao>().repo;
    await repo.removerFavorito(m.motoristaId);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        if (_lista.isEmpty)
          Vazio(
            icone: Icons.people_outline,
            titulo: 'Nenhum motorista favorito',
            descricao:
                'Favorite um parceiro ao avaliar um pedido ou convide alguem que voce ja conhece.',
            acao: FilledButton.icon(
              onPressed: _convidar,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Convidar motorista'),
            ),
          )
        else
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Bloco(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    TituloSecao('Como funciona a prioridade'),
                    Text(
                      'Ao ativar "motoristas favoritos primeiro" no pedido, seus parceiros '
                      'recebem a oferta antes da base geral. Se nenhum aceitar dentro da janela, '
                      'a oferta segue automaticamente para os outros parceiros da plataforma.',
                      style: TextStyle(fontSize: 12.5, height: 1.45, color: Cores.textoFraco),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TituloSecao('Meus parceiros (${_lista.length})'),
              for (final m in _lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Bloco(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Cores.fundo,
                          child: Icon(
                            m.disponivel ? Icons.person : Icons.person_outline,
                            color: m.disponivel ? Cores.sucesso : Cores.textoFraco,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (m.avaliacao > 0) ...[
                                    const Icon(Icons.star,
                                        size: 13, color: Cores.destaque),
                                    const SizedBox(width: 3),
                                    Text(m.avaliacao.toStringAsFixed(2),
                                        style: const TextStyle(fontSize: 12.5)),
                                    const SizedBox(width: 10),
                                  ],
                                  Text(
                                    m.totalCorridas > 0
                                        ? '${m.totalCorridas} fretes'
                                        : 'Convite pendente',
                                    style: const TextStyle(
                                        fontSize: 12.5, color: Cores.textoFraco),
                                  ),
                                ],
                              ),
                              if (m.veiculos != null && m.veiculos!.isNotEmpty)
                                Text(m.veiculos!,
                                    style: const TextStyle(
                                        fontSize: 12, color: Cores.textoFraco)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (m.disponivel ? Cores.sucesso : Cores.textoFraco)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                m.disponivel ? 'disponivel' : 'offline',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: m.disponivel ? Cores.sucesso : Cores.textoFraco,
                                ),
                              ),
                            ),
                            IconButton(
                              iconSize: 18,
                              icon: const Icon(Icons.star, color: Cores.destaque),
                              tooltip: 'Remover dos favoritos',
                              onPressed: () => _remover(m),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (_lista.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: _convidar,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Convidar motorista'),
            ),
          ),
      ],
    );
  }
}
