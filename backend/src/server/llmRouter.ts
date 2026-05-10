/**
 * Express router for LLM agent endpoints
 */
import express from "express";
import { attack, AttackRequest } from "../handlers/attack.ts";
import { attackSide, AttackSideRequest } from "../handlers/attackSide.ts";
import { defense, DefenseRequest } from "../handlers/defense.ts";
import { exploration, ExplorationRequest } from "../handlers/exploration.ts";
export const llmRouter = express.Router();

llmRouter.post("/attack", async (req, res) => {
  const reqDto = AttackRequest.parse(req.body);
  const result = await attack(reqDto);
  res.json(result);
});

llmRouter.post("/defense", async (req, res) => {
  const reqDto = DefenseRequest.parse(req.body);
  const result = await defense(reqDto);
  res.json(result);
});

llmRouter.post("/attackSide", async (req, res) => {
  const reqDto = AttackSideRequest.parse(req.body);
  const result = await attackSide(reqDto);
  res.json(result);
});

llmRouter.post("/exploration", async (req, res) => {
  const reqDto = ExplorationRequest.parse(req.body);
  const result = await exploration(reqDto);
  res.json(result);
});
