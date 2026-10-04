// Rodar com: npm test   (usa o test runner nativo do Node, sem dependencias)
const test = require('node:test');
const assert = require('node:assert/strict');
const { validarCarga, verificarCompatibilidade } = require('../src/compatibilidade');

const utilitario = {
  peso_max_kg: 650, comprimento_m: 1.9, largura_m: 1.3, altura_m: 1.2,
  aceita_refrigerada: 0, aceita_perigosa: 0,
};
const toco = {
  peso_max_kg: 6000, comprimento_m: 7.0, largura_m: 2.4, altura_m: 2.6,
  aceita_refrigerada: 1, aceita_perigosa: 1,
};

const carga = (extra = {}) => ({
  tipoCarga: 'caixas_pacotes', pesoKg: 100, comprimentoCm: 100, larguraCm: 50, alturaCm: 50, volumes: 1,
  ...extra,
});

test('carga valida nao tem erros', () => {
  assert.deepEqual(validarCarga(carga()), []);
});

test('rejeita zero, negativo, texto e tipo desconhecido', () => {
  assert.ok(validarCarga(carga({ pesoKg: 0 })).length);
  assert.ok(validarCarga(carga({ pesoKg: -5 })).length);
  assert.ok(validarCarga(carga({ comprimentoCm: '100' })).length);
  assert.ok(validarCarga(carga({ alturaCm: 0 })).length);
  assert.ok(validarCarga(carga({ volumes: 0 })).length);
  assert.ok(validarCarga(carga({ tipoCarga: 'outros' })).length);
  assert.ok(validarCarga({}).length >= 5);
});

test('peso acima da capacidade', () => {
  const r = verificarCompatibilidade(carga({ pesoKg: 700 }), utilitario);
  assert.equal(r.compativel, false);
  assert.equal(r.motivo, 'Excede a capacidade de 650 kg');
});

test('peso exatamente na capacidade e aceito', () => {
  assert.equal(verificarCompatibilidade(carga({ pesoKg: 650 }), utilitario).compativel, true);
});

test('capacidade com milhar usa ponto', () => {
  const r = verificarCompatibilidade(carga({ pesoKg: 7000 }), toco);
  assert.equal(r.motivo, 'Excede a capacidade de 6.000 kg');
});

test('maior volume que nao cabe no bau', () => {
  const r = verificarCompatibilidade(carga({ comprimentoCm: 250 }), utilitario);
  assert.equal(r.compativel, false);
  assert.match(r.motivo, /nao cabe no bau de 190 x 130 x 120 cm/);
});

test('o volume pode ser girado para caber', () => {
  // 120 x 100 x 190 nao cabe na orientacao original (190 x 130 x 120), mas cabe girado
  const r = verificarCompatibilidade(
    carga({ comprimentoCm: 120, larguraCm: 100, alturaCm: 190 }), utilitario);
  assert.equal(r.compativel, true);
});

test('tipo refrigerada e perigosa so em veiculo habilitado', () => {
  assert.equal(
    verificarCompatibilidade(carga({ tipoCarga: 'refrigerada' }), utilitario).motivo,
    'Nao comporta carga refrigerada');
  assert.equal(
    verificarCompatibilidade(carga({ tipoCarga: 'perigosa' }), utilitario).motivo,
    'Nao comporta carga perigosa');
  assert.equal(verificarCompatibilidade(carga({ tipoCarga: 'refrigerada' }), toco).compativel, true);
  assert.equal(verificarCompatibilidade(carga({ tipoCarga: 'perigosa' }), toco).compativel, true);
});

test('o peso e checado antes das dimensoes', () => {
  const r = verificarCompatibilidade(carga({ pesoKg: 9000, comprimentoCm: 900 }), utilitario);
  assert.match(r.motivo, /^Excede a capacidade/);
});
