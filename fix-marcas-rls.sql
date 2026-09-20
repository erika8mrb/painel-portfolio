-- Habilitar RLS na tabela marcas
ALTER TABLE public.marcas ENABLE ROW LEVEL SECURITY;

-- Policy: usuário vê suas próprias marcas
CREATE POLICY "marcas_usuario_ve_suas"
ON public.marcas
FOR SELECT
USING (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

-- Policy: usuário insere suas próprias marcas
CREATE POLICY "marcas_usuario_insere_suas"
ON public.marcas
FOR INSERT
WITH CHECK (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

-- Policy: usuário atualiza suas próprias marcas
CREATE POLICY "marcas_usuario_atualiza_suas"
ON public.marcas
FOR UPDATE
USING (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

-- Policy: usuário deleta suas próprias marcas
CREATE POLICY "marcas_usuario_deleta_suas"
ON public.marcas
FOR DELETE
USING (user_id = (SELECT id FROM auth.users WHERE email = 'erika333ugc@gmail.com'));

-- Pronto! Agora você consegue adicionar marcas.
