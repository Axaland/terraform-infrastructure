import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import morgan from 'morgan';

import { config } from './config';
import { authRouter } from './routes/auth';
import { errorHandler } from './middleware/error-handler';

export const createApp = () => {
  const app = express();
  app.set('trust proxy', 'loopback, linklocal, uniquelocal');
  app.use(express.json());
  app.use(helmet());
  app.use(cors());
  app.use(morgan('combined'));
  app.use(
    rateLimit({
      windowMs: config.rateLimitWindowMs,
      max: config.rateLimitMaxRequests,
      standardHeaders: true,
      legacyHeaders: false
    })
  );
  app.use('/v1/auth', authRouter);
  app.use(errorHandler);
  return app;
};
