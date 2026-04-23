# STATUS ATUAL — Banco de Dados, Edge Functions e Configurações Externas

> Última atualização: Abril/2026 — Tudo configurado e deployado.

---

## Supabase — Banco de Dados (PostgreSQL)

Todas as tabelas estão criadas, com RLS ativo, triggers automáticos e seeds.

### Tabelas existentes:

**profiles** — Criado automaticamente via trigger quando usuário se cadastra (email ou Google).
Campos: id (UUID, PK, ref auth.users), email, nome, avatar_url, provider, created_at, updated_at, deleted_at.

**gastos** — Tabela principal de despesas. É a tabela que o Flutter já usa via `ExpenseRemoteDataSource`.
Campos: id (BIGINT auto), user_id, id_local (UUID do app), data_hora, categoria, valor (NUMERIC 12,2), pagamento, texto_original, criado_em, updated_at, deleted_at.
Índice único: (user_id, id_local).

**receitas** — Tabela de receitas.
Campos: id (BIGINT auto), user_id, id_local, descricao, valor (NUMERIC 12,2), categoria, data_ocorrencia, observacao, criado_em, updated_at, deleted_at.
Índice único: (user_id, id_local).

**categories** — Categorias dinâmicas por usuário (criadas automaticamente no cadastro).
Campos: id (UUID), user_id, tipo (despesa/receita), nome, nome_key, icone, cor, ativo, deletavel, created_at.
Índice único: (user_id, tipo, nome_key).
Categoria "Outros" tem deletavel = false.

**payment_methods** — Formas de pagamento dinâmicas por usuário (criadas automaticamente no cadastro).
Campos: id (UUID), user_id, nome, nome_key, icone, ativo, deletavel, created_at.
Índice único: (user_id, nome_key).

**ai_requests** — Log de todas as chamadas à IA.
Campos: id (UUID), user_id, tipo (parse/resumo/chat), input_text, input_file_url, output_json (JSONB), status, created_at.

**ai_chat_messages** — Histórico de conversa com a IA.
Campos: id (UUID), user_id, role (user/assistant), content, related_period, created_at.

**monthly_summaries** — Resumos mensais gerados pela IA.
Campos: id (UUID), user_id, referencia_mes (YYYY-MM), total_receitas, total_despesas, saldo, resumo_ia, created_at, updated_at.
Índice único: (user_id, referencia_mes).

**app_settings** — Configurações globais do admin.
Campos: id (UUID), key, value (JSONB), updated_by, updated_at.
Já possui registro: key = "ai_daily_limit", value = {"audio_image": 5}.

**audit_logs** — Registro de ações críticas.
Campos: id (BIGINT auto), user_id, acao, entidade, entidade_id, before_data (JSONB), after_data (JSONB), origem, status, created_at.

### Triggers automáticos:

- **on_auth_user_created** → Novo usuário no Auth → cria registro em profiles com nome, email, avatar e provider.
- **on_profile_created_seed** → Novo profile criado → cria automaticamente:
  - 10 categorias de despesa: alimentacao, mercado, gasolina, transporte, lazer, assinaturas, saude, educacao, moradia, outros
  - 3 categorias de receita: salario, investimento, outros
  - 6 formas de pagamento: pix, dinheiro, debito, credito, boleto, outro
- **set_updated_at** → UPDATE em gastos, receitas, profiles ou monthly_summaries → atualiza updated_at automaticamente.

### Segurança:

- RLS ativo em TODAS as tabelas — cada usuário só acessa seus próprios dados.
- Categoria "Outros" (despesa e receita) tem deletavel = false, não pode ser excluída.
- Formas de pagamento "Outro" tem deletavel = false.

---

## Supabase — Autenticação

- **Email/senha:** habilitado
- **Google OAuth:** habilitado
  - Client ID (Web) e Client Secret preenchidos no painel
  - Authorized Client IDs: Web + Android
- **URL Configuration:**
  - Site URL: `com.example.controle_de_gastos://login-callback`
  - Redirect URLs: `com.example.controle_de_gastos://login-callback`

---

## Supabase — Storage

- Bucket `attachments` criado (private) — para áudio e imagem na entrada inteligente.

---

## Supabase — Edge Functions (todas deployadas e funcionando)

As 4 Edge Functions estão deployadas. Todas autenticam o usuário via JWT, respeitam RLS e registram logs em ai_requests.

### POST /parse-entry
- **O que faz:** Recebe entrada (texto, áudio ou imagem), interpreta via OpenAI e retorna JSON estruturado.
- **Entrada (JSON):**
  - `tipo_input`: "texto", "audio" ou "imagem"
  - `texto`: string (se tipo_input = texto)
  - `audio_base64` + `audio_mime_type`: string (se tipo_input = audio)
  - `image_base64`: string (se tipo_input = imagem)
- **Saída (JSON):**
  - `sucesso`: boolean
  - `dados`: { descricao, categoria, valor, pagamento, data_hora, confianca (0-1), observacoes }
  - `texto_original`: texto transcrito (áudio) ou enviado
  - `alerta`: mensagem se confianca < 0.5
- **Regras:** Verifica limite diário de áudio/imagem (padrão 5/dia, lido de app_settings). Usa categorias e pagamentos reais do usuário no prompt. Se IA falhar no parse, retorna campos com valores padrão e confiança baixa.
- **IA usada:** GPT-4o (texto e imagem), Whisper (áudio)

