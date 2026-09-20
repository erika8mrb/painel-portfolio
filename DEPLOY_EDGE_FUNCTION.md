# Como Fazer Deploy da Edge Function

A função `enviar-emails` está pronta! Agora você precisa fazer deploy no Supabase.

## OPÇÃO 1: VIA PAINEL DO SUPABASE (Mais Fácil)

### Passo 1: Abra o Supabase
- Vá em https://console.supabase.com
- Faça login

### Passo 2: Vá em Edge Functions
- No menu lateral esquerdo, procure pelo ícone de **raio ⚡** ou **terminal**
- Clique nele
- Vai aparecer "Edge Functions"

### Passo 3: Crie uma nova função
- Clique em **"Create a new function"** ou **"New Function"**
- Nome da função: `enviar-emails`
- Deixa o resto padrão
- Clique em **Create** ou **Deploy**

### Passo 4: Cole o código
- Abra o arquivo: `supabase/functions/enviar-emails/index.ts` (no seu projeto)
- Copie TODO o código (Ctrl+A, Ctrl+C)
- No Supabase, cole no editor (Ctrl+V)
- Clique em **Deploy**

### Passo 5: Verifique se funcionou
- Se aparecer "✓ Successfully deployed", está pronto!
- Se der erro, copie a mensagem de erro e me manda

---

## OPÇÃO 2: VIA TERMINAL (Se tiver Supabase CLI)

```bash
cd /seu-projeto
supabase functions deploy enviar-emails
```

---

## Depois de Deploy: Teste

### Teste 1: Enviar um teste
- Abra seu admin (erikabarreiros.com/painel.html)
- Vá na aba **Prospecção** (quando criar)
- Clique em "Enviar teste pra mim"
- Se receber um e-mail, funcionou! ✅

### Teste 2: Verifique o banco
- Abra Supabase
- Vá em **Banco de dados**
- Clique em `email_envios`
- Deve ter um registro com status "ok"

---

## Se der erro...

**Erro: "RESEND_API_KEY não encontrado"**
- Volte ao Supabase Settings → Secrets
- Verifique se o secret está lá com o nome exato `RESEND_API_KEY`

**Erro: "Unauthorized"**
- Verifique o e-mail no código (deve ser `erika333ugc@gmail.com`)
- Se precisar mudar, me avisa

**Outro erro:**
- Me manda a mensagem de erro que aparece

---

## Checklist Final

Quando tudo estiver pronto, você terá:

- ✅ Tabelas criadas (email_envios, email_optout)
- ✅ Coluna selecionada adicionada em marcas
- ✅ Secret RESEND_API_KEY guardado no Supabase
- ✅ Edge Function enviar-emails deployed
- ✅ Teste recebido no seu e-mail

Aí sim a aba Prospecção vai funcionar 100%!
