const express = require('express');
const { query, one, transacao } = require('../db');
const { autenticar } = require('../auth');
const { repasseParceiro } = require('../precificacao');
const { erroHttp, rota } = require('../http');
const { montarCotacao, respostaCotacao } = require('../ofertas');

const router = express.Router();
router.use(autenticar);

const EM_ANDAMENTO = ['cotado', 'aguardando_alocacao', 'alocado', 'em_deslocamento_coleta', 'carregando', 'em_transito', 'entregue'];

// No prototipo o parceiro escolhido aceita sozinho depois deste tempo.
const ACEITE_AUTOMATICO_SEGUNDOS = Number(process.env.ACEITE_AUTOMATICO_SEGUNDOS || 8);

async function carregarPedido(id) {
  const pedido = await one(
    `SELECT p.*, cv.nome AS categoria_nome, cv.codigo AS categoria_codigo,
            cv.peso_max_kg, mu.nome AS motorista_nome, mu.telefone AS motorista_telefone,
            m.avaliacao_media AS motorista_avaliacao, v.placa AS veiculo_placa,
            v.marca AS veiculo_marca, v.modelo AS veiculo_modelo,
            e.nome_fantasia AS transportadora_nome,
            e.avaliacao_media AS transportadora_avaliacao
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

async function nomeParceiro({ motorista_id: motoristaId, transportadora_id: transportadoraId }) {
  if (motoristaId) {
    const m = await one(
      `SELECT CONCAT(u.nome, ' ', COALESCE(u.sobrenome, '')) AS nome
         FROM motorista m JOIN usuario u ON u.id = m.usuario_id WHERE m.id = ?`, [motoristaId]);
    return m.nome.trim();
  }
  const e = await one('SELECT COALESCE(nome_fantasia, razao_social) AS nome FROM empresa WHERE id = ?', [transportadoraId]);
  return e.nome;
}

async function notificar(conn, usuarioId, pedidoId, titulo, mensagem) {
  await conn.execute(
    `INSERT INTO notificacao (usuario_id, categoria, titulo, mensagem, pedido_id)
     VALUES (?, 'operacional', ?, ?, ?)`,
    [usuarioId, titulo, mensagem, pedidoId]);
}

// Envia o pedido a um unico parceiro (o escolhido pelo cliente) e aguarda o aceite.
async function ofertarAoParceiro(conn, pedido, escolhido, valorTotal) {
  await conn.execute(
    `INSERT INTO oferta (pedido_id, motorista_id, transportadora_id, rodada, situacao, valor_repasse)
     VALUES (?,?,?,'geral','enviada',?)`,
    [pedido.id,
     escolhido.parceiroTipo === 'motorista' ? escolhido.parceiroId : null,
     escolhido.parceiroTipo === 'transportadora' ? escolhido.parceiroId : null,
     repasseParceiro(valorTotal)]);
  await conn.execute(
    'INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES (?,?,?)',
    [pedido.id, 'aguardando_alocacao', `Aguardando aceite de ${escolhido.nome}`]);
  await notificar(conn, pedido.cliente_id, pedido.id, 'Pedido criado',
    `Enviamos o pedido ${pedido.codigo} para ${escolhido.nome}. Aguarde o aceite.`);
}

// O parceiro aceitou: o pedido passa a 'alocado' (parceiro e veiculo ja estao no pedido).
async function aceitarOferta(conn, pedido, oferta) {
  const [r] = await conn.execute(
    'UPDATE oferta SET situacao = "aceita", respondida_em = NOW() WHERE id = ? AND situacao = "enviada"',
    [oferta.id]);
  if (r.affectedRows !== 1) return false;
  const nome = await nomeParceiro(oferta);
  await conn.execute('UPDATE pedido SET situacao = "alocado" WHERE id = ?', [pedido.id]);
  await conn.execute('INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES (?,?,?)',
    [pedido.id, 'alocado', `${nome} aceitou o pedido`]);
  await notificar(conn, pedido.cliente_id, pedido.id, `Pedido ${pedido.codigo}`, `${nome} aceitou o seu pedido.`);
  return true;
}

// Simula o aceite do parceiro depois de alguns segundos, quando o pedido e consultado.
async function aceiteAutomatico(pedidoId) {
  const pendente = await one(
    `SELECT o.*, p.codigo, p.cliente_id FROM oferta o JOIN pedido p ON p.id = o.pedido_id
      WHERE o.pedido_id = ? AND o.situacao = 'enviada' AND p.situacao = 'aguardando_alocacao'
        AND TIMESTAMPDIFF(SECOND, o.enviada_em, NOW()) >= ?
      LIMIT 1`,
    [pedidoId, ACEITE_AUTOMATICO_SEGUNDOS]);
  if (!pendente) return;
  await transacao((conn) => aceitarOferta(conn, { id: pedidoId, codigo: pendente.codigo, cliente_id: pendente.cliente_id }, pendente));
}

// Dados para refazer a cotacao de um pedido que voltou a 'cotado' (parceiro recusou).
async function contextoDeCotacao(pedidoId, usuarioId) {
  const pedido = await one('SELECT * FROM pedido WHERE id = ? AND cliente_id = ?', [pedidoId, usuarioId]);
  if (!pedido) throw erroHttp(404, 'Pedido nao encontrado');
  if (pedido.situacao !== 'cotado') throw erroHttp(409, 'Este pedido nao esta aguardando a escolha de um parceiro');

  const paradas = await query(
    'SELECT tipo, latitude, longitude FROM pedido_parada WHERE pedido_id = ? ORDER BY sequencia', [pedidoId]);
  const servicos = (await query('SELECT servico_id FROM pedido_servico WHERE pedido_id = ?', [pedidoId]))
    .map((s) => s.servico_id);
  const cupom = await one(
    'SELECT c.codigo FROM cupom_uso u JOIN cupom c ON c.id = u.cupom_id WHERE u.pedido_id = ? LIMIT 1', [pedidoId]);
  const recusas = await query(
    "SELECT motorista_id, transportadora_id FROM oferta WHERE pedido_id = ? AND situacao = 'recusada'", [pedidoId]);

  return {
    pedido,
    entrada: {
      categoriaId: pedido.categoria_id,
      paradas: paradas.map((p) => ({
        tipo: p.tipo,
        latitude: p.latitude == null ? null : Number(p.latitude),
        longitude: p.longitude == null ? null : Number(p.longitude),
      })),
      servicos,
      horas: pedido.modalidade === 'periodo' ? pedido.horas_contratadas : null,
      cupom: cupom ? cupom.codigo : null,
      clienteId: usuarioId,
      excluir: recusas.map((o) => (o.motorista_id
        ? { tipo: 'motorista', id: o.motorista_id }
        : { tipo: 'transportadora', id: o.transportadora_id })),
    },
  };
}

function localizarEscolhido(resultado, parceiroTipo, parceiroId) {
  const escolhido = [...resultado.motoristas, ...resultado.transportadoras]
    .find((o) => o.parceiroTipo === parceiroTipo && o.parceiroId === Number(parceiroId));
  if (!escolhido) throw erroHttp(422, 'Este parceiro nao esta mais disponivel. Escolha outra opcao.');
  return escolhido;
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
            COALESCE(mu.nome, e.nome_fantasia) AS motorista_nome,
            (SELECT CONCAT(logradouro, ', ', COALESCE(numero,'s/n')) FROM pedido_parada
              WHERE pedido_id = p.id AND tipo='coleta' ORDER BY sequencia LIMIT 1) AS origem,
            (SELECT CONCAT(logradouro, ', ', COALESCE(numero,'s/n')) FROM pedido_parada
              WHERE pedido_id = p.id AND tipo='entrega' ORDER BY sequencia DESC LIMIT 1) AS destino,
            (SELECT COUNT(*) FROM pedido_parada WHERE pedido_id = p.id) AS total_paradas
       FROM pedido p
       JOIN categoria_veiculo cv ON cv.id = p.categoria_id
       LEFT JOIN motorista m ON m.id = p.motorista_id
       LEFT JOIN usuario mu ON mu.id = m.usuario_id
       LEFT JOIN empresa e ON e.id = p.transportadora_id
      WHERE p.cliente_id = ? AND ${filtro}${busca}
      ORDER BY p.criado_em DESC`,
    params
  );
  res.json(rows);
});

