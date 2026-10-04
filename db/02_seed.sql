-- =====================================================================
-- SOLUS FRETE - Dados iniciais (seed)
-- Execucao: mysql -u root -p solus_frete < 02_seed.sql
-- =====================================================================
USE solus_frete;

-- ---------------------------------------------------------------------
-- Categorias de veiculo
-- ---------------------------------------------------------------------
-- Estas especificacoes espelham app/lib/core/veiculos_config.dart (o teste
-- app/test/veiculos_config_test.dart confere que os dois continuam iguais).
-- Colunas: codigo, nome, descricao, c, l, a (m), peso max (kg), ordem, refrigerada, perigosa.
INSERT INTO categoria_veiculo (codigo, nome, descricao, comprimento_m, largura_m, altura_m, peso_max_kg, ordem, aceita_refrigerada, aceita_perigosa) VALUES
('moto',          'Moto',           'Documentos e encomendas pequenas.',                                0.40, 0.35, 0.30,    20, 1, 0, 0),
('carro',         'Carro',          'Volumes medios que caibam no porta-malas e bancos.',               1.20, 0.90, 0.70,   200, 2, 0, 0),
('utilitario',    'Utilitario',     'Cargas pequenas e medias, como um Fiorino: caixas e equipamentos.', 1.90, 1.30, 1.20,   650, 3, 0, 0),
('van',           'Van',            'Volume alto protegido da chuva.',                                  3.00, 1.70, 1.80,  1500, 4, 0, 0),
('vuc',           'VUC',            'Veiculo urbano de carga: entregas grandes dentro da cidade.',      4.50, 2.10, 2.20,  3000, 5, 1, 0),
('caminhao_34',   'Caminhao 3/4',   'Cargas paletizadas e mudancas completas.',                         5.50, 2.30, 2.40,  4000, 6, 1, 0),
('caminhao_toco', 'Caminhao toco',  'Carga fechada e transferencias entre cidades.',                    7.00, 2.40, 2.60,  6000, 7, 1, 1),
('caminhao_truck','Caminhao truck', 'Grandes volumes e cargas pesadas.',                                8.50, 2.40, 2.70, 12000, 8, 1, 1),
('carreta',       'Carreta',        'Cargas muito grandes e transferencias de longa distancia.',       14.00, 2.50, 2.80, 25000, 9, 1, 1);

-- ---------------------------------------------------------------------
-- Servicos adicionais
-- ---------------------------------------------------------------------
INSERT INTO servico_adicional (codigo, nome, descricao, preco) VALUES
('ajuda_motorista',   'Ajuda do motorista',          'Carga e descarga porta a porta feita pelo motorista.', 70.00),
('ajudante_extra',    'Ajudante extra',              'Motorista mais um ajudante para carga e descarga.',   140.00),
('mudanca_completa',  'Mudanca completa',            'Motorista e ajudante com manuseio de moveis.',        190.00),
('tempo_espera',      'Tempo de espera',             'Espera adicional de ate 60 minutos no local.',         45.00),
('embalagem',         'Embalagem e protecao',        'Plastico bolha e cinta para itens frageis.',           35.00),
('coleta_agendada',   'Janela de coleta garantida',  'Compromisso de coleta dentro de uma hora especifica.', 25.00);

-- Compatibilidade servico x categoria
INSERT INTO categoria_servico (categoria_id, servico_id)
SELECT c.id, s.id FROM categoria_veiculo c JOIN servico_adicional s
WHERE (s.codigo = 'tempo_espera')
   OR (s.codigo = 'coleta_agendada')
   OR (s.codigo = 'embalagem' AND c.codigo <> 'moto')
   OR (s.codigo = 'ajuda_motorista' AND c.codigo IN ('utilitario','van','vuc','caminhao_34','caminhao_toco','caminhao_truck','carreta'))
   OR (s.codigo = 'ajudante_extra' AND c.codigo IN ('van','vuc','caminhao_34','caminhao_toco','caminhao_truck','carreta'))
   OR (s.codigo = 'mudanca_completa' AND c.codigo IN ('vuc','caminhao_34','caminhao_toco','caminhao_truck'));

