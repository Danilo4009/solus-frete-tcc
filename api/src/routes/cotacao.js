const express = require('express');
const { autenticarOpcional } = require('../auth');
const { rota } = require('../http');
const { montarCotacao, respostaCotacao } = require('../ofertas');

const router = express.Router();
router.use(autenticarOpcional);

// POST /cotacao
// body: { cidade, categoriaId, paradas:[{latitude,longitude,tipo}], servicos:[id], horas, cupom }
// resposta: ate 10 ofertas (4 motoristas autonomos + 6 transportadoras da regiao da coleta)
router.post('/', rota(async (req, res) => {
  const { cidade, categoriaId, paradas, servicos, horas, cupom } = req.body || {};
  const resultado = await montarCotacao({
    cidade, categoriaId, paradas, servicos, horas, cupom, clienteId: req.usuario?.id,
  });
  res.json(respostaCotacao(resultado));
}));

module.exports = router;
