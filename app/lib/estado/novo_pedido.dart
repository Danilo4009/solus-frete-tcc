import 'package:flutter/foundation.dart';

import '../core/compatibilidade.dart';
import '../dados/repositorio.dart';
import '../modelos/modelos.dart';

/// Rascunho do pedido sendo montado. Concentra as regras de validacao
/// do fluxo (RN01, RN02, RN04, RN10) antes de chamar o repositorio.
///
/// Ordem do fluxo: roteiro -> detalhes da carga -> veiculo -> parceiro -> pagamento.
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

  /// Preenchido quando uma alteracao na carga deixou o veiculo escolhido incompativel.
  String? avisoVeiculoDesmarcado;

  /// Muda a cada limpar(): a tela usa para recriar os campos do formulario da carga.
  int geracao = 0;

  // --- pagamento ---
  String? formaPagamento;
  String pagador = 'remetente';

  // --- preferencias ---
  bool exigeComprovante = true;
  String? observacaoMotorista;
  String? contatoTelefone;
  String? cupom;

  // --- cotacao ---
  Cotacao? cotacao;
  String? _chaveEscolhida; // parceiro escolhido entre as ofertas da cotacao
  bool cotando = false;
  String? erro;

  List<Endereco> get paradas => [if (coleta != null) coleta!, ...entregas];

  bool get roteiroCompleto => coleta != null && entregas.isNotEmpty;

  /// Oferta do parceiro escolhido, se ele ainda estiver na cotacao atual.
  OfertaParceiro? get ofertaEscolhida {
    final ofertas = cotacao?.ofertas;
    if (ofertas == null || _chaveEscolhida == null) return null;
    for (final o in ofertas) {
      if (o.chave == _chaveEscolhida) return o;
    }
    return null;
  }

  Map<String, String> get errosCarga => validarCarga(carga);

  bool get cargaValida => carga.completa && errosCarga.isEmpty;

  /// Regra RN02: peso, tamanho do maior volume e tipo de carga precisam servir ao veiculo.
  /// Null enquanto a carga esta incompleta.
  ResultadoCompatibilidade? compatibilidadeDe(CategoriaVeiculo veiculo) =>
      cargaValida ? verificarCompatibilidade(carga, veiculo) : null;

  /// A carga esta valida, mas nenhum veiculo do catalogo comporta.
  bool get nenhumVeiculoCompativel =>
      cargaValida &&
      catalogo.isNotEmpty &&
      catalogo.every((v) => !compatibilidadeDe(v)!.compativel);

  /// Menor veiculo compativel (catalogo vem ordenado por capacidade crescente):
  /// costuma sair mais barato, entao e a recomendacao padrao. Null enquanto a
  /// carga esta incompleta ou nenhum veiculo comporta.
  CategoriaVeiculo? get veiculoRecomendado {
    if (!cargaValida) return null;
    for (final v in catalogo) {
      if (compatibilidadeDe(v)!.compativel) return v;
    }
    return null;
  }

  List<String> get pendenciasParaConfirmar {
    final faltas = <String>[];
    if (!roteiroCompleto) faltas.add('Informe coleta e entrega');
    if (!cargaValida) faltas.add('Preencha os detalhes da carga');
    if (categoria == null) faltas.add('Selecione o veículo');
    if (ofertaEscolhida == null) faltas.add('Escolha um parceiro');
    if (formaPagamento == null) faltas.add('Selecione a forma de pagamento');
    if (agendado && quando == null) faltas.add('Informe a data e hora do agendamento');
    if (agendado && quando != null && !quando!.isAfter(DateTime.now())) {
      faltas.add('O agendamento deve ser no futuro');
    }
    final escolhido = categoria;
    if (escolhido != null && cargaValida && !compatibilidadeDe(escolhido)!.compativel) {
      faltas.add('Escolha um veículo compatível com a carga');
    }
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
    final compat = compatibilidadeDe(c);
    if (compat == null || !compat.compativel) return; // veiculo desabilitado na tela
    if (categoria?.id != c.id) servicosSelecionados.clear();
    categoria = c;
    avisoVeiculoDesmarcado = null;
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

  /// Se a carga passou a ser valida e o veiculo escolhido nao serve mais, desmarca o veiculo
  /// e deixa o aviso em [avisoVeiculoDesmarcado]. Enquanto a carga esta incompleta (o usuario
  /// ainda digitando), a escolha e mantida e o pedido so nao pode ser confirmado.
  void definirCarga(Carga nova) {
    carga = nova;
    final escolhido = categoria;
    if (escolhido != null && cargaValida) {
      final compat = verificarCompatibilidade(carga, escolhido);
      if (!compat.compativel) {
        avisoVeiculoDesmarcado =
            '${escolhido.nome} foi desmarcado: ${compat.motivo}. Escolha outro veículo.';
        categoria = null;
        servicosSelecionados.clear();
        cotacao = null;
        _chaveEscolhida = null;
      }
    }
    notifyListeners();
  }

  void definirPagamento(String forma, {String? quemPaga}) {
    formaPagamento = forma;
    if (quemPaga != null) pagador = quemPaga;
    notifyListeners();
  }

  void escolherOferta(OfertaParceiro oferta) {
    _chaveEscolhida = oferta.chave;
    notifyListeners();
  }

  void definirCupom(String? codigo) {
    cupom = (codigo == null || codigo.isEmpty) ? null : codigo.toUpperCase();
    notifyListeners();
    cotar();
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
      if (ofertaEscolhida == null) _chaveEscolhida = null;
    } catch (e) {
      erro = e.toString();
    } finally {
      cotando = false;
      notifyListeners();
    }
  }

  Future<Pedido?> confirmar() async {
    if (!podeConfirmar) return null;
    final oferta = ofertaEscolhida;
    if (oferta == null) return null;

    final pedido = await _repo.criarPedido({
      'categoriaId': categoria!.id,
      'parceiroTipo': oferta.tipo,
      'parceiroId': oferta.parceiroId,
      'tipoRetirada': agendado ? 'agendada' : 'imediata',
      'agendadoPara': quando,
      'modalidade': horasContratadas == null ? 'entrega' : 'periodo',
      'horasContratadas': horasContratadas,
      'paradas': paradas,
      'servicos': servicosSelecionados.toList(),
      'carga': carga,
      'formaPagamento': formaPagamento,
      'pagador': pagador,
      'exigeComprovante': exigeComprovante,
      'observacaoMotorista': observacaoMotorista,
      'contatoTelefone': contatoTelefone,
      'cupom': cupom,
      'aceiteItensProibidos': true,
      'distanciaKm': cotacao!.distanciaKm,
      'valorFrete': oferta.valorFrete,
      'valorAdicionais': oferta.valorAdicionais,
      'valorDesconto': oferta.desconto,
      'valorTotal': oferta.total,
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
    avisoVeiculoDesmarcado = null;
    geracao++;
    formaPagamento = null;
    pagador = 'remetente';
    exigeComprovante = true;
    observacaoMotorista = null;
    cupom = null;
    cotacao = null;
    _chaveEscolhida = null;
    erro = null;
    notifyListeners();
  }
}
