// Monta as ofertas de parceiros de uma cotacao.
// Regra: ate 10 opcoes = 4 motoristas autonomos + 6 transportadoras que atendem a regiao
// da coleta. Se faltar de um tipo, completa com o outro.
//   motorista autonomo -> preco da tabela_preco da plataforma (nivel padrao)
//   transportadora     -> preco proprio (transportadora_preco)

const { query, one } = require('./db');
const {
  distanciaKm, distanciaRota, calcularFrete, aplicarCupom, FATOR_ROTA,
} = require('./precificacao');
const { erroHttp } = require('./http');

const TOTAL_OFERTAS = 10;
const VAGAS_MOTORISTAS = 4;
const VELOCIDADE_MEDIA_KMH = 30;
const MINUTOS_MANUSEIO = 15;

const arredondar = (v, casas = 2) => Math.round(v * 10 ** casas) / 10 ** casas;
const minutos = (km) => Math.round((km / VELOCIDADE_MEDIA_KMH) * 60);
const temCoordenada = (p) => p && p.latitude != null && p.longitude != null;

// favoritos primeiro, depois avaliados (maior nota), depois o mais proximo
function ordenar(a, b) {
  return (Number(b.favorito) - Number(a.favorito))
    || (Number(b.nota > 0) - Number(a.nota > 0))
    || (b.nota - a.nota)
    || (a.distanciaColetaKm - b.distanciaColetaKm);
}

function selecionar(motoristas, transportadoras) {
  const vagasTransp = TOTAL_OFERTAS - VAGAS_MOTORISTAS;
  const escolhidos = [
    ...motoristas.slice(0, VAGAS_MOTORISTAS),
    ...transportadoras.slice(0, vagasTransp),
  ];
  if (escolhidos.length < TOTAL_OFERTAS) {
    const sobras = [...motoristas.slice(VAGAS_MOTORISTAS), ...transportadoras.slice(vagasTransp)]
      .sort(ordenar);
    escolhidos.push(...sobras.slice(0, TOTAL_OFERTAS - escolhidos.length));
  }
  return escolhidos.sort((a, b) => a.total - b.total);
}

// Campos internos (veiculoId) nao saem na resposta publica.
function publica(o) {
  const { veiculoId, ...resto } = o;
  return resto;
}

