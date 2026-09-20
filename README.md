<p align="center">
  <img src="app/assets/icone_app.png" width="96" alt="Ícone Solus Frete" />
</p>

<h1 align="center">Solus Frete — protótipo funcional</h1>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white">
  <img alt="Node" src="https://img.shields.io/badge/API-Node%20%2B%20Express-339933?logo=node.js&logoColor=white">
  <img alt="MySQL" src="https://img.shields.io/badge/Banco-MySQL-4479A1?logo=mysql&logoColor=white">
  <img alt="Status" src="https://img.shields.io/badge/status-prot%C3%B3tipo%20acad%C3%AAmico-informational">
</p>

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
│   ├── 01_schema.sql   28 tabelas + 1 view
│   └── 02_seed.sql     catálogo, preços, usuários, pedidos de exemplo e os parceiros
│                       da cotação (42 motoristas autônomos e 11 transportadoras)
├── api/                API REST em Node + Express + MySQL
│   ├── src/server.js   ponto de entrada
│   ├── src/db.js       pool de conexões e helper de transação
│   ├── src/precificacao.js  motor de cálculo do frete
│   ├── src/ofertas.js  monta a cotação com os parceiros (4 motoristas + 6 transportadoras)
│   └── src/routes/     auth, catalogo, cotacao, enderecos, pedidos, perfil
└── app/                aplicativo Flutter (cliente + cadastros de parceiro)
    ├── lib/
    │   ├── core/       tema, formatação e widgets compartilhados
    │   ├── modelos/    modelos de domínio
    │   ├── dados/      contrato de repositório + implementação mock e implementação API
    │   ├── estado/     Sessao e NovoPedido (Provider/ChangeNotifier)
    │   └── telas/      16 telas do fluxo
    └── test/           testes da cotação por parceiros (flutter test)
```

## Como rodar

Clone o repositório antes de tudo:

```bash
git clone https://github.com/Danilo4009/solus-frete-tcc.git
cd solus-frete-tcc
```

### 1. O app sozinho, sem backend

O protótipo já vem com um repositório em memória que reproduz as mesmas regras da
API, inclusive o cálculo de preço. Serve para apresentar o fluxo em sala sem
depender de rede ou banco.

```bash
cd app
flutter pub get
flutter run --dart-define=USAR_API=false
```

Login de demonstração: telefone `11940135904`, senha `solus123` (já preenchidos na tela).

Para rodar os testes da cotação: `flutter test`.

### 2. Com o MySQL e a API

Cada integrante da equipe roda o próprio MySQL local — sem senha pra compartilhar,
sem expor nada na rede. Todo mundo usa o mesmo `01_schema.sql` e `02_seed.sql`, então
os dados de teste ficam idênticos em qualquer máquina.

**Banco:**

```bash
mysql -u root -p < db/01_schema.sql
mysql -u root -p solus_frete < db/02_seed.sql
```

> Mac com `brew install mysql`: o `root` não tem senha por padrão, então use
> `mysql -u root` (sem `-p`) nos dois comandos.
>
> O `01_schema.sql` apaga e recria o banco `solus_frete`. Se você já tinha dados de
> teste, eles se perdem.

**API:**

```bash
cd api
npm install
cp .env.example .env     # ajuste DB_HOST, DB_USER, DB_PASSWORD
npm start                # http://localhost:3333
curl http://localhost:3333/health
```

No protótipo, o parceiro escolhido pelo cliente aceita o pedido sozinho depois de alguns
segundos (`ACEITE_AUTOMATICO_SEGUNDOS` no `.env`, padrão 8).

**App** — o endereço da API vai por `--dart-define`, sem editar código:

```bash
flutter run                                              # emulador Android (10.0.2.2:3333)
flutter run --dart-define=API_URL=http://localhost:3333  # iOS simulador, desktop ou web
flutter run --dart-define=API_URL=http://SEU_IP:3333     # celular físico na mesma rede Wi-Fi
```

Se preferir um banco único compartilhado pela equipe (todos veem os mesmos pedidos em
tempo real), qualquer MySQL acessível pela rede serve — só ajustar `DB_HOST` no `.env`
de cada um para apontar pra essa instância em vez do `localhost`.

### 3. No celular

**iPhone** (precisa de um Mac):

1. Instale o Xcode e o CocoaPods (`brew install cocoapods`).
2. Abra `app/ios/Runner.xcworkspace`, vá em Runner → *Signing & Capabilities*, marque
   *Automatically manage signing* e escolha o seu *Personal Team* (Apple ID gratuito).
   **Troque o Bundle Identifier** (`com.danilo4009.solusFrete`) por um só seu; ele
   precisa ser único.
3. No iPhone, ative o **Modo Desenvolvedor** (Ajustes → Privacidade e Segurança), conecte
   o cabo e toque em *Confiar*.
4. Com a API rodando e o iPhone no mesmo Wi-Fi do computador:

   ```bash
   cd app
   flutter run --release --dart-define=API_URL=http://IP_DO_COMPUTADOR:3333
   ```

5. Na primeira vez, confie no seu perfil em Ajustes → Geral → VPN e Gerenciamento de
   Dispositivo.

O IP do Mac sai de `ipconfig getifaddr en0`. Se o macOS perguntar se o `node` pode aceitar
conexões, permita. Com Apple ID gratuito o app expira em 7 dias e precisa ser instalado de
novo. Use `--release` para abrir o app sem o cabo; builds de debug não abrem pela tela
inicial do iOS.

**Android** — o emulador funciona com o padrão (`10.0.2.2`). Num aparelho físico por USB,
a ideia é ativar a depuração USB e usar `adb reverse tcp:3333 tcp:3333` com
`--dart-define=API_URL=http://localhost:3333`. Esse caminho ainda não foi testado num
aparelho físico neste projeto.

