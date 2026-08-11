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
  source text,                     -- 'rodape' | 'modal' (valor legado antigo: 'contact')
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
-- O ideal seria um servidor (function/edge function ou rota de
-- backend) usando a service_role key pra gravar eventos e leads,
-- em vez do navegador inserir direto com a chave anon (pública).
-- Mas o site é hospedado como estático no GitHub Pages, sem
-- servidor nenhum — então essa opção não está disponível aqui.
--
-- Dado isso, liberamos INSERT (só insert — sem select/update/delete)
-- para o papel "anon" na tabela portfolio_leads, restrito aos
-- valores esperados de "source". É a alternativa mais pragmática
-- compatível com hospedagem 100% estática: qualquer um pode inserir
-- uma linha, mas ninguém além de quem faz login (authenticated)
-- consegue ler, alterar ou apagar leads existentes.
--
-- Trade-off aceito: sem um backend no meio, não dá pra bloquear
-- 100% spam automatizado. Se isso virar problema, mitigar depois
-- com rate-limit/captcha (ex: Cloudflare Turnstile) antes do insert.
-- ------------------------------------------------------------

create policy "anon pode inserir leads"
  on public.portfolio_leads
  for insert
  to anon
  with check (source in ('rodape', 'modal'));
