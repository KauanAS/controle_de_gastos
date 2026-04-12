# CLAUDE.md — App de Controle de Gastos

> Este arquivo contém todo o contexto do projeto para que o Claude (ou qualquer assistente de IA) entenda a arquitetura, regras de negócio, convenções e decisões técnicas sem precisar perguntar.

---

## 1. Visão Geral

Aplicativo mobile de controle financeiro pessoal com entrada inteligente por IA. O usuário registra despesas e receitas de forma manual ou via texto, áudio e imagem. A IA interpreta os dados, mas **nunca salva automaticamente** — o usuário sempre confirma antes de gravar.

- **Plataforma MVP:** Android
- **Frontend:** Flutter + Dart
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **IA:** OpenAI GPT-4o (texto/visão) + Whisper (áudio), chamados exclusivamente via Edge Functions
- **Moeda MVP:** BRL (Real brasileiro). Suporte a múltiplas moedas planejado para o futuro
- **Idioma MVP:** Português (BR)
- **Custo operacional alvo:** Até R$50/mês na fase de testes

---

## 2. Estrutura do Monorepo

```
finance-app/
├── apps/
│   └── mobile_app/
│       ├── lib/
│       │   ├── app/              # routes, theme, bootstrap
│       │   ├── core/             # constants, errors, utils, services
│       │   ├── features/
│       │   │   ├── auth/         # login, cadastro, recuperação de senha, sessão
│       │   │   ├── dashboard/    # cards de resumo, gráficos, indicadores
│       │   │   ├── expenses/     # listar, filtrar, detalhar, editar, excluir
│       │   │   ├── incomes/      # listar, criar, editar, excluir
│       │   │   ├── ai_input/     # texto, áudio, imagem, confirmação
│       │   │   ├── reports/      # agregações, gráficos, resumo por IA
│       │   │   ├── ai_chat/      # conversa, histórico, perguntas rápidas
│       │   │   ├── settings/     # tema, moeda, formato de data, notificações
│       │   │   ├── profile/      # dados do usuário, exclusão de conta
│       │   │   └── privacy/      # exportação de dados, consentimentos, retenção
│       │   └── shared/           # widgets, models, enums reutilizáveis
│       ├── test/
│       └── pubspec.yaml
├── packages/
│   ├── design_system/            # tokens visuais, componentes UI compartilhados
│   ├── domain/                   # entidades, regras de negócio puras
│   ├── data/                     # repositories, data sources, DTOs
│   └── common/                   # utilitários compartilhados entre packages
├── backend/
│   └── edge_functions/
│       ├── parse-entry/          # interpretar texto/áudio/imagem via IA
│       ├── confirm-entry/        # confirmar e gravar lançamento
│       ├── generate-summary/     # gerar resumo mensal com IA
│       ├── ai-chat/              # chat analítico com IA
│       └── delete-account/       # exclusão de conta (LGPD)
├── supabase/
│   ├── migrations/               # schema SQL versionado
│   ├── seeds/                    # dados iniciais (categorias padrão etc.)
│   ├── policies/                 # RLS policies
│   ├── functions/
│   └── config.toml
├── docs/
│   ├── produto/                  # escopo, PRDs, user stories
│   ├── arquitetura/
│   ├── banco/
│   ├── api/
│   └── seguranca/
├── scripts/
├── .github/workflows/
├── melos.yaml
└── README.md
```

**Organização: por feature, não por tipo técnico.** Cada feature contém suas próprias telas, widgets, controllers, repositories e models específicos.

---

## 3. Stack Tecnológica Detalhada

### Flutter (Frontend)

| Pacote | Uso |
|---|---|
| `go_router` ou `auto_route` | Navegação |
| `flutter_riverpod` | Gestão de estado |
| `freezed` + `json_serializable` | Modelos de dados imutáveis |
| `supabase_flutter` | Integração com Supabase |
| `fl_chart` | Gráficos (pizza, evolução temporal) |
| `image_picker` | Seleção de imagens da galeria/câmera |
| `record` | Gravação de áudio |
| `permission_handler` | Permissões do dispositivo (mic, câmera) |
| `intl` | Formatação de datas e moeda (BRL) |

### Supabase (Backend)

- **PostgreSQL** — banco relacional principal
- **Supabase Auth** — autenticação (email/senha + Google)
- **Supabase Storage** — armazenamento de áudios e imagens
- **Edge Functions (TypeScript)** — lógica server-side, chamadas à API OpenAI
- **RLS (Row Level Security)** — isolamento total por usuário em todas as tabelas
- **Realtime** — reservado para uso futuro

