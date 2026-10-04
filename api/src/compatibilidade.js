// Regra de compatibilidade entre a carga e a categoria de veiculo, e validacao dos
// campos da carga. Funcoes puras (sem banco), para serem testadas isoladas.
// Espelha app/lib/core/compatibilidade.dart: se a regra mudar aqui, mude la tambem.

const TIPOS_CARGA = ['caixas_pacotes', 'paletizada', 'granel', 'fragil', 'refrigerada', 'perigosa'];

const milhar = (n) => String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
const cm = (v) => Number(Number(v).toFixed(1)).toString().replace('.', ',');
const metrosParaCm = (m) => Number((Number(m) * 100).toFixed(1));

const positivo = (v) => typeof v === 'number' && Number.isFinite(v) && v > 0;

// Devolve a lista de mensagens de erro (vazia = carga valida).
function validarCarga(carga) {
  const c = carga || {};
  const erros = [];
  if (!TIPOS_CARGA.includes(c.tipoCarga)) erros.push('Selecione o tipo de carga');
  if (!positivo(c.pesoKg)) erros.push('Informe o peso total em kg (maior que zero)');
  if (!positivo(c.comprimentoCm)) erros.push('Informe o comprimento do maior volume em cm (maior que zero)');
  if (!positivo(c.larguraCm)) erros.push('Informe a largura do maior volume em cm (maior que zero)');
  if (!positivo(c.alturaCm)) erros.push('Informe a altura do maior volume em cm (maior que zero)');
  if (!Number.isInteger(c.volumes) || c.volumes < 1) erros.push('Informe a quantidade de volumes (minimo 1)');
  return erros;
}

// veiculo: linha de categoria_veiculo (peso_max_kg, comprimento_m, largura_m, altura_m,
// aceita_refrigerada, aceita_perigosa). Retorna { compativel, motivo }.
// O maior volume pode ser girado: compara os lados ordenados do maior para o menor.
function verificarCompatibilidade(carga, veiculo) {
  const capacidade = Number(veiculo.peso_max_kg);
  if (carga.pesoKg > capacidade) {
    return { compativel: false, motivo: `Excede a capacidade de ${milhar(capacidade)} kg` };
  }

  const bau = [veiculo.comprimento_m, veiculo.largura_m, veiculo.altura_m].map(metrosParaCm);
  const volume = [carga.comprimentoCm, carga.larguraCm, carga.alturaCm];
  const ordem = (a, b) => b - a;
  const bauOrdenado = [...bau].sort(ordem);
  const volumeOrdenado = [...volume].sort(ordem);
  if (volumeOrdenado.some((lado, i) => lado > bauOrdenado[i])) {
    return {
      compativel: false,
      motivo: `O maior volume (${volume.map(cm).join(' x ')} cm) nao cabe no bau de ${bau.map(cm).join(' x ')} cm`,
    };
  }

  if (carga.tipoCarga === 'refrigerada' && !Number(veiculo.aceita_refrigerada)) {
    return { compativel: false, motivo: 'Nao comporta carga refrigerada' };
  }
  if (carga.tipoCarga === 'perigosa' && !Number(veiculo.aceita_perigosa)) {
    return { compativel: false, motivo: 'Nao comporta carga perigosa' };
  }

  return { compativel: true, motivo: null };
}

module.exports = { TIPOS_CARGA, validarCarga, verificarCompatibilidade };
