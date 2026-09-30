-- =====================================================================
-- Seguimiento semanal — accesos compartidos
-- Correr una vez en el SQL editor de Supabase (proyecto ojzcxwhoinmljospgmfp),
-- DESPUÉS de seguimiento-schema.sql.
-- =====================================================================
--
-- Hasta acá cada usuario veía únicamente su propia fila de seg_estado. Esto
-- agrega una lista de invitados por documento: el dueño carga un mail y un rol,
-- y esa persona, al entrar con su cuenta, ve el tablero del dueño.
--
-- El vínculo es por MAIL, no por user_id: así no hace falta un paso de
-- "vinculación" en el primer login como en slots y el semáforo. El mail sale
-- del JWT de Supabase, que no se puede falsear desde el navegador.
--
-- OJO: el acceso es al documento COMPLETO. Adentro conviven Email Marketing y
-- Paid Media, así que quien entra ve los dos espacios. Esconder uno por
-- pantalla sería cosmético, no seguridad: el JSON viaja entero. Si en algún
-- momento Paid tiene que ser privado para el líder de Email (o al revés), hay
-- que partirlo en dos filas, no en dos pestañas.

create table if not exists public.seg_accesos (
  dueno  uuid        not null references auth.users(id) on delete cascade,
  email  text        not null,
  rol    text        not null default 'editor' check (rol in ('editor','lector')),
  creado timestamptz not null default now(),
  primary key (dueno, email)
);

comment on table public.seg_accesos is
  'Quién puede ver o editar el seguimiento de cada dueño. Se resuelve por mail contra el JWT.';

alter table public.seg_accesos enable row level security;

-- El dueño administra su propia lista de invitados.
drop policy if exists seg_accesos_dueno on public.seg_accesos;
create policy seg_accesos_dueno on public.seg_accesos
  for all using (auth.uid() = dueno) with check (auth.uid() = dueno);

-- Cada uno puede ver los accesos que LE dieron, para saber a qué tablero entrar.
drop policy if exists seg_accesos_propio on public.seg_accesos;
create policy seg_accesos_propio on public.seg_accesos
  for select using (lower(email) = lower(auth.jwt() ->> 'email'));

-- ¿El que consulta tiene acceso al documento de <dueno_id>?
-- 'lector' pregunta por cualquier acceso; 'editor' exige permiso de escritura.
-- No hace falta SECURITY DEFINER: la política de arriba ya deja que cada uno
-- lea sus propias filas de seg_accesos, que es lo único que mira esta función.
create or replace function public.seg_puede(dueno_id uuid, minimo text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
      from public.seg_accesos a
     where a.dueno = dueno_id
       and lower(a.email) = lower(auth.jwt() ->> 'email')
       and (minimo = 'lector' or a.rol = 'editor')
  );
$$;

-- Leer: la propia, o una compartida conmigo (cualquier rol).
drop policy if exists seg_estado_select on public.seg_estado;
create policy seg_estado_select on public.seg_estado
  for select using (auth.uid() = user_id or public.seg_puede(user_id, 'lector'));

-- Escribir: la propia, o una compartida conmigo como editor.
drop policy if exists seg_estado_update on public.seg_estado;
create policy seg_estado_update on public.seg_estado
  for update using      (auth.uid() = user_id or public.seg_puede(user_id, 'editor'))
  with check            (auth.uid() = user_id or public.seg_puede(user_id, 'editor'));

-- El insert sigue siendo solo para uno mismo: nadie crea el documento de otro.
drop policy if exists seg_estado_insert on public.seg_estado;
create policy seg_estado_insert on public.seg_estado
  for insert with check (auth.uid() = user_id);

-- =====================================================================
-- Verificación, logueado como vos:
--   select * from public.seg_accesos;              -- 0 filas, sin error
--   select public.seg_puede(auth.uid(), 'editor'); -- false (no te invitaste a vos mismo)
-- Si alguna tira "permission denied", la RLS quedó mal.
-- =====================================================================