### Edge Functions (TypeScript)

- Validação com `zod`
- Estruturação de handlers por domínio
- Todas as chamadas à API OpenAI passam por aqui — **nunca pelo frontend**
- Segredos (API keys) ficam exclusivamente no backend

### Linguagens do Projeto

| Linguagem | Onde |
|---|---|
| Dart | App Flutter |
| TypeScript | Edge Functions |
| SQL | Schema, migrations, views, funções, políticas RLS |
| YAML | CI/CD e automações |
| JSON | Contratos de payload entre app e backend |

---

## 4. Modelo de Dados

### 4.1 profiles
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| email | TEXT, único |
| nome | TEXT |
| avatar_url | TEXT, nullable |
| provider | TEXT (email, google) |
| created_at | TIMESTAMP |
| updated_at | TIMESTAMP |
| deleted_at | TIMESTAMP, nullable (soft delete) |

### 4.2 categories
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| user_id | UUID, FK → profiles |
| tipo | TEXT (despesa, receita) |
| nome | TEXT |
| cor | TEXT, nullable |
| icone | TEXT, nullable |
| ativo | BOOLEAN, default true |
| created_at | TIMESTAMP |

**Categorias padrão pré-cadastradas para novos usuários:**
- Despesas: Alimentação, Aluguel, Água, Energia, Gasolina, Lazer, Outros
- Receitas: Salário, Investimento, Outros

**NÃO HÁ subcategorias no sistema.**

### 4.3 payment_methods
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| user_id | UUID, FK → profiles |
| nome | TEXT |
| ativo | BOOLEAN, default true |
| created_at | TIMESTAMP |

### 4.4 expenses
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| user_id | UUID, FK → profiles |
| category_id | UUID, FK → categories |
| payment_method_id | UUID, FK → payment_methods, nullable |
| descricao | TEXT, obrigatório |
| valor | NUMERIC(12,2) |
| moeda | TEXT, default 'BRL' |
| data_ocorrencia | TIMESTAMP |
| origem_input | TEXT (manual, texto, audio, imagem) |
| texto_original | TEXT, nullable |
| arquivo_url | TEXT, nullable |
| ai_confidence | NUMERIC, nullable |
| ai_raw_response | JSONB, nullable |
| confirmado_pelo_usuario | BOOLEAN |
| created_at | TIMESTAMP |
| updated_at | TIMESTAMP |
| deleted_at | TIMESTAMP, nullable (soft delete) |

### 4.5 incomes
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| user_id | UUID, FK → profiles |
| category_id | UUID, FK → categories |
| descricao | TEXT, obrigatório |
| valor | NUMERIC(12,2) |
| data_ocorrencia | TIMESTAMP |
| observacao | TEXT, nullable |
| created_at | TIMESTAMP |
| updated_at | TIMESTAMP |
| deleted_at | TIMESTAMP, nullable (soft delete) |

### 4.6 ai_requests
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| user_id | UUID, FK → profiles |
| tipo | TEXT (parse, resumo, chat) |
| input_text | TEXT, nullable |
| input_file_url | TEXT, nullable |
| output_json | JSONB, nullable |
| status | TEXT |
| created_at | TIMESTAMP |

### 4.7 ai_chat_messages
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| user_id | UUID, FK → profiles |
| role | TEXT (user, assistant) |
| content | TEXT |
| related_period | TEXT, nullable |
| created_at | TIMESTAMP |

### 4.8 audit_logs
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| user_id | UUID, FK → profiles |
| acao | TEXT |
| entidade | TEXT |
| entidade_id | UUID |
| before_data | JSONB, nullable |
| after_data | JSONB, nullable |
| origem | TEXT |
| status | TEXT |
| created_at | TIMESTAMP |

### 4.9 monthly_summaries
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| user_id | UUID, FK → profiles |
| referencia_mes | TEXT (YYYY-MM) |
| total_receitas | NUMERIC(12,2) |
| total_despesas | NUMERIC(12,2) |
| saldo | NUMERIC(12,2) |
| resumo_ia | TEXT, nullable |
| created_at | TIMESTAMP |
| updated_at | TIMESTAMP |

