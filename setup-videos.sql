-- ============================================================
-- setup-videos.sql — Rode este arquivo no SQL Editor do Supabase
-- (Painel do projeto > SQL Editor > New query > colar e rodar)
--
-- Cria a tabela de vídeos do portfólio. A partir de agora, o site
-- (index.html) lê os vídeos direto dessa tabela em vez do array fixo
-- CONFIG.portfolioItens — e o painel (aba "Vídeos") edita essa mesma
-- tabela. Editou no painel, aparece no site na hora, sem publicar de
-- novo (o array CONFIG.portfolioItens continua no index.html só como
-- reserva, caso o Supabase fique fora do ar).
-- ============================================================

-- ------------------------------------------------------------
-- Tabela: portfolio_videos
-- ------------------------------------------------------------
create table if not exists public.portfolio_videos (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  categoria text not null,        -- precisa bater com uma "chave" de CONFIG.portfolioCategorias no index.html
  tag text not null default 'Vídeo UGC',
  marca text,
  video_id text,                  -- ID do vídeo no YouTube (o trecho depois de "shorts/" ou "watch?v=" na URL)
  capa text,                      -- opcional: caminho de uma imagem própria em vez da miniatura automática do YouTube
  ordem integer not null default 0,  -- define a posição no carrossel (menor = mais à esquerda)
  ativo boolean not null default true, -- false = escondido do site, sem precisar excluir
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_portfolio_videos_ordem
  on public.portfolio_videos (ordem);

-- ------------------------------------------------------------
-- Row Level Security (RLS)
-- ------------------------------------------------------------
alter table public.portfolio_videos enable row level security;

-- O site (visitante, não logado) só pode LER os vídeos marcados como ativos.
create policy "anon pode ler videos ativos"
  on public.portfolio_videos
  for select
  to anon
  using (ativo = true);

-- Quem está logado no painel (você) pode ler tudo (inclusive os ocultos)
-- e também criar, editar e excluir vídeos — é assim que a aba "Vídeos"
-- do painel gerencia o portfólio.
create policy "authenticated pode gerenciar videos"
  on public.portfolio_videos
  for all
  to authenticated
  using (true)
  with check (true);

-- ------------------------------------------------------------
-- Dados iniciais: migra os 9 vídeos que já estavam fixos no
-- CONFIG.portfolioItens do index.html, na mesma ordem em que
-- apareciam no site.
-- ------------------------------------------------------------
insert into public.portfolio_videos (titulo, categoria, tag, marca, video_id, capa, ordem) values
  ('Modelador de Cachos', 'skincare', 'Vídeo UGC', 'KISS NEW YORK', 'iOT6lIM1MkA', 'imagens/capa-modelador-de-cachos.jpg', 1),
  ('Banho a Seco Pet Society', 'pet', 'Vídeo UGC', 'PET SOCIETY', 'B34NZrVWbs4', null, 2),
  ('Booster Pro', 'skincare', 'Vídeo UGC', 'MEDICUBE', '_mEa3oESgUA', null, 3),
  ('Skol Beats Spirit', 'lifestyle', 'Vídeo UGC', 'SKOL BEATS', 'GdTKT_rqcNE', null, 4),
  ('Microfone de Lapela', 'tecnologia', 'Vídeo UGC', 'A''GOLD', 'w-qKXbbCqSM', null, 5),
  ('Omega 3 VHITA', 'bem-estar', 'Vídeo UGC', 'VHITA', '28js5oXUjwA', 'imagens/capa-omega-3.jpg', 6),
  ('Cappuccino 3 Corações Havanna', 'casa', 'Vídeo UGC', '3 CORAÇÕES', 'WwwM0wkflYA', null, 7),
  ('Unboxing Óleos Essenciais', 'bem-estar', 'Vídeo UGC', 'DOTERRA', '5zeC5P23Glk', null, 8),
  ('CREATINA GROWTH', 'bem-estar', 'Vídeo UGC', 'GROWTH', 'vBai7y2ph64', null, 9);
