// ============================================================
// js/auth.js — Autenticação compartilhada (Supabase Auth)
// Usado por login.html e painel.html
// ============================================================

// Credenciais públicas do projeto Supabase (a chave anon é pública
// por design, mas a segurança real vem das policies de RLS no banco).
const SUPABASE_URL = 'https://tvgpzamubhmhypsuyyps.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2Z3B6YW11YmhtaHlwc3V5eXBzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4MDk0MjksImV4cCI6MjA5OTM4NTQyOX0.RMsHOQLOvai6uK1MbYTCw3pRHar63DrtsVq7kLC3R8I';

// Cria o cliente Supabase uma única vez (compartilhado por toda a aplicação)
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Objeto global exposto para as páginas usarem
window.Auth = {

  // Cliente supabase exposto para quem precisar consultar tabelas (painel.html)
  sb,

  /**
   * Faz login com e-mail e senha.
   * Lança um erro com mensagem amigável em caso de falha.
   */
  async login(email, senha) {
    const { data, error } = await sb.auth.signInWithPassword({
      email,
      password: senha,
    });

    if (error) {
      if (error.message === 'Invalid login credentials') {
        throw new Error('E-mail ou senha incorretos.');
      }
      throw new Error(error.message);
    }

    return data.user;
  },

  /**
   * Verifica se há uma sessão ativa.
   * Se NÃO houver, redireciona para login.html e retorna null.
   * Se houver, retorna o usuário logado.
   * Deve ser chamada no topo de toda página protegida (o "guarda").
   */
  async checkAuth() {
    const { data, error } = await sb.auth.getSession();

    if (error || !data.session) {
      window.location.href = 'login.html';
      return null;
    }

    return data.session.user;
  },

  /**
   * Encerra a sessão e volta para a tela de login.
   */
  async logout() {
    await sb.auth.signOut();
    window.location.href = 'login.html';
  },

  /**
   * Envia e-mail de recuperação de senha.
   */
  async recuperarSenha(email) {
    const { error } = await sb.auth.resetPasswordForEmail(email);
    if (error) {
      throw new Error(error.message);
    }
  },
};
