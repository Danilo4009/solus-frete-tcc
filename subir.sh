#!/usr/bin/env bash
# Sobe o banco (MySQL) e a API do Solus Frete, confirma que subiu de verdade
# e fica monitorando as requisicoes recebidas em tempo real.
# Uso: ./subir.sh   (Ctrl+C para parar tudo)

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/tmp/solus_api.log"

echo "==> Iniciando MySQL..."
brew services start mysql

echo "==> Aguardando o MySQL responder..."
MYSQL_OK=0
for i in $(seq 1 15); do
  if mysqladmin -u root ping >/dev/null 2>&1; then
    MYSQL_OK=1
    break
  fi
  sleep 1
done
if [ "$MYSQL_OK" != "1" ]; then
  echo "    MySQL nao respondeu depois de 15s. Verifique com: brew services list"
  exit 1
fi
echo "    MySQL no ar."

echo "==> Verificando se ja ha algo preso na porta 3333..."
PRESO="$(lsof -ti tcp:3333 2>/dev/null || true)"
if [ -n "$PRESO" ]; then
  echo "    Encerrando processo antigo (PID $PRESO)..."
  kill -9 $PRESO 2>/dev/null || true
  sleep 1
fi

echo "==> Subindo a API..."
cd "$PROJECT_DIR/api"
node src/server.js > "$LOG_FILE" 2>&1 &
API_PID=$!

# Qualquer saida (Ctrl+C, erro ou desistencia) derruba a API junto, sem deixar processo orfao.
limpar() {
  trap - EXIT INT TERM
  if kill -0 "$API_PID" 2>/dev/null; then
    echo
    echo "==> Parando a API..."
    kill "$API_PID" 2>/dev/null || true
    wait "$API_PID" 2>/dev/null || true
    echo "    Parado."
  fi
}
trap limpar EXIT
trap 'exit 0' INT TERM

echo "==> Aguardando a API responder..."
API_OK=0
for i in $(seq 1 20); do
  if curl -s -m 2 http://localhost:3333/health 2>/dev/null | grep -q '"status":"ok"'; then
    API_OK=1
    break
  fi
  if ! kill -0 "$API_PID" 2>/dev/null; then
    echo "    A API caiu ao iniciar. Log:"
    cat "$LOG_FILE"
    exit 1
  fi
  sleep 1
done

if [ "$API_OK" != "1" ]; then
  echo "    A API nao respondeu em 20s. Log:"
  tail -30 "$LOG_FILE"
  case "$PROJECT_DIR" in
    */Documents/*|*/Desktop/*|*"/Mobile Documents/"*)
      echo
      echo "    Dica: esta pasta e sincronizada com o iCloud, que pode esvaziar os arquivos"
      echo "    (node_modules) quando o disco enche e travar o carregamento da API."
      echo "    Rode pela pasta ~/Developer/solus-frete-tcc, que nao e sincronizada."
      ;;
    *)
      echo
      echo "    O banco pode estar indisponivel: confira com  brew services list"
      ;;
  esac
  exit 1
fi

HOST="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
echo "    API no ar e conectada ao banco."
echo
echo "    Neste Mac / simulador:  http://localhost:3333"
echo "    Celular na mesma rede:  http://${HOST}.local:3333"
echo
echo "==> Monitorando (Ctrl+C para parar tudo). Cada linha abaixo e uma requisicao recebida:"
echo
tail -f "$LOG_FILE"
