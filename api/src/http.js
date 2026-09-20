// Erro com status HTTP e wrapper para handlers async (Express 4 nao captura rejeicoes).
function erroHttp(status, mensagem) {
  return Object.assign(new Error(mensagem), { status });
}

const rota = (fn) => (req, res, next) => fn(req, res, next).catch(next);

module.exports = { erroHttp, rota };
