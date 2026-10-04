#!/usr/bin/env python3
"""Gera o diagrama ER completo do banco Solus Frete (docs/diagrama-er.png, .svg e .pdf).

As tabelas abaixo espelham db/01_schema.sql: ao mudar o schema, atualize TABELAS e
RELACIONAMENTOS e rode:  python3 db/gerar_diagrama_er.py   (precisa do Graphviz: brew install graphviz)
"""

import shutil
import subprocess
from pathlib import Path

# Cores por dominio (fundo do cabecalho de cada tabela)
DOMINIOS = {
    "Identidade":   "#2C5985",
    "Frota":        "#2E7D5B",
    "Precificacao": "#B7791F",
    "Enderecos":    "#6B4C9A",
    "Pedido":       "#B23B3B",
    "Alocacao":     "#0E7C86",
    "Financeiro":   "#8A6D00",
    "Comunicacao":  "#555555",
}

# col: (nome, tipo, flag)  flag in {"PK","FK","UK","PF"} PF = PK e FK ao mesmo tempo, "" = nenhuma
# enum: lista de valores (opcional) mostrada como sub-linha
TABELAS = {
    "usuario": {
        "dominio": "Identidade",
        "cols": [
            ("id", "bigint", "PK", None),
            ("tipo", "enum", "", ["cliente_pf", "cliente_pj", "motorista", "transportadora", "admin"]),
            ("nome", "varchar(120)", "", None),
            ("sobrenome", "varchar(120)", "", None),
            ("telefone", "varchar(20)", "UK", None),
            ("telefone_verificado", "tinyint(1)", "", None),
            ("email", "varchar(160)", "UK", None),
            ("senha_hash", "varchar(255)", "", None),
            ("foto_url", "varchar(500)", "", None),
            ("setor_atuacao", "varchar(120)", "", None),
            ("situacao", "enum", "", ["ativo", "inativo", "bloqueado"]),
            ("criado_em", "datetime", "", None),
            ("atualizado_em", "datetime", "", None),
        ],
    },
    "empresa": {
        "dominio": "Identidade",
        "cols": [
            ("id", "bigint", "PK", None),
            ("tipo", "enum", "", ["cliente_pj", "transportadora"]),
            ("cnpj", "varchar(18)", "UK", None),
            ("razao_social", "varchar(180)", "", None),
            ("nome_fantasia", "varchar(180)", "", None),
            ("registro_antt", "varchar(30)", "", None),
            ("responsavel_usuario_id", "bigint", "FK", None),
            ("telefone", "varchar(20)", "", None),
            ("email", "varchar(160)", "", None),
            ("cep", "varchar(9)", "", None),
            ("logradouro", "varchar(180)", "", None),
            ("numero", "varchar(20)", "", None),
            ("complemento", "varchar(120)", "", None),
            ("cidade", "varchar(120)", "", None),
            ("uf", "char(2)", "", None),
            ("situacao_homologacao", "enum", "", ["pendente", "aprovada", "reprovada"]),
            ("latitude", "decimal(10,7)", "", None),
            ("longitude", "decimal(10,7)", "", None),
            ("raio_atuacao_km", "smallint", "", None),
            ("avaliacao_media", "decimal(3,2)", "", None),
            ("total_fretes", "int", "", None),
            ("criado_em", "datetime", "", None),
        ],
    },
    "empresa_usuario": {
        "dominio": "Identidade",
        "cols": [
            ("id", "bigint", "PK", None),
            ("empresa_id", "bigint", "FK", None),
            ("usuario_id", "bigint", "FK", None),
            ("papel", "enum", "", ["gestor", "solicitante"]),
            ("limite_mensal", "decimal(10,2)", "", None),
            ("criado_em", "datetime", "", None),
        ],
    },
    "categoria_veiculo": {
        "dominio": "Frota",
        "cols": [
            ("id", "bigint", "PK", None),
            ("codigo", "varchar(40)", "UK", None),
            ("nome", "varchar(80)", "", None),
            ("descricao", "varchar(255)", "", None),
            ("comprimento_m", "decimal(5,2)", "", None),
            ("largura_m", "decimal(5,2)", "", None),
            ("altura_m", "decimal(5,2)", "", None),
            ("peso_max_kg", "int", "", None),
            ("aceita_refrigerada", "tinyint(1)", "", None),
            ("aceita_perigosa", "tinyint(1)", "", None),
            ("ordem", "int", "", None),
            ("ativo", "tinyint(1)", "", None),
        ],
    },
    "motorista": {
        "dominio": "Frota",
        "cols": [
            ("id", "bigint", "PK", None),
            ("usuario_id", "bigint", "FK,UK", None),
            ("transportadora_id", "bigint", "FK", None),
            ("cpf", "varchar(14)", "UK", None),
            ("cnh_numero", "varchar(20)", "", None),
            ("cnh_categoria", "varchar(5)", "", None),
            ("cnh_validade", "date", "", None),
            ("cnh_arquivo_url", "varchar(500)", "", None),
            ("situacao_homologacao", "enum", "", ["pendente", "aprovada", "reprovada"]),
            ("disponivel", "tinyint(1)", "", None),
            ("latitude", "decimal(10,7)", "", None),
            ("longitude", "decimal(10,7)", "", None),
            ("raio_atuacao_km", "smallint", "", None),
            ("avaliacao_media", "decimal(3,2)", "", None),
            ("total_corridas", "int", "", None),
            ("criado_em", "datetime", "", None),
        ],
    },
    "veiculo": {
        "dominio": "Frota",
        "cols": [
            ("id", "bigint", "PK", None),
            ("motorista_id", "bigint", "FK", None),
            ("transportadora_id", "bigint", "FK", None),
            ("categoria_id", "bigint", "FK", None),
            ("placa", "varchar(10)", "UK", None),
            ("marca", "varchar(60)", "", None),
            ("modelo", "varchar(60)", "", None),
            ("ano", "smallint", "", None),
            ("documento_url", "varchar(500)", "", None),
            ("documento_validade", "date", "", None),
            ("situacao_homologacao", "enum", "", ["pendente", "aprovada", "reprovada"]),
            ("ativo", "tinyint(1)", "", None),
        ],
    },
    "tabela_preco": {
        "dominio": "Precificacao",
        "cols": [
            ("id", "bigint", "PK", None),
            ("cidade", "varchar(120)", "", None),
            ("uf", "char(2)", "", None),
            ("categoria_id", "bigint", "FK", None),
            ("nivel_servico", "enum", "", ["expresso", "padrao", "economico"]),
            ("tarifa_base", "decimal(10,2)", "", None),
            ("valor_por_km", "decimal(10,2)", "", None),
            ("valor_por_parada", "decimal(10,2)", "", None),
            ("valor_hora", "decimal(10,2)", "", None),
            ("valor_minimo", "decimal(10,2)", "", None),
            ("vigente_desde", "date", "", None),
            ("ativo", "tinyint(1)", "", None),
        ],
    },
    "transportadora_preco": {
        "dominio": "Precificacao",
        "cols": [
            ("id", "bigint", "PK", None),
            ("empresa_id", "bigint", "FK", None),
            ("categoria_id", "bigint", "FK", None),
            ("tarifa_base", "decimal(10,2)", "", None),
            ("valor_por_km", "decimal(10,2)", "", None),
            ("valor_por_parada", "decimal(10,2)", "", None),
            ("valor_hora", "decimal(10,2)", "", None),
            ("valor_minimo", "decimal(10,2)", "", None),
            ("ativo", "tinyint(1)", "", None),
        ],
    },
    "servico_adicional": {
        "dominio": "Precificacao",
        "cols": [
            ("id", "bigint", "PK", None),
            ("codigo", "varchar(40)", "UK", None),
            ("nome", "varchar(120)", "", None),
            ("descricao", "varchar(255)", "", None),
            ("preco", "decimal(10,2)", "", None),
            ("ativo", "tinyint(1)", "", None),
        ],
    },
    "categoria_servico": {
        "dominio": "Precificacao",
        "cols": [
            ("categoria_id", "bigint", "PF", None),
            ("servico_id", "bigint", "PF", None),
        ],
    },
    "endereco": {
        "dominio": "Enderecos",
        "cols": [
            ("id", "bigint", "PK", None),
            ("usuario_id", "bigint", "FK", None),
            ("apelido", "varchar(80)", "", None),
            ("logradouro", "varchar(180)", "", None),
            ("numero", "varchar(20)", "", None),
            ("complemento", "varchar(120)", "", None),
            ("referencia", "varchar(180)", "", None),
            ("bairro", "varchar(120)", "", None),
            ("cidade", "varchar(120)", "", None),
            ("uf", "char(2)", "", None),
            ("cep", "varchar(9)", "", None),
            ("latitude", "decimal(10,7)", "", None),
            ("longitude", "decimal(10,7)", "", None),
            ("contato_nome", "varchar(120)", "", None),
            ("contato_telefone", "varchar(20)", "", None),
            ("favorito", "tinyint(1)", "", None),
            ("usado_em", "datetime", "", None),
            ("criado_em", "datetime", "", None),
        ],
    },
    "pedido": {
        "dominio": "Pedido",
        "cols": [
            ("id", "bigint", "PK", None),
            ("codigo", "varchar(20)", "UK", None),
            ("cliente_id", "bigint", "FK", None),
            ("empresa_id", "bigint", "FK", None),
            ("categoria_id", "bigint", "FK", None),
            ("nivel_servico", "enum", "", ["expresso", "padrao", "economico"]),
            ("tipo_retirada", "enum", "", ["imediata", "agendada"]),
            ("agendado_para", "datetime", "", None),
            ("modalidade", "enum", "", ["entrega", "periodo"]),
            ("horas_contratadas", "tinyint", "", None),
            ("situacao", "enum", "", ["rascunho", "cotado", "aguardando_alocacao", "alocado",
                                       "em_deslocamento_coleta", "carregando", "em_transito",
                                       "entregue", "concluido", "cancelado"]),
            ("distancia_km", "decimal(8,2)", "", None),
            ("valor_frete", "decimal(10,2)", "", None),
            ("valor_adicionais", "decimal(10,2)", "", None),
            ("valor_desconto", "decimal(10,2)", "", None),
            ("valor_total", "decimal(10,2)", "", None),
            ("forma_pagamento", "enum", "", ["carteira", "pix", "cartao", "dinheiro"]),
            ("pagador", "enum", "", ["remetente", "destinatario"]),
            ("favoritos_primeiro", "tinyint(1)", "", None),
            ("exige_comprovante", "tinyint(1)", "", None),
            ("observacao_motorista", "text", "", None),
            ("contato_telefone", "varchar(20)", "", None),
            ("motorista_id", "bigint", "FK", None),
            ("transportadora_id", "bigint", "FK", None),
            ("veiculo_id", "bigint", "FK", None),
            ("aceite_itens_proibidos", "tinyint(1)", "", None),
            ("criado_em", "datetime", "", None),
            ("atualizado_em", "datetime", "", None),
            ("concluido_em", "datetime", "", None),
            ("cancelado_em", "datetime", "", None),
            ("motivo_cancelamento", "varchar(255)", "", None),
        ],
    },
    "pedido_parada": {
        "dominio": "Pedido",
        "cols": [
            ("id", "bigint", "PK", None),
            ("pedido_id", "bigint", "FK", None),
            ("sequencia", "tinyint", "", None),
            ("tipo", "enum", "", ["coleta", "entrega"]),
            ("endereco_id", "bigint", "FK", None),
            ("logradouro", "varchar(180)", "", None),
            ("numero", "varchar(20)", "", None),
            ("complemento", "varchar(120)", "", None),
            ("referencia", "varchar(180)", "", None),
            ("cidade", "varchar(120)", "", None),
            ("uf", "char(2)", "", None),
            ("latitude", "decimal(10,7)", "", None),
            ("longitude", "decimal(10,7)", "", None),
            ("contato_nome", "varchar(120)", "", None),
            ("contato_telefone", "varchar(20)", "", None),
            ("situacao", "enum", "", ["pendente", "chegou", "concluida", "falhou"]),
            ("chegada_em", "datetime", "", None),
            ("concluida_em", "datetime", "", None),
        ],
    },
    "pedido_carga": {
        "dominio": "Pedido",
        "cols": [
            ("id", "bigint", "PK", None),
            ("pedido_id", "bigint", "FK,UK", None),
            ("tipo_carga", "enum", "", ["caixas_pacotes", "paletizada", "granel", "fragil",
                                         "refrigerada", "perigosa"]),
            ("volumes", "smallint", "", None),
            ("peso_kg", "decimal(9,2)", "", None),
            ("comprimento_cm", "decimal(8,1)", "", None),
            ("largura_cm", "decimal(8,1)", "", None),
            ("altura_cm", "decimal(8,1)", "", None),
            ("instrucao_nao_empilhar", "tinyint(1)", "", None),
            ("observacoes", "varchar(500)", "", None),
            ("nota_fiscal_url", "varchar(500)", "", None),
        ],
    },
    "pedido_servico": {
        "dominio": "Pedido",
        "cols": [
            ("pedido_id", "bigint", "PF", None),
            ("servico_id", "bigint", "PF", None),
            ("preco", "decimal(10,2)", "", None),
        ],
    },
    "pedido_evento": {
        "dominio": "Pedido",
        "cols": [
            ("id", "bigint", "PK", None),
            ("pedido_id", "bigint", "FK", None),
            ("situacao", "varchar(40)", "", None),
            ("descricao", "varchar(255)", "", None),
            ("autor_id", "bigint", "", None),
            ("criado_em", "datetime", "", None),
        ],
    },
    "comprovante": {
        "dominio": "Pedido",
        "cols": [
            ("id", "bigint", "PK", None),
            ("parada_id", "bigint", "FK", None),
            ("tipo", "enum", "", ["foto", "assinatura"]),
            ("arquivo_url", "varchar(500)", "", None),
            ("recebedor", "varchar(120)", "", None),
            ("registrado_em", "datetime", "", None),
        ],
    },
    "ocorrencia": {
        "dominio": "Pedido",
        "cols": [
            ("id", "bigint", "PK", None),
            ("pedido_id", "bigint", "FK", None),
            ("parada_id", "bigint", "FK", None),
            ("tipo", "enum", "", ["avaria", "destinatario_ausente", "endereco_inacessivel", "recusa", "outros"]),
            ("descricao", "varchar(500)", "", None),
            ("foto_url", "varchar(500)", "", None),
            ("registrada_em", "datetime", "", None),
        ],
    },
    "oferta": {
        "dominio": "Alocacao",
        "cols": [
            ("id", "bigint", "PK", None),
            ("pedido_id", "bigint", "FK", None),
            ("motorista_id", "bigint", "FK", None),
            ("transportadora_id", "bigint", "FK", None),
            ("rodada", "enum", "", ["favoritos", "geral"]),
            ("situacao", "enum", "", ["enviada", "aceita", "recusada", "expirada"]),
            ("valor_repasse", "decimal(10,2)", "", None),
            ("enviada_em", "datetime", "", None),
            ("respondida_em", "datetime", "", None),
        ],
    },
    "motorista_favorito": {
        "dominio": "Alocacao",
        "cols": [
            ("id", "bigint", "PK", None),
            ("cliente_id", "bigint", "FK", None),
            ("motorista_id", "bigint", "FK", None),
            ("origem", "enum", "", ["convite", "pos_pedido"]),
            ("criado_em", "datetime", "", None),
        ],
    },
    "convite_motorista": {
        "dominio": "Alocacao",
        "cols": [
            ("id", "bigint", "PK", None),
            ("cliente_id", "bigint", "FK", None),
            ("telefone", "varchar(20)", "", None),
            ("nome", "varchar(120)", "", None),
            ("situacao", "enum", "", ["enviado", "cadastrado", "recusado", "expirado"]),
            ("enviado_em", "datetime", "", None),
        ],
    },
    "avaliacao": {
        "dominio": "Alocacao",
        "cols": [
            ("id", "bigint", "PK", None),
            ("pedido_id", "bigint", "FK", None),
            ("autor_id", "bigint", "FK", None),
            ("avaliado_id", "bigint", "FK", None),
            ("empresa_id", "bigint", "FK", None),
            ("nota", "tinyint", "", None),
            ("comentario", "varchar(500)", "", None),
            ("criado_em", "datetime", "", None),
        ],
    },
    "carteira": {
        "dominio": "Financeiro",
        "cols": [
            ("id", "bigint", "PK", None),
            ("usuario_id", "bigint", "FK", None),
            ("empresa_id", "bigint", "FK", None),
            ("saldo", "decimal(12,2)", "", None),
            ("compartilhada", "tinyint(1)", "", None),
            ("criado_em", "datetime", "", None),
        ],
    },
    "transacao_carteira": {
        "dominio": "Financeiro",
        "cols": [
            ("id", "bigint", "PK", None),
            ("carteira_id", "bigint", "FK", None),
            ("tipo", "enum", "", ["recarga", "pagamento", "estorno", "ajuste"]),
            ("valor", "decimal(12,2)", "", None),
            ("pedido_id", "bigint", "FK", None),
            ("descricao", "varchar(255)", "", None),
            ("criada_em", "datetime", "", None),
        ],
    },
    "cupom": {
        "dominio": "Financeiro",
        "cols": [
            ("id", "bigint", "PK", None),
            ("codigo", "varchar(30)", "UK", None),
            ("descricao", "varchar(180)", "", None),
            ("tipo_desconto", "enum", "", ["valor", "percentual"]),
            ("valor", "decimal(10,2)", "", None),
            ("valor_minimo_pedido", "decimal(10,2)", "", None),
            ("usos_maximos", "int", "", None),
            ("usos_por_cliente", "int", "", None),
            ("valido_ate", "date", "", None),
            ("ativo", "tinyint(1)", "", None),
        ],
    },
    "cupom_uso": {
        "dominio": "Financeiro",
        "cols": [
            ("id", "bigint", "PK", None),
            ("cupom_id", "bigint", "FK", None),
            ("cliente_id", "bigint", "FK", None),
            ("pedido_id", "bigint", "FK", None),
            ("valor_aplicado", "decimal(10,2)", "", None),
            ("usado_em", "datetime", "", None),
        ],
    },
    "repasse": {
        "dominio": "Financeiro",
        "cols": [
            ("id", "bigint", "PK", None),
            ("tipo_beneficiario", "enum", "", ["motorista", "transportadora"]),
            ("motorista_id", "bigint", "FK", None),
            ("transportadora_id", "bigint", "FK", None),
            ("periodo_inicio", "date", "", None),
            ("periodo_fim", "date", "", None),
            ("valor_bruto", "decimal(12,2)", "", None),
            ("percentual_comissao", "decimal(5,2)", "", None),
            ("valor_comissao", "decimal(12,2)", "", None),
            ("valor_liquido", "decimal(12,2)", "", None),
            ("situacao", "enum", "", ["aberto", "fechado", "pago"]),
            ("criado_em", "datetime", "", None),
        ],
    },
    "notificacao": {
        "dominio": "Comunicacao",
        "cols": [
            ("id", "bigint", "PK", None),
            ("usuario_id", "bigint", "FK", None),
            ("categoria", "enum", "", ["operacional", "promocional"]),
            ("titulo", "varchar(140)", "", None),
            ("mensagem", "varchar(500)", "", None),
            ("pedido_id", "bigint", "FK", None),
            ("lida", "tinyint(1)", "", None),
            ("criada_em", "datetime", "", None),
        ],
    },
}

