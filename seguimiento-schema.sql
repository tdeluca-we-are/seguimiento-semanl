-- =====================================================================
-- Seguimiento semanal — esquema
-- Correr una sola vez en el SQL editor de Supabase (proyecto ojzcxwhoinmljospgmfp)
-- =====================================================================
--
-- A diferencia de slots y del semáforo, esta app es personal: un solo dueño
-- por fila, sin roles ni tabla de usuarios. Por eso el estado entero viaja
-- como un documento JSON en vez de decenas de tablas relacionales: la app ya
-- trabaja con un único objeto en memoria, los datos son chicos (KB) y hay un
-- solo escritor. Si algún día Gastón tiene que escribir, ahí sí conviene
-- normalizar.

create table if not exists public.seg_estado (
  user_id     uuid        primary key references auth.users(id) on delete cascade,
  datos       jsonb       not null default '{}'::jsonb,
  version     integer     not null default 1,
  actualizado timestamptz not null default now()
);

comment on table  public.seg_estado is 'Estado completo del seguimiento semanal, un documento por usuario';
comment on column public.seg_estado.version is
  'Se incrementa en cada guardado. La app actualiza con WHERE version = <la que leyó>: si no afecta ninguna fila es porque otra pestaña o dispositivo guardó primero, y en vez de pisar avisa.';

alter table public.seg_estado enable row level security;

-- Cada uno ve y escribe únicamente su propia fila. Sin política de DELETE a
-- propósito: desde la app no se puede borrar el documento, solo vaciarlo.
drop policy if exists seg_estado_select on public.seg_estado;
create policy seg_estado_select on public.seg_estado
  for select using (auth.uid() = user_id);

drop policy if exists seg_estado_insert on public.seg_estado;
create policy seg_estado_insert on public.seg_estado
  for insert with check (auth.uid() = user_id);

drop policy if exists seg_estado_update on public.seg_estado;
create policy seg_estado_update on public.seg_estado
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =====================================================================
-- Verificación: después de correr esto, logueado como vos, esta consulta
-- tiene que devolver 0 filas sin error (todavía no cargaste nada).
--   select user_id, version, actualizado from public.seg_estado;
-- Si devuelve "permission denied", la RLS quedó mal.
-- Si devuelve 0 filas y ningún error, está listo: la app crea la fila sola
-- en el primer login.
-- =====================================================================