// GET /pedidos/:id
router.get('/:id', rota(async (req, res) => {
  await aceiteAutomatico(req.params.id);
  const pedido = await carregarPedido(req.params.id);
  if (!pedido) return res.status(404).json({ erro: 'Pedido nao encontrado' });
  if (pedido.cliente_id !== req.usuario.id && req.usuario.tipo === 'cliente_pf') {
    return res.status(403).json({ erro: 'Sem acesso a este pedido' });
  }
  res.json(pedido);
}));

// GET /pedidos/:id/cotacao  -> novas opcoes de parceiro para um pedido que voltou a 'cotado'
router.get('/:id/cotacao', rota(async (req, res) => {
  const { entrada } = await contextoDeCotacao(req.params.id, req.usuario.id);
  res.json(respostaCotacao(await montarCotacao(entrada)));
}));

// POST /pedidos
router.post('/', rota(async (req, res) => {
  const {
    cidade = 'Sao Paulo', categoriaId, parceiroTipo, parceiroId,
    tipoRetirada = 'imediata', agendadoPara,
    modalidade = 'entrega', horasContratadas,
    paradas = [], carga = {}, servicos = [],
    formaPagamento, pagador = 'remetente',
    exigeComprovante = true,
    observacaoMotorista, contatoTelefone, cupom,
    aceiteItensProibidos = false,
  } = req.body || {};

  // --- validacoes (regras RN01, RN02, RN04, RN10) ---
  if (!categoriaId) throw erroHttp(400, 'Selecione o veiculo');
  if (paradas.length < 2) throw erroHttp(400, 'Informe coleta e entrega');
  if (!parceiroTipo || !parceiroId) throw erroHttp(400, 'Escolha um parceiro');
  if (!formaPagamento) throw erroHttp(400, 'Selecione a forma de pagamento');
  if (!aceiteItensProibidos) throw erroHttp(400, 'E necessario aceitar a politica de itens proibidos');
  if (tipoRetirada === 'agendada' && !agendadoPara) {
    throw erroHttp(400, 'Informe a data e hora do agendamento');
  }
  if (tipoRetirada === 'agendada' && new Date(agendadoPara) <= new Date()) {
    throw erroHttp(400, 'O agendamento deve ser no futuro');
  }

  const categoria = await one('SELECT * FROM categoria_veiculo WHERE id = ?', [categoriaId]);
  if (!categoria) throw erroHttp(404, 'Categoria nao encontrada');

  const PESO_FAIXA = { ate_50: 50, ate_300: 300, de_300_a_750: 750, acima_750: 3500 };
  const pesoEstimado = PESO_FAIXA[carga.faixaPeso] || 0;
  if (pesoEstimado > categoria.peso_max_kg) {
    return res.status(422).json({
      erro: 'Peso declarado acima da capacidade do veiculo',
      capacidadeKg: categoria.peso_max_kg,
      sugestao: 'Selecione uma categoria maior',
    });
  }

  // o preco vem sempre do servidor: recalcula a oferta do parceiro escolhido
  const resultado = await montarCotacao({
    cidade, categoriaId, paradas, servicos,
    horas: modalidade === 'periodo' ? horasContratadas : null,
    cupom, clienteId: req.usuario.id,
  });
  const escolhido = localizarEscolhido(resultado, parceiroTipo, parceiroId);
  const { distanciaKm: km, servicos: listaServicos, cupom: registroCupom } = resultado.contexto;
  const { valorFrete, valorAdicionais, desconto, total: valorTotal } = escolhido;

  const pedidoId = await transacao(async (conn) => {
    const [seq] = await conn.execute('SELECT COALESCE(MAX(id),0)+1 AS proximo FROM pedido');
    const codigo = 'SF-' + String(seq[0].proximo).padStart(6, '0');

    const [p] = await conn.execute(
      `INSERT INTO pedido (codigo, cliente_id, empresa_id, categoria_id, nivel_servico, tipo_retirada,
                           agendado_para, modalidade, horas_contratadas, situacao, distancia_km,
                           valor_frete, valor_adicionais, valor_desconto, valor_total,
                           forma_pagamento, pagador, favoritos_primeiro, exige_comprovante,
                           observacao_motorista, contato_telefone, aceite_itens_proibidos,
                           motorista_id, transportadora_id, veiculo_id)
       VALUES (?,?,?,?,'padrao',?,?,?,?,'aguardando_alocacao',?,?,?,?,?,?,?,0,?,?,?,1,?,?,?)`,
      [codigo, req.usuario.id, null, categoriaId, tipoRetirada,
       tipoRetirada === 'agendada' ? agendadoPara.replace('T', ' ').slice(0, 19) : null,
       modalidade, modalidade === 'periodo' ? horasContratadas : null,
       km, valorFrete, valorAdicionais, desconto, valorTotal,
       formaPagamento, pagador, exigeComprovante ? 1 : 0,
       observacaoMotorista || null, contatoTelefone || null,
       escolhido.parceiroTipo === 'motorista' ? escolhido.parceiroId : null,
       escolhido.parceiroTipo === 'transportadora' ? escolhido.parceiroId : null,
       escolhido.veiculoId]
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
      [id, 'cotado', `Pedido criado com ${escolhido.nome}`, req.usuario.id]);

    // --- alocacao: o pedido vai apenas ao parceiro escolhido pelo cliente ---
    await ofertarAoParceiro(conn, { id, codigo, cliente_id: req.usuario.id }, escolhido, valorTotal);

    return id;
  });

  res.status(201).json(await carregarPedido(pedidoId));
}));

