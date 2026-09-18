# Solus Frete — Levantamento de Requisitos

**Projeto:** TRABALHO SOLUS FRETE (TCC + Gestão de Projetos)
**Data do levantamento:** 17/09/2026
**Método:** análise exploratória de aplicativo concorrente (benchmark funcional) + derivação de requisitos
**Benchmark analisado:** Lalamove BR (iOS, v116.4.2), região São Paulo e Campinas
**Escopo do produto:** marketplace de fretes com motoristas parceiros, transportadoras e entregas agendadas
**Plataforma do protótipo:** Flutter

---

## 1. Contexto e objetivo

O Solus Frete é uma plataforma de intermediação de fretes que conecta quem precisa transportar carga a quem tem veículo disponível. Diferente de um aplicativo puramente on-demand urbano, o Solus Frete opera em três frentes simultâneas: motoristas parceiros autônomos, transportadoras (que operam frota e motoristas próprios sob um CNPJ) e entregas agendadas com data e hora combinadas.

O levantamento a seguir foi construído a partir da navegação completa de um aplicativo concorrente consolidado no mercado brasileiro, tela por tela, com o objetivo de mapear o conjunto de funcionalidades que o mercado já considera padrão. Cada funcionalidade observada foi classificada em três categorias: adotar (faz parte do MVP), adaptar (existe no concorrente mas precisa de ajuste para o modelo do Solus) e descartar ou postergar (não pertence ao recorte atual). Sobre essa base foram acrescentados os requisitos próprios do Solus Frete que não têm equivalente no benchmark, principalmente os ligados a transportadoras.

---

## 2. Atores do sistema

| Ator | Descrição | Principais responsabilidades |
|---|---|---|
| Cliente PF | Pessoa física que solicita frete pontual | Solicitar, acompanhar, pagar e avaliar |
| Cliente PJ | Empresa que solicita fretes recorrentes | Solicitar, gerenciar carteira compartilhada, extrair relatórios, gerenciar usuários da conta |
| Motorista parceiro | Autônomo com veículo próprio cadastrado | Receber ofertas, aceitar, executar coleta e entrega, registrar comprovantes |
| Transportadora | Empresa com frota e motoristas vinculados | Cadastrar frota e motoristas, aceitar cargas em nome da empresa, distribuir entre motoristas, acompanhar operação |
| Administrador Solus | Operação interna da plataforma | Homologar cadastros e documentos, configurar tabelas de preço, mediar ocorrências, monitorar indicadores |

---

## 3. Funcionalidades mapeadas no benchmark

### 3.1 Tela inicial e montagem do pedido

| # | Funcionalidade observada | Decisão |
|---|---|---|
| B01 | Endereço de origem pré-preenchido com o último local usado ou GPS | Adotar |
| B02 | Campo de destino ("Para onde?") com autocomplete | Adotar |
| B03 | Botão de inverter origem e destino | Adotar |
| B04 | Adicionar paradas extras ao roteiro (multi-drop) | Adotar |
| B05 | Seletor de horário de retirada: "Agora" ou "Agendar" com roda de dia/hora/minuto | Adotar — central no Solus |
| B06 | Catálogo de veículos em grade com ícone e nome | Adotar |
| B07 | Modalidade "Serviço por hora" (4h e 6h) — veículo e motorista à disposição | Adaptar — vira "diária/período" |
| B08 | Ficha técnica do veículo: dimensões úteis, peso máximo, descrição de uso | Adotar |
| B09 | Recomendação de veículo por IA a partir de foto da carga | Postergar — diferencial de fase 2 |
| B10 | Serviços adicionais por tipo de veículo, com faixa de preço | Adotar |

**Catálogo de veículos do concorrente:** LalaGo (moto), LalaPro, Carro Hatch, Carro, Utilitário e Pick-Up, Van, Carreto, Caminhão 2.5 Ton. Cada um com variante "serviço por 4h" ou "por 6h".

**Exemplo de ficha técnica observada (Carreto):** 3 m × 1,8 m × 2 m, máximo 1.500 kg, "ideal para mudanças ou materiais grandes e pesados", 4 serviços adicionais disponíveis.

