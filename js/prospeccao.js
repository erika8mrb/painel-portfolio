// ============================================================
// Painel Prospecção - Gerenciador de Disparos de E-mails
// ============================================================

let estadoProspeccao = {
  destinatarios: [],
  filtroAtual: 'selecionadas',
  modo: 'texto', // 'texto' ou 'html'
  assunto: '',
  html: '',
  htmlOriginal: '',
  skipEnviados: true,
  marcasSelecionadas: new Set(),
};

// Inicializar aba Prospecção
async function iniciarProspeccao() {
  console.log('Inicializando Prospecção...');

  // Garantir que marcas estão carregadas
  if (typeof cacheMarcas === 'undefined' || cacheMarcas.length === 0) {
    await recarregarMarcas();
  }

  // Montar interface
  montarTelaProspeccao();

  // Restaurar seleções do banco
  await restaurarSelecoes();

  // Atualizar números
  atualizarNumerosProspeccao();
}

// Restaurar seleções do banco de dados
async function restaurarSelecoes() {
  try {
    const { data, error } = await Auth.sb
      .from('marcas')
      .select('id')
      .eq('selecionada', true);

    if (!error && data) {
      estadoProspeccao.marcasSelecionadas = new Set(data.map(m => m.id));
      atualizarCheckboxesSelecionadas();
    }
  } catch (erro) {
    console.error('Erro ao restaurar seleções:', erro);
  }
}

