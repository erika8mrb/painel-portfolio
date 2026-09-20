-- Adicionar campos que faltam na tabela marcas
-- Execute isso no Supabase SQL Editor

ALTER TABLE public.marcas
ADD COLUMN IF NOT EXISTS nicho text,
ADD COLUMN IF NOT EXISTS site text,
ADD COLUMN IF NOT EXISTS cidade text,
ADD COLUMN IF NOT EXISTS contato_nome text,
ADD COLUMN IF NOT EXISTS proposta_data date,
ADD COLUMN IF NOT EXISTS valor_orcado numeric(10, 2),
ADD COLUMN IF NOT EXISTS categoria text,
ADD COLUMN IF NOT EXISTS favorita boolean DEFAULT false;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_marcas_nicho ON public.marcas(nicho);
CREATE INDEX IF NOT EXISTS idx_marcas_favorita ON public.marcas(favorita);

-- Pronto! Agora os campos existem e você pode adicionar marcas.
