-- ساخت کاربر ادمین (یک بار اجرا شود؛ اول supabase-setup.sql باید اجرا شده باشد)
do $$
declare uid uuid;
begin
  select id into uid from auth.users where email = 'sa0ar0a0@gmail.com';
  if uid is null then
    uid := gen_random_uuid();
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change)
    values ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', 'sa0ar0a0@gmail.com',
      extensions.crypt('amlak_sr5', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');
    insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), uid,
      jsonb_build_object('sub', uid::text, 'email', 'sa0ar0a0@gmail.com', 'email_verified', true),
      'email', uid::text, now(), now(), now());
  end if;
  insert into public.admins (user_id) values (uid) on conflict do nothing;
end $$;
