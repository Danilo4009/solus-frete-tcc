-- =====================================================================
-- SOLUS FRETE - Esquema de banco de dados (MySQL 8)
-- Projeto: TRABALHO SOLUS FRETE (TCC + Gestao de Projetos)
-- Execucao: mysql -u root -p < 01_schema.sql
-- =====================================================================

DROP DATABASE IF EXISTS solus_frete;
CREATE DATABASE solus_frete
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE solus_frete;

-- ---------------------------------------------------------------------
-- 1. IDENTIDADE
-- ---------------------------------------------------------------------

CREATE TABLE usuario (
  id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo                ENUM('cliente_pf','cliente_pj','motorista','transportadora','admin') NOT NULL,
  nome                VARCHAR(120) NOT NULL,
  sobrenome           VARCHAR(120) NULL,
  telefone            VARCHAR(20)  NOT NULL,
  telefone_verificado TINYINT(1)   NOT NULL DEFAULT 0,
  email               VARCHAR(160) NULL,
  senha_hash          VARCHAR(255) NULL,
  foto_url            VARCHAR(500) NULL,
  setor_atuacao       VARCHAR(120) NULL,
  situacao            ENUM('ativo','inativo','bloqueado') NOT NULL DEFAULT 'ativo',
  criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_usuario_telefone (telefone),
  UNIQUE KEY uk_usuario_email (email),
  KEY ix_usuario_tipo (tipo)
) ENGINE=InnoDB;

