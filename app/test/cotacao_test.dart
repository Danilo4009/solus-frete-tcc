import 'package:flutter_test/flutter_test.dart';
import 'package:solus_frete/dados/repositorio_mock.dart';
import 'package:solus_frete/modelos/modelos.dart';

void main() {
  const coleta = Endereco(
      id: 1, logradouro: 'Rua Salvador Nunes', cidade: 'Osasco', uf: 'SP',
      latitude: -23.5320, longitude: -46.7920);
  const entrega = Endereco(
      id: 2, logradouro: 'Avenida Paulista', cidade: 'Sao Paulo', uf: 'SP',
      latitude: -23.5660, longitude: -46.6520);
  const carreto = 6;

  Map<String, dynamic> corpo(OfertaParceiro oferta) => {
        'categoriaId': carreto,
        'parceiroTipo': oferta.tipo,
        'parceiroId': oferta.parceiroId,
        'tipoRetirada': 'imediata',
        'paradas': <Endereco>[coleta, entrega],
        'servicos': <int>[],
        'formaPagamento': 'pix',
      };

  test('a cotacao traz 10 opcoes: 4 motoristas e 6 transportadoras', () async {
    final repo = RepositorioMock();
    final cotacao =
        await repo.cotar(categoriaId: carreto, paradas: [coleta, entrega]);

    expect(cotacao.ofertas, hasLength(10));
    expect(cotacao.ofertas.where((o) => o.ehMotorista), hasLength(4));
    expect(cotacao.ofertas.where((o) => !o.ehMotorista), hasLength(6));
  });

  test('motorista usa o preco da plataforma e transportadora tem preco proprio', () async {
    final repo = RepositorioMock();
    final cotacao =
        await repo.cotar(categoriaId: carreto, paradas: [coleta, entrega]);

    final precosMotoristas =
        cotacao.ofertas.where((o) => o.ehMotorista).map((o) => o.total).toSet();
    final precosTransportadoras =
        cotacao.ofertas.where((o) => !o.ehMotorista).map((o) => o.total).toSet();

    expect(precosMotoristas, hasLength(1));
    expect(precosTransportadoras.length, greaterThan(1));
  });

  test('o pedido vai para o parceiro escolhido e ele pode aceitar', () async {
    final repo = RepositorioMock();
    final oferta = (await repo.cotar(categoriaId: carreto, paradas: [coleta, entrega]))
        .ofertas
        .firstWhere((o) => !o.ehMotorista);

    final pedido = await repo.criarPedido(corpo(oferta));
    expect(pedido.situacao, 'aguardando_alocacao');
    expect(pedido.transportadoraNome, oferta.nome);
    expect(pedido.valorTotal, oferta.total);

    final aceito = await repo.avancarPedido(pedido.id);
    expect(aceito.situacao, 'alocado');
  });

  test('parceiro que recusa sai da lista e o cliente escolhe outro', () async {
    final repo = RepositorioMock();
    final oferta = (await repo.cotar(categoriaId: carreto, paradas: [coleta, entrega]))
        .ofertas
        .firstWhere((o) => o.ehMotorista);
    final pedido = await repo.criarPedido(corpo(oferta));

    final recusado = await repo.recusarParceiro(pedido.id);
    expect(recusado.situacao, 'cotado');
    expect(recusado.parceiroNome, isNull);

    final novaCotacao = await repo.cotarPedido(pedido.id);
    expect(novaCotacao.ofertas.any((o) => o.chave == oferta.chave), isFalse);

    final trocado = await repo.trocarParceiro(pedido.id, novaCotacao.ofertas.first);
    expect(trocado.situacao, 'aguardando_alocacao');
    expect(trocado.parceiroNome, novaCotacao.ofertas.first.nome);
  });
}
