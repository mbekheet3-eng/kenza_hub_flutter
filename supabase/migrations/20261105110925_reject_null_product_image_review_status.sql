do $migration$
declare v_definition text; v_updated text;
begin
  select pg_get_functiondef('private.record_product_image_ai_review(uuid,text,jsonb,text)'::regprocedure)
    into v_definition;
  if position('if p_status not in (''approved'',''rejected'',''error'') then' in v_definition)=0 then
    raise exception 'EXPECTED_GUARD_NOT_FOUND: record_product_image_ai_review';
  end if;
  v_updated := replace(
    v_definition,
    'if p_status not in (''approved'',''rejected'',''error'') then',
    'if p_status is null or p_status not in (''approved'',''rejected'',''error'') then'
  );
  execute v_updated;
end;
$migration$;