import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  HOST: z.string().default("0.0.0.0"),
  PORT: z.coerce.number().min(1).max(65535).default(3000),
});

export type AppConfig = z.infer<typeof schema>;

export const loadConfig = (): AppConfig => {
  const parsed = schema.safeParse(process.env);
  if (!parsed.success) {
    throw new Error(`Configurazione non valida: ${parsed.error.message}`);
  }
  return parsed.data;
};