### 4.10 app_settings
| Campo | Tipo |
|---|---|
| id | UUID, PK |
| key | TEXT, único |
| value | JSONB |
| updated_by | UUID, FK → profiles (admin) |
| updated_at | TIMESTAMP |

Usada para configurações globais do admin, como o limite diário de envios de IA.

### Relacionamentos

- profiles 1:N → categories, expenses, incomes, ai_requests, ai_chat_messages, audit_logs, monthly_summaries
- categories 1:N → expenses, incomes
- payment_methods 1:N → expenses
- Todas as ações críticas → audit_logs

---

## 5. APIs / Edge Functions

### POST /parse-entry
- **Descrição:** Interpretar entrada (texto, áudio ou imagem) via IA
- **Entrada:** tipo_input, texto ou arquivo, metadata do cliente
- **Saída:** tipo_lancamento, descricao, categoria, valor, forma_pagamento, data_hora, confianca, observacoes
- **Regras:** verifica limite diário antes de processar. Retorna campos nulos se IA não conseguir interpretar, com indicador de confiança

### POST /confirm-entry
- **Descrição:** Confirmar e salvar lançamento após revisão do usuário
- **Entrada:** dados confirmados/editados pelo usuário
- **Saída:** id do lançamento salvo, status
- **Regras:** gera log de auditoria. Nunca é chamado automaticamente pela IA

### POST /generate-month-summary
- **Descrição:** Gerar resumo mensal com IA
- **Entrada:** user_id, mês de referência
- **Saída:** totais (receitas, despesas, saldo), resumo_ia (texto)

### POST /ai-chat
- **Descrição:** Chat analítico sobre dados do próprio usuário
- **Entrada:** pergunta, contexto opcional de período
- **Saída:** resposta, indicadores usados
- **Regras:** consulta SOMENTE dados do usuário autenticado (RLS)

---

## 6. Regras de Negócio (CRÍTICAS)

### Categorias
- Usuário pode criar categorias personalizadas
- **IA NÃO pode criar categorias novas** — usa apenas categorias existentes do usuário
- Fallback da IA: se não encontrar categoria adequada → "Outros"
- Categoria não pode ser excluída se houver lançamentos vinculados
- Categoria "Outros" é obrigatória e não pode ser excluída
- **Não existem subcategorias**

### Lançamentos
- Cada lançamento possui apenas UMA categoria
- Campo `descricao` é obrigatório e aceita apenas texto
- Descrição pode ser editada antes e depois de salvar
- **Todos os lançamentos passam por confirmação do usuário antes de gravar**
- Valores monetários salvos em NUMERIC(12,2)
- Relatórios consideram apenas registros ativos (deleted_at IS NULL)

### Inteligência Artificial
- **IA NUNCA salva dados automaticamente** — sempre exige confirmação humana
- **IA NUNCA cria categorias**
- IA pode retornar campos nulos se não conseguir interpretar, com mensagem de alerta ao usuário
- Usuário pode reenviar 1 vez; após segunda falha, deve inserir manualmente
- **Limite: 5 envios de áudio/imagem por dia** (somados), configurável pelo admin via `app_settings`
- Chat com IA limitado exclusivamente aos dados do usuário autenticado
- Todas as chamadas à IA são registradas em `ai_requests`

### Exclusão de Dados
- Soft delete em despesas, receitas e profiles (campo `deleted_at`)
- Exclusão de conta remove ou anonimiza dados conforme política de retenção
- Usuário pode solicitar exclusão pela tela de Privacidade

### Acesso e Isolamento
- RLS em TODAS as tabelas de negócio — cada usuário só vê seus próprios dados
- Nenhum usuário acessa dados de outro
- Anexos (áudio, imagem) vinculados ao usuário correto no Storage
- Toda alteração em despesas/receitas gera log de auditoria

---

## 7. Telas do Sistema

