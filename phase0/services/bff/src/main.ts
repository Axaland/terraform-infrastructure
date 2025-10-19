import Fastify from "fastify";
import cors from "@fastify/cors";
import rateLimit from "@fastify/rate-limit";
import { loadConfig } from "./config.service.js";
import { registerHealthController } from "./health.controller.js";

const bootstrap = async () => {
  const config = loadConfig();
  const app = Fastify({
    logger: {
      transport: config.NODE_ENV === "development" ? { target: "pino-pretty" } : undefined,
      level: "info",
    },
  });

  await app.register(cors, { origin: true });
  await app.register(rateLimit, {
    global: true,
    max: 100,
    timeWindow: "1 minute",
  });

  registerHealthController(app);

  try {
    await app.listen({ host: config.HOST, port: config.PORT });
    app.log.info(`BFF avviato su http://${config.HOST}:${config.PORT}`);
  } catch (err) {
    app.log.error({ err }, "Errore in fase di avvio");
    process.exit(1);
  }
};

bootstrap();
