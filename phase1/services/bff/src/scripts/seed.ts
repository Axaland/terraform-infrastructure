import { Pool } from 'pg';
import { randomUUID } from 'node:crypto';

import { config } from '../config.js';

async function main() {
  const pool = new Pool({ connectionString: config.databaseUrl });
  const seedId = randomUUID();
  await pool.query(
    `INSERT INTO app_user (id, email, oidc_provider, oidc_sub, nickname, country, lang)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (oidc_sub) DO NOTHING`,
    [seedId, 'seed@example.com', 'email', 'seed-user', 'Seed User', 'IT', 'it']
  );
  // eslint-disable-next-line no-console
  console.log('Seed user inserted');
  await pool.end();
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exitCode = 1;
});