**Serviços adicionais observados, com faixa de preço:** mudança de casa com motorista e assistente extra (R$ 145,00–215,00), ajuda do motorista porta a porta com carga e descarga (R$ 50,00–120,00), ajuda do motorista e assistente extra porta a porta (R$ 90,00–190,00), tempo de espera (R$ 25,00–82,00).

**Tabela de capacidade publicada por cidade e veículo:** limite de peso e volume por categoria (exemplo: moto com 20 kg e 35 × 40 × 30 cm).

### 3.2 Endereços

| # | Funcionalidade observada | Decisão |
|---|---|---|
| B11 | Busca textual por rua e número | Adotar |
| B12 | Uso da localização atual via GPS | Adotar |
| B13 | Endereços salvos (favoritos) | Adotar |
| B14 | Endereços recentes (histórico) | Adotar |
| B15 | Pin arrastável no mapa para ajuste fino do ponto | Adotar |
| B16 | Detalhes do endereço: complemento, ponto de referência, telefone do contato, nome do contato | Adotar |
| B17 | Importar telefone da lista de contatos do dispositivo | Adotar |
| B18 | Opção de salvar o endereço para uso futuro | Adotar |
| B19 | Reportar localização incorreta ou ausente no mapa | Postergar |

### 3.3 Cotação e precificação

| # | Funcionalidade observada | Decisão |
|---|---|---|
| B20 | Cotação automática após origem e destino definidos | Adotar |
| B21 | Três níveis de serviço com preços distintos | Adotar |
| B22 | Detalhamento do preço: taxa de entrega, cupons aplicados, total | Adotar |
| B23 | Sinalização de preço dinâmico ("está R$ 26,94 mais barato agora") | Adaptar |
| B24 | Aviso de que pedágio e estacionamento são acertados direto com o motorista | Adotar |
| B25 | Aplicação de cupom de desconto na cotação | Adotar |

**Níveis de serviço observados na mesma rota e veículo:** Prioridade R$ 229,02 ("alocação rápida para entregas expressas", marcado como melhor escolha), Regular R$ 152,68 (padrão selecionado), Agrupado R$ 114,51 ("economize — espaço dividido e entrega sem urgência"). A diferença entre o mais caro e o mais barato foi de cerca de 100%, o que mostra que o nível de serviço é uma alavanca comercial importante, não um detalhe.

### 3.4 Detalhes da carga e do pedido

| # | Funcionalidade observada | Decisão |
|---|---|---|
| B26 | Tipo de item: alimentos/mercado, material de construção, roupas e itens pessoais, móveis e eletrodomésticos, itens frágeis, outros | Adotar |
| B27 | Número de pacotes (contador) | Adotar |
| B28 | Faixa de peso total (menos de 300 kg, 300 a 750 kg, 750 kg ou mais) | Adotar |
| B29 | Instruções de manuseio: frágil, não empilhar, entre outras | Adotar |
| B30 | Campo livre de notas e informações para o motorista | Adotar |
| B31 | Telefone de contato do pedido | Adotar |
| B32 | Chave "Motoristas favoritos primeiro" | Adotar — essencial no Solus |
| B33 | Declaração de itens proibidos vinculada aos termos de uso | Adotar |

### 3.5 Pagamento

| # | Funcionalidade observada | Decisão |
|---|---|---|
| B34 | Carteira interna com saldo e recarga | Adotar |
| B35 | Pagamento online via Pix | Adotar |
| B36 | Pagamento em dinheiro com seleção de quem paga: remetente ou destinatário (frete a pagar) | Adotar |
| B37 | Cartões de crédito e débito salvos | Adotar |
| B38 | Histórico de transações da carteira | Adotar |
| B39 | Cupons na carteira | Adotar |
| B40 | Forma de pagamento obrigatória antes de revisar o pedido | Adotar como regra de negócio |

### 3.6 Motoristas parceiros e favoritos

