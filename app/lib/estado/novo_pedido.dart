import 'package:flutter/foundation.dart';

import '../dados/repositorio.dart';
import '../modelos/modelos.dart';

/// Rascunho do pedido sendo montado. Concentra as regras de validacao
/// do fluxo (RN01, RN02, RN04, RN10) antes de chamar o repositorio.
class NovoPedido extends ChangeNotifier {
  NovoPedido(this._repo);

  final Repositorio _repo;

  // --- roteiro ---
  Endereco? coleta;
  final List<Endereco> entregas = [];

  // --- agendamento ---
  bool agendado = false;
  DateTime? quando;

  // --- veiculo e servicos ---
  List<CategoriaVeiculo> catalogo = [];
  CategoriaVeiculo? categoria;
  final Set<int> servicosSelecionados = {};
  int? horasContratadas; // contratacao por periodo

  // --- carga ---
  Carga carga = const Carga();

  // --- pagamento ---
  String? formaPagamento;
  String pagador = 'remetente';

  // --- preferencias ---
  bool favoritosPrimeiro = false;
  bool exigeComprovante = true;
  String? observacaoMotorista;
  String? contatoTelefone;
  String? cupom;

  // --- cotacao ---
  Cotacao? cotacao;
  String nivelSelecionado = 'padrao';
  bool cotando = false;
  String? erro;

  List<Endereco> get paradas => [if (coleta != null) coleta!, ...entregas];

  bool get roteiroCompleto => coleta != null && entregas.isNotEmpty;

  OpcaoCotacao? get opcaoSelecionada {
    final opcoes = cotacao?.opcoes;
    if (opcoes == null) return null;
    for (final o in opcoes) {
      if (o.nivel == nivelSelecionado) return o;
    }
    return null;
  }

  /// Regra RN02: o peso declarado nao pode exceder a capacidade do veiculo.
  static const _pesoFaixa = {
    'ate_50': 50,
    'ate_300': 300,
    'de_300_a_750': 750,
    'acima_750': 3500,
  };

  String? get avisoCapacidade {
    final c = categoria;
    if (c == null) return null;
    final peso = _pesoFaixa[carga.faixaPeso] ?? 0;
    if (peso > c.pesoMaxKg) {
      return 'O peso declarado (${carga.faixaPeso == 'acima_750' ? 'acima de 750 kg' : 'ate $peso kg'}) '
          'excede a capacidade do ${c.nome} (${c.pesoMaxKg} kg). Escolha um veiculo maior.';
    }
    return null;
  }

  List<String> get pendenciasParaConfirmar {
    final faltas = <String>[];
    if (!roteiroCompleto) faltas.add('Informe coleta e entrega');
    if (categoria == null) faltas.add('Selecione o veiculo');
    if (formaPagamento == null) faltas.add('Selecione a forma de pagamento');
    if (agendado && quando == null) faltas.add('Informe a data e hora do agendamento');
    if (agendado && quando != null && !quando!.isAfter(DateTime.now())) {
      faltas.add('O agendamento deve ser no futuro');
    }
    if (avisoCapacidade != null) faltas.add('Ajuste o veiculo para o peso declarado');
    return faltas;
  }

  bool get podeConfirmar => pendenciasParaConfirmar.isEmpty;

  // ------------------------------------------------------------- acoes
  Future<void> carregarCatalogo() async {
    if (catalogo.isNotEmpty) return;
    catalogo = await _repo.veiculos();
    notifyListeners();
  }

  void definirColeta(Endereco e) {
    coleta = e;
    cotacao = null;
    notifyListeners();
    cotar();
  }

  void adicionarEntrega(Endereco e) {
    entregas.add(e);
    cotacao = null;
    notifyListeners();
    cotar();
  }

  void substituirEntrega(int indice, Endereco e) {
    entregas[indice] = e;
    cotacao = null;
    notifyListeners();
    cotar();
  }

  void removerEntrega(int indice) {
    entregas.removeAt(indice);
    cotacao = null;
    notifyListeners();
    cotar();
  }