| # | Tela | Objetivo |
|---|---|---|
| 5.1 | Splash | Carregar sessão → redirecionar para Dashboard ou Login |
| 5.2 | Login | Email/senha ou Google |
| 5.3 | Cadastro | Nome, email, senha, aceite de termos |
| 5.4 | Recuperação de senha | Enviar link por email |
| 5.5 | Dashboard | Saldo, totais, gráfico pizza/pagamento, atalhos rápidos |
| 5.6 | Menu lateral | Navegação principal para todas as telas |
| 5.7 | Lista de despesas | Listagem paginada, busca, filtros (categoria, pagamento, data), ordenação |
| 5.8 | Detalhe da despesa | Todos os campos, origem, confiança IA, texto original, anexo |
| 5.9 | Receitas | Listar, filtrar, adicionar |
| 5.10 | Cadastro manual de gasto | Descrição, categoria, valor, pagamento, data, hora, observação |
| 5.11 | Inserção inteligente | Abas texto/áudio/imagem, contador de envios diários |
| 5.12 | Confirmação da IA | Campos sugeridos editáveis, alerta se confiança baixa, confirmar/editar/descartar |
| 5.13 | Edição de lançamento | Todos os campos editáveis, gera log |
| 5.14 | Relatórios | Totais, ranking, gráficos, resumo IA, exportar CSV/PDF |
| 5.15 | Chat com IA | Mensagens, campo texto, chips rápidos, limpar conversa |
| 5.16 | Perfil | Nome, email, foto, alterar senha, excluir conta |
| 5.17 | Privacidade e dados | Termos, consentimentos, exclusão, exportação, retenção, permissões |
| 5.18 | Configurações | Tema, moeda, formato data, notificações, categoria padrão, idioma (futuro) |

**Todos as telas implementam 4 estados:** Carregando, Vazio, Erro, Sucesso.

---

## 8. Fluxos Principais

### Fluxo Principal
1. Login (email/senha ou Google)
2. Dashboard — visão geral do mês
3. Inserir gasto (manual ou via IA)
4. IA interpreta (se entrada inteligente)
5. Usuário revisa e confirma dados
6. Dados salvos no banco de dados
7. Visualizar relatórios e gráficos
8. Interagir com chat IA

### Fluxo da Entrada Inteligente
1. Usuário envia texto, áudio ou imagem
2. App verifica limite diário (5 envios áudio/imagem)
3. App envia para Edge Function
4. Edge Function chama OpenAI (GPT-4o ou Whisper)
5. IA retorna JSON padronizado
6. App apresenta tela de confirmação (alerta se confiança baixa ou campos nulos)
7. Usuário confirma, edita ou descarta
8. Se confirmado → grava despesa/receita + log de auditoria
9. Se IA falhou → reenviar (1x) ou inserir manualmente

### Fluxo do Chat IA
1. Usuário faz pergunta em linguagem natural
2. App envia para Edge Function
3. Função consulta SOMENTE dados daquele usuário
4. Monta contexto analítico e envia para GPT-4o
5. IA responde
6. App exibe resposta
7. Log técnico registra uso (sem expor conteúdo sensível)

---

## 9. Segurança e LGPD

- Autenticação forte via Supabase Auth
- RLS em todas as tabelas de negócio
- Edge Functions para toda lógica sensível — **nenhuma chave secreta no frontend**
- Criptografia em trânsito (HTTPS)
- Validação de payload em todas as funções
- Rate limit nas funções críticas
- Soft delete com possibilidade de anonimização
- Coleta mínima de dados, consentimento explícito
- Exportação de dados pelo usuário (LGPD)
- Exclusão de conta e dados sob solicitação
- Trilha de auditoria completa (audit_logs)

---

## 10. Notificações

- **In-app:** mensagens de erro, validação de campos, feedback de ações
- **Push (opcional):** 1 notificação no 1º dia do mês informando que o relatório do mês anterior está pronto
- **Sem outras notificações externas ao app no MVP**

---

## 11. Exportação de Dados

- **Gráficos:** exportados como CSV
- **Relatórios completos:** exportados como PDF contendo os gráficos gerados pelo sistema
- Disponível na tela de Relatórios

---

## 12. Perfis de Usuário

### Usuário Final
Pessoa que registra receitas e despesas, consulta relatórios e conversa com a IA. Possui limite de uso da IA (5 envios áudio/imagem por dia).

### Administrador Técnico
Perfil interno do projeto. Responsável por suporte, monitoramento, auditoria técnica, manutenção da plataforma e **configuração de limites de uso** (ex: alterar limite diário de envios de IA via `app_settings`). Único perfil com permissão para alterar limites.

---

## 13. Arquitetura em Camadas

| Camada | Responsabilidade |
|---|---|
| 1 — Apresentação | Flutter: telas, componentes, navegação, formulários, estado (Riverpod) |
| 2 — Aplicação | Casos de uso: autenticar, criar despesa, interpretar com IA, confirmar, gerar relatório, chat |
| 3 — Domínio | Entidades e regras: usuário, despesa, receita, categoria, forma de pagamento, log, conversa IA |
| 4 — Infraestrutura | Supabase Auth, PostgreSQL, Storage, Edge Functions, API OpenAI |