# (tabela_origem, coluna_fk, tabela_destino, cardinalidade_muitos, cardinalidade_um, on_delete)
# cardinalidade_muitos: "N" ou "0..N" (se FK opcional -> ainda e N do lado muitos, mas se
# a linha pode nao existir do lado um, marcamos no lado um)
RELACIONAMENTOS = [
    ("empresa", "responsavel_usuario_id", "usuario", "0..N", "0..1", "SET NULL"),
    ("empresa_usuario", "empresa_id", "empresa", "N", "1", "CASCADE"),
    ("empresa_usuario", "usuario_id", "usuario", "N", "1", "CASCADE"),
    ("motorista", "usuario_id", "usuario", "1", "1", "CASCADE"),
    ("motorista", "transportadora_id", "empresa", "0..N", "0..1", "SET NULL"),
    ("veiculo", "motorista_id", "motorista", "0..N", "0..1", "CASCADE"),
    ("veiculo", "transportadora_id", "empresa", "0..N", "0..1", "CASCADE"),
    ("veiculo", "categoria_id", "categoria_veiculo", "N", "1", "RESTRICT"),
    ("tabela_preco", "categoria_id", "categoria_veiculo", "N", "1", "CASCADE"),
    ("transportadora_preco", "empresa_id", "empresa", "N", "1", "CASCADE"),
    ("transportadora_preco", "categoria_id", "categoria_veiculo", "N", "1", "CASCADE"),
    ("categoria_servico", "categoria_id", "categoria_veiculo", "N", "1", "CASCADE"),
    ("categoria_servico", "servico_id", "servico_adicional", "N", "1", "CASCADE"),
    ("endereco", "usuario_id", "usuario", "0..N", "0..1", "CASCADE"),
    ("pedido", "cliente_id", "usuario", "N", "1", "RESTRICT"),
    ("pedido", "empresa_id", "empresa", "0..N", "0..1", "SET NULL"),
    ("pedido", "categoria_id", "categoria_veiculo", "N", "1", "RESTRICT"),
    ("pedido", "motorista_id", "motorista", "0..N", "0..1", "SET NULL"),
    ("pedido", "transportadora_id", "empresa", "0..N", "0..1", "SET NULL"),
    ("pedido", "veiculo_id", "veiculo", "0..N", "0..1", "SET NULL"),
    ("pedido_parada", "pedido_id", "pedido", "N", "1", "CASCADE"),
    ("pedido_parada", "endereco_id", "endereco", "0..N", "0..1", "SET NULL"),
    ("pedido_carga", "pedido_id", "pedido", "1", "1", "CASCADE"),
    ("pedido_servico", "pedido_id", "pedido", "N", "1", "CASCADE"),
    ("pedido_servico", "servico_id", "servico_adicional", "N", "1", "RESTRICT"),
    ("pedido_evento", "pedido_id", "pedido", "N", "1", "CASCADE"),
    ("comprovante", "parada_id", "pedido_parada", "N", "1", "CASCADE"),
    ("ocorrencia", "pedido_id", "pedido", "N", "1", "CASCADE"),
    ("ocorrencia", "parada_id", "pedido_parada", "0..N", "0..1", "SET NULL"),
    ("oferta", "pedido_id", "pedido", "N", "1", "CASCADE"),
    ("oferta", "motorista_id", "motorista", "0..N", "0..1", "CASCADE"),
    ("oferta", "transportadora_id", "empresa", "0..N", "0..1", "CASCADE"),
    ("motorista_favorito", "cliente_id", "usuario", "N", "1", "CASCADE"),
    ("motorista_favorito", "motorista_id", "motorista", "N", "1", "CASCADE"),
    ("convite_motorista", "cliente_id", "usuario", "N", "1", "CASCADE"),
    ("avaliacao", "pedido_id", "pedido", "N", "1", "CASCADE"),
    ("avaliacao", "autor_id", "usuario", "N", "1", "CASCADE"),
    ("avaliacao", "avaliado_id", "usuario", "0..N", "0..1", "CASCADE"),
    ("avaliacao", "empresa_id", "empresa", "0..N", "0..1", "CASCADE"),
    ("carteira", "usuario_id", "usuario", "0..N", "0..1", "CASCADE"),
    ("carteira", "empresa_id", "empresa", "0..N", "0..1", "CASCADE"),
    ("transacao_carteira", "carteira_id", "carteira", "N", "1", "CASCADE"),
    ("transacao_carteira", "pedido_id", "pedido", "0..N", "0..1", "SET NULL"),
    ("cupom_uso", "cupom_id", "cupom", "N", "1", "CASCADE"),
    ("cupom_uso", "cliente_id", "usuario", "N", "1", "CASCADE"),
    ("cupom_uso", "pedido_id", "pedido", "N", "1", "CASCADE"),
    ("repasse", "motorista_id", "motorista", "0..N", "0..1", "CASCADE"),
    ("repasse", "transportadora_id", "empresa", "0..N", "0..1", "CASCADE"),
    ("notificacao", "usuario_id", "usuario", "N", "1", "CASCADE"),
    ("notificacao", "pedido_id", "pedido", "0..N", "0..1", "SET NULL"),
]

