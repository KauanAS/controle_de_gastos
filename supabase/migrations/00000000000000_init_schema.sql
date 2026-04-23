-- ════════════════════════════════════════════════════════════════════════════
-- SCHEMA COMPLETO — Controle de Gastos
-- Roda no SQL Editor do Supabase UMA VEZ num projeto novo e vazio.
-- Compatível com o app Flutter atual (não exige mudança no código).
-- ════════════════════════════════════════════════════════════════════════════

-- ─── Limpeza defensiva (caso rode 2x, não quebra) ──────────────────────────
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.handle_new_profile() cascade;
drop function if exists public.set_updated_at() cascade;

-- ════════════════════════════════════════════════════════════════════════════
-- 1. TABELAS
-- ════════════════════════════════════════════════════════════════════════════

-- ─── profiles ──────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text,
  nome        text not null default 'Usuário',
  avatar_url  text,
  provider    text not null default 'email',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- ─── categories ────────────────────────────────────────────────────────────
create table if not exists public.categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  tipo        text not null check (tipo in ('despesa', 'receita')),
  nome        text not null,
  nome_key    text not null,
  icone       text,
  cor         text,
  ativo       boolean not null default true,
  deletavel   boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (user_id, tipo, nome_key)
);

-- ─── payment_methods ───────────────────────────────────────────────────────
create table if not exists public.payment_methods (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  nome        text not null,
  nome_key    text not null,
  icone       text,
  ativo       boolean not null default true,
  deletavel   boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (user_id, nome_key)
);

-- ─── gastos ────────────────────────────────────────────────────────────────
create table if not exists public.gastos (
  id              bigserial primary key,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  id_local        uuid not null,
  data_hora       timestamptz not null default now(),
  categoria       text not null default 'outros',
  valor           numeric(12, 2) not null check (valor >= 0),
  pagamento       text not null default 'outro',
  texto_original  text,
  criado_em       timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  unique (user_id, id_local)
);

-- ─── receitas ──────────────────────────────────────────────────────────────
create table if not exists public.receitas (
  id               bigserial primary key,
  user_id          uuid not null references public.profiles(id) on delete cascade,
  id_local         uuid not null,
  descricao        text not null,
  valor            numeric(12, 2) not null check (valor >= 0),
  categoria        text not null default 'outros',
  data_ocorrencia  timestamptz not null default now(),
  observacao       text,
  criado_em        timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz,
  unique (user_id, id_local)
);

-- ─── ai_requests ───────────────────────────────────────────────────────────
create table if not exists public.ai_requests (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  tipo            text not null check (tipo in ('parse', 'resumo', 'chat')),
  input_text      text,
  input_file_url  text,
  output_json     jsonb,
  status          text not null default 'ok',
  created_at      timestamptz not null default now()
);

-- ─── ai_chat_messages ──────────────────────────────────────────────────────
create table if not exists public.ai_chat_messages (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  role            text not null check (role in ('user', 'assistant')),
  content         text not null,
  related_period  text,
  created_at      timestamptz not null default now()
);

-- ─── monthly_summaries ─────────────────────────────────────────────────────
create table if not exists public.monthly_summaries (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles(id) on delete cascade,
  referencia_mes   text not null,
  total_receitas   numeric(12, 2) not null default 0,
  total_despesas   numeric(12, 2) not null default 0,
  saldo            numeric(12, 2) not null default 0,
  resumo_ia        text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (user_id, referencia_mes)
);

-- ─── app_settings ──────────────────────────────────────────────────────────
create table if not exists public.app_settings (
  id          uuid primary key default gen_random_uuid(),
  key         text not null unique,
  value       jsonb not null,
  updated_by  uuid references public.profiles(id),
  updated_at  timestamptz not null default now()
);

insert into public.app_settings (key, value)
values ('ai_daily_limit', '{"audio_image": 5}'::jsonb)
on conflict (key) do nothing;

-- ─── audit_logs ────────────────────────────────────────────────────────────
create table if not exists public.audit_logs (
  id           bigserial primary key,
  user_id      uuid references public.profiles(id) on delete set null,
  acao         text not null,
  entidade     text not null,
  entidade_id  text,
  before_data  jsonb,
  after_data   jsonb,
  origem       text,
  status       text not null default 'ok',
  created_at   timestamptz not null default now()
);

-- ════════════════════════════════════════════════════════════════════════════
-- 2. TRIGGERS E FUNÇÕES
-- ════════════════════════════════════════════════════════════════════════════

-- ─── Atualiza updated_at automaticamente ───────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated    before update on public.profiles           for each row execute function public.set_updated_at();
create trigger trg_gastos_updated      before update on public.gastos             for each row execute function public.set_updated_at();
create trigger trg_receitas_updated    before update on public.receitas           for each row execute function public.set_updated_at();
create trigger trg_monthly_updated     before update on public.monthly_summaries  for each row execute function public.set_updated_at();

-- ─── Cria profile ao cadastrar usuário em auth.users ───────────────────────
-- SECURITY DEFINER: roda como dono da função, bypassa RLS.
-- EXCEPTION WHEN OTHERS: se falhar, NÃO quebra o cadastro.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, nome, avatar_url, provider)
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Usuário'
    ),
    coalesce(
      new.raw_user_meta_data->>'avatar_url',
      new.raw_user_meta_data->>'picture'
    ),
    coalesce(new.raw_app_meta_data->>'provider', 'email')
  )
  on conflict (id) do nothing;
  return new;
