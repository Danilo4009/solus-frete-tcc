require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { pool } = require('./db');

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.use((req, _res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.originalUrl}`);
  next();
});

app.get('/health', async (_req, res) => {
  try {
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();
    res.json({ status: 'ok', banco: 'conectado' });
  } catch (erro) {
    res.status(503).json({ status: 'erro', banco: 'indisponivel', detalhe: erro.message });
  }
});

app.use('/auth',      require('./routes/auth'));
app.use('/catalogo',  require('./routes/catalogo'));
app.use('/cotacao',   require('./routes/cotacao'));
app.use('/enderecos', require('./routes/enderecos'));
app.use('/pedidos',   require('./routes/pedidos'));
app.use('/perfil',    require('./routes/perfil'));

app.use((_req, res) => res.status(404).json({ erro: 'Rota não encontrada' }));

app.use((erro, _req, res, _next) => {
  if (erro.status) return res.status(erro.status).json({ erro: erro.message });
  console.error(erro);
  res.status(500).json({ erro: 'Erro interno', detalhe: erro.message });
});

const porta = Number(process.env.PORT || 3333);
app.listen(porta, () => console.log(`Solus Frete API ouvindo em http://localhost:${porta}`));
