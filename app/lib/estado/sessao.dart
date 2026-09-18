import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../dados/repositorio.dart';
import '../dados/repositorio_api.dart';
import '../dados/repositorio_mock.dart';
import '../modelos/modelos.dart';

/// Sessao do usuario e ponto unico de acesso ao repositorio.
class Sessao extends ChangeNotifier {
  Sessao() : repo = Config.usarApi ? RepositorioApi() : RepositorioMock();

  final Repositorio repo;

  Usuario? _usuario;
  bool _carregando = false;
  String? _erro;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;
  bool get carregando => _carregando;
  String? get erro => _erro;

  void _iniciar() {
    _carregando = true;
    _erro = null;
    notifyListeners();
  }

  void _finalizar([String? erro]) {
    _carregando = false;
    _erro = erro;
    notifyListeners();
  }

  Future<bool> entrar(String telefone, String senha) async {
    _iniciar();
    try {
      final r = await repo.login(telefone, senha);
      _usuario = r.usuario;
      _finalizar();
      return true;
    } catch (e) {
      _finalizar(e.toString());
      return false;
    }
  }

  Future<bool> cadastrarCliente({
    required String nome,
    String? sobrenome,
    required String telefone,
    String? email,
    required String senha,
    String? setor,
  }) async {
    _iniciar();
    try {
      final r = await repo.cadastrarCliente(
        nome: nome,
        sobrenome: sobrenome,
        telefone: telefone,
        email: email,
        senha: senha,
        setor: setor,
      );
      _usuario = r.usuario;
      _finalizar();
      return true;
    } catch (e) {
      _finalizar(e.toString());
      return false;
    }
  }

  Future<String?> cadastrarMotorista(Map<String, dynamic> dados) async {
    _iniciar();
    try {
      final mensagem = await repo.cadastrarMotorista(dados);
      _finalizar();
      return mensagem;
    } catch (e) {
      _finalizar(e.toString());
      return null;
    }
  }

  Future<String?> cadastrarTransportadora(Map<String, dynamic> dados) async {
    _iniciar();
    try {
      final mensagem = await repo.cadastrarTransportadora(dados);
      _finalizar();
      return mensagem;
    } catch (e) {
      _finalizar(e.toString());
      return null;
    }
  }

  void sair() {
    _usuario = null;
    notifyListeners();
  }
}
