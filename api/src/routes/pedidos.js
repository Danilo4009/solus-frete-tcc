const express = require('express');
const { query, one, transacao } = require('../db');
const { autenticar } = require('../auth');
const { distanciaRota, calcularFrete, aplicarCupom, repasseParceiro } = require('../precificacao');

const router = express.Router();
router.use(autenticar);

const EM_ANDAMENTO = ['cotado', 'aguardando_alocacao', 'alocado', 'em_deslocamento_coleta', 'carregando', 'em_transito', 'entregue'];

async function carregarPedido(id) {
  const pedido = await one(
    `SELECT p.*, cv.nome AS categoria_nome, cv.codigo AS categoria_codigo,
            cv.peso_max_kg, mu.nome AS motorista_nome, mu.telefone AS motorista_telefone,
            m.avaliacao_media AS motorista_avaliacao, v.placa AS veiculo_placa,
            v.marca AS veiculo_marca, v.modelo AS veiculo_modelo,
            e.nome_fantasia AS transportadora_nome
       FROM pedido p
       JOIN categoria_veiculo cv ON cv.id = p.categoria_id
       LEFT JOIN motorista m ON m.id = p.motorista_id
       LEFT JOIN usuario mu ON mu.id = m.usuario_id
       LEFT JOIN veiculo v ON v.id = p.veiculo_id
       LEFT JOIN empresa e ON e.id = p.transportadora_id
      WHERE p.id = ?`,
    [id]
  );
  if (!pedido) return null;
  pedido.paradas = await query('SELECT * FROM pedido_parada WHERE pedido_id = ? ORDER BY sequencia', [id]);
  pedido.carga = await one('SELECT * FROM pedido_carga WHERE pedido_id = ?', [id]);
  pedido.servicos = await query(
    `SELECT s.id, s.codigo, s.nome, ps.preco
       FROM pedido_servico ps JOIN servico_adicional s ON s.id = ps.servico_id
      WHERE ps.pedido_id = ?`, [id]);
  pedido.eventos = await query(
    'SELECT situacao, descricao, criado_em FROM pedido_evento WHERE pedido_id = ? ORDER BY criado_em', [id]);
  return pedido;
}

// GET /pedidos?situacao=em_andamento|concluido|cancelado&q=
router.get('/', async (req, res) => {
  const { situacao = 'em_andamento', q } = req.query;
  const params = [req.usuario.id];
  let filtro;
  if (situacao === 'concluido') filtro = "p.situacao = 'concluido'";
  else if (situacao === 'cancelado') filtro = "p.situacao = 'cancelado'";
  else filtro = `p.situacao IN (${EM_ANDAMENTO.map(() => '?').join(',')})`;
  if (situacao !== 'concluido' && situacao !== 'cancelado') params.push(...EM_ANDAMENTO);

  let busca = '';
  if (q) {
    busca = ` AND (p.codigo LIKE ? OR EXISTS (
                SELECT 1 FROM pedido_parada pp WHERE pp.pedido_id = p.id AND pp.logradouro LIKE ?))`;
    params.push(`%${q}%`, `%${q}%`);
  }

  const rows = await query(
    `SELECT p.id, p.codigo, p.situacao, p.nivel_servico, p.tipo_retirada, p.agendado_para,
            p.valor_total, p.distancia_km, p.criado_em, cv.nome AS categoria_nome,
            mu.nome AS motorista_nome,
            (SELECT CONCAT(logradouro, ', ', COALESCE(numero,'s/n')) FROM pedido_parada
              WHERE pedido_id = p.id AND tipo='coleta' ORDER BY sequencia LIMIT 1) AS origem,
            (SELECT CONCAT(logradouro, ', ', COALESCE(numero,'s/n')) FROM pedido_parada
              WHERE pedido_id = p.id AND tipo='entrega' ORDER BY sequencia DESC LIMIT 1) AS destino,
            (SELECT COUNT(*) FROM pedido_parada WHERE pedido_id = p.id) AS total_paradas
       FROM pedido p
       JOIN categoria_veiculo cv ON cv.id = p.categoria_id
       LEFT JOIN motorista m ON m.id = p.motorista_id
       LEFT JOIN usuario mu ON mu.id = m.usuario_id
      WHERE p.cliente_id = ? AND ${filtro}${busca}
      ORDER BY p.criado_em DESC`,
    params
  );
  res.json(rows);
});

