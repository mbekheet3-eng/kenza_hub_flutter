drop policy if exists "Kenza admins can update member gender" on public.profiles;
create policy "Kenza admins can update member gender"
  on public.profiles for update to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

create or replace function public.apply_gender_change_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status in ('approved','rejected') then
    if coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false) = false then
      raise exception 'Only administrators can review gender change requests'
        using errcode = '42501';
    end if;
    if new.reviewed_by is distinct from auth.uid() or new.reviewed_at is null then
      raise exception 'Reviewer identity and review timestamp are required';
    end if;
    if new.status = 'approved' then
      update public.profiles
      set gender = new.requested_gender
      where id = new.member_id and gender = new.current_gender;
      if not found then
        raise exception 'Member gender changed or profile is unavailable';
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists apply_gender_change_request_trigger on public.gender_change_requests;
create trigger apply_gender_change_request_trigger
before update of status on public.gender_change_requests
for each row execute function public.apply_gender_change_request();
