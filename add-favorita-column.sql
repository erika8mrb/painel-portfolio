-- Adicionar coluna favorita à tabela marcas (se não existir)
-- Execute isso no Supabase SQL Editor

ALTER TABLE public.marcas
ADD COLUMN IF NOT EXISTS favorita boolean DEFAULT false;

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_marcas_favorita
ON public.marcas(favorita);

-- Pronto! Agora você pode:
-- 1. Acesse a aba Marcas
-- 2. Clique em "⭐ Destacar" em qualquer marca
-- 3. Marcas favoritas aparecerão no topo com estrela
-- 4. Clique novamente para "☆ Remover destaque"
