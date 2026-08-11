# Backup — TikTok temporariamente oculto (2026-08-11)

## Por quê
A Erika pediu pra tirar temporariamente do site todo ícone/botão/link do TikTok, sem apagar
a configuração, pra poder reativar depois sem recriar nada.

## O que foi feito
Não apaguei nenhum dado. Adicionei uma flag em `CONFIG.perfil` (arquivo `index.html`) e usei ela
pra pular a renderização do link do TikTok nos 2 lugares onde ele aparecia no site:

```js
// CONFIG.perfil, perto de tiktokHandle/tiktokLink
tiktokAtivo: false,
```

Os 2 pontos que passaram a checar essa flag antes de renderizar o `<a>` do TikTok:
1. `renderizarHero()` — ícone do TikTok ao lado do Instagram, no topo da capa (bloco `.hero-redes`).
2. `renderizarRodape()` — ícone do TikTok no rodapé, ao lado de Instagram/WhatsApp/E-mail
   (bloco `#rodape-redes`).

Instagram, WhatsApp e e-mail não foram tocados.

## Dados originais (preservados intactos no próprio `index.html`, nunca foram removidos)
```js
tiktokHandle: "@erikabarreir",
tiktokLink: "https://www.tiktok.com/@erikabarreir",
```
Essas duas linhas continuam no `CONFIG.perfil` normalmente — só a flag `tiktokAtivo: false`
impede o ícone de aparecer.

## Como reativar no futuro
Basta dizer "reative o TikTok no site" ou, manualmente, em `index.html`:
- Trocar `tiktokAtivo: false` para `tiktokAtivo: true` (ou apagar essa linha) dentro de
  `CONFIG.perfil`.

Nenhuma outra mudança é necessária — os dois pontos de renderização (hero e rodapé) voltam a
mostrar o ícone automaticamente, puxando o mesmo `tiktokHandle`/`tiktokLink` de sempre.

## Status
Mudança só local ainda (não commitada nem enviada ao GitHub) — combina com o fluxo já
estabelecido do projeto de só publicar depois de aprovação explícita dela.