### 4. Mapa

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
cotação com até 10 parceiros da região (4 motoristas autônomos e 6 transportadoras), com
filtro por tipo, ordenação por preço, prazo e avaliação e detalhamento do preço; escolha
do parceiro, que aceita ou recusa o pedido (simulado no protótipo) e, se recusar, o
cliente volta à lista para escolher outro; cupom de desconto; motoristas favoritos com
destaque na lista; exigência de comprovante de entrega; pagamento
por carteira, Pix, cartão ou dinheiro com escolha do pagador (frete a pagar); revisão e
confirmação; acompanhamento com mapa, linha do tempo e dados do parceiro; simulação da
máquina de estados; cancelamento com regra de taxa por etapa; avaliação com opção de
favoritar; histórico com abas e busca; motoristas favoritos com convite por telefone;
carteira com saldo, recarga e extrato; caixa de entrada; perfil e preferências.

**Parceiros**: cadastro de motorista em três passos (dados pessoais, habilitação com
validade e anexo, veículo com categoria e documento) e cadastro de transportadora em
três passos (empresa com CNPJ e registro ANTT, responsável legal, frota inicial). Ambos
terminam em homologação pela operação, conforme o requisito RF06.

## Cobertura do backlog

Situação de cada história de usuário do backlog no protótipo:

| História | Título | Situação | Observação |
|---|---|---|---|
| US01 | Login | Parcial | Entra por telefone e senha. Faltam login por e-mail, recuperação de senha, bloqueio após 3 tentativas e o aviso de LGPD |
| US02 | Cadastro de contratante | Parcial | Faltam CPF com validação, token por SMS ou e-mail e consentimento LGPD |
| US03 | Cadastro de transportadora | Parcial | Faltam validação do CNPJ, token e consentimento LGPD. Os anexos são simulados |
| US04 | Cadastro de motorista parceiro | Parcial | Faltam token, consentimento LGPD e o vínculo com uma transportadora. Os anexos são simulados |
| US05 | Solicitação do frete | Implementada | Imediato ou agendado, roteiro, carga, estimativa, revisão e status |
| US06 | Dados da carga | Parcial | Tipo, volumes, faixa de peso e instruções de manuseio. Não há dimensões nem nível de fragilidade |
| US07 | Origem e destino | Parcial | Busca de endereço e distância; a coleta define o raio dos parceiros. Faltam validação por CEP e escolha no mapa |
| US08 | Consulta e comparação de cotações | Implementada | 10 parceiros, filtro e ordenação; se o parceiro recusa, volta à lista |
| US09 | Consulta de avaliação | Parcial | Nota, total de fretes e "Sem avaliações ainda". Faltam os comentários e o perfil do parceiro |
| US10 | Comunicação (chat) | Não implementada | |
| US11 | Acompanhamento do frete | Parcial | Status e linha do tempo simulados; o mapa é esquemático, sem localização em tempo real |
| US12 | Demanda de fretes (transportadora) | Não implementada | Lado do parceiro fora do escopo do protótipo |
| US13 | Gestão de frota e motoristas | Não implementada | A frota vem só do cadastro e do seed |
| US14 | Ganhos da transportadora | Não implementada | |
| US15 | Demanda de fretes (motorista) | Não implementada | Lado do parceiro fora do escopo do protótipo |
| US16 | Ganhos do motorista | Não implementada | |