### POST /confirm-entry
- **O que faz:** Recebe dados confirmados/editados pelo usuário e salva no banco.
- **Entrada (JSON):**
  - `tipo_lancamento`: "despesa" (padrão) ou "receita"
  - `id_local`: UUID gerado pelo app
  - `descricao`, `categoria`, `valor`, `pagamento`, `data_hora`
  - `texto_original`, `origem_input` (manual/texto/audio/imagem)
  - `ai_confidence`, `ai_raw_response`, `observacao` (opcionais)
- **Saída:** { sucesso, id, tipo }
- **Regras:** Insere em `gastos` ou `receitas` conforme tipo_lancamento. Gera audit_log automaticamente.

### POST /generate-summary
- **O que faz:** Calcula totais do mês, agrupa por categoria/pagamento, gera resumo analítico com IA.
- **Entrada (JSON):**
  - `mes`: formato "YYYY-MM" (ex: "2026-04")
- **Saída:** { sucesso, mes, total_receitas, total_despesas, saldo, por_categoria, por_pagamento, resumo_ia, qtd_despesas, qtd_receitas }
- **Regras:** Salva/atualiza em monthly_summaries. Registra em ai_requests.

### POST /ai-chat
- **O que faz:** Responde perguntas em linguagem natural sobre os dados financeiros do usuário.
- **Entrada (JSON):**
  - `pergunta`: string
  - `periodo`: opcional — "YYYY-MM" (mês único) ou "YYYY-MM:YYYY-MM" (intervalo). Se omitido, usa últimos 3 meses.
- **Saída:** { sucesso, resposta, periodo_consultado }
- **Regras:** Busca apenas dados do usuário autenticado. Monta contexto com totais, categorias e últimas transações. Usa histórico de conversa (últimas 10 mensagens). Salva pergunta e resposta em ai_chat_messages.

### Como o Flutter chama as Edge Functions:

```dart
// Exemplo: chamar parse-entry
final response = await Supabase.instance.client.functions.invoke(
  'parse-entry',
  body: {
    'tipo_input': 'texto',
    'texto': 'Gastei 45 reais no mercado hoje no pix',
  },
);
final data = response.data;

// Exemplo: chamar ai-chat
final response = await Supabase.instance.client.functions.invoke(
  'ai-chat',
  body: {
    'pergunta': 'Quanto eu gastei com alimentação este mês?',
    'periodo': '2026-04',
  },
);

// Exemplo: chamar generate-summary
final response = await Supabase.instance.client.functions.invoke(
  'generate-summary',
  body: {'mes': '2026-04'},
);

// Exemplo: chamar confirm-entry
final response = await Supabase.instance.client.functions.invoke(
  'confirm-entry',
  body: {
    'tipo_lancamento': 'despesa',
    'id_local': 'uuid-gerado-no-app',
    'descricao': 'Mercado Extra',
    'categoria': 'mercado',
    'valor': 45.00,
    'pagamento': 'pix',
    'data_hora': '2026-04-14T10:30:00',
    'origem_input': 'texto',
    'ai_confidence': 0.92,
  },
);
```

---

## Google Cloud Console

- Projeto criado com OAuth consent screen configurado (escopos: openid, email, profile)
- Client ID Web Application criado, com Authorized Redirect URI: `https://zbzwgfpmayeyjbctfwgd.supabase.co/auth/v1/callback`
- Client ID Android criado, com package name `com.example.controle_de_gastos` e SHA-1 de debug

---

## Flutter — Configuração Atual

- `android/app/src/main/AndroidManifest.xml` possui intent-filter com scheme `com.example.controle_de_gastos` e host `login-callback`
- `lib/config/app_config.dart` contém supabaseUrl e supabaseAnonKey preenchidos
- `lib/presentation/notifiers/auth_notifier.dart` já implementa signInWithOAuth(OAuthProvider.google) com listener em onAuthStateChange
- `lib/data/datasources/remote/expense_remote_datasource.dart` faz INSERT na tabela `gastos` com campos: id_local, data_hora, categoria, valor, pagamento, texto_original, criado_em

---

## Secrets configurados no Supabase

- `OPENAI_API_KEY` — chave da API OpenAI (GPT-4o + Whisper)
- `SUPABASE_URL` — injetado automaticamente pelo Supabase
- `SUPABASE_ANON_KEY` — injetado automaticamente pelo Supabase
- `SUPABASE_SERVICE_ROLE_KEY` — injetado automaticamente pelo Supabase

---

## O que está 100% pronto

- ✅ Google Cloud OAuth (Web + Android)
- ✅ Supabase Auth (email/senha + Google)
- ✅ Todas as tabelas do banco com RLS + triggers + seeds
- ✅ Storage (bucket attachments)
- ✅ Edge Functions deployadas (parse-entry, confirm-entry, generate-summary, ai-chat)
- ✅ Secret OPENAI_API_KEY configurada
- ✅ Deep link configurado (AndroidManifest + Supabase URL Config)

## O que falta (só código Flutter)

- Telas de inserção inteligente (texto, áudio, imagem) chamando parse-entry
- Tela de confirmação da IA chamando confirm-entry
- Tela de relatórios chamando generate-summary
- Tela de chat com IA chamando ai-chat
- Integração das tabelas categories e payment_methods dinâmicas (substituir enums fixos)
- Tela de gestão de categorias e formas de pagamento
- Exportação de relatórios (CSV/PDF)
- Tela de privacidade e dados (LGPD)
