import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
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
        oidc_provider text NOT NULL,
        oidc_sub text NOT NULL,
        nickname text,
        country char(2),
        lang char(2),
        status text DEFAULT 'active'
      );
      CREATE UNIQUE INDEX app_user_oidc_provider_sub_idx
        ON app_user (oidc_provider, oidc_sub);
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
    expect(response.body.token_type).toBe('Bearer');
    expect(response.body.expires_in).toBe(config.tokenTtlSeconds);
    expect(response.body.user.nickname).toBe('PlayerOne');
  });

  it('refreshes tokens and retrieves profile', async () => {
    const app = createApp();
    const idToken = buildIdToken({
      sub: 'user-abc',
      provider: 'google',
      nickname: 'PlayerTwo',
      country: 'IT',
      lang: 'it'
    });

    const login = await request(app)
      .post('/v1/auth/login')
      .send({ provider: 'google', id_token: idToken, device_id: 'device-42' })
      .expect(200);

    const refresh = await request(app)
      .post('/v1/auth/refresh')
      .send({ refresh_token: login.body.refresh_token })
      .expect(200);

    expect(refresh.body.access_token).toBeDefined();
    expect(refresh.body.refresh_token).toBeDefined();
    expect(refresh.body.token_type).toBe('Bearer');
    expect(refresh.body.expires_in).toBe(config.tokenTtlSeconds);

    const profile = await request(app)
      .get('/v1/auth/me')
      .set('authorization', `Bearer ${login.body.access_token}`)
      .expect(200);

    expect(profile.body.id).toEqual(login.body.user.id);
    expect(profile.body.nickname).toBe('PlayerTwo');
    expect(profile.body.country).toBe('IT');
  });

  it('rejects mismatched provider tokens', async () => {
    const app = createApp();
    const idToken = buildIdToken({
      sub: 'user-xyz',
      provider: 'apple'
    });

    const response = await request(app)
      .post('/v1/auth/login')
      .send({ provider: 'google', id_token: idToken, device_id: 'device-1' })
      .expect(401);

    expect(response.body.error).toMatch(/Invalid id_token/i);
  });
});