// Montar a tela de Prospecção
function montarTelaProspeccao() {
  const container = document.getElementById('abaPerspeccao');
  if (!container) return;

  container.innerHTML = `
    <!-- CAPA -->
    <div class="prospeccao-capa">
      <div class="prospeccao-capa-conteudo">
        <div class="prospeccao-icone">✉️</div>
        <h1>Prospecção</h1>
        <p>Envie e-mails personalizados para suas marcas em massa</p>
        <div class="prospeccao-stats">
          <div class="stat-item">
            <span class="stat-numero">${obterTotalEnviados()}</span>
            <span class="stat-label">enviados até agora</span>
          </div>
        </div>
        <div class="prospeccao-tags">
          <span class="tag">✓ Teste antes sempre</span>
          <span class="tag">✓ Chave no Supabase</span>
          <span class="tag">✓ Responder SAIR para sair</span>
        </div>
      </div>
    </div>

    <!-- CARTÕES DE MÉTRICAS -->
    <div class="prospeccao-metricas">
      <div class="metrica-card" style="border-left-color: #9c8365;">
        <div class="metrica-numero" style="color: #9c8365;">${obterMarcasComEmail()}</div>
        <div class="metrica-nome">com e-mail</div>
        <div class="metrica-contexto">na base</div>
      </div>

      <div class="metrica-card" style="border-left-color: #2d5a3d;">
        <div class="metrica-numero" style="color: #2d5a3d;">${obterParaEnviar()}</div>
        <div class="metrica-nome">a enviar</div>
      </div>

      <div class="metrica-card" style="border-left-color: #3b7a8a;">
        <div class="metrica-numero" style="color: #3b7a8a;">${obterJaEnviados()}</div>
        <div class="metrica-nome">já receberam</div>
      </div>

      <div class="metrica-card" style="border-left-color: #d4a574;">
        <div class="metrica-numero" style="color: #d4a574;">${obterFalhas()}</div>
        <div class="metrica-nome">falhas</div>
        <div class="metrica-contexto">pra revisar</div>
      </div>

      <div class="metrica-card" style="border-left-color: #c76464;">
        <div class="metrica-numero" style="color: #c76464;">${obterDescadastrados()}</div>
        <div class="metrica-nome">descadastrados</div>
      </div>
    </div>

    <!-- CONTEÚDO PRINCIPAL -->
    <div class="prospeccao-main">
      <!-- COLUNA ESQUERDA: Formulário -->
      <div class="prospeccao-form">
        <!-- SEÇÃO: ESCOLHER DESTINATÁRIOS -->
        <div class="prospeccao-secao">
          <h2>Escolher pra quem vai</h2>
          <p class="prospeccao-info">⚠️ Os e-mails vêm de sua aba Marcas</p>

          <div class="filtros-destinatarios">
            <label class="filtro-radio">
              <input type="radio" name="filtro" value="selecionadas" checked onchange="mudarFiltro(this.value)">
              <span>Só as selecionadas</span>
            </label>

            <label class="filtro-radio">
              <input type="radio" name="filtro" value="teste" onchange="mudarFiltro(this.value)">
              <span>Teste (só pra mim)</span>
            </label>

            <label class="filtro-radio">
              <input type="radio" name="filtro" value="todas" onchange="mudarFiltro(this.value)">
              <span>Todas com e-mail</span>
            </label>
          </div>

          <div id="filtrosSituacao" style="margin-top: 12px;"></div>

          <div class="prospeccao-resumo">
            <strong id="totalDestinatarios">0</strong> marcas <span id="semEmail"></span>
          </div>

          <label class="checkbox-opcao">
            <input type="checkbox" id="skipEnviados" checked onchange="estadoProspeccao.skipEnviados = this.checked">
            <span>Pular quem já recebeu este assunto</span>
          </label>
        </div>

        <!-- SEÇÃO: ESCREVER E-MAIL -->
        <div class="prospeccao-secao">
          <h2>Escrever o e-mail</h2>

          <div class="modo-toggle">
            <button class="modo-btn ativo" onclick="mudarModo('texto')">Texto Fácil</button>
            <button class="modo-btn" onclick="mudarModo('html')">HTML</button>
          </div>

          <!-- MODO TEXTO -->
          <div id="modoTexto" class="modo-conteudo">
            <div class="form-group">
              <label>Assunto</label>
              <input type="text" id="assuntoEmail" placeholder="Ex: Parceria para conteúdo UGC" oninput="atualizarPrevia()" onchange="atualizarPrevia()">
            </div>

            <div class="form-group">
              <label>Texto do e-mail</label>
              <textarea id="textoEmail" placeholder="Escreva seu e-mail aqui...&#10;&#10;Use {{nome}} para o primeiro nome&#10;Use {{marca}} para o nome completo" oninput="atualizarPrevia()" onchange="atualizarPrevia()"></textarea>
            </div>

            <div class="form-group">
              <label>Botão (opcional)</label>
              <input type="text" id="textoButao" placeholder="Texto do botão" oninput="atualizarPrevia()" onchange="atualizarPrevia()">
              <input type="text" id="linkButao" placeholder="URL do botão" oninput="atualizarPrevia()" onchange="atualizarPrevia()">
            </div>
          </div>

          <!-- MODO HTML -->
          <div id="modoHtml" class="modo-conteudo" style="display: none;">
            <button class="btn-secundario" onclick="carregarModeloHtml()" style="margin-bottom: 12px;">
              Começar do modelo
            </button>

            <div class="form-group">
              <label>HTML do e-mail</label>
              <textarea id="htmlEmail" placeholder="Cole aqui o HTML completo..." oninput="atualizarPrevia()" onchange="atualizarPrevia()"></textarea>
            </div>
          </div>
        </div>

        <!-- SEÇÃO: ENVIAR -->
        <div class="prospeccao-secao">
          <h2>Enviar</h2>

          <button class="botao botao-teste" onclick="enviarTeste()">
            📧 Enviar teste pra mim
          </button>

          <button class="botao" onclick="disparar()" id="botaoDisparar">
            Disparar agora
          </button>

          <div id="progressoEnvio" style="display: none; margin-top: 12px;">
            <div class="barra-progresso">
              <div id="barraPreenchida" class="barra-preenchida"></div>
            </div>
            <p id="textoProgresso" style="font-size: 13px; color: var(--texto-suave); margin-top: 8px;"></p>
          </div>
        </div>

        <!-- SEÇÃO: HISTÓRICO -->
        <div class="prospeccao-secao">
          <h2>Histórico</h2>
          <div id="historicoEnvios"></div>
        </div>
      </div>

      <!-- COLUNA DIREITA: Prévia -->
      <div class="prospeccao-preview">
        <div class="preview-header">
          <button class="btn-tela-cheia" onclick="abrirTelaCheia()">👁️ Ver em tela cheia</button>
          <p style="font-size: 12px; color: var(--texto-suave); margin-top: 12px;">
            💡 Mande o teste pra você no celular para conferir como vai chegar
          </p>
        </div>
        <div id="previewEmail" class="preview-email">
          <div class="email-header">
            <div class="email-avatar">E</div>
            <div class="email-info">
              <div class="email-assunto">Seu assunto aqui</div>
              <div class="email-from">de Erika Barreiros &lt;erika333ugc@gmail.com&gt;</div>
              <div class="email-para">para você</div>
            </div>
          </div>
          <div class="email-body">
            Escreva seu e-mail para ver a prévia aqui
          </div>
        </div>
      </div>
    </div>
  `;

  adicionarEstilosProspeccao();
}