-- ---------------------------------------------------------------------
-- Tabela de preco - Sao Paulo/SP
-- expresso  = alocacao prioritaria
-- padrao    = operacao normal
-- economico = carga agrupada, sem urgencia
-- ---------------------------------------------------------------------
INSERT INTO tabela_preco (cidade, uf, categoria_id, nivel_servico, tarifa_base, valor_por_km, valor_por_parada, valor_hora, valor_minimo, vigente_desde)
SELECT 'Sao Paulo','SP', c.id, n.nivel,
       ROUND(c.base * n.fator, 2),
       ROUND(c.km   * n.fator, 2),
       ROUND(c.parada * n.fator, 2),
       ROUND(c.hora * n.fator, 2),
       ROUND(c.minimo * n.fator, 2),
       '2026-01-01'
FROM (
  SELECT id, codigo,
         -- Sem ELSE de proposito: categoria nova sem preco falha no NOT NULL em vez de
         -- herdar o preco de outra. Valores de vuc, caminhao_truck e carreta sao de prototipo.
         CASE codigo
           WHEN 'moto' THEN 8.00 WHEN 'carro' THEN 16.00 WHEN 'utilitario' THEN 28.00
           WHEN 'van' THEN 38.00 WHEN 'vuc' THEN 65.00 WHEN 'caminhao_34' THEN 90.00
           WHEN 'caminhao_toco' THEN 140.00 WHEN 'caminhao_truck' THEN 190.00
           WHEN 'carreta' THEN 320.00 END AS base,
         CASE codigo
           WHEN 'moto' THEN 1.90 WHEN 'carro' THEN 2.70 WHEN 'utilitario' THEN 3.60
           WHEN 'van' THEN 4.30 WHEN 'vuc' THEN 5.80 WHEN 'caminhao_34' THEN 7.40
           WHEN 'caminhao_toco' THEN 9.80 WHEN 'caminhao_truck' THEN 12.50
           WHEN 'carreta' THEN 18.00 END AS km,
         CASE codigo WHEN 'moto' THEN 4.00 WHEN 'carro' THEN 6.00
           ELSE 10.00 END AS parada,
         CASE codigo
           WHEN 'moto' THEN 38.00 WHEN 'carro' THEN 58.00 WHEN 'utilitario' THEN 78.00
           WHEN 'van' THEN 92.00 WHEN 'vuc' THEN 125.00 WHEN 'caminhao_34' THEN 160.00
           WHEN 'caminhao_toco' THEN 220.00 WHEN 'caminhao_truck' THEN 290.00
           WHEN 'carreta' THEN 480.00 END AS hora,
         CASE codigo
           WHEN 'moto' THEN 14.00 WHEN 'carro' THEN 26.00 WHEN 'utilitario' THEN 45.00
           WHEN 'van' THEN 62.00 WHEN 'vuc' THEN 105.00 WHEN 'caminhao_34' THEN 140.00
           WHEN 'caminhao_toco' THEN 210.00 WHEN 'caminhao_truck' THEN 280.00
           WHEN 'carreta' THEN 480.00 END AS minimo
  FROM categoria_veiculo
) c
CROSS JOIN (
  SELECT 'expresso' AS nivel, 1.45 AS fator
  UNION ALL SELECT 'padrao', 1.00
  UNION ALL SELECT 'economico', 0.74
) n;

-- Osasco reaproveita a tabela de Sao Paulo com leve ajuste
INSERT INTO tabela_preco (cidade, uf, categoria_id, nivel_servico, tarifa_base, valor_por_km, valor_por_parada, valor_hora, valor_minimo, vigente_desde)
SELECT 'Osasco','SP', categoria_id, nivel_servico,
       ROUND(tarifa_base*0.95,2), ROUND(valor_por_km*0.95,2), valor_por_parada,
       ROUND(valor_hora*0.95,2), ROUND(valor_minimo*0.95,2), '2026-01-01'
FROM tabela_preco WHERE cidade = 'Sao Paulo';

-- ---------------------------------------------------------------------
-- Usuarios de demonstracao  (senha de todos: solus123)
-- hash bcrypt de 'solus123'
-- ---------------------------------------------------------------------
SET @H = '$2a$10$52BAUvY540uqv3KNhSytg.Uh3RMi9rMqDiCAQnef4TwMDpFGW.2Ea';

