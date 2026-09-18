const jwt = require('jsonwebtoken');

const SEGREDO = process.env.JWT_SECRET || 'solus-dev';

function gerarToken(usuario) {
  return jwt.sign(
    { sub: usuario.id, tipo: usuario.tipo, nome: usuario.nome },
    SEGREDO,
    { expiresIn: '30d' }
  );
}

function autenticar(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ erro: 'Token ausente' });
  try {
    const payload = jwt.verify(token, SEGREDO);
    req.usuario = { id: payload.sub, tipo: payload.tipo, nome: payload.nome };
    next();
  } catch {
    return res.status(401).json({ erro: 'Token invalido ou expirado' });
  }
}

module.exports = { gerarToken, autenticar };