// excluir: lista de { tipo, id } de parceiros que ja recusaram este pedido
async function montarCotacao({
  cidade = 'Sao Paulo', categoriaId, paradas = [], servicos = [], horas, cupom,
  clienteId, excluir = [],
}) {
  if (!categoriaId) throw erroHttp(400, 'Informe a categoria do veículo');
  if (paradas.length < 2) throw erroHttp(400, 'Informe ao menos uma coleta e uma entrega');

  const categoria = await one('SELECT * FROM categoria_veiculo WHERE id = ? AND ativo = 1', [categoriaId]);
  if (!categoria) throw erroHttp(404, 'Categoria não encontrada');

  const precoPlataforma = await one(
    `SELECT * FROM tabela_preco
      WHERE cidade = ? AND categoria_id = ? AND nivel_servico = 'padrao' AND ativo = 1
      ORDER BY vigente_desde DESC LIMIT 1`,
    [cidade, categoriaId]
  );
  if (!precoPlataforma) throw erroHttp(404, 'Sem tabela de preço para esta cidade e veículo');

  const km = distanciaRota(paradas);
  const coleta = paradas[0];

  let listaServicos = [];
  if (servicos.length) {
    const marcadores = servicos.map(() => '?').join(',');
    listaServicos = await query(
      `SELECT id, codigo, nome, preco FROM servico_adicional WHERE id IN (${marcadores}) AND ativo = 1`,
      servicos
    );
  }
  const valorAdicionais = listaServicos.reduce((soma, s) => soma + Number(s.preco), 0);

  let registroCupom = null;
  if (cupom) {
    registroCupom = await one(
      'SELECT * FROM cupom WHERE codigo = ? AND ativo = 1 AND (valido_ate IS NULL OR valido_ate >= CURDATE())',
      [String(cupom).toUpperCase()]
    );
  }

  const bloqueados = new Set(excluir.map((e) => `${e.tipo}-${e.id}`));
  const favoritos = new Set();
  if (clienteId) {
    const linhas = await query('SELECT motorista_id FROM motorista_favorito WHERE cliente_id = ?', [clienteId]);
    linhas.forEach((l) => favoritos.add(l.motorista_id));
  }

  // distancia (por estrada) do parceiro ate a coleta; sem coordenadas, nao restringe
  const distanciaAteColeta = (p) => (temCoordenada(coleta) && temCoordenada(p)
    ? distanciaKm(
        { latitude: Number(p.latitude), longitude: Number(p.longitude) },
        { latitude: Number(coleta.latitude), longitude: Number(coleta.longitude) }
      ) * FATOR_ROTA
    : 0);

  function oferta({ tipo, id, nome, nota, totalFretes, favorito, veiculo, veiculoId, distColeta, preco }) {
    const valorFrete = calcularFrete({ preco, km, paradas: paradas.length, horas });
    const desconto = aplicarCupom(valorFrete, registroCupom);
    const chegadaColetaMin = minutos(distColeta);
    return {
      chave: `${tipo}-${id}`,
      parceiroTipo: tipo,
      parceiroId: id,
      nome,
      nota: Number(nota),
      totalFretes: Number(totalFretes),
      favorito,
      veiculo,
      veiculoId,
      distanciaColetaKm: arredondar(distColeta, 1),
      chegadaColetaMin,
      prazoEntregaMin: chegadaColetaMin + minutos(km) + MINUTOS_MANUSEIO,
      valorFrete,
      valorAdicionais,
      desconto,
      total: arredondar(valorFrete + valorAdicionais - desconto),
    };
  }

  // --- motoristas autonomos ---
  const linhasMotoristas = await query(
    `SELECT m.id, u.nome, u.sobrenome, m.latitude, m.longitude, m.raio_atuacao_km,
            m.avaliacao_media, m.total_corridas,
            v.id AS veiculo_id, v.marca, v.modelo
       FROM motorista m
       JOIN usuario u ON u.id = m.usuario_id
       JOIN veiculo v ON v.motorista_id = m.id AND v.categoria_id = ? AND v.ativo = 1
                     AND v.situacao_homologacao = 'aprovada'
      WHERE m.transportadora_id IS NULL AND m.situacao_homologacao = 'aprovada'
        AND m.disponivel = 1 AND m.cnh_validade >= CURDATE()
      ORDER BY m.id, v.id`,
    [categoriaId]
  );
  const vistos = new Set();
  const motoristas = [];
  for (const m of linhasMotoristas) {
    if (vistos.has(m.id) || bloqueados.has(`motorista-${m.id}`)) continue;
    vistos.add(m.id);
    const dist = distanciaAteColeta(m);
    if (dist > m.raio_atuacao_km) continue;
    motoristas.push(oferta({
      tipo: 'motorista', id: m.id,
      nome: `${m.nome} ${m.sobrenome || ''}`.trim(),
      nota: m.avaliacao_media, totalFretes: m.total_corridas,
      favorito: favoritos.has(m.id),
      veiculo: `${m.marca || ''} ${m.modelo || ''}`.trim() || categoria.nome,
      veiculoId: m.veiculo_id, distColeta: dist, preco: precoPlataforma,
    }));
  }

  // --- transportadoras ---
  const linhasTransp = await query(
    `SELECT e.id, COALESCE(e.nome_fantasia, e.razao_social) AS nome, e.latitude, e.longitude,
            e.raio_atuacao_km, e.avaliacao_media, e.total_fretes,
            tp.tarifa_base, tp.valor_por_km, tp.valor_por_parada, tp.valor_hora, tp.valor_minimo,
            v.id AS veiculo_id, v.marca, v.modelo
       FROM empresa e
       JOIN transportadora_preco tp ON tp.empresa_id = e.id AND tp.categoria_id = ? AND tp.ativo = 1
       JOIN veiculo v ON v.transportadora_id = e.id AND v.categoria_id = ? AND v.ativo = 1
                     AND v.situacao_homologacao = 'aprovada'
      WHERE e.tipo = 'transportadora' AND e.situacao_homologacao = 'aprovada'
      ORDER BY e.id, v.id`,
    [categoriaId, categoriaId]
  );
  const vistas = new Set();
  const transportadoras = [];
  for (const t of linhasTransp) {
    if (vistas.has(t.id) || bloqueados.has(`transportadora-${t.id}`)) continue;
    vistas.add(t.id);
    const dist = distanciaAteColeta(t);
    if (dist > t.raio_atuacao_km) continue;
    transportadoras.push(oferta({
      tipo: 'transportadora', id: t.id, nome: t.nome,
      nota: t.avaliacao_media, totalFretes: t.total_fretes, favorito: false,
      veiculo: `${t.marca || ''} ${t.modelo || ''}`.trim() || categoria.nome,
      veiculoId: t.veiculo_id, distColeta: dist, preco: t,
    }));
  }

  motoristas.sort(ordenar);
  transportadoras.sort(ordenar);

  return {
    contexto: {
      cidade, distanciaKm: km, paradas: paradas.length, categoria,
      servicos: listaServicos, cupom: registroCupom,
    },
    motoristas,
    transportadoras,
    ofertas: selecionar(motoristas, transportadoras),
  };
}

// Corpo da resposta de POST /cotacao e GET /pedidos/:id/cotacao
function respostaCotacao({ contexto, ofertas }) {
  const { categoria } = contexto;
  return {
    cidade: contexto.cidade,
    distanciaKm: contexto.distanciaKm,
    paradas: contexto.paradas,
    categoria: {
      id: categoria.id, codigo: categoria.codigo, nome: categoria.nome,
      pesoMaxKg: categoria.peso_max_kg,
      dimensoes: `${categoria.comprimento_m} x ${categoria.largura_m} x ${categoria.altura_m} m`,
    },
    servicos: contexto.servicos,
    cupom: contexto.cupom
      ? { codigo: contexto.cupom.codigo, descricao: contexto.cupom.descricao }
      : null,
    ofertas: ofertas.map(publica),
    avisos: [
      'Pedagio e estacionamento nao estao inclusos e sao acertados direto com o parceiro.',
      'O peso declarado nao pode exceder a capacidade do veiculo escolhido.',
    ],
  };
}

module.exports = { montarCotacao, respostaCotacao, TOTAL_OFERTAS, VAGAS_MOTORISTAS };
