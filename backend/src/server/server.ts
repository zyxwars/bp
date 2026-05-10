/**
 * Express server entry point
 */
import cors from "cors";
import express, {
  type NextFunction,
  type Request,
  type Response,
} from "express";
import helmet from "helmet";
import { config } from "../config/config.ts";
import { Logger } from "../common/logger.ts";
import { logRouter } from "../server/logRouter.ts";
import { llmRouter } from "./llmRouter.ts";

const log = new Logger("server");

export const app = express();

// Register middlewares
app.use(helmet());

if (config.corsOrigin !== undefined) {
  app.use(cors({ origin: config.corsOrigin }));
}

// NOTE: if you are running behind a reverse-proxy check body limit on the proxy as well
app.use(express.json({ limit: config.bodyLimit }));

app.use((req, _res, next) => {
  log.info(`${req.method} ${req.path}`);
  next();
});

// Routes
app.use("/llm", llmRouter);
app.use("/log", logRouter);

// Error handling
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  log.error(err);
  res.status(500).json({
    status: "error",
    message: "Server error occurred",
  });
});

// Run
app.listen(config.port, () => {
  log.info(`Server listening on port ${config.port}`);
});
