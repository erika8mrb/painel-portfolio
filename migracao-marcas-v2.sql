-- ============================================================
-- Migração: Melhorar tabela de marcas com mais informações
-- Execute isso no Supabase SQL Editor
-- ============================================================

ALTER TABLE public.marcas ADD COLUMN IF NOT EXISTS nicho text;
ALTER TABLE public.marcas ADD COLUMN IF NOT EXISTS site text;
ALTER TABLE public.marcas ADD COLUMN IF NOT EXISTS cidade text;
ALTER TABLE public.marcas ADD COLUMN IF NOT EXISTS contato_nome text;
ALTER TABLE public.marcas ADD COLUMN IF NOT EXISTS proposta_data date;
ALTER TABLE public.marcas ADD COLUMN IF NOT EXISTS valor_orcado numeric(10,2);
ALTER TABLE public.marcas ADD COLUMN IF NOT EXISTS categoria text;

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_marcas_nicho ON public.marcas(nicho);
CREATE INDEX IF NOT EXISTS idx_marcas_categoria ON public.marcas(categoria);
CREATE INDEX IF NOT EXISTS idx_marcas_cidade ON public.marcas(cidade);

-- Adicionar comentários às colunas (opcional, para documentação)
COMMENT ON COLUMN public.marcas.nicho IS 'Área ou nicho da marca (ex: beleza, tecnologia, moda)';
COMMENT ON COLUMN public.marcas.site IS 'URL do site da marca';
COMMENT ON COLUMN public.marcas.cidade IS 'Cidade onde a marca está localizada';
COMMENT ON COLUMN public.marcas.contato_nome IS 'Nome da pessoa responsável pelo contato';
COMMENT ON COLUMN public.marcas.proposta_data IS 'Data em que a proposta foi enviada';
COMMENT ON COLUMN public.marcas.valor_orcado IS 'Valor da proposta/orçamento';
COMMENT ON COLUMN public.marcas.categoria IS 'Categoria da marca (ex: PME, startup, grande empresa)';
