import { FastifyInstance } from "fastify";

export const registerHealthController = (app: FastifyInstance) => {
  app.get("/healthz", async () => ({ status: "OK" }));
};