// POST /pedidos/:id/recusar-parceiro  -> simula a recusa do parceiro (so no prototipo)
router.post('/:id/recusar-parceiro', rota(async (req, res) => {
  const pedido = await one('SELECT * FROM pedido WHERE id = ? AND cliente_id = ?', [req.params.id, req.usuario.id]);
  if (!pedido) throw erroHttp(404, 'Pedido nao encontrado');
  const oferta = await one("SELECT * FROM oferta WHERE pedido_id = ? AND situacao = 'enviada' LIMIT 1", [pedido.id]);
  if (pedido.situacao !== 'aguardando_alocacao' || !oferta) {
    throw erroHttp(409, 'So e possivel simular a recusa enquanto o parceiro ainda nao aceitou');
  }
  const nome = await nomeParceiro(oferta);

  await transacao(async (conn) => {
    await conn.execute('UPDATE oferta SET situacao = "recusada", respondida_em = NOW() WHERE id = ?', [oferta.id]);
    await conn.execute(
      'UPDATE pedido SET situacao = "cotado", motorista_id = NULL, transportadora_id = NULL, veiculo_id = NULL WHERE id = ?',
      [pedido.id]);
    await conn.execute('INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES (?,?,?)',
      [pedido.id, 'cotado', `${nome} recusou o pedido. Escolha outro parceiro.`]);
    await notificar(conn, pedido.cliente_id, pedido.id, `Pedido ${pedido.codigo}`,
      `${nome} nao pode atender. Escolha outro parceiro para continuar.`);
  });

  res.json(await carregarPedido(pedido.id));
}));