Este foi o bloco mais relevante para o Solus Frete, porque o modelo de motoristas parceiros do concorrente é exatamente o que o projeto pretende oferecer. As regras documentadas no FAQ do próprio aplicativo:

| # | Funcionalidade observada | Decisão |
|---|---|---|
| B41 | Lista de motoristas favoritos do cliente | Adotar |
| B42 | Convidar um motorista conhecido pelo número de telefone; a plataforma envia SMS convidando-o a se tornar parceiro e, uma vez ativado o cadastro, ele entra na lista de favoritos do cliente | Adotar |
| B43 | Favoritar o motorista ao concluir e avaliar o pedido | Adotar |
| B44 | Prioridade de oferta: favoritos recebem a notificação do pedido alguns segundos antes dos demais; se nenhum aceitar, a oferta segue para a base geral de parceiros | Adotar |
| B45 | FAQ explicando a diferença entre contratar pela plataforma e contratar o motorista por fora (pagamento virtual, segurança, substituição automática) | Adotar como conteúdo |

### 3.7 Pedidos e acompanhamento

| # | Funcionalidade observada | Decisão |
|---|---|---|
| B46 | Lista de pedidos com abas Em andamento, Concluído e Cancelado | Adotar |
| B47 | Busca em todos os pedidos | Adotar |
| B48 | Comprovante de entrega: assinatura ou foto após a entrega (configurável) | Adotar |
| B49 | Recibo eletrônico enviado por e-mail | Adotar |

### 3.8 Funcionalidade destacada: formulário de entrega compartilhável

O concorrente marca como novidade um recurso em que o remetente define o ponto de coleta, gera um formulário e o compartilha com os destinatários; cada destinatário preenche os próprios dados de entrega e o remetente é avisado para então solicitar o pedido. O argumento de venda é reduzir erro de endereço.

Para o Solus Frete isso resolve um problema real de operação com transportadoras e clientes PJ, que frequentemente montam romaneios com endereços recebidos de terceiros. **Decisão: adotar, com prioridade alta na fase 2.**

### 3.9 Conta, relacionamento e configurações

| # | Funcionalidade observada | Decisão |
|---|---|---|
| B50 | Perfil: foto, nome, sobrenome, celular com selo de verificado, e-mail, setor de atuação | Adotar |
| B51 | Perfil comercial gratuito com relatórios mensais, carteiras compartilhadas e painel analítico | Adotar — vira conta PJ |
| B52 | Programa de fidelidade com pontos por pedido e catálogo de recompensas, com adesão opt-in e aceite de termos | Postergar |
| B53 | Indique um amigo e ganhe cupons | Postergar |
| B54 | Central de ajuda | Adotar em versão simplificada |
| B55 | Autenticação por senha e por passkey (chave de acesso) | Adotar senha no MVP |
| B56 | Preferências: e-mail de recibos, comprovante de entrega, idioma, notificações | Adotar parcialmente |
| B57 | Caixa de entrada com abas Notificações e Promoções | Adotar |
| B58 | Seleção de região de operação (cidade) | Adotar |
| B59 | Página pública de padrão de preços por cidade e veículo | Adotar |

---

## 4. Requisitos funcionais do Solus Frete

### 4.1 Módulo de identidade e cadastro

| ID | Requisito | Prioridade |
|---|---|---|
| RF01 | O sistema deve permitir cadastro e login de cliente por telefone com verificação por código SMS | Must |
| RF02 | O sistema deve permitir cadastro de cliente PJ com CNPJ, razão social e usuários vinculados à mesma conta | Must |
| RF03 | O sistema deve permitir cadastro de motorista parceiro com dados pessoais, CNH, dados do veículo e documento do veículo | Must |
| RF04 | O sistema deve permitir cadastro de transportadora com CNPJ, registro ANTT, responsável legal e endereço | Must |
| RF05 | A transportadora deve poder vincular e desvincular motoristas e veículos à sua frota | Must |
| RF06 | O sistema deve submeter cadastros de motorista, veículo e transportadora à homologação do administrador antes de liberar operação | Must |
| RF07 | O sistema deve manter o perfil do usuário editável: foto, nome, sobrenome, e-mail, telefone verificado e setor de atuação | Should |
| RF08 | O sistema deve registrar validade dos documentos e bloquear a operação do parceiro quando um documento obrigatório estiver vencido | Should |