CREATE TABLE empresa (
  id                    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo                  ENUM('cliente_pj','transportadora') NOT NULL,
  cnpj                  VARCHAR(18)  NOT NULL,
  razao_social          VARCHAR(180) NOT NULL,
  nome_fantasia         VARCHAR(180) NULL,
  registro_antt         VARCHAR(30)  NULL,
  responsavel_usuario_id BIGINT UNSIGNED NULL,
  telefone              VARCHAR(20)  NULL,
  email                 VARCHAR(160) NULL,
  cep                   VARCHAR(9)   NULL,
  logradouro            VARCHAR(180) NULL,
  numero                VARCHAR(20)  NULL,
  complemento           VARCHAR(120) NULL,
  cidade                VARCHAR(120) NULL,
  uf                    CHAR(2)      NULL,
  situacao_homologacao  ENUM('pendente','aprovada','reprovada') NOT NULL DEFAULT 'pendente',
  criado_em             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_empresa_cnpj (cnpj),
  CONSTRAINT fk_empresa_responsavel FOREIGN KEY (responsavel_usuario_id)
    REFERENCES usuario(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- vincula usuarios a uma conta PJ (varios solicitantes na mesma empresa)
CREATE TABLE empresa_usuario (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id   BIGINT UNSIGNED NOT NULL,
  usuario_id   BIGINT UNSIGNED NOT NULL,
  papel        ENUM('gestor','solicitante') NOT NULL DEFAULT 'solicitante',
  limite_mensal DECIMAL(10,2) NULL,
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_empresa_usuario (empresa_id, usuario_id),
  CONSTRAINT fk_eu_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id) ON DELETE CASCADE,
  CONSTRAINT fk_eu_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. FROTA
-- ---------------------------------------------------------------------

CREATE TABLE categoria_veiculo (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo        VARCHAR(40)  NOT NULL,
  nome          VARCHAR(80)  NOT NULL,
  descricao     VARCHAR(255) NULL,
  comprimento_m DECIMAL(5,2) NULL,
  largura_m     DECIMAL(5,2) NULL,
  altura_m      DECIMAL(5,2) NULL,
  peso_max_kg   INT UNSIGNED NOT NULL,
  ordem         INT NOT NULL DEFAULT 0,
  ativo         TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uk_categoria_codigo (codigo)
) ENGINE=InnoDB;

CREATE TABLE motorista (
  id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id          BIGINT UNSIGNED NOT NULL,
  transportadora_id   BIGINT UNSIGNED NULL,  -- NULL = autonomo
  cpf                 VARCHAR(14)  NOT NULL,
  cnh_numero          VARCHAR(20)  NOT NULL,
  cnh_categoria       VARCHAR(5)   NOT NULL,
  cnh_validade        DATE         NOT NULL,
  cnh_arquivo_url     VARCHAR(500) NULL,
  situacao_homologacao ENUM('pendente','aprovada','reprovada') NOT NULL DEFAULT 'pendente',
  disponivel          TINYINT(1) NOT NULL DEFAULT 0,
  latitude            DECIMAL(10,7) NULL,
  longitude           DECIMAL(10,7) NULL,
  avaliacao_media     DECIMAL(3,2) NOT NULL DEFAULT 0,
  total_corridas      INT UNSIGNED NOT NULL DEFAULT 0,
  criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_motorista_usuario (usuario_id),
  UNIQUE KEY uk_motorista_cpf (cpf),
  KEY ix_motorista_disponivel (disponivel),
  CONSTRAINT fk_motorista_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
  CONSTRAINT fk_motorista_transportadora FOREIGN KEY (transportadora_id) REFERENCES empresa(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE veiculo (
  id                   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  motorista_id         BIGINT UNSIGNED NULL,
  transportadora_id    BIGINT UNSIGNED NULL,
  categoria_id         BIGINT UNSIGNED NOT NULL,
  placa                VARCHAR(10)  NOT NULL,
  marca                VARCHAR(60)  NULL,
  modelo               VARCHAR(60)  NULL,
  ano                  SMALLINT UNSIGNED NULL,
  documento_url        VARCHAR(500) NULL,
  documento_validade   DATE NULL,
  situacao_homologacao ENUM('pendente','aprovada','reprovada') NOT NULL DEFAULT 'pendente',
  ativo                TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uk_veiculo_placa (placa),
  CONSTRAINT fk_veiculo_motorista FOREIGN KEY (motorista_id) REFERENCES motorista(id) ON DELETE CASCADE,
  CONSTRAINT fk_veiculo_transportadora FOREIGN KEY (transportadora_id) REFERENCES empresa(id) ON DELETE CASCADE,
  CONSTRAINT fk_veiculo_categoria FOREIGN KEY (categoria_id) REFERENCES categoria_veiculo(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. PRECIFICACAO
-- ---------------------------------------------------------------------

CREATE TABLE tabela_preco (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cidade            VARCHAR(120) NOT NULL,
  uf                CHAR(2) NOT NULL,
  categoria_id      BIGINT UNSIGNED NOT NULL,
  nivel_servico     ENUM('expresso','padrao','economico') NOT NULL,
  tarifa_base       DECIMAL(10,2) NOT NULL,
  valor_por_km      DECIMAL(10,2) NOT NULL,
  valor_por_parada  DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_hora        DECIMAL(10,2) NULL,   -- contratacao por periodo
  valor_minimo      DECIMAL(10,2) NOT NULL DEFAULT 0,
  vigente_desde     DATE NOT NULL,
  ativo             TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uk_preco (cidade, categoria_id, nivel_servico, vigente_desde),
  CONSTRAINT fk_preco_categoria FOREIGN KEY (categoria_id) REFERENCES categoria_veiculo(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE servico_adicional (
  id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo    VARCHAR(40)  NOT NULL,
  nome      VARCHAR(120) NOT NULL,
  descricao VARCHAR(255) NULL,
  preco     DECIMAL(10,2) NOT NULL,
  ativo     TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uk_servico_codigo (codigo)
) ENGINE=InnoDB;

CREATE TABLE categoria_servico (
  categoria_id BIGINT UNSIGNED NOT NULL,
  servico_id   BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (categoria_id, servico_id),
  CONSTRAINT fk_cs_categoria FOREIGN KEY (categoria_id) REFERENCES categoria_veiculo(id) ON DELETE CASCADE,
  CONSTRAINT fk_cs_servico   FOREIGN KEY (servico_id)   REFERENCES servico_adicional(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. ENDERECOS
-- ---------------------------------------------------------------------

CREATE TABLE endereco (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id       BIGINT UNSIGNED NULL,
  apelido          VARCHAR(80)  NULL,
  logradouro       VARCHAR(180) NOT NULL,
  numero           VARCHAR(20)  NULL,
  complemento      VARCHAR(120) NULL,
  referencia       VARCHAR(180) NULL,
  bairro           VARCHAR(120) NULL,
  cidade           VARCHAR(120) NOT NULL,
  uf               CHAR(2)      NOT NULL,
  cep              VARCHAR(9)   NULL,
  latitude         DECIMAL(10,7) NULL,
  longitude        DECIMAL(10,7) NULL,
  contato_nome     VARCHAR(120) NULL,
  contato_telefone VARCHAR(20)  NULL,
  favorito         TINYINT(1) NOT NULL DEFAULT 0,
  usado_em         DATETIME NULL,
  criado_em        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_endereco_usuario (usuario_id, favorito),
  CONSTRAINT fk_endereco_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. PEDIDO
-- ---------------------------------------------------------------------

CREATE TABLE pedido (
  id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo              VARCHAR(20) NOT NULL,
  cliente_id          BIGINT UNSIGNED NOT NULL,
  empresa_id          BIGINT UNSIGNED NULL,
  categoria_id        BIGINT UNSIGNED NOT NULL,
  nivel_servico       ENUM('expresso','padrao','economico') NOT NULL DEFAULT 'padrao',
  tipo_retirada       ENUM('imediata','agendada') NOT NULL DEFAULT 'imediata',
  agendado_para       DATETIME NULL,
  modalidade          ENUM('entrega','periodo') NOT NULL DEFAULT 'entrega',
  horas_contratadas   TINYINT UNSIGNED NULL,
  situacao            ENUM('rascunho','cotado','aguardando_alocacao','alocado',
                           'em_deslocamento_coleta','carregando','em_transito',
                           'entregue','concluido','cancelado') NOT NULL DEFAULT 'rascunho',
  distancia_km        DECIMAL(8,2) NOT NULL DEFAULT 0,
  valor_frete         DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_adicionais    DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_desconto      DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_total         DECIMAL(10,2) NOT NULL DEFAULT 0,
  forma_pagamento     ENUM('carteira','pix','cartao','dinheiro') NULL,
  pagador             ENUM('remetente','destinatario') NOT NULL DEFAULT 'remetente',
  favoritos_primeiro  TINYINT(1) NOT NULL DEFAULT 0,
  exige_comprovante   TINYINT(1) NOT NULL DEFAULT 1,
  observacao_motorista TEXT NULL,
  contato_telefone    VARCHAR(20) NULL,
  motorista_id        BIGINT UNSIGNED NULL,
  transportadora_id   BIGINT UNSIGNED NULL,
  veiculo_id          BIGINT UNSIGNED NULL,
  aceite_itens_proibidos TINYINT(1) NOT NULL DEFAULT 0,
  criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  concluido_em        DATETIME NULL,
  cancelado_em        DATETIME NULL,
  motivo_cancelamento VARCHAR(255) NULL,
  UNIQUE KEY uk_pedido_codigo (codigo),
  KEY ix_pedido_cliente_situacao (cliente_id, situacao),
  KEY ix_pedido_motorista (motorista_id),
  KEY ix_pedido_agendado (agendado_para),
  CONSTRAINT fk_pedido_cliente FOREIGN KEY (cliente_id) REFERENCES usuario(id),
  CONSTRAINT fk_pedido_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id) ON DELETE SET NULL,
  CONSTRAINT fk_pedido_categoria FOREIGN KEY (categoria_id) REFERENCES categoria_veiculo(id),
  CONSTRAINT fk_pedido_motorista FOREIGN KEY (motorista_id) REFERENCES motorista(id) ON DELETE SET NULL,
  CONSTRAINT fk_pedido_transportadora FOREIGN KEY (transportadora_id) REFERENCES empresa(id) ON DELETE SET NULL,
  CONSTRAINT fk_pedido_veiculo FOREIGN KEY (veiculo_id) REFERENCES veiculo(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE pedido_parada (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id    BIGINT UNSIGNED NOT NULL,
  sequencia    TINYINT UNSIGNED NOT NULL,
  tipo         ENUM('coleta','entrega') NOT NULL,
  endereco_id  BIGINT UNSIGNED NULL,
  logradouro   VARCHAR(180) NOT NULL,
  numero       VARCHAR(20)  NULL,
  complemento  VARCHAR(120) NULL,
  referencia   VARCHAR(180) NULL,
  cidade       VARCHAR(120) NOT NULL,
  uf           CHAR(2) NOT NULL,
  latitude     DECIMAL(10,7) NULL,
  longitude    DECIMAL(10,7) NULL,
  contato_nome     VARCHAR(120) NULL,
  contato_telefone VARCHAR(20)  NULL,
  situacao     ENUM('pendente','chegou','concluida','falhou') NOT NULL DEFAULT 'pendente',
  chegada_em   DATETIME NULL,
  concluida_em DATETIME NULL,
  UNIQUE KEY uk_parada (pedido_id, sequencia),
  CONSTRAINT fk_parada_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_parada_endereco FOREIGN KEY (endereco_id) REFERENCES endereco(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE pedido_carga (
  id                   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id            BIGINT UNSIGNED NOT NULL,
  tipo_item            ENUM('alimentos','material_construcao','roupas_pessoais',
                            'moveis_eletrodomesticos','fragil','outros') NOT NULL,
  volumes              SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  faixa_peso           ENUM('ate_50','ate_300','de_300_a_750','acima_750') NOT NULL,
  instrucao_fragil     TINYINT(1) NOT NULL DEFAULT 0,
  instrucao_nao_empilhar TINYINT(1) NOT NULL DEFAULT 0,
  instrucao_refrigerado TINYINT(1) NOT NULL DEFAULT 0,
  observacoes          VARCHAR(500) NULL,
  nota_fiscal_url      VARCHAR(500) NULL,
  UNIQUE KEY uk_carga_pedido (pedido_id),
  CONSTRAINT fk_carga_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pedido_servico (
  pedido_id  BIGINT UNSIGNED NOT NULL,
  servico_id BIGINT UNSIGNED NOT NULL,
  preco      DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (pedido_id, servico_id),
  CONSTRAINT fk_ps_pedido  FOREIGN KEY (pedido_id)  REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_ps_servico FOREIGN KEY (servico_id) REFERENCES servico_adicional(id)
) ENGINE=InnoDB;

CREATE TABLE pedido_evento (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id  BIGINT UNSIGNED NOT NULL,
  situacao   VARCHAR(40) NOT NULL,
  descricao  VARCHAR(255) NULL,
  autor_id   BIGINT UNSIGNED NULL,
  criado_em  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_evento_pedido (pedido_id, criado_em),
  CONSTRAINT fk_evento_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE comprovante (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parada_id   BIGINT UNSIGNED NOT NULL,
  tipo        ENUM('foto','assinatura') NOT NULL,
  arquivo_url VARCHAR(500) NOT NULL,
  recebedor   VARCHAR(120) NULL,
  registrado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comprovante_parada FOREIGN KEY (parada_id) REFERENCES pedido_parada(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ocorrencia (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id   BIGINT UNSIGNED NOT NULL,
  parada_id   BIGINT UNSIGNED NULL,
  tipo        ENUM('avaria','destinatario_ausente','endereco_inacessivel','recusa','outros') NOT NULL,
  descricao   VARCHAR(500) NULL,
  foto_url    VARCHAR(500) NULL,
  registrada_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ocorrencia_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_ocorrencia_parada FOREIGN KEY (parada_id) REFERENCES pedido_parada(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. ALOCACAO E RELACIONAMENTO
-- ---------------------------------------------------------------------

CREATE TABLE oferta (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id    BIGINT UNSIGNED NOT NULL,
  motorista_id BIGINT UNSIGNED NULL,
  transportadora_id BIGINT UNSIGNED NULL,
  rodada       ENUM('favoritos','geral') NOT NULL DEFAULT 'geral',
  situacao     ENUM('enviada','aceita','recusada','expirada') NOT NULL DEFAULT 'enviada',
  valor_repasse DECIMAL(10,2) NOT NULL,
  enviada_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  respondida_em DATETIME NULL,
  KEY ix_oferta_pedido (pedido_id, situacao),
  CONSTRAINT fk_oferta_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_oferta_motorista FOREIGN KEY (motorista_id) REFERENCES motorista(id) ON DELETE CASCADE,
  CONSTRAINT fk_oferta_transportadora FOREIGN KEY (transportadora_id) REFERENCES empresa(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE motorista_favorito (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id   BIGINT UNSIGNED NOT NULL,
  motorista_id BIGINT UNSIGNED NOT NULL,
  origem       ENUM('convite','pos_pedido') NOT NULL DEFAULT 'pos_pedido',
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_favorito (cliente_id, motorista_id),
  CONSTRAINT fk_fav_cliente FOREIGN KEY (cliente_id) REFERENCES usuario(id) ON DELETE CASCADE,
  CONSTRAINT fk_fav_motorista FOREIGN KEY (motorista_id) REFERENCES motorista(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE convite_motorista (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id BIGINT UNSIGNED NOT NULL,
  telefone   VARCHAR(20) NOT NULL,
  nome       VARCHAR(120) NULL,
  situacao   ENUM('enviado','cadastrado','recusado','expirado') NOT NULL DEFAULT 'enviado',
  enviado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_convite_cliente FOREIGN KEY (cliente_id) REFERENCES usuario(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE avaliacao (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id  BIGINT UNSIGNED NOT NULL,
  autor_id   BIGINT UNSIGNED NOT NULL,
  avaliado_id BIGINT UNSIGNED NOT NULL,
  nota       TINYINT UNSIGNED NOT NULL,
  comentario VARCHAR(500) NULL,
  criado_em  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_avaliacao (pedido_id, autor_id),
  CONSTRAINT fk_aval_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_aval_autor FOREIGN KEY (autor_id) REFERENCES usuario(id) ON DELETE CASCADE,
  CONSTRAINT fk_aval_avaliado FOREIGN KEY (avaliado_id) REFERENCES usuario(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. FINANCEIRO
-- ---------------------------------------------------------------------

CREATE TABLE carteira (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id BIGINT UNSIGNED NULL,
  empresa_id BIGINT UNSIGNED NULL,
  saldo      DECIMAL(12,2) NOT NULL DEFAULT 0,
  compartilhada TINYINT(1) NOT NULL DEFAULT 0,
  criado_em  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_carteira_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
  CONSTRAINT fk_carteira_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE transacao_carteira (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  carteira_id BIGINT UNSIGNED NOT NULL,
  tipo        ENUM('recarga','pagamento','estorno','ajuste') NOT NULL,
  valor       DECIMAL(12,2) NOT NULL,
  pedido_id   BIGINT UNSIGNED NULL,
  descricao   VARCHAR(255) NULL,
  criada_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_transacao_carteira (carteira_id, criada_em),
  CONSTRAINT fk_transacao_carteira FOREIGN KEY (carteira_id) REFERENCES carteira(id) ON DELETE CASCADE,
  CONSTRAINT fk_transacao_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE cupom (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo        VARCHAR(30) NOT NULL,
  descricao     VARCHAR(180) NULL,
  tipo_desconto ENUM('valor','percentual') NOT NULL,
  valor         DECIMAL(10,2) NOT NULL,
  valor_minimo_pedido DECIMAL(10,2) NOT NULL DEFAULT 0,
  usos_maximos  INT UNSIGNED NULL,
  usos_por_cliente INT UNSIGNED NOT NULL DEFAULT 1,
  valido_ate    DATE NULL,
  ativo         TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uk_cupom_codigo (codigo)
) ENGINE=InnoDB;

CREATE TABLE cupom_uso (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cupom_id   BIGINT UNSIGNED NOT NULL,
  cliente_id BIGINT UNSIGNED NOT NULL,
  pedido_id  BIGINT UNSIGNED NOT NULL,
  valor_aplicado DECIMAL(10,2) NOT NULL,
  usado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_cupom_pedido (cupom_id, pedido_id),
  CONSTRAINT fk_uso_cupom FOREIGN KEY (cupom_id) REFERENCES cupom(id) ON DELETE CASCADE,
  CONSTRAINT fk_uso_cliente FOREIGN KEY (cliente_id) REFERENCES usuario(id) ON DELETE CASCADE,
  CONSTRAINT fk_uso_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE repasse (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo_beneficiario ENUM('motorista','transportadora') NOT NULL,
  motorista_id      BIGINT UNSIGNED NULL,
  transportadora_id BIGINT UNSIGNED NULL,
  periodo_inicio    DATE NOT NULL,
  periodo_fim       DATE NOT NULL,
  valor_bruto       DECIMAL(12,2) NOT NULL,
  percentual_comissao DECIMAL(5,2) NOT NULL,
  valor_comissao    DECIMAL(12,2) NOT NULL,
  valor_liquido     DECIMAL(12,2) NOT NULL,
  situacao          ENUM('aberto','fechado','pago') NOT NULL DEFAULT 'aberto',
  criado_em         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_repasse_motorista FOREIGN KEY (motorista_id) REFERENCES motorista(id) ON DELETE CASCADE,
  CONSTRAINT fk_repasse_transportadora FOREIGN KEY (transportadora_id) REFERENCES empresa(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. COMUNICACAO
-- ---------------------------------------------------------------------

CREATE TABLE notificacao (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id BIGINT UNSIGNED NOT NULL,
  categoria  ENUM('operacional','promocional') NOT NULL DEFAULT 'operacional',
  titulo     VARCHAR(140) NOT NULL,
  mensagem   VARCHAR(500) NOT NULL,
  pedido_id  BIGINT UNSIGNED NULL,
  lida       TINYINT(1) NOT NULL DEFAULT 0,
  criada_em  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_notificacao_usuario (usuario_id, lida),
  CONSTRAINT fk_notif_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. VISOES DE APOIO
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_pedido_resumo AS
SELECT p.id, p.codigo, p.situacao, p.nivel_servico, p.tipo_retirada, p.agendado_para,
       p.valor_total, p.distancia_km, p.criado_em,
       u.nome AS cliente_nome, cv.nome AS categoria_nome,
       (SELECT CONCAT(logradouro, ', ', COALESCE(numero,'s/n'))
          FROM pedido_parada WHERE pedido_id = p.id AND tipo='coleta'
          ORDER BY sequencia LIMIT 1) AS origem,
       (SELECT CONCAT(logradouro, ', ', COALESCE(numero,'s/n'))
          FROM pedido_parada WHERE pedido_id = p.id AND tipo='entrega'
          ORDER BY sequencia DESC LIMIT 1) AS destino,
       (SELECT COUNT(*) FROM pedido_parada WHERE pedido_id = p.id) AS total_paradas,
       mu.nome AS motorista_nome
FROM pedido p
JOIN usuario u ON u.id = p.cliente_id
JOIN categoria_veiculo cv ON cv.id = p.categoria_id
LEFT JOIN motorista m ON m.id = p.motorista_id
LEFT JOIN usuario mu ON mu.id = m.usuario_id;