FONT = "Helvetica"


def escapar(txt):
    return (txt.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
               .replace('"', "&quot;"))


def marcador(flag):
    partes = flag.split(",") if flag else []
    if "PF" in partes:
        return "PK/FK"
    if "PK" in partes and "FK" in partes:
        return "PK/FK"
    if "PK" in partes:
        return "PK"
    if "FK" in partes:
        return "FK"
    if "UK" in partes:
        return "UK"
    return ""


def gerar_label_tabela(nome, dados):
    cor = DOMINIOS[dados["dominio"]]
    linhas = []
    linhas.append(
        f'<TR><TD COLSPAN="3" BGCOLOR="{cor}" ALIGN="CENTER">'
        f'<FONT COLOR="white" FACE="{FONT}" POINT-SIZE="15"><B>{escapar(nome)}</B></FONT></TD></TR>'
    )
    for col_nome, tipo, flag, enum_vals in dados["cols"]:
        marca = marcador(flag)
        negrito_ini, negrito_fim = ("<B>", "</B>") if marca in ("PK", "PK/FK") else ("", "")
        cor_marca = "#B23B3B" if marca in ("PK", "PK/FK") else ("#2C5985" if marca == "FK" else "#6B4C9A")
        marca_html = (
            f'<FONT COLOR="{cor_marca}" FACE="{FONT}" POINT-SIZE="10"><B>{marca}</B></FONT>' if marca else ""
        )
        linhas.append(
            '<TR>'
            f'<TD ALIGN="LEFT" PORT="{escapar(col_nome)}" BGCOLOR="white">'
            f'<FONT FACE="{FONT}" POINT-SIZE="11">{negrito_ini}{escapar(col_nome)}{negrito_fim}</FONT></TD>'
            f'<TD ALIGN="LEFT" BGCOLOR="white"><FONT FACE="{FONT}" POINT-SIZE="10" COLOR="#444444">{escapar(tipo)}</FONT></TD>'
            f'<TD ALIGN="CENTER" BGCOLOR="white" WIDTH="34">{marca_html}</TD>'
            '</TR>'
        )
        if enum_vals:
            lista = ", ".join(enum_vals)
            linhas.append(
                '<TR><TD COLSPAN="3" ALIGN="LEFT" BGCOLOR="#F2F2F2">'
                f'<FONT FACE="{FONT}" POINT-SIZE="8" COLOR="#777777">{escapar(lista)}</FONT></TD></TR>'
            )
    tabela_html = (
        f'<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="4" COLOR="#999999">'
        + "".join(linhas) + "</TABLE>>"
    )
    return tabela_html


