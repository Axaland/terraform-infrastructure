import type { RequestHandler } from 'express';
import createHttpError from 'http-errors';
import jwt from 'jsonwebtoken';

import { config } from '../config';

type AccessTokenPayload = {
  sub: string;
  provider: string;
  nickname: string | null;
};

declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        provider: string;
        nickname: string | null;
      };
    }
  }
}

export const authMiddleware: RequestHandler = (req, _res, next) => {
  const header = req.header('authorization');
  if (!header) {
    next(createHttpError(401, 'Missing Authorization header'));
    return;
  }
  const [scheme, token] = header.split(' ');
  if (scheme.toLowerCase() !== 'bearer' || !token) {
    next(createHttpError(401, 'Invalid Authorization header'));
    return;
  }
  try {
    const payload = jwt.verify(token, config.jwtAccessSecret) as AccessTokenPayload;
    req.user = {
      userId: payload.sub,
      provider: payload.provider,
      nickname: payload.nickname
    };
    next();
  } catch (error) {
    next(createHttpError(401, 'Invalid token'));
  }
};

export {};