// POST /pedidos/:id/parceiro  -> escolhe outro parceiro depois de uma recusa
router.post('/:id/parceiro', rota(async (req, res) => {
  const { parceiroTipo, parceiroId } = req.body || {};
  if (!parceiroTipo || !parceiroId) throw erroHttp(400, 'Escolha um parceiro');

  const { pedido, entrada } = await contextoDeCotacao(req.params.id, req.usuario.id);
  const escolhido = localizarEscolhido(await montarCotacao(entrada), parceiroTipo, parceiroId);

  await transacao(async (conn) => {
    await conn.execute(
      `UPDATE pedido SET situacao = 'aguardando_alocacao', motorista_id = ?, transportadora_id = ?,
                         veiculo_id = ?, valor_frete = ?, valor_adicionais = ?, valor_desconto = ?,
                         valor_total = ?
        WHERE id = ?`,
      [escolhido.parceiroTipo === 'motorista' ? escolhido.parceiroId : null,
       escolhido.parceiroTipo === 'transportadora' ? escolhido.parceiroId : null,
       escolhido.veiculoId, escolhido.valorFrete, escolhido.valorAdicionais, escolhido.desconto,
       escolhido.total, pedido.id]);
    await ofertarAoParceiro(conn, pedido, escolhido, escolhido.total);
  });

  res.json(await carregarPedido(pedido.id));
}));