Fora do escopo (Won't): IA no canal de chat e nas rotas.

## Regras de negócio no código

| Regra | Onde está |
|---|---|
| Pedido só confirma com roteiro, veículo e forma de pagamento | `NovoPedido.pendenciasParaConfirmar` e `routes/pedidos.js` |
| Peso declarado não pode exceder a capacidade do veículo | `NovoPedido.avisoCapacidade` e validação HTTP 422 na API |
| Agendamento precisa ser no futuro | `NovoPedido` e `routes/pedidos.js` |
| Aceite de itens proibidos obrigatório | `TelaRevisao` e `routes/pedidos.js` |
| A cotação mostra até 10 parceiros: 4 motoristas autônomos e 6 transportadoras (se faltar de um tipo, completa com o outro) | `api/src/ofertas.js` (`selecionar`) e `RepositorioMock._montarCotacao` |
| Só entra na cotação parceiro aprovado, disponível, com veículo da categoria e coleta dentro do raio de atuação | `api/src/ofertas.js` (`montarCotacao`) |
| Motorista autônomo usa a tabela de preço da plataforma; transportadora tem preço próprio | `api/src/ofertas.js` e tabela `transportadora_preco` |
| Favoritos aparecem primeiro entre os motoristas; depois quem tem nota e o mais próximo da coleta | `api/src/ofertas.js` (`ordenar`) |
| O pedido vai só ao parceiro escolhido; se ele recusar, o pedido volta a `cotado` e o parceiro sai da lista | `POST /pedidos/:id/recusar-parceiro`, `GET /pedidos/:id/cotacao`, `POST /pedidos/:id/parceiro` |
| O preço do parceiro escolhido é sempre recalculado no servidor | `routes/pedidos.js` (`POST /pedidos`) |
| Cancelamento sem taxa antes da alocação, 15% depois, bloqueado após a coleta | `POST /pedidos/:id/cancelar` |
| Comissão da plataforma sobre o valor do frete | `precificacao.repasseParceiro` |
| Cupom só vale acima do valor mínimo do pedido | `precificacao.aplicarCupom` |

## Calibragem do preço

O motor usa `tarifa_base + valor_por_km × km + valor_por_parada × paradas_extras`,
respeitando o valor mínimo da categoria.

- **Motoristas autônomos** usam a linha `padrão` da `tabela_preco` da plataforma.
- **Transportadoras** têm preço próprio em `transportadora_preco`. No seed, é a tabela da
  plataforma multiplicada por um fator entre 0,89 e 1,15 por empresa.
- Os níveis expresso e econômico continuam na `tabela_preco`, mas a cotação não os usa
  mais: quem diferencia as opções agora é o parceiro (preço, prazo e avaliação).
- O prazo estimado soma o deslocamento do parceiro até a coleta, o trajeto e 15 minutos
  de manuseio, a uma média de 30 km/h.

Na mesma rota testada no aplicativo de referência (Osasco → Avenida Paulista, carreto) o
preço `padrão` ficou em R$ 155,64 contra R$ 152,68 do concorrente — ou seja, a estrutura
de preço reproduz a ordem de grandeza do mercado.

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
GET    /pedidos/:id/cotacao
POST   /pedidos/:id/recusar-parceiro
POST   /pedidos/:id/parceiro
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

**Cotação e escolha do parceiro**

`POST /cotacao` recebe `{ categoriaId, paradas, servicos, horas, cupom }` e devolve as
`ofertas` (até 10). Cada oferta traz o parceiro, a nota, o prazo e o preço:

```json
{
  "chave": "transportadora-7",
  "parceiroTipo": "transportadora",
  "parceiroId": 7,
  "nome": "Barueri Log",
  "nota": 4.5,
  "totalFretes": 730,
  "favorito": false,
  "veiculo": "Mercedes Sprinter Chassi",
  "distanciaColetaKm": 12.6,
  "chegadaColetaMin": 25,
  "prazoEntregaMin": 80,
  "valorFrete": 138.56,
  "valorAdicionais": 0,
  "desconto": 0,
  "total": 138.56
}
```

`POST /pedidos` recebe `parceiroTipo` (`motorista` ou `transportadora`) e `parceiroId` no
lugar do antigo nível de serviço. O pedido nasce em `aguardando_alocacao` e segue só para
o parceiro escolhido. `POST /pedidos/:id/recusar-parceiro` existe apenas no protótipo, para
simular a recusa; o pedido volta a `cotado`, `GET /pedidos/:id/cotacao` traz as opções
sem o parceiro que recusou e `POST /pedidos/:id/parceiro` escolhe outro.

## Como contribuir

1. Crie uma branch a partir da `main`: `git checkout -b minha-feature`.
2. Faça as alterações e commit.
3. Abra um Pull Request pra `main` — quem revisar confere se a API e o app continuam
   rodando antes de aprovar.

Se você não tem permissão de push direto neste repositório, faça um fork e abra o PR
a partir dele.

## O que ficou fora de propósito

Cadastro de cartão de crédito (fora do protótipo por segurança), upload real de
documentos (o anexo é simulado), app do motorista e painel da transportadora como
aplicativos próprios (por isso o aceite e a recusa do parceiro são simulados),
recomendação de veículo por foto, programa de fidelidade e
indicação de amigos. Tudo isso está mapeado nas fases 2 e 3 do backlog no documento de
requisitos.
