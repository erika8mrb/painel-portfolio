-- Tabela de roteiros (transcrições de vídeos)
CREATE TABLE roteiros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  fonte TEXT NOT NULL CHECK (fonte IN ('instagram', 'tiktok', 'youtube', 'manual')),
  url TEXT NOT NULL,
  perfil TEXT,
  de_quem TEXT DEFAULT 'outra' CHECK (de_quem IN ('minha', 'outra')),

  titulo TEXT,
  transcricao TEXT,
  legenda TEXT,
  postado_em DATE,
  tags TEXT[] DEFAULT '{}',
  obs TEXT,

  status TEXT DEFAULT 'pronto' CHECK (status IN ('processando', 'pronto', 'falhou')),
  erro TEXT,
  segmentos JSONB
);

CREATE INDEX idx_roteiros_created_at ON roteiros(created_at DESC);
CREATE INDEX idx_roteiros_user_id ON roteiros(user_id);

-- Tabela de configurações (chaves de API, etc)
CREATE TABLE configuracoes (
  chave TEXT PRIMARY KEY,
  valor TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  user_id UUID NOT NULL REFERENCES auth.users(id)
);

CREATE INDEX idx_configuracoes_user_id ON configuracoes(user_id);

-- RLS: Roteiros
ALTER TABLE roteiros ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários podem ler/escrever seus próprios roteiros"
  ON roteiros
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS: Configurações
ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários podem ler/escrever suas próprias configurações"
  ON configuracoes
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Grant
GRANT ALL ON roteiros TO authenticated;
GRANT ALL ON configuracoes TO authenticated;