INSERT INTO usuario (tipo, nome, sobrenome, telefone, telefone_verificado, email, senha_hash, setor_atuacao) VALUES
('cliente_pf',    'Danilo',  'Lopes',    '11940135904', 1, 'danilo@solusfrete.dev',   @H, 'Tecnologia'),
('cliente_pj',    'Marina',  'Alves',    '11988887777', 1, 'marina@casaviva.com.br',  @H, 'Varejo'),
('motorista',     'Jose',    'Bezerra',  '11977776666', 1, 'jose.motorista@mail.com', @H, NULL),
('motorista',     'Aline',   'Souza',    '11966665555', 1, 'aline.motorista@mail.com',@H, NULL),
('motorista',     'Rafael',  'Nunes',    '11955554444', 1, 'rafael.motorista@mail.com',@H, NULL),
('transportadora','Carlos',  'Meireles', '11944443333', 1, 'carlos@translog.com.br',  @H, 'Logistica'),
('admin',         'Operacao','Solus',    '11900000000', 1, 'admin@solusfrete.dev',    @H, NULL);

SET @cli_pf  = (SELECT id FROM usuario WHERE telefone='11940135904');
SET @cli_pj  = (SELECT id FROM usuario WHERE telefone='11988887777');
SET @mot1    = (SELECT id FROM usuario WHERE telefone='11977776666');
SET @mot2    = (SELECT id FROM usuario WHERE telefone='11966665555');
SET @mot3    = (SELECT id FROM usuario WHERE telefone='11955554444');
SET @resp_tr = (SELECT id FROM usuario WHERE telefone='11944443333');

-- ---------------------------------------------------------------------
-- Empresas
-- ---------------------------------------------------------------------
INSERT INTO empresa (tipo, cnpj, razao_social, nome_fantasia, registro_antt, responsavel_usuario_id, telefone, email, cidade, uf, situacao_homologacao) VALUES
('cliente_pj',    '12.345.678/0001-90', 'Casa Viva Comercio de Moveis LTDA', 'Casa Viva', NULL,       @cli_pj,  '1133224455', 'compras@casaviva.com.br', 'Sao Paulo','SP','aprovada'),
('transportadora','98.765.432/0001-10', 'TransLog Transportes LTDA',         'TransLog',  'RNTRC 123456', @resp_tr, '1133556677', 'operacao@translog.com.br','Osasco','SP','aprovada');

SET @emp_pj = (SELECT id FROM empresa WHERE cnpj='12.345.678/0001-90');
SET @emp_tr = (SELECT id FROM empresa WHERE cnpj='98.765.432/0001-10');

INSERT INTO empresa_usuario (empresa_id, usuario_id, papel, limite_mensal) VALUES
(@emp_pj, @cli_pj, 'gestor', 5000.00);

-- ---------------------------------------------------------------------
-- Motoristas e veiculos
-- ---------------------------------------------------------------------
INSERT INTO motorista (usuario_id, transportadora_id, cpf, cnh_numero, cnh_categoria, cnh_validade, situacao_homologacao, disponivel, latitude, longitude, avaliacao_media, total_corridas) VALUES
(@mot1, NULL,    '111.222.333-44', '01234567890', 'B',  '2029-05-20', 'aprovada', 1, -23.5489, -46.6388, 4.85, 312),
(@mot2, NULL,    '222.333.444-55', '09876543210', 'AB', '2028-11-02', 'aprovada', 1, -23.5320, -46.7920, 4.92, 128),
(@mot3, @emp_tr, '333.444.555-66', '05555544444', 'C',  '2030-02-15', 'aprovada', 1, -23.5290, -46.7710, 4.70,  64);

SET @m1 = (SELECT id FROM motorista WHERE cpf='111.222.333-44');
SET @m2 = (SELECT id FROM motorista WHERE cpf='222.333.444-55');
SET @m3 = (SELECT id FROM motorista WHERE cpf='333.444.555-66');

INSERT INTO veiculo (motorista_id, transportadora_id, categoria_id, placa, marca, modelo, ano, documento_validade, situacao_homologacao) VALUES
(@m1, NULL, (SELECT id FROM categoria_veiculo WHERE codigo='van'),        'ABC1D23', 'Mercedes','Sprinter',        2020, '2027-03-01','aprovada'),
(@m2, NULL, (SELECT id FROM categoria_veiculo WHERE codigo='moto'),       'XYZ9K88', 'Honda',   'CG 160 Cargo',    2022, '2027-08-10','aprovada'),
(@m3, @emp_tr,(SELECT id FROM categoria_veiculo WHERE codigo='caminhao_34'),'TRL4A55','Volkswagen','Delivery 9.170',2021,'2027-12-20','aprovada');

-- Motorista favorito do cliente PF
INSERT INTO motorista_favorito (cliente_id, motorista_id, origem) VALUES (@cli_pf, @m1, 'pos_pedido');

