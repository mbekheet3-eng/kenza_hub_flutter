
-- Column-level least privilege: keep identifiers for policy evaluation, not client disclosure.
revoke select on public.orders from authenticated;
grant select (
 id,order_number,seller_profile_id,product_id,status,quantity,currency_id,total_amount,
 platform_fee,shipping_cost,agreement_snapshot,agreement_version,buyer_confirmed_at,
 seller_confirmed_at,agreement_confirmed_at,agreed_unit_price,agreed_shipping_method,
 agreed_shipping_cost,agreed_fees,agreed_delivery_terms,created_at,updated_at
) on public.orders to authenticated;

revoke select on public.auction_bids from anon,authenticated;
grant select(id,auction_id,amount,created_at) on public.auction_bids to anon,authenticated;

revoke select on public.offers from authenticated;
grant select(id,product_id,seller_profile_id,offered_price,status,expires_at,responded_at,created_at)
on public.offers to authenticated;

revoke select on public.reviews from anon,authenticated;
grant select(id,order_id,seller_profile_id,rating,comment,created_at) on public.reviews to anon,authenticated;

revoke select on public.product_images from anon,authenticated;
grant select(id,product_id,image_path,storage_bucket,display_order,ai_review_status,created_at)
on public.product_images to anon,authenticated;

revoke select on public.pro_seller_upgrade_requests from authenticated;
grant select(id,seller_profile_id,requested_business_type,status,applicant_note,reviewed_at,review_note,created_at)
on public.pro_seller_upgrade_requests to authenticated;

revoke select on public.disputes from authenticated;
grant select(id,order_id,status,reason,description,admin_decision,resolved_at,created_at,updated_at)
on public.disputes to authenticated;

revoke select on public.dispute_evidence from authenticated;
grant select(id,dispute_id,storage_path,caption,created_at) on public.dispute_evidence to authenticated;

revoke select on public.chats from authenticated;
grant select(id,product_id,seller_profile_id,created_at) on public.chats to authenticated;

revoke select on public.delivery_assignments from authenticated;
grant select(id,order_id,status,assigned_at,ended_at) on public.delivery_assignments to authenticated;

revoke select on public.order_status_history from authenticated;
grant select(id,order_id,previous_status,new_status,action,actor_role,reason,metadata,created_at)
on public.order_status_history to authenticated;

revoke select on public.dispute_status_consents from authenticated;
grant select(id,dispute_id,proposed_status,consented_at) on public.dispute_status_consents to authenticated;