### 4.2 Módulo de endereços

| ID | Requisito | Prioridade |
|---|---|---|
| RF09 | O sistema deve permitir busca de endereço por texto com sugestões automáticas | Must |
| RF10 | O sistema deve permitir capturar a localização atual do dispositivo como endereço | Must |
| RF11 | O sistema deve permitir ajuste fino do ponto arrastando o marcador no mapa | Should |
| RF12 | O sistema deve armazenar endereços favoritos por usuário, com apelido | Must |
| RF13 | O sistema deve exibir os endereços utilizados recentemente | Should |
| RF14 | Cada endereço do pedido deve aceitar complemento, ponto de referência, nome e telefone do contato no local | Must |
| RF15 | O sistema deve permitir importar o telefone do contato a partir da agenda do dispositivo | Could |

### 4.3 Módulo de solicitação de frete

| ID | Requisito | Prioridade |
|---|---|---|
| RF16 | O sistema deve permitir montar um pedido com um ponto de coleta e um ou mais pontos de entrega | Must |
| RF17 | O sistema deve permitir reordenar e inverter os pontos do roteiro | Should |
| RF18 | O sistema deve permitir escolher entre retirada imediata e retirada agendada, com data e hora | Must |
| RF19 | O sistema deve permitir agendamento recorrente para clientes PJ (mesma rota em dias definidos da semana) | Should |
| RF20 | O sistema deve apresentar o catálogo de veículos disponíveis para a rota, com ficha técnica: dimensões úteis, peso máximo e descrição de uso | Must |
| RF21 | O sistema deve permitir a contratação de veículo por período (diária de 4h, 6h ou 8h) com motorista à disposição | Should |
| RF22 | O sistema deve permitir a seleção de serviços adicionais compatíveis com o veículo escolhido, exibindo o preço de cada um | Must |
| RF23 | O sistema deve registrar os detalhes da carga: tipo de item, número de volumes, faixa de peso e instruções de manuseio | Must |
| RF24 | O sistema deve permitir notas livres direcionadas ao motorista | Must |
| RF25 | O sistema deve exigir aceite da declaração de itens proibidos antes de confirmar o pedido | Must |
| RF26 | O sistema deve permitir anexar documentos fiscais da carga (nota fiscal, romaneio) para fretes agendados e de transportadora | Should |

### 4.4 Módulo de cotação e preço

| ID | Requisito | Prioridade |
|---|---|---|
| RF27 | O sistema deve calcular a cotação automaticamente a partir da rota, do veículo e dos serviços adicionais | Must |
| RF28 | A cotação deve apresentar no mínimo três níveis de serviço com preços distintos: Expresso, Padrão e Econômico (carga agrupada) | Must |
| RF29 | O sistema deve exibir o detalhamento do preço: tarifa base, valor por distância, serviços adicionais, descontos e total | Must |
| RF30 | O sistema deve informar explicitamente quais despesas não estão inclusas (pedágio, estacionamento) e como são acertadas | Must |
| RF31 | O sistema deve permitir aplicar cupom de desconto, validando regras de uso | Should |
| RF32 | O administrador deve poder configurar tabelas de preço por cidade, veículo e nível de serviço | Must |
| RF33 | Para transportadoras, o sistema deve permitir o modo cotação sob demanda, em que a empresa responde com proposta de valor e prazo em vez de usar a tabela automática | Should |
| RF34 | O sistema deve publicar a tabela de capacidades e o padrão de preços por cidade em área consultável pelo cliente | Could |

### 4.5 Módulo de alocação e motoristas parceiros

