import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/sessao.dart';
import '../modelos/modelos.dart';

/// Busca de endereco com favoritos, recentes e detalhamento do ponto.
class TelaSelecaoEndereco extends StatefulWidget {
  const TelaSelecaoEndereco({super.key, required this.titulo, required this.ehColeta});

  final String titulo;
  final bool ehColeta;

  @override
  State<TelaSelecaoEndereco> createState() => _TelaSelecaoEnderecoState();
}

class _TelaSelecaoEnderecoState extends State<TelaSelecaoEndereco> {
  final _busca = TextEditingController();
  List<Endereco> _favoritos = [];
  List<Endereco> _recentes = [];
  List<Endereco> _resultados = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final repo = context.read<Sessao>().repo;
    final r = await repo.enderecos();
    if (!mounted) return;
    setState(() {
      _favoritos = r.favoritos;
      _recentes = r.recentes;
      _carregando = false;
    });
  }

  Future<void> _buscar(String termo) async {
    if (termo.trim().length < 3) {
      setState(() => _resultados = []);
      return;
    }
    final repo = context.read<Sessao>().repo;
    final r = await repo.buscarEnderecos(termo.trim());
    if (!mounted) return;
    setState(() => _resultados = r);
  }

  Future<void> _detalhar(Endereco base) async {
    final resultado = await Navigator.of(context).push<Endereco>(
      MaterialPageRoute(
        builder: (_) => TelaDetalhesEndereco(endereco: base, ehColeta: widget.ehColeta),
      ),
    );
    if (resultado != null && mounted) Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    final mostrandoBusca = _resultados.isNotEmpty || _busca.text.trim().length >= 3;

    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busca,
              autofocus: true,
              onChanged: (v) {
                setState(() {});
                _buscar(v);
              },
              decoration: InputDecoration(
                hintText: widget.ehColeta
                    ? 'Local de retirada (rua e número)'
                    : 'Local de entrega (rua e número)',
                prefixIcon: Icon(
                  widget.ehColeta ? Icons.trip_origin : Icons.place,
                  color: widget.ehColeta ? Cores.primaria : Cores.destaque,
                  size: 20,
                ),
                suffixIcon: _busca.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busca.clear();
                          setState(() => _resultados = []);
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      if (mostrandoBusca) ...[
                        const TituloSecao('Resultados'),
                        if (_resultados.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text('Nenhum endereço encontrado.',
                                style: TextStyle(color: Cores.textoFraco)),
                          )
                        else
                          Bloco(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final e in _resultados)
                                  _ItemEndereco(
                                    endereco: e,
                                    icone: Icons.location_on_outlined,
                                    onTap: () => _detalhar(e),
                                  ),
                              ],
                            ),
                          ),
                      ] else ...[
                        Bloco(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(Icons.my_location, color: Cores.primaria),
                            title: const Text('Usar minha localização atual'),
                            subtitle: const Text(
                              'No protótipo usa o primeiro endereço favorito',
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: _favoritos.isEmpty
                                ? null
                                : () => _detalhar(_favoritos.first),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_favoritos.isNotEmpty) ...[
                          const TituloSecao('Endereços salvos'),
                          Bloco(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final e in _favoritos)
                                  _ItemEndereco(
                                    endereco: e,
                                    icone: Icons.bookmark_outline,
                                    onTap: () => _detalhar(e),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_recentes.isNotEmpty) ...[
                          const TituloSecao('Usados recentemente'),
                          Bloco(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final e in _recentes)
                                  _ItemEndereco(
                                    endereco: e,
                                    icone: Icons.history,
                                    onTap: () => _detalhar(e),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemEndereco extends StatelessWidget {
  const _ItemEndereco({
    required this.endereco,
    required this.icone,
    required this.onTap,
  });

  final Endereco endereco;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: Cores.textoFraco, size: 20),
      title: Text(
        endereco.apelido ?? endereco.linhaPrincipal,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      subtitle: Text(
        endereco.apelido == null
            ? endereco.linhaSecundaria
            : '${endereco.linhaPrincipal} - ${endereco.linhaSecundaria}',
        style: const TextStyle(fontSize: 12.5),
        maxLines: 2,
      ),
      onTap: onTap,
    );
  }
}

/// Complemento, contato no local e opcao de salvar.
class TelaDetalhesEndereco extends StatefulWidget {
  const TelaDetalhesEndereco({
    super.key,
    required this.endereco,
    required this.ehColeta,
  });

  final Endereco endereco;
  final bool ehColeta;

  @override
  State<TelaDetalhesEndereco> createState() => _TelaDetalhesEnderecoState();
}

class _TelaDetalhesEnderecoState extends State<TelaDetalhesEndereco> {
  late final TextEditingController _complemento;
  late final TextEditingController _referencia;
  late final TextEditingController _contatoNome;
  late final TextEditingController _contatoTelefone;
  final _apelido = TextEditingController();
  bool _salvar = false;

  @override
  void initState() {
    super.initState();
    _complemento = TextEditingController(text: widget.endereco.complemento ?? '');
    _referencia = TextEditingController(text: widget.endereco.referencia ?? '');
    _contatoNome = TextEditingController(text: widget.endereco.contatoNome ?? '');
    _contatoTelefone =
        TextEditingController(text: widget.endereco.contatoTelefone ?? '');
  }

  @override
  void dispose() {
    for (final c in [_complemento, _referencia, _contatoNome, _contatoTelefone, _apelido]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmar() async {
    var endereco = widget.endereco.copiarCom(
      complemento: _complemento.text.trim(),
      referencia: _referencia.text.trim(),
      contatoNome: _contatoNome.text.trim(),
      contatoTelefone: _contatoTelefone.text.trim(),
      apelido: _salvar && _apelido.text.trim().isNotEmpty ? _apelido.text.trim() : null,
      favorito: _salvar,
    );

    if (_salvar) {
      final repo = context.read<Sessao>().repo;
      endereco = await repo.salvarEndereco(endereco);
    }
    if (mounted) Navigator.of(context).pop(endereco);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.endereco;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do endereço')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MapaSimulado(
            altura: 170,
            pontos: e.latitude == null
                ? const []
                : [
                    (lat: e.latitude!, lng: e.longitude!),
                    (lat: e.latitude! + 0.004, lng: e.longitude! + 0.004),
                  ],
          ),
          const SizedBox(height: 12),
          Bloco(
            child: Row(
              children: [
                Icon(widget.ehColeta ? Icons.trip_origin : Icons.place,
                    color: widget.ehColeta ? Cores.primaria : Cores.destaque),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.linhaPrincipal,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(e.linhaSecundaria,
                          style: const TextStyle(
                              fontSize: 12.5, color: Cores.textoFraco)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TituloSecao('Complemento e contato'),
                TextField(
                  controller: _complemento,
                  decoration: const InputDecoration(
                      labelText: 'Complemento', hintText: 'Apto, bloco, sala'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _referencia,
                  decoration: const InputDecoration(
                      labelText: 'Ponto de referência',
                      hintText: 'Em frente à praça, portão azul'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contatoNome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome do contato'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contatoTelefone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Telefone do contato', prefixText: '+55 '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Bloco(
            child: Column(
              children: [
                CheckboxListTile(
                  value: _salvar,
                  onChanged: (v) => setState(() => _salvar = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Salvar este endereço'),
                ),
                if (_salvar)
                  TextField(
                    controller: _apelido,
                    decoration: const InputDecoration(
                        labelText: 'Apelido', hintText: 'Casa, Loja, Depósito'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _confirmar, child: const Text('Confirmar')),
        ],
      ),
    );
  }
}