// Adicionar estilos CSS
function adicionarEstilosProspeccao() {
  if (document.getElementById('estilosProspeccao')) return;

  const style = document.createElement('style');
  style.id = 'estilosProspeccao';
  style.innerHTML = `
    .prospeccao-capa {
      background: linear-gradient(135deg, #9c8365 0%, #6d5a47 100%);
      border-radius: 16px;
      padding: 32px;
      margin-bottom: 24px;
      color: white;
    }

    .prospeccao-icone {
      font-size: 48px;
      margin-bottom: 16px;
    }

    .prospeccao-capa h1 {
      font-size: 32px;
      font-weight: 600;
      margin: 0 0 8px 0;
    }

    .prospeccao-capa > div > p {
      margin: 0 0 24px 0;
      opacity: 0.95;
      font-size: 14px;
    }

    .prospeccao-stats {
      display: flex;
      gap: 16px;
      margin-bottom: 16px;
    }

    .stat-item {
      display: flex;
      flex-direction: column;
    }

    .stat-numero {
      font-size: 28px;
      font-weight: 600;
    }

    .stat-label {
      font-size: 12px;
      opacity: 0.85;
    }

    .prospeccao-tags {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .tag {
      background: rgba(255, 255, 255, 0.15);
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
    }

    .prospeccao-metricas {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }

    .metrica-card {
      background: white;
      border-left: 4px solid;
      border-radius: 8px;
      padding: 16px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }

    .metrica-numero {
      font-size: 28px;
      font-weight: 600;
      display: block;
    }

    .metrica-nome {
      font-size: 13px;
      font-weight: 500;
      color: var(--grafite);
      margin-top: 4px;
    }

    .metrica-contexto {
      font-size: 11px;
      color: var(--texto-suave);
    }

    .prospeccao-main {
      display: grid;
      grid-template-columns: 1fr 380px;
      gap: 24px;
    }

    @media (max-width: 1024px) {
      .prospeccao-main {
        grid-template-columns: 1fr;
      }
    }

    .prospeccao-secao {
      background: white;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 16px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }

    .prospeccao-secao h2 {
      font-size: 16px;
      font-weight: 600;
      margin: 0 0 16px 0;
      color: var(--grafite);
    }

    .prospeccao-info {
      background: #fff9f0;
      border-left: 3px solid #d4a574;
      padding: 12px;
      border-radius: 4px;
      font-size: 13px;
      margin-bottom: 12px;
      margin: 0 0 12px 0;
    }

    .filtros-destinatarios {
      display: flex;
      flex-direction: column;
      gap: 8px;
      margin-bottom: 12px;
    }

    .filtro-radio {
      display: flex;
      align-items: center;
      gap: 8px;
      cursor: pointer;
      font-size: 14px;
    }

    .filtro-radio input {
      accent-color: #9c8365;
    }

    .prospeccao-resumo {
      background: #f5f5f5;
      padding: 8px 12px;
      border-radius: 4px;
      font-size: 13px;
      margin: 12px 0;
    }

    .checkbox-opcao {
      display: flex;
      align-items: center;
      gap: 8px;
      cursor: pointer;
      font-size: 13px;
      margin-top: 12px;
    }

    .modo-toggle {
      display: flex;
      gap: 8px;
      margin-bottom: 16px;
    }

    .modo-btn {
      flex: 1;
      padding: 8px 12px;
      border: 1px solid #ddd;
      background: white;
      border-radius: 6px;
      cursor: pointer;
      font-size: 13px;
      transition: all 0.15s;
    }

    .modo-btn.ativo {
      background: #9c8365;
      color: white;
      border-color: #9c8365;
    }

    .modo-conteudo {
      animation: fadeIn 0.15s ease;
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }

    .form-group {
      margin-bottom: 12px;
    }

    .form-group label {
      display: block;
      font-size: 12px;
      font-weight: 600;
      color: var(--grafite);
      margin-bottom: 6px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .form-group input[type="text"],
    .form-group textarea {
      width: 100%;
      padding: 10px 12px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-family: var(--fonte-texto);
      font-size: 13px;
      resize: vertical;
      min-height: 100px;
    }

    .form-group input[type="text"]:focus,
    .form-group textarea:focus {
      outline: none;
      border-color: #9c8365;
      box-shadow: 0 0 0 3px rgba(156, 131, 101, 0.1);
    }

    .botao-teste {
      background: #f0f0f0;
      color: var(--grafite);
      margin-bottom: 12px;
    }

    .botao-teste:hover {
      background: #e0e0e0;
    }

    .barra-progresso {
      background: #f0f0f0;
      height: 6px;
      border-radius: 3px;
      overflow: hidden;
    }

    .barra-preenchida {
      background: #2d5a3d;
      height: 100%;
      width: 0%;
      transition: width 0.3s ease;
    }

    .prospeccao-preview {
      background: white;
      border-radius: 12px;
      padding: 20px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
      height: fit-content;
      position: sticky;
      top: 20px;
    }

    .preview-header {
      margin-bottom: 16px;
    }

    .btn-tela-cheia {
      background: #f0f0f0;
      border: none;
      padding: 8px 12px;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
      width: 100%;
      transition: background 0.15s;
    }

    .btn-tela-cheia:hover {
      background: #e0e0e0;
    }

    .preview-email {
      background: #f9f9f9;
      border-radius: 8px;
      overflow: hidden;
      border: 1px solid #ddd;
    }

    .email-header {
      display: flex;
      gap: 12px;
      padding: 12px;
      border-bottom: 1px solid #ddd;
      background: white;
    }

    .email-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: #9c8365;
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      flex-shrink: 0;
    }

    .email-info {
      flex: 1;
      min-width: 0;
    }

    .email-assunto {
      font-weight: 600;
      font-size: 14px;
      color: var(--grafite);
      margin-bottom: 4px;
    }

    .email-from {
      font-size: 12px;
      color: var(--texto-suave);
    }

    .email-para {
      font-size: 12px;
      color: var(--texto-suave);
    }

    .email-body {
      padding: 16px;
      font-size: 13px;
      line-height: 1.6;
      color: var(--grafite);
      white-space: pre-wrap;
      word-wrap: break-word;
    }
  `;

  document.head.appendChild(style);
}