| ID | Requisito | Prioridade |
|---|---|---|
| RF35 | O sistema deve ofertar o pedido aos parceiros elegíveis considerando categoria do veículo, proximidade e disponibilidade | Must |
| RF36 | O cliente deve poder manter uma lista de motoristas parceiros favoritos | Must |
| RF37 | O cliente deve poder ativar a opção de ofertar primeiro aos seus favoritos, com janela de exclusividade configurável antes de liberar para a base geral | Must |
| RF38 | O cliente deve poder convidar um motorista conhecido informando o telefone; o sistema envia convite e, após homologação, o vincula como favorito daquele cliente | Should |
| RF39 | O cliente deve poder favoritar o motorista no momento da avaliação do pedido concluído | Should |
| RF40 | A transportadora deve poder aceitar uma carga em nome da empresa e, em seguida, designar qual motorista da frota executará o serviço | Must |
| RF41 | O sistema deve permitir que o parceiro recuse a oferta e deve repassá-la ao próximo elegível sem intervenção manual | Must |
| RF42 | Para fretes agendados, o sistema deve confirmar a alocação com antecedência e notificar cliente e motorista com lembrete antes da janela de coleta | Must |

### 4.6 Módulo de execução e rastreamento

| ID | Requisito | Prioridade |
|---|---|---|
| RF43 | O cliente deve acompanhar o pedido em tempo real, com a posição do veículo no mapa e o estágio atual | Must |
| RF44 | O sistema deve manter a máquina de estados do pedido: rascunho, cotado, aguardando alocação, alocado, em deslocamento para coleta, carregando, em trânsito, entregue, concluído, cancelado | Must |
| RF45 | O motorista deve registrar a coleta e cada entrega com comprovante: foto da carga e assinatura ou foto do recebedor, conforme configuração do pedido | Must |
| RF46 | O sistema deve disponibilizar canal de contato entre cliente e motorista durante o pedido ativo, sem expor os números pessoais | Should |
| RF47 | O sistema deve registrar ocorrências durante a execução (avaria, destinatário ausente, endereço inacessível) com foto e observação | Should |
| RF48 | O sistema deve permitir cancelamento com aplicação das regras de taxa conforme o estágio do pedido | Must |
| RF49 | O sistema deve calcular e registrar tempo de espera excedente para cobrança do serviço adicional correspondente | Could |

### 4.7 Módulo de pagamento e financeiro

| ID | Requisito | Prioridade |
|---|---|---|
| RF50 | O sistema deve oferecer as formas de pagamento: carteira interna, Pix, cartão de crédito e dinheiro | Must |
| RF51 | O sistema deve permitir definir quem paga o frete em dinheiro: remetente ou destinatário (frete a pagar) | Must |
| RF52 | O sistema deve exigir a definição da forma de pagamento antes de permitir a confirmação do pedido | Must |
| RF53 | O sistema deve manter carteira com saldo, recarga e extrato de transações | Should |
| RF54 | Clientes PJ devem poder operar carteira compartilhada entre os usuários da conta, com limite por usuário | Should |
| RF55 | O sistema deve emitir recibo eletrônico do pedido e enviá-lo ao e-mail cadastrado | Should |
| RF56 | O sistema deve calcular o repasse ao parceiro, descontando a comissão da plataforma, e registrar o valor a pagar por período | Must |
| RF57 | No caso de transportadora, o repasse deve ser consolidado no CNPJ da empresa, não no motorista executante | Must |

### 4.8 Módulo de histórico, avaliação e relatórios

| ID | Requisito | Prioridade |
|---|---|---|
| RF58 | O sistema deve listar os pedidos separados por situação: em andamento, concluídos e cancelados | Must |
| RF59 | O sistema deve permitir busca e filtro no histórico por período, endereço, veículo e situação | Should |
| RF60 | O cliente deve avaliar o motorista com nota e comentário ao final do pedido | Must |
| RF61 | O motorista deve poder avaliar o cliente | Could |
| RF62 | Clientes PJ devem ter relatórios de gastos por período, centro de custo e usuário, exportáveis | Should |
| RF63 | O administrador deve ter painel com indicadores de operação: pedidos por situação, taxa de aceite, tempo médio de alocação, cancelamentos e faturamento | Should |

### 4.9 Módulo de comunicação

