const express = require('express');
const { query, one } = require('../db');
const { distanciaRota, calcularFrete, aplicarCupom } = require('../precificacao');

const router = express.Router();

const NIVEIS = ['expresso', 'padrao', 'economico'];
const ROTULOS = {
  expresso:  { nome: 'Expresso',  descricao: 'Alocacao prioritaria para entregas urgentes.' },
  padrao:    { nome: 'Padrao',    descricao: 'Equilibrio entre prazo e preco.' },
  economico: { nome: 'Economico', descricao: 'Carga agrupada, sem urgencia. Mais barato.' },
};

// POST /cotacao
// body: { cidade, categoriaId, paradas:[{latitude,longitude,tipo}], servicos:[id], horas, cupom }
router.post('/', async (req, res) => {
  const { cidade = 'Sao Paulo', categoriaId, paradas = [], servicos = [], horas, cupom } = req.body || {};

  if (!categoriaId) return res.status(400).json({ erro: 'Informe a categoria do veiculo' });
  if (paradas.length < 2) return res.status(400).json({ erro: 'Informe ao menos uma coleta e uma entrega' });

  const categoria = await one('SELECT * FROM categoria_veiculo WHERE id = ? AND ativo = 1', [categoriaId]);
  if (!categoria) return res.status(404).json({ erro: 'Categoria nao encontrada' });

  const precos = await query(
    `SELECT * FROM tabela_preco
      WHERE cidade = ? AND categoria_id = ? AND ativo = 1
      ORDER BY vigente_desde DESC`,
    [cidade, categoriaId]
  );
  if (!precos.length) return res.status(404).json({ erro: 'Sem tabela de preco para esta cidade e veiculo' });

  const km = distanciaRota(paradas);

  let valorAdicionais = 0;
  let listaServicos = [];
  if (servicos.length) {
    const marcadores = servicos.map(() => '?').join(',');
    listaServicos = await query(
      `SELECT id, codigo, nome, preco FROM servico_adicional WHERE id IN (${marcadores}) AND ativo = 1`,
      servicos
    );
    valorAdicionais = listaServicos.reduce((soma, s) => soma + Number(s.preco), 0);
  }

  let registroCupom = null;
  if (cupom) {
    registroCupom = await one(
      'SELECT * FROM cupom WHERE codigo = ? AND ativo = 1 AND (valido_ate IS NULL OR valido_ate >= CURDATE())',
      [String(cupom).toUpperCase()]
    );
  }

  const opcoes = NIVEIS.map((nivel) => {
    const preco = precos.find((p) => p.nivel_servico === nivel);
    if (!preco) return null;
    const valorFrete = calcularFrete({ preco, km, paradas: paradas.length, horas });
    const desconto = aplicarCupom(valorFrete, registroCupom);
    const total = Math.round((valorFrete + valorAdicionais - desconto) * 100) / 100;
    return {
      nivel,
      ...ROTULOS[nivel],
      valorFrete,
      valorAdicionais,
      desconto,
      total,
      recomendado: nivel === 'padrao',
    };
  }).filter(Boolean);

  res.json({
    cidade,
    distanciaKm: km,
    paradas: paradas.length,
    categoria: {
      id: categoria.id, codigo: categoria.codigo, nome: categoria.nome,
      pesoMaxKg: categoria.peso_max_kg,
      dimensoes: `${categoria.comprimento_m} x ${categoria.largura_m} x ${categoria.altura_m} m`,
    },
    servicos: listaServicos,
    cupom: registroCupom ? { codigo: registroCupom.codigo, descricao: registroCupom.descricao } : null,
    opcoes,
    avisos: [
      'Pedagio e estacionamento nao estao inclusos e sao acertados direto com o parceiro.',
      'O peso declarado nao pode exceder a capacidade do veiculo escolhido.',
    ],
  });
});

module.exports = router;