-- ---------------------------------------------------------------------
-- Enderecos salvos e recentes
-- ---------------------------------------------------------------------
INSERT INTO endereco (usuario_id, apelido, logradouro, numero, complemento, referencia, bairro, cidade, uf, cep, latitude, longitude, contato_nome, contato_telefone, favorito, usado_em) VALUES
(@cli_pf,'Casa',     'Rua Salvador Nunes', '120','Casa 2','Em frente a praca','Jardim Piratininga','Osasco','SP','06230-000',-23.5320,-46.7920,'Danilo','11940135904',1,'2026-09-16 09:10:00'),
(@cli_pf,'Trabalho', 'Avenida Paulista',  '1159','9o andar','Proximo ao MASP','Bela Vista','Sao Paulo','SP','01311-200',-23.5660,-46.6520,'Recepcao','1133334444',1,'2026-09-17 17:44:00'),
(@cli_pf, NULL,      'Rua Pastoril de Nanuque','196',NULL,NULL,'Ponte Rasa','Sao Paulo','SP','03910-000',-23.5170,-46.4780,NULL,NULL,0,'2026-09-10 14:20:00'),
(@cli_pj,'Loja Centro','Rua 25 de Marco', '800','Loja 4','Galeria','Centro','Sao Paulo','SP','01021-000',-23.5430,-46.6330,'Marina','11988887777',1,'2026-09-15 11:00:00'),
(@cli_pj,'Deposito',  'Rua Cabo Diogo Oliveira','45',NULL,'Portao azul','Vila Leopoldina','Sao Paulo','SP','05318-000',-23.5290,-46.7360,'Estoque','1133224455',1,'2026-09-16 08:00:00');

-- ---------------------------------------------------------------------
-- Carteiras
-- ---------------------------------------------------------------------
INSERT INTO carteira (usuario_id, empresa_id, saldo, compartilhada) VALUES
(@cli_pf, NULL, 120.00, 0),
(NULL, @emp_pj, 2400.00, 1);

INSERT INTO transacao_carteira (carteira_id, tipo, valor, descricao) VALUES
((SELECT id FROM carteira WHERE usuario_id=@cli_pf),'recarga',150.00,'Recarga via Pix'),
((SELECT id FROM carteira WHERE usuario_id=@cli_pf),'pagamento',-30.00,'Pedido SF-000001');

-- ---------------------------------------------------------------------
-- Cupons
-- ---------------------------------------------------------------------
INSERT INTO cupom (codigo, descricao, tipo_desconto, valor, valor_minimo_pedido, usos_por_cliente, valido_ate) VALUES
('SOLUS10',   'R$ 10 de desconto no primeiro frete', 'valor',      10.00,  40.00, 1, '2026-12-31'),
('MUDANCA15', '15% off em fretes de van e caminhao', 'percentual', 15.00, 150.00, 2, '2026-12-31');

-- ---------------------------------------------------------------------
-- Pedidos de demonstracao
-- ---------------------------------------------------------------------
-- 1) Pedido concluido
INSERT INTO pedido (codigo, cliente_id, categoria_id, nivel_servico, tipo_retirada, situacao,
                    distancia_km, valor_frete, valor_adicionais, valor_desconto, valor_total,
                    forma_pagamento, pagador, favoritos_primeiro, contato_telefone, motorista_id, veiculo_id,
                    aceite_itens_proibidos, criado_em, concluido_em)
VALUES ('SF-000001', @cli_pf, (SELECT id FROM categoria_veiculo WHERE codigo='moto'),
        'padrao','imediata','concluido', 7.40, 25.60, 0.00, 0.00, 25.60,
        'carteira','remetente',0,'11940135904', @m2, (SELECT id FROM veiculo WHERE placa='XYZ9K88'),
        1,'2026-09-10 14:05:00','2026-09-10 14:52:00');

SET @p1 = (SELECT id FROM pedido WHERE codigo='SF-000001');
INSERT INTO pedido_parada (pedido_id, sequencia, tipo, logradouro, numero, cidade, uf, latitude, longitude, situacao, concluida_em) VALUES
(@p1,1,'coleta', 'Rua Salvador Nunes','120','Osasco','SP',-23.5320,-46.7920,'concluida','2026-09-10 14:20:00'),
(@p1,2,'entrega','Rua Pastoril de Nanuque','196','Sao Paulo','SP',-23.5170,-46.4780,'concluida','2026-09-10 14:52:00');
INSERT INTO pedido_carga (pedido_id, tipo_carga, volumes, peso_kg, comprimento_cm, largura_cm, altura_cm, observacoes) VALUES
(@p1,'caixas_pacotes',1,0.50,30,22,3,'Envelope com contratos');
INSERT INTO avaliacao (pedido_id, autor_id, avaliado_id, nota, comentario) VALUES
(@p1, @cli_pf, @mot2, 5, 'Rapido e cuidadoso.');
INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES
(@p1,'cotado','Cotacao gerada'),(@p1,'alocado','Motorista Aline aceitou'),
(@p1,'em_transito','Coleta realizada'),(@p1,'concluido','Entrega confirmada');

