-- ============================================================
-- setup-capas-portfolio.sql — rode no SQL Editor do Supabase.
-- Cria o bucket público onde ficam as capas enviadas pelo painel.
-- Pode rodar mais de uma vez.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('capas-portfolio', 'capas-portfolio', true)
on conflict (id) do update set public = true;

drop policy if exists "capas: logado envia" on storage.objects;
create policy "capas: logado envia"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'capas-portfolio');

drop policy if exists "capas: logado atualiza" on storage.objects;
create policy "capas: logado atualiza"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'capas-portfolio');

drop policy if exists "capas: logado apaga" on storage.objects;
create policy "capas: logado apaga"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'capas-portfolio');
