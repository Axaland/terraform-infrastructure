import jwt from 'jsonwebtoken';
import { config } from '../config';

export type AuthTokens = {
  accessToken: string;
  refreshToken: string;
};

type TokenPayload = {
  sub: string;
  provider: string;
};

type AccessTokenPayload = TokenPayload & {
  nickname: string | null;
  country: string | null;
  lang: string | null;
};

export const tokenService = {
  signTokens(payload: AccessTokenPayload): AuthTokens {
    const accessToken = jwt.sign(payload, config.jwtAccessSecret, {
      expiresIn: config.tokenTtlSeconds
    });
    const refreshToken = jwt.sign({ sub: payload.sub }, config.jwtRefreshSecret, {
      expiresIn: config.refreshTokenTtlSeconds
    });
    return { accessToken, refreshToken };
  },

  verifyRefreshToken(token: string) {
    return jwt.verify(token, config.jwtRefreshSecret) as TokenPayload;
  }
};
