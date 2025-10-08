import { Router } from 'express';
import createHttpError from 'http-errors';

import { validateBody } from '../validators/validate-body';
import { loginSchema, refreshSchema } from '../validators/auth-schemas';
import { authService } from '../services/auth-service';
import { authMiddleware } from '../services/auth-middleware';

export const authRouter = Router();

authRouter.post('/login', validateBody(loginSchema), async (req, res, next) => {
  try {
    const { provider, id_token: idToken, device_id: deviceId } = req.body;
    const session = await authService.login({ provider, idToken, deviceId });
    res.json(session);
  } catch (error) {
    next(error);
  }
});

authRouter.post('/refresh', validateBody(refreshSchema), async (req, res, next) => {
  try {
    const result = await authService.refresh(req.body.refresh_token);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

authRouter.get('/me', authMiddleware, async (req, res, next) => {
  try {
    if (!req.user) {
      throw createHttpError(401, 'Missing session');
    }
    const profile = await authService.getProfile(req.user.userId);
    res.json(profile);
  } catch (error) {
    next(error);
  }
});