exception when others then
  raise warning 'handle_new_user falhou para %: %', new.id, sqlerrm;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─── Seed de categorias e formas de pagamento ao criar profile ─────────────
-- Também com EXCEPTION WHEN OTHERS pra não quebrar o profile.
create or replace function public.handle_new_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Categorias de despesa
  insert into public.categories (user_id, tipo, nome, nome_key, icone, deletavel) values
    (new.id, 'despesa', 'Alimentação',  'alimentacao', '🍽️', true),
    (new.id, 'despesa', 'Mercado',      'mercado',     '🛒', true),
    (new.id, 'despesa', 'Gasolina',     'gasolina',    '⛽', true),
    (new.id, 'despesa', 'Transporte',   'transporte',  '🚌', true),
    (new.id, 'despesa', 'Lazer',        'lazer',       '🎬', true),
    (new.id, 'despesa', 'Assinaturas',  'assinaturas', '📱', true),
    (new.id, 'despesa', 'Saúde',        'saude',       '🏥', true),
    (new.id, 'despesa', 'Educação',     'educacao',    '📚', true),
    (new.id, 'despesa', 'Moradia',      'moradia',     '🏠', true),
    (new.id, 'despesa', 'Outros',       'outros',      '📦', false)
  on conflict (user_id, tipo, nome_key) do nothing;

  -- Categorias de receita
  insert into public.categories (user_id, tipo, nome, nome_key, icone, deletavel) values
    (new.id, 'receita', 'Salário',      'salario',     '💼', true),
    (new.id, 'receita', 'Investimento', 'investimento','📈', true),
    (new.id, 'receita', 'Outros',       'outros',      '📦', false)
  on conflict (user_id, tipo, nome_key) do nothing;

  -- Formas de pagamento
  insert into public.payment_methods (user_id, nome, nome_key, icone, deletavel) values
    (new.id, 'Pix',      'pix',      '⚡',  true),
    (new.id, 'Dinheiro', 'dinheiro', '💵',  true),
    (new.id, 'Débito',   'debito',   '💳',  true),
    (new.id, 'Crédito',  'credito',  '💳',  true),
    (new.id, 'Boleto',   'boleto',   '🧾',  true),
    (new.id, 'Outro',    'outro',    '💰',  false)
  on conflict (user_id, nome_key) do nothing;

  return new;
exception when others then
  raise warning 'handle_new_profile falhou para %: %', new.id, sqlerrm;
  return new;
end;
$$;

create trigger on_profile_created_seed
  after insert on public.profiles
  for each row execute function public.handle_new_profile();

-- ════════════════════════════════════════════════════════════════════════════
-- 3. ROW LEVEL SECURITY
-- ════════════════════════════════════════════════════════════════════════════

alter table public.profiles           enable row level security;
alter table public.categories         enable row level security;
alter table public.payment_methods    enable row level security;
alter table public.gastos             enable row level security;
alter table public.receitas           enable row level security;
alter table public.ai_requests        enable row level security;
alter table public.ai_chat_messages   enable row level security;
alter table public.monthly_summaries  enable row level security;
alter table public.app_settings       enable row level security;
alter table public.audit_logs         enable row level security;

-- ─── profiles ──────────────────────────────────────────────────────────────
create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- ─── categories ────────────────────────────────────────────────────────────
create policy "categories_all_own" on public.categories for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── payment_methods ───────────────────────────────────────────────────────
create policy "payment_methods_all_own" on public.payment_methods for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── gastos ────────────────────────────────────────────────────────────────
create policy "gastos_all_own" on public.gastos for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── receitas ──────────────────────────────────────────────────────────────
create policy "receitas_all_own" on public.receitas for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── ai_requests ───────────────────────────────────────────────────────────
create policy "ai_requests_all_own" on public.ai_requests for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── ai_chat_messages ──────────────────────────────────────────────────────
create policy "ai_chat_all_own" on public.ai_chat_messages for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── monthly_summaries ─────────────────────────────────────────────────────
create policy "monthly_all_own" on public.monthly_summaries for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── app_settings (leitura pública pra todo usuário autenticado) ───────────
create policy "app_settings_read_auth" on public.app_settings for select using (auth.role() = 'authenticated');

-- ─── audit_logs (leitura só do próprio; insert feito por edge function com service_role) ─
create policy "audit_select_own" on public.audit_logs for select using (auth.uid() = user_id);

-- ════════════════════════════════════════════════════════════════════════════
-- 4. ÍNDICES AUXILIARES
-- ════════════════════════════════════════════════════════════════════════════

create index if not exists idx_gastos_user_data        on public.gastos(user_id, data_hora desc);
create index if not exists idx_receitas_user_data      on public.receitas(user_id, data_ocorrencia desc);
create index if not exists idx_categories_user_tipo    on public.categories(user_id, tipo);
create index if not exists idx_ai_chat_user_created    on public.ai_chat_messages(user_id, created_at desc);
create index if not exists idx_audit_user_created      on public.audit_logs(user_id, created_at desc);

-- ════════════════════════════════════════════════════════════════════════════
-- PRONTO.
-- Próximos passos:
-- 1. Auth → Providers → habilitar Email e Google (cola Web Client ID + Secret).
-- 2. Auth → URL Configuration → Site URL: com.example.controle_de_gastos://login-callback
-- 3. Storage → New Bucket → nome: attachments → Private.
-- 4. Settings → API → copiar Project URL e anon key pro app_config.dart.
-- 5. Deploy das Edge Functions: supabase functions deploy --project-ref <ref>.
-- ════════════════════════════════════════════════════════════════════════════