---

## 14. Requisitos Não Funcionais

| Requisito | Meta |
|---|---|
| Tempo de resposta | Até 2 segundos |
| Plataforma MVP | Android |
| Escala inicial | Poucos usuários (fase de testes) |
| Custo operacional | Até R$50/mês (fase de testes) |
| Moeda | BRL no MVP |
| Idioma | Português (BR) no MVP |
| Escalabilidade | Estrutura preparada para crescimento |
| Exportação | CSV (gráficos), PDF com gráficos (relatórios) |

---

## 15. Roadmap

### Fase 1 — MVP
- Autenticação (email/senha + Google)
- Dashboard básico com gráfico por categoria
- Cadastro manual de despesas e receitas
- Listagem, filtros, edição e exclusão
- Categorias padrão pré-cadastradas
- Formas de pagamento
- Banco com logs de auditoria

### Fase 2 — IA de Captura
- Entrada por texto, áudio e imagem
- Tela de confirmação com edição
- Limite de 5 envios/dia (áudio + imagem)
- Tratamento de erros e campos nulos
- Persistência do retorno interpretado

### Fase 3 — Relatórios Inteligentes
- Resumo mensal gerado por IA
- Comparativos por período
- Exportação de gráficos (CSV) e relatórios (PDF)
- Melhorias visuais nos gráficos

### Fase 4 — Chat Analítico
- Conversa com IA sobre dados do usuário
- Histórico e contexto por período
- Perguntas rápidas sugeridas

### Fase 5 — Governança e Escala
- Exportação de dados pessoais (LGPD)
- Exclusão automatizada da conta
- Observabilidade e monitoramento
- Endurecimento de segurança
- Otimização de performance
- Possível suporte a múltiplas moedas
- Possível backend dedicado

---

## 16. Decisões Arquiteturais Registradas

1. **Sem backend próprio nesta fase** — toda lógica sensível via Edge Functions do Supabase
2. **RLS em todas as tabelas** — isolamento por usuário no nível do banco
3. **Monorepo com melos** — apps, packages, backend, supabase e docs no mesmo repositório
4. **App organizado por feature** — cada feature é autocontida (não por tipo técnico)
5. **OpenAI como provedor de IA** — GPT-4o para texto/visão, Whisper para áudio
6. **Sem subcategorias** — simplicidade para o dev e para o usuário
7. **Soft delete** — registros não são removidos fisicamente
8. **Logs de auditoria separados** — tabela dedicada `audit_logs`
9. **Limite de IA configurável** — 5/dia padrão, admin pode alterar via `app_settings`
10. **Exportação: CSV + PDF** — gráficos em CSV, relatórios completos em PDF com gráficos

---

## 17. Convenções para Desenvolvimento

### Nomenclatura
- **Arquivos Dart:** snake_case (ex: `expense_repository.dart`)
- **Classes Dart:** PascalCase (ex: `ExpenseRepository`)
- **Tabelas SQL:** snake_case plural (ex: `expenses`, `audit_logs`)
- **Edge Functions:** kebab-case (ex: `parse-entry`, `ai-chat`)
- **Branches:** `feature/nome`, `fix/nome`, `refactor/nome`

### Código
- Estado gerenciado com **Riverpod**
- Modelos de dados com **Freezed** (imutáveis + serialização)
- Navegação com **go_router** ou **auto_route**
- Validação de payload nas Edge Functions com **zod**
- Todo código em Português nos nomes de campos do banco; inglês nas variáveis e classes do app

### Testes
- Testes unitários para regras de negócio (domain)
- Testes de widget no Flutter
- Testes de integração para fluxos críticos
- Testes das Edge Functions
- Validação de políticas RLS

---

## 18. Checklist Rápido para Novas Features

Ao implementar qualquer feature, verificar:

- [ ] RLS policy criada para a tabela envolvida?
- [ ] Soft delete implementado (deleted_at)?
- [ ] Log de auditoria gerado para ações críticas?
- [ ] Validação de payload na Edge Function?
- [ ] Confirmação do usuário antes de gravar (se envolver IA)?
- [ ] Estados de tela implementados (loading, empty, error, success)?
- [ ] Nenhuma chave secreta exposta no frontend?
- [ ] Testes escritos?
