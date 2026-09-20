import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

interface RequestBody {
  destinatarios: string[];
  assunto: string;
  html: string;
  skip_enviados?: boolean;
}

interface EmailResult {
  email: string;
  status: "ok" | "erro" | "pulado";
  erro_mensagem?: string;
  resend_message_id?: string;
}

const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_KEY!);

// Extrair primeiro nome de um texto
function extrairPrimeiroNome(nome: string): string {
  return nome.split(" ")[0];
}

// Substituir variáveis no HTML
function substituirVariaveis(html: string, nome: string): string {
  const primeiroNome = extrairPrimeiroNome(nome);
  return html
    .replace(/\{\{nome\}\}/g, primeiroNome)
    .replace(/\{\{marca\}\}/g, nome);
}

// Verificar se e-mail está em descadastro
const verificarDescadastro = async (email: string): Promise<boolean> => {
  const { data } = await supabase
    .from("email_optout")
    .select("id")
    .eq("email_descadastrado", email.toLowerCase())
    .single();
  return !!data;
};

// Verificar se já foi enviado o mesmo assunto
const verificarEnviado = async (
  email: string,
  assunto: string
): Promise<boolean> => {
  const { data } = await supabase
    .from("email_envios")
    .select("id")
    .eq("email_destinatario", email.toLowerCase())
    .eq("assunto", assunto)
    .eq("status", "ok")
    .single();
  return !!data;
};

// Enviar e-mail via Resend
const enviarViaResend = async (
  email: string,
  assunto: string,
  html: string
): Promise<any> => {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: "Erika Barreiros <noreply@erikabarreiros.com>",
      to: email,
      subject: assunto,
      html: html,
      reply_to: "erika333ugc@gmail.com",
      headers: {
        "List-Unsubscribe": "<mailto:erika333ugc@gmail.com?subject=SAIR>",
      },
    }),
  });

  const data = await response.json();
  return { success: response.ok, data };
};

// Aguardar em ms
const delay = (ms: number) => new Promise((r) => setTimeout(r, ms));

serve(async (req) => {
  // Validar autenticação
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ erro: "Não autenticado" }), {
      status: 401,
    });
  }

  try {
    const token = authHeader.replace("Bearer ", "");
    const { data: user } = await supabase.auth.getUser(token);

    if (!user?.user?.email || user.user.email !== "erika333ugc@gmail.com") {
      return new Response(JSON.stringify({ erro: "Usuário não autorizado" }), {
        status: 403,
      });
    }

    const body: RequestBody = await req.json();

    if (!body.destinatarios || body.destinatarios.length === 0) {
      return new Response(
        JSON.stringify({ erro: "Nenhum destinatário fornecido" }),
        { status: 400 }
      );
    }

    if (body.destinatarios.length > 250) {
      return new Response(
        JSON.stringify({ erro: "Máximo 250 destinatários por vez" }),
        { status: 400 }
      );
    }

    const resultados: EmailResult[] = [];
    let enviados = 0;
    let falhas = 0;
    let pulados = 0;
    let quotaExcedida = false;

    // Deduplicar e-mails
    const destinatariosUnicos = [...new Set(body.destinatarios.map((e) => e.toLowerCase()))];

    for (const email of destinatariosUnicos) {
      // Verificar descadastro
      const estaDescadastrado = await verificarDescadastro(email);
      if (estaDescadastrado) {
        pulados++;
        resultados.push({
          email,
          status: "pulado",
          erro_mensagem: "E-mail está em descadastro",
        });
        continue;
      }

      // Verificar se já foi enviado (se skip_enviados ativado)
      if (body.skip_enviados) {
        const jaFoiEnviado = await verificarEnviado(email, body.assunto);
        if (jaFoiEnviado) {
          pulados++;
          resultados.push({
            email,
            status: "pulado",
            erro_mensagem: "Já recebeu este assunto",
          });
          continue;
        }
      }

      // Substituir variáveis
      const htmlPersonalizado = substituirVariaveis(body.html, email);

      // Enviar e-mail
      const resultado = await enviarViaResend(
        email,
        body.assunto,
        htmlPersonalizado
      );

      if (resultado.data?.error?.message?.includes("daily_quota_exceeded")) {
        quotaExcedida = true;
        break;
      }

      if (resultado.success) {
        enviados++;
        resultados.push({
          email,
          status: "ok",
          resend_message_id: resultado.data.id,
        });
      } else {
        falhas++;
        resultados.push({
          email,
          status: "erro",
          erro_mensagem: resultado.data?.error?.message || "Erro desconhecido",
        });
      }

      // Aguardar 200ms entre envios
      await delay(200);
    }

    // Registrar todos os resultados no banco
    const registros = resultados.map((r) => ({
      user_id: user.user.id,
      email_destinatario: r.email,
      assunto: body.assunto,
      status: r.status,
      erro_mensagem: r.erro_mensagem || null,
      resend_message_id: r.resend_message_id || null,
    }));

    await supabase.from("email_envios").insert(registros);

    return new Response(
      JSON.stringify({
        sucesso: true,
        resumo: {
          enviados,
          falhas,
          pulados,
          quota_excedida: quotaExcedida,
          total_processado: destinatariosUnicos.length,
        },
        detalhes: resultados,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (erro) {
    return new Response(JSON.stringify({ erro: erro.message }), {
      status: 500,
    });
  }
});