-- 2) Pedido em transito
INSERT INTO pedido (codigo, cliente_id, categoria_id, nivel_servico, tipo_retirada, situacao,
                    distancia_km, valor_frete, valor_adicionais, valor_total,
                    forma_pagamento, pagador, favoritos_primeiro, contato_telefone, motorista_id, veiculo_id,
                    aceite_itens_proibidos, criado_em)
VALUES ('SF-000002', @cli_pf, (SELECT id FROM categoria_veiculo WHERE codigo='van'),
        'padrao','imediata','em_transito', 18.60, 148.72, 70.00, 218.72,
        'pix','remetente',1,'11940135904', @m1, (SELECT id FROM veiculo WHERE placa='ABC1D23'),
        1,'2026-09-17 16:30:00');

SET @p2 = (SELECT id FROM pedido WHERE codigo='SF-000002');
INSERT INTO pedido_parada (pedido_id, sequencia, tipo, logradouro, numero, complemento, cidade, uf, latitude, longitude, contato_nome, contato_telefone, situacao, concluida_em) VALUES
(@p2,1,'coleta', 'Rua Salvador Nunes','120','Casa 2','Osasco','SP',-23.5320,-46.7920,'Danilo','11940135904','concluida','2026-09-17 17:05:00'),
(@p2,2,'entrega','Avenida Paulista','1159','9o andar','Sao Paulo','SP',-23.5660,-46.6520,'Recepcao','1133334444','pendente',NULL);
INSERT INTO pedido_carga (pedido_id, tipo_carga, volumes, peso_kg, comprimento_cm, largura_cm, altura_cm, instrucao_nao_empilhar, observacoes) VALUES
(@p2,'fragil',4,320.00,180,90,75,1,'Uma mesa de vidro, favor nao empilhar');
INSERT INTO pedido_servico (pedido_id, servico_id, preco) VALUES
(@p2,(SELECT id FROM servico_adicional WHERE codigo='ajuda_motorista'),70.00);
INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES
(@p2,'cotado','Cotacao gerada'),(@p2,'aguardando_alocacao','Ofertado aos favoritos'),
(@p2,'alocado','Motorista Jose aceitou'),(@p2,'carregando','Chegou na coleta'),
(@p2,'em_transito','Carga coletada, seguindo para entrega');

-- 3) Pedido agendado, aguardando alocacao (cliente PJ)
INSERT INTO pedido (codigo, cliente_id, empresa_id, categoria_id, nivel_servico, tipo_retirada, agendado_para,
                    situacao, distancia_km, valor_frete, valor_adicionais, valor_total,
                    forma_pagamento, pagador, contato_telefone, aceite_itens_proibidos, criado_em)
VALUES ('SF-000003', @cli_pj, @emp_pj, (SELECT id FROM categoria_veiculo WHERE codigo='caminhao_34'),
        'padrao','agendada','2026-09-19 08:00:00','aguardando_alocacao', 24.30, 269.82, 190.00, 459.82,
        'carteira','remetente','11988887777',1,'2026-09-17 10:00:00');

SET @p3 = (SELECT id FROM pedido WHERE codigo='SF-000003');
INSERT INTO pedido_parada (pedido_id, sequencia, tipo, logradouro, numero, cidade, uf, latitude, longitude, contato_nome, contato_telefone) VALUES
(@p3,1,'coleta', 'Rua Cabo Diogo Oliveira','45','Sao Paulo','SP',-23.5290,-46.7360,'Estoque','1133224455'),
(@p3,2,'entrega','Rua 25 de Marco','800','Sao Paulo','SP',-23.5430,-46.6330,'Marina','11988887777'),
(@p3,3,'entrega','Avenida Paulista','1159','Sao Paulo','SP',-23.5660,-46.6520,'Recepcao','1133334444');
INSERT INTO pedido_carga (pedido_id, tipo_carga, volumes, peso_kg, comprimento_cm, largura_cm, altura_cm, observacoes) VALUES
(@p3,'paletizada',12,2600.00,120,100,150,'Reposicao de estoque das lojas');
INSERT INTO pedido_servico (pedido_id, servico_id, preco) VALUES
(@p3,(SELECT id FROM servico_adicional WHERE codigo='mudanca_completa'),190.00);
INSERT INTO oferta (pedido_id, transportadora_id, rodada, situacao, valor_repasse) VALUES
(@p3, @emp_tr, 'geral','enviada', 367.86);
INSERT INTO pedido_evento (pedido_id, situacao, descricao) VALUES
(@p3,'cotado','Cotacao gerada'),(@p3,'aguardando_alocacao','Ofertado a transportadoras parceiras');

