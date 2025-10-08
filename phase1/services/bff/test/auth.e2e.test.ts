import request from 'supertest';
import { newDb } from 'pg-mem';
import { Pool } from 'pg';
import jwt from 'jsonwebtoken';

import { createApp } from '../src/app';
import { config } from '../src/config';
import { UserRepository } from '../src/repositories/user-repository';
import { configureAuthService } from '../src/services/auth-service';

function buildIdToken(payload: Record<string, unknown>) {
  return jwt.sign(payload, config.idTokenSharedSecret);
}

describe('Auth endpoints', () => {
  const database = newDb();
  let pool: Pool;

  beforeAll(async () => {
    const adapter = database.adapters.createPg();
    pool = new adapter.Pool();
    await pool.query(`
      CREATE TABLE app_user (
        id uuid PRIMARY KEY,
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now(),
        email text UNIQUE,
        oidc_provider text,
        oidc_sub text,
        nickname text,
        country char(2),
        lang char(2),
        status text DEFAULT 'active'
      );
    `);
    configureAuthService({ pool, userRepository: new UserRepository({ pool }) });
  });

  afterAll(async () => {
    await pool.end();
  });

  it('logs in a new user and returns tokens', async () => {
    const app = createApp();
    const idToken = buildIdToken({
      sub: 'user-123',
      provider: 'google',
      email: 'user@example.com',
      nickname: 'PlayerOne'
    });
    const response = await request(app)
      .post('/v1/auth/login')
      .send({ provider: 'google', id_token: idToken, device_id: 'device-1' })
      .expect(200);

    expect(response.body.access_token).toBeDefined();
    expect(response.body.refresh_token).toBeDefined();
    expect(response.body.user.nickname).toBe('PlayerOne');
  });
});