| ID | Requisito | Prioridade |
|---|---|---|
| RF64 | O sistema deve enviar notificações push nos eventos do pedido: alocado, a caminho da coleta, coletado, a caminho da entrega, entregue | Must |
| RF65 | O sistema deve manter caixa de entrada no aplicativo com notificações operacionais e promoções separadas | Should |
| RF66 | O sistema deve permitir gerar e compartilhar link de formulário de entrega para que o destinatário preencha os próprios dados, notificando o remetente quando preenchido | Should |
| RF67 | O sistema deve oferecer central de ajuda com perguntas frequentes e abertura de atendimento | Should |

---

## 5. Requisitos não funcionais

| ID | Requisito |
|---|---|
| RNF01 | A cotação deve ser retornada ao cliente em até 3 segundos em condições normais de rede |
| RNF02 | A atualização da posição do veículo no rastreamento deve ocorrer em intervalo não superior a 15 segundos |
| RNF03 | O aplicativo deve funcionar em Android e iOS a partir de uma única base de código Flutter |
| RNF04 | O aplicativo deve manter funcionalidade mínima de consulta offline: pedidos recentes e dados do pedido em andamento em cache |
| RNF05 | Os dados pessoais devem ser tratados em conformidade com a LGPD, com base legal registrada, consentimento para uso de localização e política de retenção definida |
| RNF06 | Os números de telefone de cliente e motorista não devem ser expostos entre as partes; a comunicação deve ser mediada |
| RNF07 | As senhas devem ser armazenadas com hash e salt; o acesso à API deve usar token com expiração |
| RNF08 | Documentos enviados (CNH, CRLV, nota fiscal, comprovantes) devem ser armazenados com acesso restrito e link assinado temporário |
| RNF09 | A interface deve seguir um design system único, com contraste adequado e suporte a fontes ampliadas |
| RNF10 | O sistema deve registrar log de auditoria das alterações de situação do pedido, com autor e timestamp |
| RNF11 | A arquitetura deve suportar operação multi-cidade, com tabelas de preço e cobertura independentes por região |
| RNF12 | O consumo de bateria e de dados do aplicativo do motorista deve ser otimizado, considerando jornadas longas com GPS ativo |

---

## 6. Regras de negócio

| ID | Regra |
|---|---|
| RN01 | Um pedido só pode ser confirmado com origem, destino, veículo, detalhes da carga e forma de pagamento definidos |
| RN02 | O peso e o volume declarados não podem exceder a capacidade do veículo selecionado; o sistema deve sugerir o upgrade de categoria quando excederem |
| RN03 | Pedágio e estacionamento não integram a cotação e são acertados diretamente com o parceiro |
| RN04 | Fretes agendados só podem ser marcados dentro da janela de antecedência configurada e dentro do horário de operação da região |
| RN05 | A janela de exclusividade dos motoristas favoritos é limitada; esgotada, a oferta é liberada para a base geral automaticamente |
| RN06 | Cancelamento antes da alocação não gera taxa; após a alocação, aplica-se a taxa vigente; após a coleta, o pedido não pode ser cancelado, apenas convertido em ocorrência |
| RN07 | A comissão da plataforma incide sobre o valor do frete, não sobre os reembolsos de despesa |
| RN08 | Motorista ou veículo com documento vencido não recebe ofertas |
| RN09 | No frete a pagar, a entrega só é encerrada após a confirmação de recebimento do valor pelo parceiro |
| RN10 | Itens proibidos declarados na política não podem ser transportados; a declaração de aceite é registrada em cada pedido |

---

## 7. Histórias de usuário do MVP

**HU01 — Solicitar frete imediato.** Como cliente, quero informar coleta e entrega, escolher o veículo e ver o preço antes de confirmar, para decidir se contrato. *Aceite:* com origem e destino preenchidos, o sistema exibe os veículos compatíveis e, ao selecionar um, apresenta os três níveis de serviço com preços; a confirmação só é liberada após escolher a forma de pagamento.

**HU02 — Agendar frete.** Como cliente, quero marcar a coleta para um dia e hora futuros, para organizar minha operação. *Aceite:* o seletor permite escolher data e hora dentro da janela permitida; o pedido agendado aparece na aba Em andamento com a etiqueta de agendado e a data visível.

