-- ============================================================
-- setup.sql — Rode este arquivo no SQL Editor do Supabase
-- (Painel do projeto > SQL Editor > New query > colar e rodar)
-- ============================================================

-- ------------------------------------------------------------
-- Tabela: portfolio_events
-- Guarda os eventos do site (visitas, cliques, vídeos assistidos)
-- ------------------------------------------------------------
create table if not exists public.portfolio_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,        -- 'page_view' | 'button_click' | 'video_view'
  event_name text,                 -- nome do evento (ex: 'contact_whatsapp', id do vídeo)
  session_id text,                 -- identifica um visitante dentro de uma sessão
  page_path text,                  -- caminho da página onde o evento ocorreu
  metadata jsonb,                  -- dados extras (ex: title, brand, category)
  created_at timestamptz not null default now()
);

-- Índices para acelerar as consultas do painel (filtro por data e por tipo)
create index if not exists idx_portfolio_events_created_at
  on public.portfolio_events (created_at desc);

create index if not exists idx_portfolio_events_type
  on public.portfolio_events (event_type);

-- ------------------------------------------------------------
-- Tabela: portfolio_leads
-- Guarda as mensagens de contato recebidas pelo site
-- ------------------------------------------------------------
create table if not exists public.portfolio_leads (
  id uuid primary key default gen_random_uuid(),
  name text,
  email text,
  phone text,
  brand text,
  budget text,
  message text,
  source text,                     -- 'contact' | 'popup'
  created_at timestamptz not null default now()
);

create index if not exists idx_portfolio_leads_created_at
  on public.portfolio_leads (created_at desc);

-- ------------------------------------------------------------
-- Row Level Security (RLS)
-- ------------------------------------------------------------
alter table public.portfolio_events enable row level security;
alter table public.portfolio_leads enable row level security;

-- Permite que qualquer usuário LOGADO no painel (authenticated) possa LER
-- as duas tabelas. É assim que painel.html consegue montar os números.
create policy "authenticated pode ler eventos"
  on public.portfolio_events
  for select
  to authenticated
  using (true);

create policy "authenticated pode ler leads"
  on public.portfolio_leads
  for select
  to authenticated
  using (true);

-- ------------------------------------------------------------
-- IMPORTANTE — sobre a escrita (INSERT) dos eventos e leads:
--
-- Este arquivo NÃO cria policies de INSERT para o papel "anon".
-- Isso é proposital: a chave anon é pública (fica exposta no HTML
-- do site do portfólio), então se qualquer visitante pudesse
-- inserir diretamente pelo navegador, alguém mal-intencionado
-- poderia forjar visitas, cliques e mensagens falsas.
--
-- A forma correta de registrar eventos e leads vindos do site
-- público é através de um servidor (uma function/edge function
-- ou uma rota de backend) que usa a service_role key do Supabase
-- (a chave secreta, nunca exposta no navegador) para inserir os
-- dados. O navegador do visitante chama o seu servidor, e é o
-- servidor quem grava no banco.
--
-- Se quiser liberar a escrita direto do navegador mesmo assim
-- (não recomendado), seria necessário criar policies de INSERT
-- para o papel "anon" nas duas tabelas — mas isso abre a porta
-- para dados falsos e spam.
-- ------------------------------------------------------------
