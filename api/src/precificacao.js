// Motor de precificacao do Solus Frete.
// Regra: (tarifa_base + valor_por_km * km + valor_por_parada * paradas_extras)
//        respeitando o valor minimo da categoria, mais servicos adicionais.

const RAIO_TERRA_KM = 6371;
const FATOR_ROTA = 1.35; // distancia rodoviaria estimada sobre a linha reta

function distanciaKm(a, b) {
  const rad = (g) => (g * Math.PI) / 180;
  const dLat = rad(b.latitude - a.latitude);
  const dLon = rad(b.longitude - a.longitude);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.latitude)) * Math.cos(rad(b.latitude)) * Math.sin(dLon / 2) ** 2;
  return 2 * RAIO_TERRA_KM * Math.asin(Math.sqrt(h));
}

function distanciaRota(paradas) {
  let total = 0;
  for (let i = 1; i < paradas.length; i++) {
    const a = paradas[i - 1];
    const b = paradas[i];
    if (
      a.latitude == null || a.longitude == null ||
      b.latitude == null || b.longitude == null
    ) continue;
    total += distanciaKm(a, b);
  }
  return Math.round(total * FATOR_ROTA * 100) / 100;
}

function calcularFrete({ preco, km, paradas, horas }) {
  let base;
  if (horas && preco.valor_hora) {
    base = Number(preco.valor_hora) * horas;
  } else {
    const paradasExtras = Math.max(0, paradas - 2);
    base =
      Number(preco.tarifa_base) +
      Number(preco.valor_por_km) * km +
      Number(preco.valor_por_parada) * paradasExtras;
  }
  const valor = Math.max(base, Number(preco.valor_minimo));
  return Math.round(valor * 100) / 100;
}

function aplicarCupom(valorFrete, cupom) {
  if (!cupom) return 0;
  if (valorFrete < Number(cupom.valor_minimo_pedido)) return 0;
  const desconto =
    cupom.tipo_desconto === 'percentual'
      ? (valorFrete * Number(cupom.valor)) / 100
      : Number(cupom.valor);
  return Math.round(Math.min(desconto, valorFrete) * 100) / 100;
}

function repasseParceiro(valorTotal) {
  const comissao = Number(process.env.COMISSAO_PLATAFORMA || 0.2);
  return Math.round(valorTotal * (1 - comissao) * 100) / 100;
}

module.exports = {
  distanciaKm, distanciaRota, calcularFrete, aplicarCupom, repasseParceiro, FATOR_ROTA,
};
