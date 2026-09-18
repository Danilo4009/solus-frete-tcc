const express = require('express');
const { query, one } = require('../db');
const { autenticar } = require('../auth');

const router = express.Router();
router.use(autenticar);

// GET /perfil
router.get('/', async (req, res) => {
  const usuario = await one(
    `SELECT id, tipo, nome, sobrenome, telefone, telefone_verificado, email, foto_url, setor_atuacao, criado_em
       FROM usuario WHERE id = ?`, [req.usuario.id]);
  const empresa = await one(
    `SELECT e.id, e.tipo, e.cnpj, e.razao_social, e.nome_fantasia, eu.papel, eu.limite_mensal
       FROM empresa_usuario eu JOIN empresa e ON e.id = eu.empresa_id
      WHERE eu.usuario_id = ? LIMIT 1`, [req.usuario.id]);
  res.json({ ...usuario, empresa });
});

// PUT /perfil
router.put('/', async (req, res) => {
  const { nome, sobrenome, email, setor } = req.body || {};
  await query(
    'UPDATE usuario SET nome = COALESCE(?,nome), sobrenome = ?, email = ?, setor_atuacao = ? WHERE id = ?',
    [nome || null, sobrenome || null, email || null, setor || null, req.usuario.id]);
  res.json({ ok: true });
});

// GET /perfil/carteira
router.get('/carteira', async (req, res) => {
  let carteira = await one('SELECT * FROM carteira WHERE usuario_id = ?', [req.usuario.id]);
  if (!carteira) {
    await query('INSERT INTO carteira (usuario_id, saldo) VALUES (?, 0)', [req.usuario.id]);
    carteira = await one('SELECT * FROM carteira WHERE usuario_id = ?', [req.usuario.id]);
  }
  const transacoes = await query(
    'SELECT tipo, valor, descricao, criada_em FROM transacao_carteira WHERE carteira_id = ? ORDER BY criada_em DESC LIMIT 30',
    [carteira.id]);
  const cupons = await query(
    `SELECT codigo, descricao, tipo_desconto, valor, valor_minimo_pedido, valido_ate
       FROM cupom WHERE ativo = 1 AND (valido_ate IS NULL OR valido_ate >= CURDATE())`);
  res.json({ saldo: Number(carteira.saldo), transacoes, cupons });
});

// POST /perfil/carteira/recarga
router.post('/carteira/recarga', async (req, res) => {
  const valor = Number(req.body?.valor || 0);
  if (valor <= 0) return res.status(400).json({ erro: 'Valor invalido' });
  const carteira = await one('SELECT * FROM carteira WHERE usuario_id = ?', [req.usuario.id]);
  if (!carteira) return res.status(404).json({ erro: 'Carteira nao encontrada' });
  await query('UPDATE carteira SET saldo = saldo + ? WHERE id = ?', [valor, carteira.id]);
  await query(
    'INSERT INTO transacao_carteira (carteira_id, tipo, valor, descricao) VALUES (?,"recarga",?,?)',
    [carteira.id, valor, `Recarga de R$ ${valor.toFixed(2)}`]);
  res.json({ ok: true, saldo: Number(carteira.saldo) + valor });
});

// GET /perfil/favoritos
router.get('/favoritos', async (req, res) => {
  const rows = await query(
    `SELECT m.id AS motorista_id, u.nome, u.sobrenome, u.telefone, m.avaliacao_media, m.total_corridas,
            m.disponivel, f.origem, f.criado_em,
            GROUP_CONCAT(DISTINCT cv.nome) AS veiculos
       FROM motorista_favorito f
       JOIN motorista m ON m.id = f.motorista_id
       JOIN usuario u ON u.id = m.usuario_id
       LEFT JOIN veiculo v ON v.motorista_id = m.id
       LEFT JOIN categoria_veiculo cv ON cv.id = v.categoria_id
      WHERE f.cliente_id = ?
      GROUP BY m.id, f.origem, f.criado_em
      ORDER BY m.avaliacao_media DESC`,
    [req.usuario.id]);
  res.json(rows);
});

// POST /perfil/favoritos/convite  (RF38)
router.post('/favoritos/convite', async (req, res) => {
  const { telefone, nome } = req.body || {};
  if (!telefone) return res.status(400).json({ erro: 'Informe o telefone do motorista' });
  const tel = String(telefone).replace(/\D/g, '');

  const existente = await one(
    `SELECT m.id FROM usuario u JOIN motorista m ON m.usuario_id = u.id
      WHERE u.telefone = ? AND m.situacao_homologacao = 'aprovada'`, [tel]);

  if (existente) {
    await query(
      'INSERT IGNORE INTO motorista_favorito (cliente_id, motorista_id, origem) VALUES (?,?,"convite")',
      [req.usuario.id, existente.id]);
    return res.json({ vinculado: true, mensagem: 'Motorista ja e parceiro Solus e foi adicionado aos seus favoritos.' });
  }

  await query('INSERT INTO convite_motorista (cliente_id, telefone, nome) VALUES (?,?,?)',
    [req.usuario.id, tel, nome || null]);
  res.status(201).json({
    vinculado: false,
    mensagem: 'Convite enviado por SMS. Assim que ele concluir o cadastro e for homologado, entra nos seus favoritos.',
  });
});

// DELETE /perfil/favoritos/:motoristaId
router.delete('/favoritos/:motoristaId', async (req, res) => {
  await query('DELETE FROM motorista_favorito WHERE cliente_id = ? AND motorista_id = ?',
    [req.usuario.id, req.params.motoristaId]);
  res.status(204).end();
});

// GET /perfil/notificacoes
router.get('/notificacoes', async (req, res) => {
  const rows = await query(
    `SELECT id, categoria, titulo, mensagem, pedido_id, lida, criada_em
       FROM notificacao WHERE usuario_id = ? ORDER BY criada_em DESC LIMIT 50`,
    [req.usuario.id]);
  res.json({
    operacionais: rows.filter((r) => r.categoria === 'operacional'),
    promocionais: rows.filter((r) => r.categoria === 'promocional'),
    naoLidas: rows.filter((r) => !r.lida).length,
  });
});

// PATCH /perfil/notificacoes/:id/lida
router.patch('/notificacoes/:id/lida', async (req, res) => {
  await query('UPDATE notificacao SET lida = 1 WHERE id = ? AND usuario_id = ?',
    [req.params.id, req.usuario.id]);
  res.json({ ok: true });
});

module.exports = router;