// Obter métricas
function obterTotalEnviados() {
  return cacheMarcas.filter(m => m.data_ultimo_envio).length || 0;
}

function obterMarcasComEmail() {
  return cacheMarcas.filter(m => m.email).length || 0;
}

function obterParaEnviar() {
  const com_email = cacheMarcas.filter(m => m.email).length || 0;
  const ja_enviado = obterTotalEnviados();
  return Math.max(0, com_email - ja_enviado);
}

function obterJaEnviados() {
  return obterTotalEnviados();
}

function obterFalhas() {
  return 0; // TODO: contar de email_envios com status erro
}

function obterDescadastrados() {
  return 0; // TODO: contar de email_optout
}

// Mudar filtro
function mudarFiltro(filtro) {
  estadoProspeccao.filtroAtual = filtro;
  atualizarNumerosProspeccao();
}

// Mudar modo
function mudarModo(modo) {
  estadoProspeccao.modo = modo;

  document.querySelectorAll('.modo-btn').forEach(btn => {
    btn.classList.remove('ativo');
  });

  event.target.classList.add('ativo');

  document.getElementById('modoTexto').style.display = modo === 'texto' ? 'block' : 'none';
  document.getElementById('modoHtml').style.display = modo === 'html' ? 'block' : 'none';
}

