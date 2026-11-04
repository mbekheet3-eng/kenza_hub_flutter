# Kenza Hub — Supabase Database Redesign Plan

**Status:** Approved to resume redesign and implementation  
**Approved:** 2026-11-04  
**Target branch:** `feature/db-schema-alignment`  
**Production project:** read-only reference; this document does not authorize production changes.

## 1. Decision precedence

The 2026-10-31 decision to redesign the Supabase database (option 3) is active. It supersedes the 2026-11-02 wording in `DATABASE_INTEGRATION_AUDIT.md` that described production as structurally final and prohibited further migrations.

Retain sound existing tables, relationships, constraints, functions, triggers, and policies; rebuild or replace only what fails approved requirements. Production remains a read-only reference while the target design is prepared and tested locally.

Mandatory order:
1. Capture the production schema and behavior.
2. Complete target schema and security design.
3. Implement migrations in the local Supabase stack.
4. Apply the chain to a clean local database and run repeatable tests.
5. Obtain independent review of schema, RLS, grants, functions, triggers, Storage, and workflows.
6. Obtain explicit approval for a specifically identified production deployment.
7. Deploy only the reviewed migrations after that approval.
8. Align Flutter after database contracts are stable.

## 2. Safety boundaries

- No production DDL, DML, migrations, seed changes, or Auth/Storage configuration changes during design/local implementation.
- Work only on `feature/db-schema-alignment`; never change `main`.
- No paid Supabase development branch, plan upgrade, or paid resource.
- No dropping/overwriting production objects merely to make a migration pass.
- Migrations must be ordered, documented, and tested against a clean local database; make them reversible where practical.
- Never invent columns, enum values, RPC contracts, or business rules to fill unresolved decisions.
- Keep order creation, checkout, and payment disabled until the buyer/seller agreement and the approved first-purchase phone OTP workflow are implemented and tested.
- Never commit credentials, access tokens, service-role keys, or connection strings.

## 3. Approved target requirements

### Seller profiles, Pro Seller, agencies, and online stores
- Unified registration; no separate seller registration.
- One seller profile/store per account. No second profile without an approved administrative procedure.
- Default profile creation through the existing `seller-profile-create` server function.
- Pro Seller is an upgrade of the existing seller profile, not a separate account.
- Agency and Online Store are business-directory classifications associated with the seller profile, not separate auth/account types.
- The owner controls employee membership and permissions. Employees cannot grant/edit/revoke their own permissions or manage ownership.
- Employee permissions must be enforced server-side, not only by Flutter.
- Employees must not read buyer identity or delivery details.

### Privacy and delivery data
Implement the approved 2026-11-02 document **“Kenza Hub — وثيقة حماية البيانات الشخصية وبيانات التوصيل” v1.0** across database policies, RPCs/Edge Functions, Realtime, Storage, notifications, logs, exports, and backup/restore.

Core requirements:
- Auth is the source of truth for login email/phone; avoid unnecessary duplication in public tables.
- Address book entries are optional and user-controlled.
- Order delivery details are isolated from general order data and exposed only for a valid, limited delivery assignment.
- A courier receives access only to the specific assigned delivery task; access ends when the assignment/task ends.
- Store employees do not receive buyer phone/address merely because they belong to the seller profile.
- Admin access to sensitive data is exceptional, reason-bound, scoped, and audited.
- Audit records are append-only.
- Chat contact-detail handling is server-side, not Flutter-only.
- Dispute evidence belongs in a private Storage bucket separate from public product images.
- Apply the approved 60-day delivery-data retention rule, counted from delivery/closure, with an open-dispute legal hold. It does not mean deleting Auth identity, optional address-book entries, or commercial order records. Dispute evidence has a separate retention policy and must not be deleted by the delivery-data purge.

### Authentication and phone verification
- Email/password, Google, and Apple sign-in remain unchanged; no OTP at login or first login on a new device.
- Persistent sessions must survive app closure and device restart, with secure refresh-token handling.
- Verify a phone by SMS OTP only at the first product-publication attempt or first purchase attempt when the phone is not already verified.
- Once verified, do not repeat OTP for every listing or purchase. A phone-number change requires verification of the new number.
- Phone verification must be enforced server-side. It does not replace login protections against compromised passwords.
- Keep order creation disabled until the buyer/seller agreement and first-purchase phone-verification flow are implemented and tested.

### AI image review
- Every uploaded product image must pass image quality, relevance, and prohibited/explicit-content review before product publication.
- The database already has an AI review status/result gate; the external provider integration is not yet configured.
- Do not invent a provider or commit credentials. Keep provider selection/configuration as a deployment prerequisite.