**HU03 — Priorizar meus motoristas de confiança.** Como cliente recorrente, quero que meus motoristas favoritos recebam a oferta antes dos demais, para trabalhar com quem já conheço. *Aceite:* com a opção ativa, os favoritos recebem a oferta na janela de exclusividade; esgotado o prazo sem aceite, a oferta segue para os demais parceiros e o cliente é informado.

**HU04 — Acompanhar a entrega.** Como cliente, quero ver onde está o veículo e em que etapa está o pedido, para informar meu destinatário. *Aceite:* a tela de acompanhamento mostra o mapa com a posição do veículo, a etapa atual, os dados do motorista e o contato mediado.

**HU05 — Aceitar e executar corrida.** Como motorista parceiro, quero receber ofertas compatíveis com meu veículo e registrar coleta e entrega, para ser remunerado com comprovação. *Aceite:* a oferta apresenta rota, veículo, valor do repasse e distância até a coleta; ao executar, o motorista registra foto na coleta e assinatura ou foto na entrega.

**HU06 — Distribuir cargas na frota.** Como transportadora, quero aceitar uma carga em nome da empresa e designar o motorista que vai executá-la, para usar minha frota. *Aceite:* a transportadora aceita a carga e escolhe, entre os motoristas homologados e disponíveis, quem executará; o pedido passa a exibir o motorista designado, e o repasse é consolidado no CNPJ da empresa.

**HU07 — Controlar gastos da empresa.** Como cliente PJ, quero relatório dos fretes por período e por usuário, para prestar contas. *Aceite:* o relatório lista pedidos com data, rota, veículo, usuário solicitante e valor, com total do período e exportação.

**HU08 — Pagar como preferir.** Como cliente, quero escolher entre carteira, Pix, cartão e dinheiro, e definir se o frete é pago na origem ou no destino. *Aceite:* escolhendo dinheiro, o sistema exige a indicação do pagador entre remetente e destinatário, e essa informação aparece na oferta enviada ao motorista.

---

## 8. Recorte do protótipo funcional em Flutter

O protótipo deve demonstrar o fluxo completo de valor, com dados simulados em camada de repositório trocável por API real. Telas propostas:

**App do cliente:** splash e login com código; home com mapa, campos de coleta e entrega e seletor "agora ou agendar"; seleção de veículo com ficha técnica e serviços adicionais; detalhes da carga; cotação com os três níveis de serviço e detalhamento de preço; escolha de pagamento com definição do pagador; revisão e confirmação; acompanhamento com mapa e linha do tempo de etapas; avaliação com opção de favoritar o motorista; histórico com as três abas; motoristas favoritos com convite por telefone; perfil e carteira.

**App do motorista parceiro:** login; painel de disponibilidade com chave de online e offline; oferta recebida com rota, valor de repasse e contagem para aceitar; execução passo a passo com registro de comprovantes; ganhos do período.

**Painel da transportadora:** cargas ofertadas à empresa; aceite e designação de motorista da frota; acompanhamento das cargas em execução; gestão de frota e motoristas.

Sugestão de organização: arquitetura em camadas com separação entre apresentação, domínio e dados; gerência de estado com Riverpod ou Bloc; navegação com go_router; mapa com google_maps_flutter; e repositórios com implementação fake no protótipo, para que a troca pela API não exija reescrever as telas.

---

## 9. Modelo de dados preliminar