// GET /pedidos/:id
router.get('/:id', async (req, res) => {
  const pedido = await carregarPedido(req.params.id);
  if (!pedido) return res.status(404).json({ erro: 'Pedido não encontrado' });
  if (pedido.cliente_id !== req.usuario.id && req.usuario.tipo === 'cliente_pf') {
    return res.status(403).json({ erro: 'Sem acesso a este pedido' });
  }
  res.json(pedido);
});

// POST /pedidos
router.post('/', async (req, res) => {
  const {
    cidade = 'Sao Paulo', categoriaId, nivelServico = 'padrao',
    tipoRetirada = 'imediata', agendadoPara,
    modalidade = 'entrega', horasContratadas,
    paradas = [], carga = {}, servicos = [],
    formaPagamento, pagador = 'remetente',
    favoritosPrimeiro = false, exigeComprovante = true,
    observacaoMotorista, contatoTelefone, cupom,
    aceiteItensProibidos = false,
  } = req.body || {};

  // --- validacoes (regras RN01, RN02, RN04, RN10) ---
  if (!categoriaId) return res.status(400).json({ erro: 'Selecione o veículo' });
  if (paradas.length < 2) return res.status(400).json({ erro: 'Informe coleta e entrega' });
  if (!formaPagamento) return res.status(400).json({ erro: 'Selecione a forma de pagamento' });
  if (!aceiteItensProibidos) return res.status(400).json({ erro: 'É necessário aceitar a política de itens proibidos' });
  if (tipoRetirada === 'agendada' && !agendadoPara) {
    return res.status(400).json({ erro: 'Informe a data e hora do agendamento' });
  }
  if (tipoRetirada === 'agendada' && new Date(agendadoPara) <= new Date()) {
    return res.status(400).json({ erro: 'O agendamento deve ser no futuro' });
  }

  const categoria = await one('SELECT * FROM categoria_veiculo WHERE id = ?', [categoriaId]);
  if (!categoria) return res.status(404).json({ erro: 'Categoria não encontrada' });

  const PESO_FAIXA = { ate_50: 50, ate_300: 300, de_300_a_750: 750, acima_750: 3500 };
  const pesoEstimado = PESO_FAIXA[carga.faixaPeso] || 0;
  if (pesoEstimado > categoria.peso_max_kg) {
    return res.status(422).json({
      erro: 'Peso declarado acima da capacidade do veículo',
      capacidadeKg: categoria.peso_max_kg,
      sugestao: 'Selecione uma categoria maior',
    });
  }

  const preco = await one(
    `SELECT * FROM tabela_preco WHERE cidade = ? AND categoria_id = ? AND nivel_servico = ? AND ativo = 1
      ORDER BY vigente_desde DESC LIMIT 1`,
    [cidade, categoriaId, nivelServico]
  );
  if (!preco) return res.status(404).json({ erro: 'Sem tabela de preço para esta combinação' });

  const km = distanciaRota(paradas);
  const valorFrete = calcularFrete({
    preco, km, paradas: paradas.length,
    horas: modalidade === 'periodo' ? horasContratadas : null,
  });

  let valorAdicionais = 0;
  let listaServicos = [];
  if (servicos.length) {
    const marcadores = servicos.map(() => '?').join(',');
    listaServicos = await query(
      `SELECT id, preco FROM servico_adicional WHERE id IN (${marcadores}) AND ativo = 1`, servicos);
    valorAdicionais = listaServicos.reduce((s, x) => s + Number(x.preco), 0);
  }

  let registroCupom = null;
  if (cupom) {
    registroCupom = await one(
      'SELECT * FROM cupom WHERE codigo = ? AND ativo = 1 AND (valido_ate IS NULL OR valido_ate >= CURDATE())',
      [String(cupom).toUpperCase()]);
  }
  const desconto = aplicarCupom(valorFrete, registroCupom);
  const valorTotal = Math.round((valorFrete + valorAdicionais - desconto) * 100) / 100;

  const pedidoId = await transacao(async (conn) => {
    const [seq] = await conn.execute('SELECT COALESCE(MAX(id),0)+1 AS proximo FROM pedido');
    const codigo = 'SF-' + String(seq[0].proximo).padStart(6, '0');

    const [p] = await conn.execute(
      `INSERT INTO pedido (codigo, cliente_id, empresa_id, categoria_id, nivel_servico, tipo_retirada,
                           agendado_para, modalidade, horas_contratadas, situacao, distancia_km,
                           valor_frete, valor_adicionais, valor_desconto, valor_total,
                           forma_pagamento, pagador, favoritos_primeiro, exige_comprovante,
                           observacao_motorista, contato_telefone, aceite_itens_proibidos)
       VALUES (?,?,?,?,?,?,?,?,?,'aguardando_alocacao',?,?,?,?,?,?,?,?,?,?,?,1)`,
      [codigo, req.usuario.id, null, categoriaId, nivelServico, tipoRetirada,
       tipoRetirada === 'agendada' ? agendadoPara.replace('T', ' ').slice(0, 19) : null,
       modalidade, modalidade === 'periodo' ? horasContratadas : null,
       km, valorFrete, valorAdicionais, desconto, valorTotal,
       formaPagamento, pagador, favoritosPrimeiro ? 1 : 0, exigeComprovante ? 1 : 0,
       observacaoMotorista || null, contatoTelefone || null]
    );
    const id = p.insertId;

    let sequencia = 1;
    for (const parada of paradas) {
      await conn.execute(
        `INSERT INTO pedido_parada (pedido_id, sequencia, tipo, endereco_id, logradouro, numero,
                                    complemento, referencia, cidade, uf, latitude, longitude,
                                    contato_nome, contato_telefone)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        [id, sequencia++, parada.tipo || (sequencia === 2 ? 'coleta' : 'entrega'),
         parada.enderecoId || null, parada.logradouro, parada.numero || null,
         parada.complemento || null, parada.referencia || null,
         parada.cidade || cidade, parada.uf || 'SP',
         parada.latitude ?? null, parada.longitude ?? null,
         parada.contatoNome || null, parada.contatoTelefone || null]
      );
    }

    await conn.execute(
      `INSERT INTO pedido_carga (pedido_id, tipo_item, volumes, faixa_peso,
                                 instrucao_fragil, instrucao_nao_empilhar, instrucao_refrigerado, observacoes)
       VALUES (?,?,?,?,?,?,?,?)`,
      [id, carga.tipoItem || 'outros', carga.volumes || 1, carga.faixaPeso || 'ate_50',
       carga.fragil ? 1 : 0, carga.naoEmpilhar ? 1 : 0, carga.refrigerado ? 1 : 0,
       carga.observacoes || null]
    );

    for (const s of listaServicos) {
      await conn.execute('INSERT INTO pedido_servico (pedido_id, servico_id, preco) VALUES (?,?,?)',
        [id, s.id, s.preco]);
    }

    if (registroCupom && desconto > 0) {
      await conn.execute(
        'INSERT INTO cupom_uso (cupom_id, cliente_id, pedido_id, valor_aplicado) VALUES (?,?,?,?)',
        [registroCupom.id, req.usuario.id, id, desconto]);
    }

    await conn.execute(
      'INSERT INTO pedido_evento (pedido_id, situacao, descricao, autor_id) VALUES (?,?,?,?)',
      [id, 'cotado', 'Pedido criado e cotado', req.usuario.id]);

    // --- alocacao (RF35, RF37): oferta primeiro aos favoritos, depois base geral ---
    const repasse = repasseParceiro(valorTotal);
    let rodada = 'geral';
    let ofertados = [];

    if (favoritosPrimeiro) {
      const [favs] = await conn.execute(
        `SELECT m.id FROM motorista_favorito f
           JOIN motorista m ON m.id = f.motorista_id
           JOIN veiculo v ON v.motorista_id = m.id AND v.categoria_id = ? AND v.ativo = 1
          WHERE f.cliente_id = ? AND m.situacao_homologacao = 'aprovada'
            AND m.disponivel = 1 AND m.cnh_validade >= CURDATE()`,
        [categoriaId, req.usuario.id]);
      if (favs.length) { rodada = 'favoritos'; ofertados = favs; }
    }

    if (!ofertados.length) {
      const [gerais] = await conn.execute(
        `SELECT m.id FROM motorista m
           JOIN veiculo v ON v.motorista_id = m.id AND v.categoria_id = ? AND v.ativo = 1
          WHERE m.situacao_homologacao = 'aprovada' AND m.disponivel = 1
            AND m.cnh_validade >= CURDATE()
          LIMIT 10`,
        [categoriaId]);
      ofertados = gerais;
    }

    for (const m of ofertados) {
      await conn.execute(
        'INSERT INTO oferta (pedido_id, motorista_id, rodada, situacao, valor_repasse) VALUES (?,?,?,"enviada",?)',
        [id, m.id, rodada, repasse]);
    }

    await conn.execute(
      'INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES (?,?,?)',
      [id, 'aguardando_alocacao',
       rodada === 'favoritos'
         ? `Ofertado aos seus motoristas favoritos (${ofertados.length})`
         : `Ofertado a ${ofertados.length} parceiro(s) da base`]);

    await conn.execute(
      `INSERT INTO notificacao (usuario_id, categoria, titulo, mensagem, pedido_id)
       VALUES (?, 'operacional', 'Pedido criado', ?, ?)`,
      [req.usuario.id, `Estamos buscando um parceiro para o pedido ${codigo}.`, id]);

    return id;
  });

  res.status(201).json(await carregarPedido(pedidoId));
});

// POST /pedidos/:id/avancar  -> simula a evolucao do pedido no prototipo
const FLUXO = ['aguardando_alocacao', 'alocado', 'em_deslocamento_coleta', 'carregando', 'em_transito', 'entregue', 'concluido'];
// Mesmos rotulos que o app mostra (app/lib/core/formato.dart, rotuloSituacao)
const ROTULOS_ETAPA = {
  aguardando_alocacao: 'Buscando parceiro',
  alocado: 'Parceiro confirmado',
  em_deslocamento_coleta: 'A caminho da coleta',
  carregando: 'Carregando',
  em_transito: 'Em trânsito',
  entregue: 'Entregue',
  concluido: 'Concluído',
};
router.post('/:id/avancar', async (req, res) => {
  const pedido = await one('SELECT * FROM pedido WHERE id = ?', [req.params.id]);
  if (!pedido) return res.status(404).json({ erro: 'Pedido não encontrado' });
  if (pedido.situacao === 'cancelado' || pedido.situacao === 'concluido') {
    return res.status(409).json({ erro: 'Pedido finalizado' });
  }
  const atual = FLUXO.indexOf(pedido.situacao);
  const proxima = FLUXO[atual + 1];
  if (!proxima) return res.status(409).json({ erro: 'Não há próxima etapa' });

  await transacao(async (conn) => {
    if (proxima === 'alocado') {
      const [oferta] = await conn.execute(
        'SELECT motorista_id FROM oferta WHERE pedido_id = ? AND situacao = "enviada" LIMIT 1',
        [pedido.id]);
      if (oferta.length) {
        const [veic] = await conn.execute(
          'SELECT id FROM veiculo WHERE motorista_id = ? AND categoria_id = ? LIMIT 1',
          [oferta[0].motorista_id, pedido.categoria_id]);
        await conn.execute(
          'UPDATE oferta SET situacao = "aceita", respondida_em = NOW() WHERE pedido_id = ? AND motorista_id = ?',
          [pedido.id, oferta[0].motorista_id]);
        await conn.execute(
          'UPDATE pedido SET motorista_id = ?, veiculo_id = ? WHERE id = ?',
          [oferta[0].motorista_id, veic.length ? veic[0].id : null, pedido.id]);
      }
    }
    if (proxima === 'em_transito') {
      await conn.execute(
        'UPDATE pedido_parada SET situacao = "concluida", concluida_em = NOW() WHERE pedido_id = ? AND tipo = "coleta"',
        [pedido.id]);
    }
    if (proxima === 'entregue') {
      await conn.execute(
        'UPDATE pedido_parada SET situacao = "concluida", concluida_em = NOW() WHERE pedido_id = ? AND tipo = "entrega"',
        [pedido.id]);
    }
    const extra = proxima === 'concluido' ? ', concluido_em = NOW()' : '';
    await conn.execute(`UPDATE pedido SET situacao = ?${extra} WHERE id = ?`, [proxima, pedido.id]);
    await conn.execute('INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES (?,?,?)',
      [pedido.id, proxima, 'Atualização de etapa']);
    await conn.execute(
      `INSERT INTO notificacao (usuario_id, categoria, titulo, mensagem, pedido_id)
       VALUES (?, 'operacional', ?, ?, ?)`,
      [pedido.cliente_id, `Pedido ${pedido.codigo}`, `Nova etapa: ${ROTULOS_ETAPA[proxima] || proxima}`, pedido.id]);
  });

  res.json(await carregarPedido(pedido.id));
});

// POST /pedidos/:id/cancelar  (RN06)
router.post('/:id/cancelar', async (req, res) => {
  const pedido = await one('SELECT * FROM pedido WHERE id = ?', [req.params.id]);
  if (!pedido) return res.status(404).json({ erro: 'Pedido não encontrado' });
  if (['em_transito', 'entregue', 'concluido'].includes(pedido.situacao)) {
    return res.status(409).json({ erro: 'Pedido já coletado não pode ser cancelado. Registre uma ocorrência.' });
  }
  const taxa = ['alocado', 'em_deslocamento_coleta', 'carregando'].includes(pedido.situacao)
    ? Math.round(Number(pedido.valor_total) * 0.15 * 100) / 100
    : 0;

  await transacao(async (conn) => {
    await conn.execute(
      'UPDATE pedido SET situacao = "cancelado", cancelado_em = NOW(), motivo_cancelamento = ? WHERE id = ?',
      [req.body?.motivo || 'Cancelado pelo cliente', pedido.id]);
    await conn.execute('UPDATE oferta SET situacao = "expirada" WHERE pedido_id = ? AND situacao = "enviada"',
      [pedido.id]);
    await conn.execute('INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES (?,?,?)',
      [pedido.id, 'cancelado', taxa > 0 ? `Cancelado com taxa de R$ ${taxa.toFixed(2)}` : 'Cancelado sem taxa']);
  });

  res.json({ ok: true, taxaCancelamento: taxa });
});

// POST /pedidos/:id/avaliar  (RF60, RF39)
router.post('/:id/avaliar', async (req, res) => {
  const { nota, comentario, favoritar } = req.body || {};
  if (!nota || nota < 1 || nota > 5) return res.status(400).json({ erro: 'Nota deve ser de 1 a 5' });

  const pedido = await one(
    `SELECT p.*, m.usuario_id AS motorista_usuario_id FROM pedido p
       LEFT JOIN motorista m ON m.id = p.motorista_id WHERE p.id = ?`, [req.params.id]);
  if (!pedido) return res.status(404).json({ erro: 'Pedido não encontrado' });
  if (pedido.situacao !== 'concluido') return res.status(409).json({ erro: 'Avalie apenas pedidos concluídos' });

  await transacao(async (conn) => {
    await conn.execute(
      `INSERT INTO avaliacao (pedido_id, autor_id, avaliado_id, nota, comentario)
       VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE nota = VALUES(nota), comentario = VALUES(comentario)`,
      [pedido.id, req.usuario.id, pedido.motorista_usuario_id, nota, comentario || null]);

    if (pedido.motorista_id) {
      await conn.execute(
        `UPDATE motorista m SET m.avaliacao_media = (
            SELECT ROUND(AVG(a.nota),2) FROM avaliacao a
              JOIN pedido p2 ON p2.id = a.pedido_id WHERE p2.motorista_id = m.id)
          WHERE m.id = ?`, [pedido.motorista_id]);

      if (favoritar) {
        await conn.execute(
          `INSERT IGNORE INTO motorista_favorito (cliente_id, motorista_id, origem)
           VALUES (?,?, 'pos_pedido')`, [req.usuario.id, pedido.motorista_id]);
      }
    }
  });

  res.json({ ok: true, favoritado: !!favoritar });
});

module.exports = router;