### Disputes
- Participants may perform only permitted participant transitions.
- Participants cannot resolve/close disputes or set admin-only fields.
- Admin decisions/overrides must be explicitly authorized and audited.
- Consent records and evidence access must be connected to enforced server-side transitions.
- Do not expose dispute UI workflows until end-to-end permissions and transition tests pass.

### Catalogue and service coverage
- Four root categories: Kids Supplies, Home Supplies, Clothes, Shoes.
- Clothes and Shoes support Men, Women, Kids child categories.
- Kids Supplies excludes clothing.
- Flutter reads hierarchy dynamically through `categories.parent_id`.
- Nationwide registration/browsing remains allowed; publication and delivery eligibility follow approved service-area rules.
- Internal launch coverage: Maadi, Dokki, Agouza, Mohandessin, Downtown, Manial, and adjacent areas. Existing region rows/flags do not match and require a reviewed data migration.

## 4. Known production gaps for target design

These are confirmed design issues, not permission to change production:
1. Product write policies check active seller membership but do not enforce each employee's granted permission.
2. Seller-profile updates are not sufficiently owner/field restricted.
3. Seller-profile membership management lacks the complete owner-only permission-edit/revoke workflow.
4. Seller members can read full order rows, including buyer/order delivery identifiers.
5. Authenticated users may read seller profile phone; public business-vs-private personal classification is unresolved.
6. Product audience visibility is not proven to be enforced for unrelated users.
7. Pro Seller approval and Agency/Online Store classification persistence lack a confirmed atomic server workflow.
8. Dispute updates allow broader participant row updates than the approved state machine.
9. Delivery details need separation, scoped courier assignment access, retention, dispute hold, and audit.
10. Chat contact handling must be server-enforced.
11. Dispute evidence needs private Storage access and a confirmed retention policy.
12. Product image Storage insertion does not currently enforce the uploader UID folder in the object path.
13. Active service regions do not match approved internal delivery coverage.
14. Existing users lack default region; signup/profile setup needs region selection compatible with nationwide browsing and service validation.
15. Backup/restore and scheduled deletion must account for 60-day retention; do not assume pg_cron exists.

Retain existing controls only after tests confirm them, including seller-profile creation transaction, order transition protections, immutable agreement snapshots, dispute-evidence append-only protection, and authenticated daily-deduplicated product-view RPC.

## 5. Explicitly unresolved decisions

Do not silently decide:
- Is `seller_profiles.phone` a public business contact or private personal number?
- Should chat contact details be rejected or redacted server-side before storage?
- What legal retention period applies to original dispute evidence in private Storage?
- Which supported scheduler/operations mechanism runs the 60-day purge, and how do backup/restore procedures prevent expired delivery details from being reintroduced?
- What happens if a dispute is opened after the 60-day delivery-data window?
- How must backup retention/restore prevent expired delivery details being reintroduced?
- Which supported scheduler/operations mechanism runs retention cleanup without assuming pg_cron?
- What if a dispute is opened after the 60-day delivery-data deletion window?
- ADR-02 for the layered database architecture has not been approved.

Proceed with independent work that does not depend on these answers. Isolate unresolved behavior behind explicit interfaces or mark it blocked.

## 6. Migration and test requirements

- Create timestamped migration files using the Supabase CLI migration workflow; never invent timestamps.
- Prefer additive or safely staged migrations. Destructive cleanup requires separate documentation and explicit review.
- Keep deterministic local seed/reference data separate from production data.
- Add SQL tests for RLS/grants as anon, authenticated owner, seller employee with/without each permission, buyer, assigned courier, unassigned courier, and admin.
- Test allowed and denied operations; successful schema apply alone is insufficient.
- Test Storage policies/object ownership, Realtime visibility, RPC grants, function search_path, and SECURITY DEFINER behavior.
- Run local security/performance advisors and document accepted findings.
- Verify the complete migration chain against a fresh local database before proposing production deployment.

## 7. Implementation sequence

1. Establish a reproducible local baseline from inspected production schema without writing to production.
2. Inventory exact columns, constraints, indexes, enums, policies, grants, triggers, functions, Storage policies, and Edge Function contracts.
3. Produce target ERD and role/policy matrix.
4. Implement seller membership/permission enforcement and private order/delivery access.
5. Implement dispute state machine, evidence access, and audit controls.
6. Implement chat contact handling and Storage ownership controls.
7. Implement service-region and signup-region reconciliation.
8. Implement retention/backup only after unresolved retention decisions are settled.
9. Run local tests and independent review.
10. Align Flutter after target contracts stabilize.

**Checkpoint (2026-11-04):** approval to resume redesign on this branch is recorded. No production schema or data has been changed.
