import { Pool } from 'pg';
import { randomUUID } from 'node:crypto';

type AppUser = {
  id: string;
  email: string | null;
  oidc_provider: string | null;
  oidc_sub: string | null;
  nickname: string | null;
  country: string | null;
  lang: string | null;
  status: 'active' | 'banned';
};

export interface UserRepositoryOptions {
  pool: Pool;
}

export class UserRepository {
  constructor(private readonly options: UserRepositoryOptions) {}

  async findByOidc(provider: string, sub: string): Promise<AppUser | null> {
    const result = await this.options.pool.query<AppUser>(
      'SELECT * FROM app_user WHERE oidc_provider = $1 AND oidc_sub = $2',
      [provider, sub]
    );
    return result.rows[0] ?? null;
  }

  async upsertFromOidc(params: {
    provider: string;
    sub: string;
    email?: string;
    nickname?: string;
    country?: string;
    lang?: string;
  }): Promise<AppUser> {
    const existing = await this.findByOidc(params.provider, params.sub);
    if (existing) {
      return existing;
    }
    const id = randomUUID();
    const query = `
      INSERT INTO app_user (
        id, email, oidc_provider, oidc_sub, nickname, country, lang
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;
    const result = await this.options.pool.query<AppUser>(query, [
      id,
      params.email ?? null,
      params.provider,
      params.sub,
      params.nickname ?? null,
      params.country ?? null,
      params.lang ?? null
    ]);
    return result.rows[0];
  }

  async findById(id: string): Promise<AppUser | null> {
    const result = await this.options.pool.query<AppUser>(
      'SELECT * FROM app_user WHERE id = $1',
      [id]
    );
    return result.rows[0] ?? null;
  }
}
