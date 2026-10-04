const express = require('express');
const bcrypt = require('bcryptjs');
const { query, one, transacao } = require('../db');
const { gerarToken } = require('../auth');

const router = express.Router();

// POST /auth/login
router.post('/login', async (req, res) => {
  const { telefone, senha } = req.body || {};
  if (!telefone || !senha) return res.status(400).json({ erro: 'Informe telefone e senha' });

  const usuario = await one(
    'SELECT id, tipo, nome, sobrenome, telefone, email, senha_hash, situacao FROM usuario WHERE telefone = ?',
    [String(telefone).replace(/\D/g, '')]
  );
  if (!usuario) return res.status(401).json({ erro: 'Usuário não encontrado' });
  if (usuario.situacao !== 'ativo') return res.status(403).json({ erro: 'Conta inativa' });

  const ok = usuario.senha_hash ? await bcrypt.compare(senha, usuario.senha_hash) : false;
  if (!ok) return res.status(401).json({ erro: 'Senha incorreta' });

  delete usuario.senha_hash;
  res.json({ token: gerarToken(usuario), usuario });
});

// POST /auth/registro/cliente
router.post('/registro/cliente', async (req, res) => {
  const { nome, sobrenome, telefone, email, senha, setor } = req.body || {};
  if (!nome || !telefone || !senha) {
    return res.status(400).json({ erro: 'Nome, telefone e senha são obrigatórios' });
  }
  const tel = String(telefone).replace(/\D/g, '');
  const existe = await one('SELECT id FROM usuario WHERE telefone = ?', [tel]);
  if (existe) return res.status(409).json({ erro: 'Telefone já cadastrado' });

  const hash = await bcrypt.hash(senha, 10);
  const usuario = await transacao(async (conn) => {
    const [r] = await conn.execute(
      `INSERT INTO usuario (tipo, nome, sobrenome, telefone, telefone_verificado, email, senha_hash, setor_atuacao)
       VALUES ('cliente_pf', ?, ?, ?, 1, ?, ?, ?)`,
      [nome, sobrenome || null, tel, email || null, hash, setor || null]
    );
    await conn.execute('INSERT INTO carteira (usuario_id, saldo) VALUES (?, 0)', [r.insertId]);
    return { id: r.insertId, tipo: 'cliente_pf', nome, sobrenome, telefone: tel, email };
  });

  res.status(201).json({ token: gerarToken(usuario), usuario });
});

// POST /auth/registro/motorista
router.post('/registro/motorista', async (req, res) => {
  const {
    nome, sobrenome, telefone, email, senha,
    cpf, cnhNumero, cnhCategoria, cnhValidade,
    veiculo, // { categoriaCodigo, placa, marca, modelo, ano, documentoValidade }
  } = req.body || {};

  if (!nome || !telefone || !senha || !cpf || !cnhNumero || !cnhValidade) {
    return res.status(400).json({ erro: 'Dados obrigatórios do motorista incompletos' });
  }
  if (!veiculo || !veiculo.categoriaCodigo || !veiculo.placa) {
    return res.status(400).json({ erro: 'Informe a categoria e a placa do veículo' });
  }

  const tel = String(telefone).replace(/\D/g, '');
  if (await one('SELECT id FROM usuario WHERE telefone = ?', [tel])) {
    return res.status(409).json({ erro: 'Telefone já cadastrado' });
  }
  const categoria = await one('SELECT id FROM categoria_veiculo WHERE codigo = ?', [veiculo.categoriaCodigo]);
  if (!categoria) return res.status(400).json({ erro: 'Categoria de veículo inválida' });

  const hash = await bcrypt.hash(senha, 10);
  const resultado = await transacao(async (conn) => {
    const [u] = await conn.execute(
      `INSERT INTO usuario (tipo, nome, sobrenome, telefone, telefone_verificado, email, senha_hash)
       VALUES ('motorista', ?, ?, ?, 1, ?, ?)`,
      [nome, sobrenome || null, tel, email || null, hash]
    );
    const [m] = await conn.execute(
      `INSERT INTO motorista (usuario_id, cpf, cnh_numero, cnh_categoria, cnh_validade, situacao_homologacao)
       VALUES (?, ?, ?, ?, ?, 'pendente')`,
      [u.insertId, cpf, cnhNumero, cnhCategoria || 'B', cnhValidade]
    );
    await conn.execute(
      `INSERT INTO veiculo (motorista_id, categoria_id, placa, marca, modelo, ano, documento_validade, situacao_homologacao)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pendente')`,
      [m.insertId, categoria.id, String(veiculo.placa).toUpperCase(),
       veiculo.marca || null, veiculo.modelo || null, veiculo.ano || null,
       veiculo.documentoValidade || null]
    );
    await conn.execute(
      `INSERT INTO notificacao (usuario_id, categoria, titulo, mensagem)
       VALUES (?, 'operacional', 'Cadastro em análise',
               'Recebemos seus documentos. Assim que a homologação for concluída você começa a receber ofertas.')`,
      [u.insertId]
    );
    return { usuarioId: u.insertId, motoristaId: m.insertId };
  });

  res.status(201).json({
    ...resultado,
    situacao: 'pendente',
    mensagem: 'Cadastro enviado para homologação da operação Solus.',
  });
});

// POST /auth/registro/transportadora
router.post('/registro/transportadora', async (req, res) => {
  const {
    cnpj, razaoSocial, nomeFantasia, registroAntt,
    cidade, uf, telefoneEmpresa, emailEmpresa,
    responsavel, // { nome, sobrenome, telefone, email, senha }
  } = req.body || {};

  if (!cnpj || !razaoSocial || !responsavel || !responsavel.nome || !responsavel.telefone || !responsavel.senha) {
    return res.status(400).json({ erro: 'Dados obrigatórios da transportadora incompletos' });
  }
  if (await one('SELECT id FROM empresa WHERE cnpj = ?', [cnpj])) {
    return res.status(409).json({ erro: 'CNPJ já cadastrado' });
  }
  const tel = String(responsavel.telefone).replace(/\D/g, '');
  if (await one('SELECT id FROM usuario WHERE telefone = ?', [tel])) {
    return res.status(409).json({ erro: 'Telefone do responsável já cadastrado' });
  }

  const hash = await bcrypt.hash(responsavel.senha, 10);
  const resultado = await transacao(async (conn) => {
    const [u] = await conn.execute(
      `INSERT INTO usuario (tipo, nome, sobrenome, telefone, telefone_verificado, email, senha_hash)
       VALUES ('transportadora', ?, ?, ?, 1, ?, ?)`,
      [responsavel.nome, responsavel.sobrenome || null, tel, responsavel.email || null, hash]
    );
    const [e] = await conn.execute(
      `INSERT INTO empresa (tipo, cnpj, razao_social, nome_fantasia, registro_antt,
                            responsavel_usuario_id, telefone, email, cidade, uf, situacao_homologacao)
       VALUES ('transportadora', ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pendente')`,
      [cnpj, razaoSocial, nomeFantasia || null, registroAntt || null, u.insertId,
       telefoneEmpresa || null, emailEmpresa || null, cidade || null, uf || null]
    );
    await conn.execute('INSERT INTO empresa_usuario (empresa_id, usuario_id, papel) VALUES (?, ?, "gestor")',
      [e.insertId, u.insertId]);
    return { usuarioId: u.insertId, empresaId: e.insertId };
  });

  res.status(201).json({
    ...resultado,
    situacao: 'pendente',
    mensagem: 'Transportadora enviada para homologação. Você poderá cadastrar a frota após a aprovação.',
  });
});

module.exports = router;