  void inverterRoteiro() {
    if (coleta == null || entregas.isEmpty) return;
    final antigaColeta = coleta!;
    coleta = entregas.removeAt(0);
    entregas.insert(0, antigaColeta);
    cotacao = null;
    notifyListeners();
    cotar();
  }

  void definirAgendamento(bool ativo, [DateTime? data]) {
    agendado = ativo;
    quando = ativo ? data : null;
    notifyListeners();
  }

  void selecionarCategoria(CategoriaVeiculo c) {
    if (categoria?.id != c.id) servicosSelecionados.clear();
    categoria = c;
    notifyListeners();
    cotar();
  }

  void alternarServico(int id) {
    if (servicosSelecionados.contains(id)) {
      servicosSelecionados.remove(id);
    } else {
      servicosSelecionados.add(id);
    }
    notifyListeners();
    cotar();
  }

  void definirHoras(int? horas) {
    horasContratadas = horas;
    notifyListeners();
    cotar();
  }

  void definirCarga(Carga nova) {
    carga = nova;
    notifyListeners();
  }

  void definirPagamento(String forma, {String? quemPaga}) {
    formaPagamento = forma;
    if (quemPaga != null) pagador = quemPaga;
    notifyListeners();
  }

  void definirNivel(String nivel) {
    nivelSelecionado = nivel;
    notifyListeners();
  }

  void definirCupom(String? codigo) {
    cupom = (codigo == null || codigo.isEmpty) ? null : codigo.toUpperCase();
    notifyListeners();
    cotar();
  }

  void alternarFavoritosPrimeiro(bool valor) {
    favoritosPrimeiro = valor;
    notifyListeners();
  }

  void alternarComprovante(bool valor) {
    exigeComprovante = valor;
    notifyListeners();
  }

  void definirObservacao(String? texto) {
    observacaoMotorista = texto;
    notifyListeners();
  }

  Future<void> cotar() async {
    if (!roteiroCompleto || categoria == null) return;
    cotando = true;
    erro = null;
    notifyListeners();
    try {
      cotacao = await _repo.cotar(
        categoriaId: categoria!.id,
        paradas: paradas,
        servicos: servicosSelecionados.toList(),
        horas: horasContratadas,
        cupom: cupom,
      );
    } catch (e) {
      erro = e.toString();
    } finally {
      cotando = false;
      notifyListeners();
    }
  }

  Future<Pedido?> confirmar() async {
    if (!podeConfirmar) return null;
    final opcao = opcaoSelecionada;
    if (opcao == null) return null;

    final pedido = await _repo.criarPedido({
      'categoriaId': categoria!.id,
      'nivelServico': nivelSelecionado,
      'tipoRetirada': agendado ? 'agendada' : 'imediata',
      'agendadoPara': quando,
      'modalidade': horasContratadas == null ? 'entrega' : 'periodo',
      'horasContratadas': horasContratadas,
      'paradas': paradas,
      'servicos': servicosSelecionados.toList(),
      'carga': carga,
      'formaPagamento': formaPagamento,
      'pagador': pagador,
      'favoritosPrimeiro': favoritosPrimeiro,
      'exigeComprovante': exigeComprovante,
      'observacaoMotorista': observacaoMotorista,
      'contatoTelefone': contatoTelefone,
      'cupom': cupom,
      'aceiteItensProibidos': true,
      'distanciaKm': cotacao!.distanciaKm,
      'valorFrete': opcao.valorFrete,
      'valorAdicionais': opcao.valorAdicionais,
      'valorDesconto': opcao.desconto,
      'valorTotal': opcao.total,
    });
    return pedido;
  }

  void limpar() {
    coleta = null;
    entregas.clear();
    agendado = false;
    quando = null;
    categoria = null;
    servicosSelecionados.clear();
    horasContratadas = null;
    carga = const Carga();
    formaPagamento = null;
    pagador = 'remetente';
    favoritosPrimeiro = false;
    exigeComprovante = true;
    observacaoMotorista = null;
    cupom = null;
    cotacao = null;
    nivelSelecionado = 'padrao';
    erro = null;
    notifyListeners();
  }
}
