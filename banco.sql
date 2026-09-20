-- ============================================================
-- BANCO DE DADOS — Painel Administrativo da Erika
-- ============================================================
-- Este arquivo contém todas as tabelas do painel administrativo.
-- Copie TUDO abaixo, cole no SQL Editor do Supabase e clique em "Run".
-- ============================================================

-- ============================================================
-- Tabela: videos
-- Armazena os vídeos do portfólio
-- ============================================================
create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  titulo text not null,
  link text,                          -- URL do YouTube ou similar
  nicho text,                         -- skincare, pet, bem-estar, etc.
  formato text,                       -- shorts, reels, vídeo completo
  marca text,
  destaque text,                      -- "2,4M views", "5M alcance", etc.
  ordem integer not null default 0,   -- para reordenar
  visivel boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_videos_user_id on public.videos(user_id);
create index if not exists idx_videos_ordem on public.videos(ordem);

-- ============================================================
-- Tabela: marcas
-- Base de contatos de empresas/marcas para parcerias
-- ============================================================
create table if not exists public.marcas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nome text not null,
  instagram text,
  email text,
  telefone text,
  situacao text not null default 'lead',  -- lead, conversando, cliente, parada
  obs text,
  ultimo_contato timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_marcas_user_id on public.marcas(user_id);
create index if not exists idx_marcas_situacao on public.marcas(situacao);

-- ============================================================
-- Tabela: calendario
-- Planejamento de atividades (gravar, editar, postar)
-- ============================================================
create table if not exists public.calendario (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  titulo text not null,
  marca text,
  tipo text not null,                 -- gravar, editar, postar
  data date not null,
  status text not null default 'a fazer',  -- a fazer, feito
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_calendario_user_id on public.calendario(user_id);
create index if not exists idx_calendario_data on public.calendario(data);

-- ============================================================
-- Tabela: campanhas
-- Gestão de campanhas com clientes, status e pagamento
-- ============================================================
create table if not exists public.campanhas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  campanha text not null,
  cliente text,
  tipo text not null,                 -- Conteúdo, Publicidade
  status text not null default 'Briefing',  -- Briefing, Roteiro, Aprovação Roteiro, Gravação, Edição, Aprovado, Entregue
  qtd integer default 0,              -- quantidade de vídeos
  valor numeric(10,2) default 0,      -- valor total
  prazo date,
  pagamento text default 'pendente',  -- pendente, pago
  ativa boolean not null default true,
  favorita boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_campanhas_user_id on public.campanhas(user_id);
create index if not exists idx_campanhas_status on public.campanhas(status);
create index if not exists idx_campanhas_prazo on public.campanhas(prazo);

-- ============================================================
-- Tabela: marcados
-- Checklist do portfólio — itens que você já marcou como prontos
-- A chave é o ID do item no checklist (texto), não UUID
-- ============================================================
create table if not exists public.marcados (
  id text primary key,                -- ex: "checklist_video_hook", "checklist_roteiro_tempo"
  user_id uuid not null references auth.users(id) on delete cascade,
  checked boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_marcados_user_id on public.marcados(user_id);

-- ============================================================
-- Tabela: visitas
-- Rastreamento de visitas do portfólio (público lê e escreve)
-- ============================================================
create table if not exists public.visitas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,              -- o dono do portfólio
  pagina text,                        -- / , /portfolio, /sobre, etc.
  de_onde text,                       -- referrer (google, instagram, etc.)
  ip_address text,                    -- para detectar visitante único
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists idx_visitas_user_id on public.visitas(user_id);
create index if not exists idx_visitas_created_at on public.visitas(created_at desc);

-- ============================================================
-- Row Level Security (RLS)
-- Tranca: só o usuário logado acessa seus próprios dados
-- ============================================================

-- VIDEOS: só o dono lê e escreve
alter table public.videos enable row level security;
create policy "videos_usuario_logado"
  on public.videos
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- MARCAS: o dono lê e escreve; qualquer um pode INSERT (formulário do site)
alter table public.marcas enable row level security;
create policy "marcas_usuario_logado_leitura_escrita"
  on public.marcas
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "marcas_anon_pode_inserir"
  on public.marcas
  for insert
  to anon
  with check (true);  -- qualquer um pode inserir (formulário público)

-- CALENDARIO: só o dono
alter table public.calendario enable row level security;
create policy "calendario_usuario_logado"
  on public.calendario
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- CAMPANHAS: só o dono
alter table public.campanhas enable row level security;
create policy "campanhas_usuario_logado"
  on public.campanhas
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- MARCADOS: só o dono
alter table public.marcados enable row level security;
create policy "marcados_usuario_logado"
  on public.marcados
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- VISITAS: só o dono lê; qualquer um pode INSERT (rastreamento público)
alter table public.visitas enable row level security;
create policy "visitas_usuario_logado_leitura"
  on public.visitas
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "visitas_anon_pode_inserir"
  on public.visitas
  for insert
  to anon
  with check (true);  -- qualquer visitante pode registrar sua visita

-- ============================================================
-- DADOS DE EXEMPLO
-- Uma linha de exemplo em cada tabela, marcada como exemplo.
-- Você pode deletar depois que entender o formato.
-- ============================================================

insert into public.videos (user_id, titulo, link, nicho, formato, marca, destaque, ordem, visivel)
values (
  (select id from auth.users limit 1),
  'EXEMPLO — Modelador de Cachos',
  'https://youtube.com/shorts/xxxxx',
  'skincare',
  'shorts',
  'KISS NEW YORK',
  '2,4M views',
  1,
  true
) on conflict do nothing;

insert into public.marcas (user_id, nome, instagram, email, telefone, situacao, obs, ultimo_contato)
values (
  (select id from auth.users limit 1),
  'EXEMPLO — Marca Legal',
  '@marca.legal',
  'contato@marca.com',
  '(11) 9999-9999',
  'lead',
  'EXEMPLO - pode deletar. Foco em skincare, orçamento aberto.',
  now()
) on conflict do nothing;

insert into public.calendario (user_id, titulo, marca, tipo, data, status)
values (
  (select id from auth.users limit 1),
  'EXEMPLO — Gravar vídeo',
  'Marca de Teste',
  'gravar',
  now()::date,
  'a fazer'
) on conflict do nothing;

insert into public.campanhas (user_id, campanha, cliente, tipo, status, qtd, valor, prazo, pagamento, ativa)
values (
  (select id from auth.users limit 1),
  'Campanha de Exemplo',
  'Cliente Teste',
  'Conteúdo',
  'Briefing',
  3,
  1500.00,
  now()::date + interval '7 days',
  'pendente',
  true
) on conflict do nothing;

-- ============================================================
-- FIM DO SCRIPT
-- Rode tudo acima no Supabase > SQL Editor > New query
-- Depois, volte aqui e siga os próximos passos.
-- ============================================================