// POST /pedidos/:id/avancar  -> simula a evolucao do pedido no prototipo
const FLUXO = ['aguardando_alocacao', 'alocado', 'em_deslocamento_coleta', 'carregando', 'em_transito', 'entregue', 'concluido'];
router.post('/:id/avancar', rota(async (req, res) => {
  const pedido = await one('SELECT * FROM pedido WHERE id = ?', [req.params.id]);
  if (!pedido) return res.status(404).json({ erro: 'Pedido nao encontrado' });
  if (pedido.situacao === 'cancelado' || pedido.situacao === 'concluido') {
    return res.status(409).json({ erro: 'Pedido finalizado' });
  }
  if (pedido.situacao === 'cotado') {
    return res.status(409).json({ erro: 'Escolha um parceiro antes de avancar o pedido' });
  }
  const atual = FLUXO.indexOf(pedido.situacao);
  const proxima = FLUXO[atual + 1];
  if (!proxima) return res.status(409).json({ erro: 'Nao ha proxima etapa' });

  await transacao(async (conn) => {
    if (proxima === 'alocado') {
      const [ofertas] = await conn.execute(
        'SELECT * FROM oferta WHERE pedido_id = ? AND situacao = "enviada" LIMIT 1', [pedido.id]);
      if (ofertas.length) {
        await aceitarOferta(conn, pedido, ofertas[0]);
        return;
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
      [pedido.id, proxima, 'Atualizacao de etapa']);
    await notificar(conn, pedido.cliente_id, pedido.id, `Pedido ${pedido.codigo}`,
      `Nova etapa: ${proxima.replace(/_/g, ' ')}`);
  });

  res.json(await carregarPedido(pedido.id));
}));

// POST /pedidos/:id/cancelar  (RN06)
router.post('/:id/cancelar', async (req, res) => {
  const pedido = await one('SELECT * FROM pedido WHERE id = ?', [req.params.id]);
  if (!pedido) return res.status(404).json({ erro: 'Pedido nao encontrado' });
  if (['em_transito', 'entregue', 'concluido'].includes(pedido.situacao)) {
    return res.status(409).json({ erro: 'Pedido ja coletado nao pode ser cancelado. Registre uma ocorrencia.' });
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
  if (!pedido) return res.status(404).json({ erro: 'Pedido nao encontrado' });
  if (pedido.situacao !== 'concluido') return res.status(409).json({ erro: 'Avalie apenas pedidos concluidos' });

  await transacao(async (conn) => {
    // avaliado e o motorista; quando o frete foi feito por transportadora, a propria empresa
    await conn.execute(
      `INSERT INTO avaliacao (pedido_id, autor_id, avaliado_id, empresa_id, nota, comentario)
       VALUES (?,?,?,?,?,?) ON DUPLICATE KEY UPDATE nota = VALUES(nota), comentario = VALUES(comentario)`,
      [pedido.id, req.usuario.id, pedido.motorista_usuario_id || null,
       pedido.motorista_id ? null : pedido.transportadora_id, nota, comentario || null]);

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
    } else if (pedido.transportadora_id) {
      await conn.execute(
        `UPDATE empresa e SET e.avaliacao_media = (
            SELECT ROUND(AVG(a.nota),2) FROM avaliacao a WHERE a.empresa_id = e.id)
          WHERE e.id = ?`, [pedido.transportadora_id]);
    }
  });

  res.json({ ok: true, favoritado: !!favoritar && !!pedido.motorista_id });
});

module.exports = router;
