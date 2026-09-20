-- ============================================================
-- Migração: Sistema de Prospecção e Envio de E-mails
-- Execute isso no Supabase SQL Editor
-- ============================================================

-- 1. Adicionar coluna selecionada na tabela marcas
-- Permite marcar quais marcas receberão o próximo disparo
ALTER TABLE public.marcas
ADD COLUMN IF NOT EXISTS selecionada boolean DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_marcas_selecionada
ON public.marcas(selecionada);

COMMENT ON COLUMN public.marcas.selecionada
IS 'Se a marca foi selecionada para receber o próximo disparo de e-mail';

-- ============================================================

-- 2. Criar tabela email_envios
-- Registra cada e-mail enviado: destinatário, assunto, status, data
CREATE TABLE IF NOT EXISTS public.email_envios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Dados do envio
  email_destinatario text NOT NULL,
  assunto text NOT NULL,

  -- Status e erros
  status text NOT NULL DEFAULT 'pendente', -- 'ok', 'erro', 'pulado'
  erro_mensagem text, -- Descrição do erro se houver

  -- ID da resposta do Resend
  resend_message_id text,

  -- Quando foi enviado
  criado_em timestamp with time zone DEFAULT now(),

  CONSTRAINT email_envios_status_check
    CHECK (status IN ('ok', 'erro', 'pulado'))
);

CREATE INDEX IF NOT EXISTS idx_email_envios_user_id
ON public.email_envios(user_id);

CREATE INDEX IF NOT EXISTS idx_email_envios_email
ON public.email_envios(email_destinatario);

CREATE INDEX IF NOT EXISTS idx_email_envios_assunto
ON public.email_envios(assunto);

CREATE INDEX IF NOT EXISTS idx_email_envios_status
ON public.email_envios(status);

CREATE INDEX IF NOT EXISTS idx_email_envios_criado
ON public.email_envios(criado_em);

COMMENT ON TABLE public.email_envios
IS 'Registro de cada e-mail enviado para rastreamento e auditoria';

COMMENT ON COLUMN public.email_envios.user_id
IS 'Usuário que fez o disparo';

COMMENT ON COLUMN public.email_envios.email_destinatario
IS 'E-mail da marca que recebeu';

COMMENT ON COLUMN public.email_envios.status
IS 'ok = entregue, erro = falhou, pulado = foi ignorado';

COMMENT ON COLUMN public.email_envios.resend_message_id
IS 'ID devolvido pelo Resend para rastreamento';

-- ============================================================

-- 3. Criar tabela email_optout
-- Quem pediu pra sair (respondeu SAIR no e-mail)
CREATE TABLE IF NOT EXISTS public.email_optout (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  email_descadastrado text NOT NULL UNIQUE,
  motivo text, -- opcional: por que saiu
  criado_em timestamp with time zone DEFAULT now(),

  CONSTRAINT email_optout_email_check
    CHECK (email_descadastrado ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX IF NOT EXISTS idx_email_optout_user_id
ON public.email_optout(user_id);

CREATE INDEX IF NOT EXISTS idx_email_optout_email
ON public.email_optout(email_descadastrado);

COMMENT ON TABLE public.email_optout
IS 'E-mails que pediram para sair (responderam SAIR)';

COMMENT ON COLUMN public.email_optout.email_descadastrado
IS 'E-mail que foi descadastrado';

-- ============================================================

-- 4. RLS (Row Level Security) - email_envios
-- Só o usuário logado vê seus próprios envios
ALTER TABLE public.email_envios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "email_envios_usuario_ve_seus"
ON public.email_envios
FOR SELECT
USING (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

CREATE POLICY "email_envios_usuario_insere_seus"
ON public.email_envios
FOR INSERT
WITH CHECK (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

CREATE POLICY "email_envios_usuario_deleta_seus"
ON public.email_envios
FOR DELETE
USING (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

-- ============================================================

-- 5. RLS (Row Level Security) - email_optout
-- Só o usuário logado vê e gerencia seus descadastros
ALTER TABLE public.email_optout ENABLE ROW LEVEL SECURITY;

CREATE POLICY "email_optout_usuario_ve_seus"
ON public.email_optout
FOR SELECT
USING (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

CREATE POLICY "email_optout_usuario_insere_seus"
ON public.email_optout
FOR INSERT
WITH CHECK (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

CREATE POLICY "email_optout_usuario_deleta_seus"
ON public.email_optout
FOR DELETE
USING (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

-- ============================================================
-- FIM DA MIGRAÇÃO
-- Se tudo rodou sem erro, você está pronto!
-- ============================================================
