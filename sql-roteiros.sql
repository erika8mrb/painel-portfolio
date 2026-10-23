-- Roteiros e configurações (transcrição via Supadata).
-- Pode rodar mais de uma vez, com o banco no estado que estiver.

CREATE TABLE IF NOT EXISTS roteiros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id)
);

ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS fonte TEXT NOT NULL DEFAULT 'manual';
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS url TEXT;
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS perfil TEXT;
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS de_quem TEXT NOT NULL DEFAULT 'outra';
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS titulo TEXT;
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS transcricao TEXT;
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS segmentos JSONB;
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS legenda TEXT;
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS postado_em DATE;
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS obs TEXT;
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pronto';
ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS erro TEXT;

ALTER TABLE roteiros ALTER COLUMN url DROP NOT NULL;

ALTER TABLE roteiros ADD COLUMN IF NOT EXISTS capa_url TEXT;

ALTER TABLE roteiros DROP CONSTRAINT IF EXISTS roteiros_fonte_check;
ALTER TABLE roteiros ADD CONSTRAINT roteiros_fonte_check
  CHECK (fonte IN ('instagram', 'tiktok', 'youtube', 'manual'));

ALTER TABLE roteiros DROP CONSTRAINT IF EXISTS roteiros_de_quem_check;
ALTER TABLE roteiros ADD CONSTRAINT roteiros_de_quem_check
  CHECK (de_quem IN ('minha', 'outra'));

ALTER TABLE roteiros DROP CONSTRAINT IF EXISTS roteiros_status_check;
ALTER TABLE roteiros ADD CONSTRAINT roteiros_status_check
  CHECK (status IN ('processando', 'pronto', 'falhou'));

CREATE INDEX IF NOT EXISTS idx_roteiros_created_at ON roteiros (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_roteiros_user_id ON roteiros (user_id);

CREATE TABLE IF NOT EXISTS configuracoes (
  chave TEXT PRIMARY KEY,
  valor TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  user_id UUID DEFAULT auth.uid() REFERENCES auth.users(id)
);

ALTER TABLE configuracoes ADD COLUMN IF NOT EXISTS user_id UUID DEFAULT auth.uid() REFERENCES auth.users(id);

ALTER TABLE roteiros ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuários podem ler/escrever seus próprios roteiros" ON roteiros;
DROP POLICY IF EXISTS "roteiros_somente_dono" ON roteiros;
CREATE POLICY "roteiros_somente_dono" ON roteiros
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem ler/escrever suas próprias configurações" ON configuracoes;
DROP POLICY IF EXISTS "configuracoes_somente_dono" ON configuracoes;
CREATE POLICY "configuracoes_somente_dono" ON configuracoes
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

REVOKE ALL ON roteiros FROM anon;
REVOKE ALL ON configuracoes FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON roteiros TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON configuracoes TO authenticated;