// Atualizar prévia
function atualizarPrevia() {
  const containerPrevia = document.getElementById('previaEmail');
  if (!containerPrevia) return;

  const assunto = document.getElementById('assuntoEmail')?.value || estadoProspeccao.assunto;
  const textoEmail = document.getElementById('textoEmail')?.value || '';
  const htmlEmail = document.getElementById('htmlEmail')?.value || '';
  const modo = document.querySelector('input[name="modo"]:checked')?.value || estadoProspeccao.modo;

  estadoProspeccao.assunto = assunto;
  estadoProspeccao.modo = modo;

  let htmlParaMostrar = '';

  if (modo === 'texto') {
    estadoProspeccao.html = `<p>${textoEmail.replace(/\n/g, '</p><p>')}</p>`;
    htmlParaMostrar = `<pre style="white-space: pre-wrap; word-wrap: break-word; font-family: inherit;">${escapeHtml(textoEmail)}</pre>`;
  } else {
    estadoProspeccao.html = htmlEmail;
    htmlParaMostrar = htmlEmail;
  }

  containerPrevia.innerHTML = `
    <div style="background: white; border: 1px solid var(--borda); border-radius: var(--raio-sm); overflow: hidden;">
      <div style="padding: 16px; border-bottom: 1px solid var(--borda); background: var(--creme);">
        <div style="font-size: 12px; color: var(--texto-suave); margin-bottom: 4px;">Assunto</div>
        <div style="font-weight: 600; color: var(--grafite);">${escapeHtml(assunto) || '(vazio)'}</div>
      </div>
      <div style="padding: 24px; font-size: 14px; line-height: 1.6; color: var(--grafite);">
        ${htmlParaMostrar}
      </div>
    </div>
  `;
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Carregar modelo HTML
function carregarModeloHtml() {
  const html = `<html>
  <body style="font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px;">
    <div style="max-width: 560px; background: white; border-radius: 8px; padding: 32px; margin: 0 auto;">
      <p>Olá {{nome}},</p>

      <p>Gostaria de conversar sobre uma parceria com {{marca}}!</p>

      <p><a href="#" style="display: inline-block; background: #9c8365; color: white; padding: 10px 24px; border-radius: 6px; text-decoration: none;">Clique aqui para responder</a></p>

      <p>Abraços,<br>Erika Barreiros</p>

      <hr style="border: none; border-top: 1px solid #ddd; margin: 24px 0;">

      <p style="font-size: 12px; color: #999;">
        Se não quer mais receber, responda com SAIR
      </p>
    </div>
  </body>
</html>`;

  document.getElementById('htmlEmail').value = html;
  atualizarPrevia();
}

// Enviar teste
async function enviarTeste() {
  if (!estadoProspeccao.assunto.trim()) {
    alert('⚠️ Digite um assunto para o teste');
    return;
  }

  const botaoTeste = document.querySelector('[onclick="enviarTeste()"]');
  const boesOriginal = botaoTeste?.textContent;
  if (botaoTeste) botaoTeste.disabled = true;

  try {
    if (botaoTeste) botaoTeste.textContent = 'Enviando...';

    const session = await Auth.sb.auth.getSession();
    const token = session?.data?.session?.access_token;

    if (!token) {
      alert('❌ Sessão expirada. Faça login novamente.');
      return;
    }

    const response = await fetch(
      'https://tvgpzamubhmhypsuyyps.supabase.co/functions/v1/enviar-emails',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          destinatarios: ['erika333ugc@gmail.com'],
          assunto: estadoProspeccao.assunto,
          html: estadoProspeccao.html || `<p>${estadoProspeccao.assunto}</p>`,
          skip_enviados: false,
        }),
      }
    );

    const resultado = await response.json();

    if (resultado.sucesso) {
      alert(`✅ Teste enviado!\n\nVerifique seu e-mail em alguns segundos.`);
      atualizarNumerosProspeccao();
    } else {
      alert(`❌ Erro: ${resultado.erro || 'Desconhecido'}`);
    }
  } catch (erro) {
    console.error(erro);
    alert(`❌ Erro ao enviar: ${erro.message}`);
  } finally {
    if (botaoTeste) {
      botaoTeste.disabled = false;
      botaoTeste.textContent = boesOriginal || 'Enviar teste';
    }
  }
}