def main():
    out = []
    out.append("digraph SolusFreteER {")
    out.append('  rankdir=TB;')
    out.append('  graph [fontname="%s", splines=curved, nodesep=0.55, ranksep=1.3, bgcolor="white", concentrate=false];' % FONT)
    out.append('  node [shape=plain, fontname="%s"];' % FONT)
    out.append('  edge [fontname="%s", fontsize=9, color="#9A9A9A", penwidth=1.1, arrowsize=0.7];' % FONT)
    out.append('  label="Solus Frete - Diagrama Entidade-Relacionamento (schema MySQL, db/01_schema.sql)";')
    out.append('  labelloc="t"; fontsize=20; fontname="%s";' % FONT)
    out.append("")

    # agrupa por dominio em subgraphs (clusters) para o layout ficar organizado
    por_dominio = {}
    for nome, dados in TABELAS.items():
        por_dominio.setdefault(dados["dominio"], []).append(nome)

    for i, (dominio, tabelas) in enumerate(por_dominio.items()):
        cor = DOMINIOS[dominio]
        out.append(f'  subgraph cluster_{i} {{')
        out.append(f'    label="{dominio}"; fontsize=16; fontname="{FONT}"; fontcolor="{cor}";')
        out.append(f'    color="{cor}"; style="rounded"; penwidth=1.6; margin=16;')
        for nome in tabelas:
            label = gerar_label_tabela(nome, TABELAS[nome])
            out.append(f'    {nome} [label={label}];')
        out.append("  }")
        out.append("")

    for origem, coluna, destino, card_muitos, card_um, on_delete in RELACIONAMENTOS:
        # liga caixa a caixa (sem porta de coluna): evita a linha cruzar por cima
        # do texto de outras colunas dentro da tabela.
        out.append(
            f'  {origem} -> {destino} '
            f'[taillabel="{card_muitos}", headlabel="{card_um}", labeldistance=2.2, '
            f'labelfontsize=9, labelfontcolor="#333333", arrowhead=vee, arrowtail=none];'
        )

    out.append("}")

    docs = Path(__file__).resolve().parent.parent / "docs"
    docs.mkdir(exist_ok=True)
    dot_path = docs / "diagrama-er.dot"
    dot_path.write_text("\n".join(out), encoding="utf-8")
    print("diagrama-er.dot gerado:", len(TABELAS), "tabelas,", len(RELACIONAMENTOS), "relacionamentos")

    if shutil.which("dot") is None:
        print("Graphviz nao encontrado (brew install graphviz): so o .dot foi gerado.")
        return
    for formato, extra in (("png", ["-Gdpi=300"]), ("svg", []), ("pdf", [])):
        destino = docs / f"diagrama-er.{formato}"
        subprocess.run(["dot", f"-T{formato}", *extra, str(dot_path), "-o", str(destino)], check=True)
        print("gerado:", destino)


if __name__ == "__main__":
    main()
