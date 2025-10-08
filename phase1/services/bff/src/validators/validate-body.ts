import type { RequestHandler } from 'express';
import type { ZodSchema } from 'zod';
import createHttpError from 'http-errors';

export const validateBody = <T>(schema: ZodSchema<T>): RequestHandler =>
  (req, _res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      const message = result.error.issues.map((issue) => issue.message).join(', ');
      next(createHttpError(400, message));
      return;
    }
    req.body = result.data;
    next();
  };