-- 4) Pedido cancelado
INSERT INTO pedido (codigo, cliente_id, categoria_id, nivel_servico, tipo_retirada, situacao,
                    distancia_km, valor_frete, valor_total, forma_pagamento, pagador,
                    contato_telefone, aceite_itens_proibidos, criado_em, cancelado_em, motivo_cancelamento)
VALUES ('SF-000004', @cli_pf, (SELECT id FROM categoria_veiculo WHERE codigo='van'),
        'expresso','imediata','cancelado', 11.20, 103.40, 103.40,'dinheiro','destinatario',
        '11940135904',1,'2026-09-12 19:10:00','2026-09-12 19:14:00','Cliente desistiu antes da alocacao');

SET @p4 = (SELECT id FROM pedido WHERE codigo='SF-000004');
INSERT INTO pedido_parada (pedido_id, sequencia, tipo, logradouro, numero, cidade, uf, latitude, longitude) VALUES
(@p4,1,'coleta', 'Rua Salvador Nunes','120','Osasco','SP',-23.5320,-46.7920),
(@p4,2,'entrega','Rua 25 de Marco','800','Sao Paulo','SP',-23.5430,-46.6330);
INSERT INTO pedido_carga (pedido_id, tipo_carga, volumes, peso_kg, comprimento_cm, largura_cm, altura_cm, observacoes) VALUES
(@p4,'caixas_pacotes',6,220.00,60,50,40,'Material de construcao');

-- ---------------------------------------------------------------------
-- Notificacoes
-- ---------------------------------------------------------------------
INSERT INTO notificacao (usuario_id, categoria, titulo, mensagem, pedido_id) VALUES
(@cli_pf,'operacional','Carga coletada','Seu pedido SF-000002 saiu para entrega.', @p2),
(@cli_pf,'promocional','Cupom SOLUS10','Use SOLUS10 e ganhe R$ 10 no proximo frete.', NULL),
(@cli_pj,'operacional','Frete agendado confirmado','Coleta marcada para 19/09 as 08:00.', @p3);

-- ---------------------------------------------------------------------
-- Parceiros da cotacao (dados gerados para a demonstracao, regiao de Sao Paulo)
-- Cada cotacao mostra ate 10 opcoes: 4 motoristas autonomos + 6 transportadoras.
--   motoristas: 5 por categoria de veiculo, preco pela tabela_preco da plataforma
--   transportadoras: 10 + TransLog, cada uma com preco proprio (transportadora_preco)
-- ---------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_n (n INT PRIMARY KEY);
INSERT INTO tmp_n VALUES (1),(2),(3),(4),(5);

CREATE TEMPORARY TABLE tmp_modelo (
  codigo VARCHAR(40) PRIMARY KEY, marca VARCHAR(60), modelo VARCHAR(60), cnh CHAR(1));
INSERT INTO tmp_modelo VALUES
('moto','Honda','CG 160 Cargo','A'),
('carro','Chevrolet','Onix Plus','B'),
('utilitario','Fiat','Fiorino','B'),
('van','Renault','Master','B'),
('vuc','Volkswagen','Delivery Express','C'),
('caminhao_34','Volkswagen','Delivery 9.170','C'),
('caminhao_toco','Mercedes','Accelo 1016','C'),
('caminhao_truck','Volkswagen','Constellation 24.280','C'),
('carreta','Scania','R 450 com carreta','E');

