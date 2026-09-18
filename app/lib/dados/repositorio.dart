import '../modelos/modelos.dart';

/// Contrato de acesso a dados. O prototipo roda com [RepositorioMock];
/// trocar por [RepositorioApi] nao exige alterar nenhuma tela.
abstract class Repositorio {
  Future<({String token, Usuario usuario})> login(String telefone, String senha);

  Future<({String token, Usuario usuario})> cadastrarCliente({
    required String nome,
    String? sobrenome,
    required String telefone,
    String? email,
    required String senha,
    String? setor,
  });

  Future<String> cadastrarMotorista(Map<String, dynamic> dados);

  Future<String> cadastrarTransportadora(Map<String, dynamic> dados);

  Future<List<CategoriaVeiculo>> veiculos({String cidade});

  Future<({List<Endereco> favoritos, List<Endereco> recentes})> enderecos();

  Future<List<Endereco>> buscarEnderecos(String termo);

  Future<Endereco> salvarEndereco(Endereco endereco);

  Future<Cotacao> cotar({
    required int categoriaId,
    required List<Endereco> paradas,
    List<int> servicos,
    int? horas,
    String? cupom,
  });

  Future<Pedido> criarPedido(Map<String, dynamic> corpo);

  Future<List<Pedido>> listarPedidos({String situacao, String? busca});

  Future<Pedido> obterPedido(int id);

  Future<Pedido> avancarPedido(int id);

  Future<double> cancelarPedido(int id, String motivo);

  Future<void> avaliarPedido(int id, int nota, String? comentario, bool favoritar);

  Future<List<MotoristaFavorito>> favoritos();

  Future<String> convidarMotorista(String telefone, String? nome);

  Future<void> removerFavorito(int motoristaId);

  Future<Carteira> carteira();

  Future<double> recarregar(double valor);

  Future<({List<Notificacao> operacionais, List<Notificacao> promocionais})>
      notificacoes();
}
