do $migration$
declare v record; v_definition text; v_updated text;
begin
  for v in
    select * from (values
      ('private.admin_review_pro_seller_request(uuid,text,text)', 'if p_decision not in (''approved'',''rejected'') then', 'if p_decision is null or p_decision not in (''approved'',''rejected'') then'),
      ('private.admin_review_report(uuid,text,text)', 'if p_decision not in (''under_review'',''resolved'',''rejected'') then', 'if p_decision is null or p_decision not in (''under_review'',''resolved'',''rejected'') then'),
      ('private.moderate_product(uuid,text,text)', 'if p_decision not in (''approved'',''rejected'',''hidden'') then', 'if p_decision is null or p_decision not in (''approved'',''rejected'',''hidden'') then'),
      ('private.respond_exchange_offer(uuid,text)', 'if p_decision not in (''accepted'',''rejected'') then', 'if p_decision is null or p_decision not in (''accepted'',''rejected'') then'),
      ('private.respond_offer(uuid,text)', 'if p_decision not in (''accepted'',''rejected'') then', 'if p_decision is null or p_decision not in (''accepted'',''rejected'') then'),
      ('private.submit_dispute_consent(uuid,text)', 'if p_proposed_status not in (''awaiting_response'',''resolved'') then', 'if p_proposed_status is null or p_proposed_status not in (''awaiting_response'',''resolved'') then'),
      ('private.edit_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text)', 'if p_price<=0 or (p_weight_kg is not null and (p_weight_kg<0 or p_weight_kg>10)) then', 'if p_price is null or p_price<=0 or (p_weight_kg is not null and (p_weight_kg<0 or p_weight_kg>10)) then'),
      ('private.edit_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text)', 'if p_audience not in (''public'',''followers'',''private'') then', 'if p_audience is null or p_audience not in (''public'',''followers'',''private'') then'),
      ('private.set_dispute_evidence_legal_hold(uuid,boolean,text)', 'if p_hold and (p_reason is null or char_length(trim(p_reason)) < 8) then', 'if p_hold is null then raise exception ''INVALID_LEGAL_HOLD_ACTION''; end if;
  if p_hold and (p_reason is null or char_length(trim(p_reason)) < 8) then')
    ) as x(signature, old_text, new_text)
  loop
    select pg_get_functiondef(v.signature::regprocedure) into v_definition;
    if position(v.old_text in v_definition)=0 then raise exception 'EXPECTED_GUARD_NOT_FOUND: %', v.signature; end if;
    v_updated := replace(v_definition, v.old_text, v.new_text);
    execute v_updated;
  end loop;
end;
$migration$;