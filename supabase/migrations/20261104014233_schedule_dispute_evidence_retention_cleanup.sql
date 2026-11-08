
select cron.schedule(
  'dispute-evidence-retention-daily',
  '20 3 * * *',
  $job$
    select net.http_post(
      url := (select decrypted_secret from vault.decrypted_secrets where name = 'kenza_project_url')
             || '/functions/v1/purge-expired-dispute-evidence',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', (select decrypted_secret from vault.decrypted_secrets where name = 'kenza_publishable_key'),
        'x-retention-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'dispute_evidence_retention_cron_secret')
      ),
      body := '{}'::jsonb
    );
  $job$
);
