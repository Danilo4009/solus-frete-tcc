# Solus Frete — protótipo funcional

Protótipo do aplicativo **Solus Frete**, plataforma de fretes com motoristas parceiros,
transportadoras e entregas agendadas. Construído para o TCC de Sistemas de Informação
e para a disciplina de Gestão de Projetos.

Os requisitos que originaram este protótipo estão no documento
`levantamento-requisitos-solus-frete.md`, resultado da análise funcional de um
aplicativo concorrente consolidado no mercado brasileiro.

## O que está aqui

```
solus-frete/
├── db/                 esquema e dados iniciais do MySQL
│   ├── 01_schema.sql   24 tabelas + 1 view
│   └── 02_seed.sql     catálogo, tabelas de preço, usuários e pedidos de exemplo
├── api/                API REST em Node + Express + MySQL
│   ├── src/server.js   ponto de entrada
│   ├── src/db.js       pool de conexões e helper de transação
│   ├── src/precificacao.js  motor de cálculo do frete
│   └── src/routes/     auth, catalogo, cotacao, enderecos, pedidos, perfil
└── app/                aplicativo Flutter (cliente + cadastros de parceiro)
    └── lib/
        ├── core/       tema, formatação e widgets compartilhados
        ├── modelos/    modelos de domínio
        ├── dados/      contrato de repositório + implementação mock e implementação API
        ├── estado/     Sessao e NovoPedido (Provider/ChangeNotifier)
        └── telas/      16 telas do fluxo
```

## Como rodar

### 1. O app sozinho, sem backend

O protótipo já vem com um repositório em memória que reproduz as mesmas regras da
API, inclusive o cálculo de preço. Serve para apresentar o fluxo em sala sem
depender de rede ou banco.

```bash
cd app
flutter pub get
flutter run
```

Login de demonstração: telefone `11940135904`, senha `solus123` (já preenchidos na tela).

### 2. Com o MySQL e a API

**Banco** — a equipe toda aponta para a mesma instância:

```bash
mysql -u root -p < db/01_schema.sql
mysql -u root -p solus_frete < db/02_seed.sql
```

**API**:

```bash
cd api
npm install
cp .env.example .env     # ajuste DB_HOST, DB_USER, DB_PASSWORD
npm start                # http://localhost:3333
curl http://localhost:3333/health
```

**App** — em `app/lib/core/config.dart`:

```dart
static const bool usarApi = true;
static const String baseUrl = 'http://10.0.2.2:3333';  // emulador Android
// iOS simulador ou desktop: http://localhost:3333
// celular físico na mesma rede: http://SEU_IP_LOCAL:3333
```

Para a equipe compartilhar o banco, qualquer MySQL acessível serve: uma máquina da
equipe com a porta liberada na rede local, um servidor da faculdade, ou uma instância
gerenciada gratuita. Só mude `DB_HOST` no `.env` de cada um — o esquema e o seed são
os mesmos.

### 3. Mapa

O protótipo desenha um mapa esquemático em canvas (`MapaSimulado`), sem chave de API,
para não quebrar na apresentação. Quando quiserem o Google Maps de verdade: adicione
`google_maps_flutter` ao `pubspec.yaml`, configure a chave no Android e no iOS, troque
`Config.usarMapaReal` para `true` e substitua o widget `MapaSimulado` por `GoogleMap`
nas três telas que o usam (novo pedido, detalhes do endereço e acompanhamento).

## Fluxos implementados

**Cliente**: login e cadastro; busca de endereço com favoritos, recentes e complemento
com contato no local; roteiro com múltiplas paradas e inversão de sentido; retirada
imediata ou agendada; catálogo de veículos com ficha técnica (dimensões, capacidade e
serviços disponíveis); serviços adicionais por categoria; contratação por período (4h,
6h, 8h); detalhes da carga com tipo, volumes, faixa de peso e instruções de manuseio;
cotação em três níveis de serviço com detalhamento do preço; cupom de desconto;
prioridade para motoristas favoritos; exigência de comprovante de entrega; pagamento
por carteira, Pix, cartão ou dinheiro com escolha do pagador (frete a pagar); revisão e
confirmação; acompanhamento com mapa, linha do tempo e dados do parceiro; simulação da
máquina de estados; cancelamento com regra de taxa por etapa; avaliação com opção de
favoritar; histórico com abas e busca; motoristas favoritos com convite por telefone;
carteira com saldo, recarga e extrato; caixa de entrada; perfil e preferências.

