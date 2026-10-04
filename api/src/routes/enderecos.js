const express = require('express');
const { query, one } = require('../db');
const { autenticar } = require('../auth');

const router = express.Router();
router.use(autenticar);

// GET /enderecos  -> favoritos e recentes
router.get('/', async (req, res) => {
  const favoritos = await query(
    `SELECT * FROM endereco WHERE usuario_id = ? AND favorito = 1 ORDER BY apelido`,
    [req.usuario.id]
  );
  const recentes = await query(
    `SELECT * FROM endereco WHERE usuario_id = ? AND favorito = 0 AND usado_em IS NOT NULL
      ORDER BY usado_em DESC LIMIT 10`,
    [req.usuario.id]
  );
  res.json({ favoritos, recentes });
});

// GET /enderecos/busca?q=
// Busca nos enderecos do usuario. Em producao, delegar ao provedor de geocodificacao.
router.get('/busca', async (req, res) => {
  const termo = `%${(req.query.q || '').trim()}%`;
  const rows = await query(
    `SELECT * FROM endereco
      WHERE usuario_id = ? AND (logradouro LIKE ? OR bairro LIKE ? OR apelido LIKE ?)
      ORDER BY favorito DESC, usado_em DESC LIMIT 15`,
    [req.usuario.id, termo, termo, termo]
  );
  res.json(rows);
});

// POST /enderecos
router.post('/', async (req, res) => {
  const {
    apelido, logradouro, numero, complemento, referencia, bairro,
    cidade, uf, cep, latitude, longitude, contatoNome, contatoTelefone, favorito,
  } = req.body || {};

  if (!logradouro || !cidade || !uf) {
    return res.status(400).json({ erro: 'Logradouro, cidade e UF são obrigatórios' });
  }

  const rows = await query(
    `INSERT INTO endereco (usuario_id, apelido, logradouro, numero, complemento, referencia, bairro,
                           cidade, uf, cep, latitude, longitude, contato_nome, contato_telefone, favorito, usado_em)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW())`,
    [req.usuario.id, apelido || null, logradouro, numero || null, complemento || null,
     referencia || null, bairro || null, cidade, uf, cep || null,
     latitude ?? null, longitude ?? null, contatoNome || null, contatoTelefone || null,
     favorito ? 1 : 0]
  );
  const novo = await one('SELECT * FROM endereco WHERE id = ?', [rows.insertId]);
  res.status(201).json(novo);
});

// PATCH /enderecos/:id/favorito
router.patch('/:id/favorito', async (req, res) => {
  await query('UPDATE endereco SET favorito = ? WHERE id = ? AND usuario_id = ?',
    [req.body?.favorito ? 1 : 0, req.params.id, req.usuario.id]);
  res.json({ ok: true });
});

// DELETE /enderecos/:id
router.delete('/:id', async (req, res) => {
  await query('DELETE FROM endereco WHERE id = ? AND usuario_id = ?', [req.params.id, req.usuario.id]);
  res.status(204).end();
});

module.exports = router;