// Disparar para todos os selecionados
async function disparar() {
  if (!estadoProspeccao.assunto.trim()) {
    alert('⚠️ Digite um assunto');
    return;
  }

  if (estadoProspeccao.destinatarios.length === 0) {
    alert('⚠️ Selecione pelo menos um destinatário');
    return;
  }

  if (!confirm(`📧 Enviar para ${estadoProspeccao.destinatarios.length} marca(s)?\n\nVerifique tudo antes de confirmar!`)) {
    return;
  }

  const botaoDisparar = document.querySelector('[onclick="disparar()"]');
  const textoOriginal = botaoDisparar?.textContent;
  if (botaoDisparar) botaoDisparar.disabled = true;

  try {
    if (botaoDisparar) botaoDisparar.textContent = 'Disparando...';

    const session = await Auth.sb.auth.getSession();
    const token = session?.data?.session?.access_token;

    if (!token) {
      alert('❌ Sessão expirada. Faça login novamente.');
      return;
    }

    const response = await fetch(
      'https://tvgpzamubhmhypsuyyps.supabase.co/functions/v1/enviar-emails',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          destinatarios: estadoProspeccao.destinatarios,
          assunto: estadoProspeccao.assunto,
          html: estadoProspeccao.html || `<p>${estadoProspeccao.assunto}</p>`,
          skip_enviados: estadoProspeccao.skipEnviados,
        }),
      }
    );

    const resultado = await response.json();

    if (resultado.sucesso) {
      const msg = `✅ Disparo concluído!\n\n📤 Enviados: ${resultado.resumo.enviados}\n❌ Falhas: ${resultado.resumo.falhas}\n⏭️ Pulados: ${resultado.resumo.pulados}`;
      alert(msg);
      atualizarNumerosProspeccao();
      estadoProspeccao.assunto = '';
      estadoProspeccao.html = '';
      document.getElementById('abaPerspeccao').innerHTML = ''; // Recarrega a tela
      montarTelaProspeccao();
    } else {
      alert(`❌ Erro: ${resultado.erro || 'Desconhecido'}`);
    }
  } catch (erro) {
    console.error(erro);
    alert(`❌ Erro ao enviar: ${erro.message}`);
  } finally {
    if (botaoDisparar) {
      botaoDisparar.disabled = false;
      botaoDisparar.textContent = textoOriginal || 'Disparar';
    }
  }
}

// Atualizar números
function atualizarNumerosProspeccao() {
  const marcasComEmail = cacheMarcas.filter(m => m.email).length || 0;
  const semEmail = cacheMarcas.filter(m => !m.email).length || 0;

  document.getElementById('totalDestinatarios').textContent = marcasComEmail;
  document.getElementById('semEmail').innerHTML = semEmail > 0 ? ` (<span style="color: var(--texto-suave);">${semEmail} sem e-mail)</span>` : '';
}

// Funções auxiliares
function abrirTelaCheia() {
  alert('Tela cheia será implementada');
}

function atualizarCheckboxesSelecionadas() {
  // TODO: Atualizar checkboxes na aba Marcas
}
