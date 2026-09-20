-- ============================================================
-- Migração: Adicionar coluna de favorita/destaque em marcas
-- Execute isso no Supabase SQL Editor
-- ============================================================

ALTER TABLE public.marcas ADD COLUMN IF NOT EXISTS favorita boolean default false;

-- Criar índice para melhorar performance
CREATE INDEX IF NOT EXISTS idx_marcas_favorita ON public.marcas(favorita);

-- Comentário
COMMENT ON COLUMN public.marcas.favorita IS 'Se a marca está marcada como favorita/destaque';
