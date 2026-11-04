# Supabase database work

Kenza Hub's approved database redesign is active. See the root `DATABASE_REDESIGN_PLAN.md` for requirements, known gaps, open decisions, and implementation order.

## Safety
- Production is a read-only reference during design and local implementation.
- Local Supabase is the required implementation and verification target.
- Do not deploy migrations to production without explicit approval for the specific deployment.
- Do not commit credentials, tokens, service-role keys, or connection strings.
- Do not create placeholder SQL migrations or fabricate migration timestamps.
- Do not modify `main`.
- Keep order creation and payment disabled until the approved agreement/OTP workflow is complete.

Create real migration files with the Supabase CLI after the local baseline and target design are established. Test the complete chain against a clean local database before independent review.
