/// Especificacoes dos veiculos: capacidade, dimensoes internas do bau e tipos de carga aceitos.
///
/// E a fonte usada pelo app no modo sem backend (RepositorioMock) e pelos testes. Com a API,
/// os mesmos dados vem do banco (db/02_seed.sql, tabela categoria_veiculo); o teste
/// test/veiculos_config_test.dart confere que os dois continuam iguais.
///
/// Para adicionar ou ajustar um veiculo: edite esta lista, o INSERT de categoria_veiculo no
/// seed e o preco em tabela_preco (seed) e _tarifas (RepositorioMock). Se o codigo for novo,
/// acrescente tambem os modelos dos parceiros (tmp_modelo no seed e _modelos no mock).
class EspecVeiculo {
  const EspecVeiculo({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.comprimentoM,
    required this.larguraM,
    required this.alturaM,
    required this.pesoMaxKg,
    this.aceitaRefrigerada = false,
    this.aceitaPerigosa = false,
  });

  /// Mesmo id da tabela categoria_veiculo (ordem de insercao no seed).
  final int id;
  final String codigo;
  final String nome;
  final String descricao;

  /// Dimensoes internas do bau, em metros.
  final double comprimentoM;
  final double larguraM;
  final double alturaM;

  /// Capacidade maxima de carga, em kg.
  final int pesoMaxKg;

  /// Carga refrigerada e perigosa so em veiculos marcados; os demais tipos qualquer um aceita.
  final bool aceitaRefrigerada;
  final bool aceitaPerigosa;

  double get volumeM3 => comprimentoM * larguraM * alturaM;
}

const List<EspecVeiculo> veiculosConfig = [
  EspecVeiculo(
    id: 1,
    codigo: 'moto',
    nome: 'Moto',
    descricao: 'Documentos e encomendas pequenas.',
    comprimentoM: 0.40,
    larguraM: 0.35,
    alturaM: 0.30,
    pesoMaxKg: 20,
  ),
  EspecVeiculo(
    id: 2,
    codigo: 'carro',
    nome: 'Carro',
    descricao: 'Volumes medios que caibam no porta-malas e bancos.',
    comprimentoM: 1.20,
    larguraM: 0.90,
    alturaM: 0.70,
    pesoMaxKg: 200,
  ),
  EspecVeiculo(
    id: 3,
    codigo: 'utilitario',
    nome: 'Utilitario',
    descricao: 'Cargas pequenas e medias, como um Fiorino: caixas e equipamentos.',
    comprimentoM: 1.90,
    larguraM: 1.30,
    alturaM: 1.20,
    pesoMaxKg: 650,
  ),
  EspecVeiculo(
    id: 4,
    codigo: 'van',
    nome: 'Van',
    descricao: 'Volume alto protegido da chuva.',
    comprimentoM: 3.00,
    larguraM: 1.70,
    alturaM: 1.80,
    pesoMaxKg: 1500,
  ),
  EspecVeiculo(
    id: 5,
    codigo: 'vuc',
    nome: 'VUC',
    descricao: 'Veiculo urbano de carga: entregas grandes dentro da cidade.',
    comprimentoM: 4.50,
    larguraM: 2.10,
    alturaM: 2.20,
    pesoMaxKg: 3000,
    aceitaRefrigerada: true,
  ),
  EspecVeiculo(
    id: 6,
    codigo: 'caminhao_34',
    nome: 'Caminhao 3/4',
    descricao: 'Cargas paletizadas e mudancas completas.',
    comprimentoM: 5.50,
    larguraM: 2.30,
    alturaM: 2.40,
    pesoMaxKg: 4000,
    aceitaRefrigerada: true,
  ),
  EspecVeiculo(
    id: 7,
    codigo: 'caminhao_toco',
    nome: 'Caminhao toco',
    descricao: 'Carga fechada e transferencias entre cidades.',
    comprimentoM: 7.00,
    larguraM: 2.40,
    alturaM: 2.60,
    pesoMaxKg: 6000,
    aceitaRefrigerada: true,
    aceitaPerigosa: true,
  ),
  EspecVeiculo(
    id: 8,
    codigo: 'caminhao_truck',
    nome: 'Caminhao truck',
    descricao: 'Grandes volumes e cargas pesadas.',
    comprimentoM: 8.50,
    larguraM: 2.40,
    alturaM: 2.70,
    pesoMaxKg: 12000,
    aceitaRefrigerada: true,
    aceitaPerigosa: true,
  ),
  EspecVeiculo(
    id: 9,
    codigo: 'carreta',
    nome: 'Carreta',
    descricao: 'Cargas muito grandes e transferencias de longa distancia.',
    comprimentoM: 14.00,
    larguraM: 2.50,
    alturaM: 2.80,
    pesoMaxKg: 25000,
    aceitaRefrigerada: true,
    aceitaPerigosa: true,
  ),
];