-- motoristas autonomos: usuario, motorista e veiculo
INSERT INTO usuario (tipo, nome, sobrenome, telefone, telefone_verificado, email, senha_hash)
SELECT 'motorista',
       ELT(1 + MOD(g.i, 16), 'Carlos','Marcos','Paulo','Andre','Bruno','Diego','Fabio','Gustavo',
                             'Henrique','Igor','Julio','Leandro','Mauricio','Nelson','Otavio','Renato'),
       ELT(1 + MOD(g.i * 5, 12), 'Silva','Santos','Oliveira','Souza','Pereira','Costa','Ribeiro',
                                 'Almeida','Carvalho','Gomes','Martins','Rocha'),
       CONCAT('1197', LPAD(g.i, 7, '0')), 1, CONCAT('parceiro', g.i, '@solusfrete.dev'), @H
  FROM (SELECT (c.ordem - 1) * 5 + n.n AS i FROM categoria_veiculo c CROSS JOIN tmp_n n) g;

INSERT INTO motorista (usuario_id, transportadora_id, cpf, cnh_numero, cnh_categoria, cnh_validade,
                       situacao_homologacao, disponivel, latitude, longitude, avaliacao_media, total_corridas)
SELECT u.id, NULL,
       CONCAT(LPAD(g.i, 3, '0'), '.000.000-', LPAD(MOD(g.i, 100), 2, '0')),
       CONCAT('9', LPAD(g.i, 10, '0')), m.cnh, '2029-12-31', 'aprovada',
       IF(MOD(g.i, 9) = 0, 0, 1),
       ROUND(-23.5500 + (MOD(g.i * 7, 13) - 6) * 0.014, 7),
       ROUND(-46.6500 + (MOD(g.i * 11, 17) - 8) * 0.016, 7),
       IF(MOD(g.i, 11) = 0, 0, ROUND(4.0 + MOD(g.i * 7, 10) * 0.1, 2)),
       IF(MOD(g.i, 11) = 0, 0, 20 + MOD(g.i * 37, 400))
  FROM (SELECT (c.ordem - 1) * 5 + n.n AS i, c.codigo
          FROM categoria_veiculo c CROSS JOIN tmp_n n) g
  JOIN tmp_modelo m ON m.codigo = g.codigo
  JOIN usuario u ON u.telefone = CONCAT('1197', LPAD(g.i, 7, '0'));

INSERT INTO veiculo (motorista_id, transportadora_id, categoria_id, placa, marca, modelo, ano,
                     documento_validade, situacao_homologacao)
SELECT mo.id, NULL, g.categoria_id, CONCAT('SOL', LPAD(g.i, 4, '0')), m.marca, m.modelo,
       2018 + MOD(g.i, 7), '2027-12-31', 'aprovada'
  FROM (SELECT (c.ordem - 1) * 5 + n.n AS i, c.id AS categoria_id, c.codigo
          FROM categoria_veiculo c CROSS JOIN tmp_n n) g
  JOIN tmp_modelo m ON m.codigo = g.codigo
  JOIN usuario u ON u.telefone = CONCAT('1197', LPAD(g.i, 7, '0'))
  JOIN motorista mo ON mo.usuario_id = u.id;

-- transportadoras: empresa, frota (1 veiculo por categoria) e preco proprio
CREATE TEMPORARY TABLE tmp_transp (
  n TINYINT PRIMARY KEY, razao VARCHAR(180), fantasia VARCHAR(180), cidade VARCHAR(120),
  lat DECIMAL(10,7), lng DECIMAL(10,7), raio SMALLINT, fator DECIMAL(4,2),
  nota DECIMAL(3,2), fretes INT);
INSERT INTO tmp_transp VALUES
(1,'RapidoSul Logistica LTDA','RapidoSul','Sao Paulo',-23.5505,-46.6333,80,0.92,4.60,1240),
(2,'Via Expressa Transportes LTDA','Via Expressa','Guarulhos',-23.4543,-46.5333,70,0.96,4.40,860),
(3,'Metropole Cargas LTDA','Metropole Cargas','Osasco',-23.5329,-46.7917,60,1.00,4.80,2100),
(4,'Grande SP Fretes LTDA','Grande SP Fretes','Santo Andre',-23.6639,-46.5383,70,1.05,4.20,540),
(5,'Barueri Log Transportes LTDA','Barueri Log','Barueri',-23.5057,-46.8790,50,0.89,4.50,730),
(6,'TransPaulista LTDA','TransPaulista','Sao Paulo',-23.5614,-46.6559,90,1.10,4.90,3300),
(7,'Carga Certa Transportes LTDA','Carga Certa','Sao Bernardo do Campo',-23.6914,-46.5646,60,0.94,4.10,410),
(8,'EntregaJa Logistica LTDA','EntregaJa','Sao Paulo',-23.5200,-46.7300,60,1.02,0.00,0),
(9,'Norte Sul Transportes LTDA','Norte Sul','Sao Paulo',-23.4890,-46.6100,75,1.15,4.70,1500),
(10,'Rota Segura Cargas LTDA','Rota Segura','Osasco',-23.5480,-46.8200,25,0.97,4.30,650);