**Usuario** (id, tipo: PF/PJ/motorista/transportadora/admin, nome, telefone, telefone_verificado, email, foto, criado_em)
**Empresa** (id, cnpj, razao_social, tipo: cliente_pj/transportadora, registro_antt, endereco, situacao_homologacao)
**Motorista** (id, usuario_id, transportadora_id nulo quando autônomo, cnh, validade_cnh, situacao, avaliacao_media)
**Veiculo** (id, motorista_id, categoria_id, placa, documento, validade_documento, situacao)
**CategoriaVeiculo** (id, nome, comprimento_m, largura_m, altura_m, peso_max_kg, descricao)
**ServicoAdicional** (id, nome, descricao, preco_min, preco_max, categorias_compatíveis)
**TabelaPreco** (id, cidade, categoria_id, nivel_servico, tarifa_base, valor_por_km, valor_por_parada, valor_hora)
**Endereco** (id, usuario_id, apelido, logradouro, numero, complemento, referencia, latitude, longitude, contato_nome, contato_telefone, favorito)
**Pedido** (id, cliente_id, empresa_id, categoria_id, nivel_servico, tipo_retirada: imediata/agendada, data_hora_agendada, situacao, valor_frete, valor_adicionais, desconto, valor_total, forma_pagamento, pagador: remetente/destinatario, motorista_id, transportadora_id, criado_em)
**PedidoParada** (id, pedido_id, sequencia, tipo: coleta/entrega, endereco_id, situacao, chegada_em, concluida_em)
**PedidoCarga** (id, pedido_id, tipo_item, volumes, faixa_peso, instrucoes_manuseio, observacoes)
**Comprovante** (id, parada_id, tipo: foto/assinatura, arquivo_url, registrado_em)
**Ocorrencia** (id, pedido_id, parada_id, tipo, descricao, foto_url, registrada_em)
**Avaliacao** (id, pedido_id, autor_id, avaliado_id, nota, comentario)
**MotoristaFavorito** (id, cliente_id, motorista_id, origem: convite/pos_pedido, criado_em)
**Carteira** (id, titular_id, saldo) e **TransacaoCarteira** (id, carteira_id, tipo, valor, pedido_id, criada_em)
**Cupom** (id, codigo, tipo_desconto, valor, regras, validade) e **CupomUso** (id, cupom_id, cliente_id, pedido_id)
**Repasse** (id, beneficiario_id, tipo_beneficiario, periodo, valor_bruto, comissao, valor_liquido, situacao)

---

## 10. Backlog priorizado

**Fase 1 — MVP do protótipo.** Cadastro e login, endereços com favoritos e recentes, montagem do pedido com multi-parada, retirada imediata e agendada, catálogo de veículos com ficha técnica, detalhes da carga, cotação em três níveis, serviços adicionais, formas de pagamento com definição do pagador, alocação com prioridade para favoritos, aceite pelo motorista, execução com comprovantes, rastreamento, histórico, avaliação, aceite e designação pela transportadora, notificações dos eventos do pedido.

**Fase 2 — Consolidação comercial.** Conta PJ com carteira compartilhada e relatórios, agendamento recorrente, formulário de entrega compartilhável, cotação sob demanda para transportadoras, anexo de documentos fiscais, registro de ocorrências, painel administrativo com indicadores, central de ajuda.

**Fase 3 — Diferenciação.** Recomendação de veículo por IA a partir de foto da carga, programa de fidelidade com pontos e recompensas, indicação de amigos com cupons, autenticação por passkey, otimização automática de roteiro em pedidos com muitas paradas, integração com ERP de clientes PJ.

---

## 11. Observações sobre o método

O levantamento foi feito por navegação direta no aplicativo concorrente, percorrendo o fluxo de pedido até a etapa anterior à confirmação e varrendo o menu completo: pedidos, carteira, métodos de pagamento, formulário de entrega, motoristas parceiros com o respectivo FAQ, fidelidade, configurações, perfil e caixa de entrada. Nenhum pedido foi efetivado e nenhum dado de pagamento foi cadastrado durante a análise.

Os valores de preço citados são de uma única consulta pontual, em uma rota específica de São Paulo, e servem apenas para dimensionar a diferença relativa entre os níveis de serviço — não como referência de tabela. A precificação do Solus Frete precisa ser construída a partir de custo operacional próprio, e essa definição é um item de trabalho em aberto.

Dois pontos permanecem em aberto e merecem decisão antes de fechar o escopo: o percentual de comissão da plataforma e o modelo de repasse aos parceiros, e a definição de quais cidades compõem a operação inicial, o que determina o esforço de cadastro de tabelas de preço e de cobertura.
