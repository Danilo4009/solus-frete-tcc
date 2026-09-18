const express = require('express');
const { query } = require('../db');

const router = express.Router();

// GET /catalogo/veiculos?cidade=Sao Paulo
router.get('/veiculos', async (req, res) => {
  const cidade = req.query.cidade || 'Sao Paulo';
  const veiculos = await query(
    `SELECT c.id, c.codigo, c.nome, c.descricao, c.comprimento_m, c.largura_m, c.altura_m,
            c.peso_max_kg, c.ordem,
            MAX(CASE WHEN p.nivel_servico='padrao'    THEN p.tarifa_base END)  AS tarifa_base,
            MAX(CASE WHEN p.nivel_servico='padrao'    THEN p.valor_por_km END) AS valor_por_km,
            MAX(CASE WHEN p.nivel_servico='padrao'    THEN p.valor_minimo END) AS valor_minimo,
            MAX(CASE WHEN p.nivel_servico='padrao'    THEN p.valor_hora END)   AS valor_hora
       FROM categoria_veiculo c
       JOIN tabela_preco p ON p.categoria_id = c.id AND p.cidade = ? AND p.ativo = 1
      WHERE c.ativo = 1
      GROUP BY c.id
      ORDER BY c.ordem`,
    [cidade]
  );

  const servicos = await query(
    `SELECT cs.categoria_id, s.id, s.codigo, s.nome, s.descricao, s.preco
       FROM categoria_servico cs
       JOIN servico_adicional s ON s.id = cs.servico_id AND s.ativo = 1`
  );

  res.json(
    veiculos.map((v) => ({
      ...v,
      servicos: servicos
        .filter((s) => s.categoria_id === v.id)
        .map(({ categoria_id, ...s }) => s),
    }))
  );
});

// GET /catalogo/cidades
router.get('/cidades', async (_req, res) => {
  const rows = await query(
    'SELECT DISTINCT cidade, uf FROM tabela_preco WHERE ativo = 1 ORDER BY cidade'
  );
  res.json(rows);
});

// GET /catalogo/servicos
router.get('/servicos', async (_req, res) => {
  res.json(await query('SELECT id, codigo, nome, descricao, preco FROM servico_adicional WHERE ativo = 1'));
});

module.exports = router;