INSERT INTO empresa (tipo, cnpj, razao_social, nome_fantasia, registro_antt, telefone, email, cidade, uf,
                     situacao_homologacao, latitude, longitude, raio_atuacao_km, avaliacao_media, total_fretes)
SELECT 'transportadora', CONCAT('55.', LPAD(t.n, 3, '0'), '.000/0001-', LPAD(t.n, 2, '0')),
       t.razao, t.fantasia, CONCAT('RNTRC ', 200000 + t.n),
       CONCAT('113000', LPAD(t.n, 4, '0')), CONCAT('contato', t.n, '@parceiro.solusfrete.dev'),
       t.cidade, 'SP', 'aprovada', t.lat, t.lng, t.raio, t.nota, t.fretes
  FROM tmp_transp t;

INSERT INTO veiculo (motorista_id, transportadora_id, categoria_id, placa, marca, modelo, ano,
                     documento_validade, situacao_homologacao)
SELECT NULL, e.id, c.id, CONCAT('TRP', LPAD(t.n, 2, '0'), LPAD(c.ordem, 2, '0')), m.marca, m.modelo,
       2019 + MOD(t.n + c.ordem, 6), '2027-12-31', 'aprovada'
  FROM tmp_transp t
  JOIN empresa e ON e.cnpj = CONCAT('55.', LPAD(t.n, 3, '0'), '.000/0001-', LPAD(t.n, 2, '0'))
  CROSS JOIN categoria_veiculo c
  JOIN tmp_modelo m ON m.codigo = c.codigo;

INSERT INTO transportadora_preco (empresa_id, categoria_id, tarifa_base, valor_por_km,
                                  valor_por_parada, valor_hora, valor_minimo)
SELECT e.id, tp.categoria_id,
       ROUND(tp.tarifa_base * t.fator, 2), ROUND(tp.valor_por_km * t.fator, 2),
       ROUND(tp.valor_por_parada * t.fator, 2), ROUND(tp.valor_hora * t.fator, 2),
       ROUND(tp.valor_minimo * t.fator, 2)
  FROM tmp_transp t
  JOIN empresa e ON e.cnpj = CONCAT('55.', LPAD(t.n, 3, '0'), '.000/0001-', LPAD(t.n, 2, '0'))
  JOIN tabela_preco tp ON tp.cidade = 'Sao Paulo' AND tp.nivel_servico = 'padrao' AND tp.ativo = 1;

-- TransLog (ja cadastrada acima) passa a participar da cotacao com o caminhao 3/4
UPDATE empresa SET latitude = -23.5329, longitude = -46.7917, raio_atuacao_km = 60,
                   avaliacao_media = 4.70, total_fretes = 64
 WHERE id = @emp_tr;

INSERT INTO transportadora_preco (empresa_id, categoria_id, tarifa_base, valor_por_km,
                                  valor_por_parada, valor_hora, valor_minimo)
SELECT @emp_tr, tp.categoria_id, tp.tarifa_base, tp.valor_por_km, tp.valor_por_parada,
       tp.valor_hora, tp.valor_minimo
  FROM tabela_preco tp
  JOIN categoria_veiculo c ON c.id = tp.categoria_id
 WHERE tp.cidade = 'Sao Paulo' AND tp.nivel_servico = 'padrao' AND c.codigo = 'caminhao_34';

DROP TEMPORARY TABLE tmp_transp;
DROP TEMPORARY TABLE tmp_modelo;
DROP TEMPORARY TABLE tmp_n;

SELECT 'Seed concluido' AS status,
       (SELECT COUNT(*) FROM usuario) AS usuarios,
       (SELECT COUNT(*) FROM categoria_veiculo) AS categorias,
       (SELECT COUNT(*) FROM tabela_preco) AS precos,
       (SELECT COUNT(*) FROM pedido) AS pedidos,
       (SELECT COUNT(*) FROM motorista WHERE transportadora_id IS NULL) AS motoristas_autonomos,
       (SELECT COUNT(*) FROM empresa WHERE tipo = 'transportadora') AS transportadoras;
