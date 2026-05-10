/**
 * Express router for game log endpoints
 */
import express from "express";
import { logGame, LogGameRequest } from "../handlers/gameLog.ts";

export const logRouter = express.Router();

logRouter.post("/", (req, res) => {
  const reqDto = LogGameRequest.parse(req.body);
  logGame(reqDto);
  res.json({});
});