**Parceiros**: cadastro de motorista em três passos (dados pessoais, habilitação com
validade e anexo, veículo com categoria e documento) e cadastro de transportadora em
três passos (empresa com CNPJ e registro ANTT, responsável legal, frota inicial). Ambos
terminam em homologação pela operação, conforme o requisito RF06.

## Regras de negócio no código

| Regra | Onde está |
|---|---|
| Pedido só confirma com roteiro, veículo e forma de pagamento | `NovoPedido.pendenciasParaConfirmar` e `routes/pedidos.js` |
| Peso declarado não pode exceder a capacidade do veículo | `NovoPedido.avisoCapacidade` e validação HTTP 422 na API |
| Agendamento precisa ser no futuro | `NovoPedido` e `routes/pedidos.js` |
| Aceite de itens proibidos obrigatório | `TelaRevisao` e `routes/pedidos.js` |
| Oferta aos favoritos antes da base geral | `routes/pedidos.js`, bloco de alocação |
| Cancelamento sem taxa antes da alocação, 15% depois, bloqueado após a coleta | `POST /pedidos/:id/cancelar` |
| Comissão da plataforma sobre o valor do frete | `precificacao.repasseParceiro` |
| Cupom só vale acima do valor mínimo do pedido | `precificacao.aplicarCupom` |

## Calibragem do preço

O motor usa `tarifa_base + valor_por_km × km + valor_por_parada × paradas_extras`,
respeitando o valor mínimo da categoria, multiplicado pelo fator do nível de serviço
(expresso 1,45; padrão 1,00; econômico 0,74). Na mesma rota testada no aplicativo de
referência (Osasco → Avenida Paulista, carreto) o resultado ficou em R$ 225,67 /
R$ 155,64 / R$ 115,21 contra R$ 229,02 / R$ 152,68 / R$ 114,51 do concorrente — ou seja,
a estrutura de preço reproduz a ordem de grandeza do mercado.

Isso é calibragem de protótipo, não precificação de negócio. A tabela definitiva precisa
partir de custo operacional próprio e da comissão que vocês decidirem praticar; os dois
pontos continuam abertos no documento de requisitos.

## Endpoints da API

```
GET    /health
POST   /auth/login
POST   /auth/registro/cliente
POST   /auth/registro/motorista
POST   /auth/registro/transportadora
GET    /catalogo/veiculos?cidade=
GET    /catalogo/cidades
GET    /catalogo/servicos
POST   /cotacao
GET    /enderecos
GET    /enderecos/busca?q=
POST   /enderecos
PATCH  /enderecos/:id/favorito
DELETE /enderecos/:id
GET    /pedidos?situacao=&q=
GET    /pedidos/:id
POST   /pedidos
POST   /pedidos/:id/avancar
POST   /pedidos/:id/cancelar
POST   /pedidos/:id/avaliar
GET    /perfil
PUT    /perfil
GET    /perfil/carteira
POST   /perfil/carteira/recarga
GET    /perfil/favoritos
POST   /perfil/favoritos/convite
DELETE /perfil/favoritos/:motoristaId
GET    /perfil/notificacoes
PATCH  /perfil/notificacoes/:id/lida
```

Rotas sob `/enderecos`, `/pedidos` e `/perfil` exigem `Authorization: Bearer <token>`,
obtido no login. Senha de todos os usuários do seed: `solus123`.

## O que ficou fora de propósito

Cadastro de cartão de crédito (fora do protótipo por segurança), upload real de
documentos (o anexo é simulado), app do motorista e painel da transportadora como
aplicativos próprios, recomendação de veículo por foto, programa de fidelidade e
indicação de amigos. Tudo isso está mapeado nas fases 2 e 3 do backlog no documento de
requisitos.
