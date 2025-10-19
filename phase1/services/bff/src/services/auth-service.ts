import createHttpError from 'http-errors';
import jwt from 'jsonwebtoken';
import { Pool } from 'pg';

import { config } from '../config';
import { UserRepository } from '../repositories/user-repository';
import { tokenService } from './token-service';

let pool = new Pool({ connectionString: config.databaseUrl });
let userRepository = new UserRepository({ pool });

export function configureAuthService(overrides: { pool?: Pool; userRepository?: UserRepository } = {}) {
  if (overrides.pool) {
    pool = overrides.pool;
  }
  if (overrides.userRepository) {
    userRepository = overrides.userRepository;
  }
}

type OidcPayload = {
  sub: string;
  email?: string;
  nickname?: string;
  country?: string;
  lang?: string;
};

type LoginParams = {
  provider: string;
  idToken: string;
  deviceId: string;
};

export const authService = {
  async login(params: LoginParams) {
    const { provider, idToken } = params;
    const decoded = verifyIdToken(provider, idToken);
    const user = await userRepository.upsertFromOidc({
      provider,
      sub: decoded.sub,
      email: decoded.email,
      nickname: decoded.nickname,
      country: decoded.country,
      lang: decoded.lang
    });

    const tokens = tokenService.signTokens({
      sub: user.id,
      provider,
      nickname: user.nickname,
      country: user.country,
      lang: user.lang
    });

    return {
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
      expires_in: tokens.expiresIn,
      token_type: 'Bearer',
      user: {
        id: user.id,
        nickname: user.nickname,
        country: user.country,
        lang: user.lang,
        status: user.status
      }
    };
  },

  async refresh(refreshToken: string) {
    try {
      const payload = tokenService.verifyRefreshToken(refreshToken);
      const user = await userRepository.findById(payload.sub);
      if (!user) {
        throw createHttpError(401, 'Session expired');
      }
      const tokens = tokenService.signTokens({
        sub: user.id,
        provider: user.oidc_provider ?? 'unknown',
        nickname: user.nickname,
        country: user.country,
        lang: user.lang
      });
      return {
        access_token: tokens.accessToken,
        refresh_token: tokens.refreshToken,
        expires_in: tokens.expiresIn,
        token_type: 'Bearer'
      };
    } catch (error) {
      throw createHttpError(401, 'Invalid refresh token');
    }
  },

  async getProfile(userId: string) {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw createHttpError(404, 'User not found');
    }
    return {
      id: user.id,
      nickname: user.nickname,
      country: user.country,
      lang: user.lang,
      status: user.status
    };
  }
};

function verifyIdToken(provider: string, idToken: string): OidcPayload {
  try {
    const decoded = jwt.verify(idToken, config.idTokenSharedSecret) as OidcPayload & {
      provider: string;
    };
    if (decoded.provider !== provider) {
      throw new Error('Provider mismatch');
    }
    return decoded;
  } catch (error) {
    throw createHttpError(401, 'Invalid id_token');
  }
}
