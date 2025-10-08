import { z } from 'zod';

export const loginSchema = z.object({
  provider: z.enum(['apple', 'google', 'email']),
  id_token: z.string().min(1),
  device_id: z.string().min(1)
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(1)
});
