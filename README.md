# Painel administrativo do portfólio

Painel simples (HTML, CSS e JavaScript puro) para acompanhar visitas, cliques,
vídeos assistidos e mensagens de contato do seu portfólio. Os dados vêm do
Supabase (tabelas `portfolio_events` e `portfolio_leads`).

## Arquivos

- `login.html` — tela de login.
- `painel.html` — painel interno, protegido por sessão.
- `js/auth.js` — autenticação compartilhada (cliente Supabase + login/logout).
- `css/painel.css` — variáveis de design (cores, fontes, componentes).
- `setup.sql` — script para criar as tabelas e as permissões no Supabase.

## Passo a passo

1. **Rode o `setup.sql`**: abra o [painel do Supabase](https://supabase.com/dashboard) do seu projeto, vá em **SQL Editor > New query**, cole o conteúdo de `setup.sql` e clique em **Run**. Isso cria as tabelas `portfolio_events` e `portfolio_leads` com RLS habilitado.

2. **Crie seu usuário de login**: no painel do Supabase, vá em **Authentication > Users > Add user**, informe seu e-mail e uma senha. Marque a opção para já confirmar o e-mail automaticamente (ou confirme depois pelo link que o Supabase envia).

3. **Teste localmente**: como o navegador bloqueia módulos/fetch abertos direto do disco em alguns casos, rode um servidor local simples na pasta do projeto, por exemplo `npx serve .` ou `python3 -m http.server 8000`, e abra `http://localhost:8000/login.html`.

4. **Faça login**: entre com o e-mail e a senha criados no passo 2. Você deve cair em `painel.html` e ver os números (vazios até o site começar a gerar eventos).

5. **Publique no GitHub Pages ou na Vercel**: suba a pasta inteira (incluindo `js/` e `css/`) para um repositório GitHub. No GitHub Pages, ative em **Settings > Pages** apontando para a branch principal. Na Vercel, importe o repositório como um site estático (sem build command).

6. **Ligue o site ao painel**: os eventos e leads precisam ser gravados nas tabelas por um servidor seu (usando a chave `service_role`, nunca a `anon`) — veja o comentário no final de `setup.sql` para entender por quê.
