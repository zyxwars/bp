/**
 * Game log persistence
 */
import { appendFileSync, mkdirSync } from "node:fs";
import path from "node:path";
import z from "zod";
import { config } from "../config/config.ts";
import { AttackSide } from "../common/constants.ts";

/**
 * Formats for loggin player actions
 */
export const LogGameRequest = z.object({
  userId: z.string(),
  sessionId: z.string(),
  data: z.discriminatedUnion("type", [
    z.object({
      type: z.literal("decideExploration"),
      playerId: z.number(),
      privateThought: z.string(),
      explorationShipCount: z.number(),
      discussion: z.string(),
      strategy: z.string(),
      playerAnalysis: z.record(z.string(), z.string()),
    }),
    z.object({
      type: z.literal("decideAttack"),
      playerId: z.number(),
      privateThought: z.string(),
      defenderId: z.number(),
      invitedPlayerIds: z.array(z.number()),
      discussion: z.string(),
    }),
    z.object({
      type: z.literal("decideDefense"),
      playerId: z.number(),
      privateThought: z.string(),
      invitedPlayerIds: z.array(z.number()),
      discussion: z.string(),
    }),
    z.object({
      type: z.literal("decideAttackSide"),
      playerId: z.number(),
      privateThought: z.string(),
      side: z.enum([AttackSide.Attack, AttackSide.Defense, AttackSide.Neutral]),
      discussion: z.string(),
    }),
    z.object({
      type: z.literal("roundStarted"),
      round: z.number(),
      players: z.array(
        z.object({
          id: z.number(),
          name: z.string(),
          gold: z.number(),
          explorationShipCount: z.number(),
        })
      ),
    }),
    z.object({
      type: z.literal("attackResolved"),
      round: z.number(),
      attackerId: z.number(),
      defenderId: z.number(),
      attackWon: z.boolean(),
      players: z.array(
        z.object({
          playerId: z.number(),
          side: z.enum([
            AttackSide.Attack,
            AttackSide.Defense,
            AttackSide.Neutral,
          ]),
          invitedByAttacker: z.boolean(),
          invitedByDefender: z.boolean(),
          homeShips: z.number(),
          goldChange: z.number(),
        })
      ),
    }),
    z.object({
      type: z.literal("explorationResolved"),
      round: z.number(),
      players: z.array(
        z.object({
          playerId: z.number(),
          explorationShipCount: z.number(),
          goldChange: z.number(),
        })
      ),
    }),
    z.object({
      type: z.literal("roundEnded"),
      round: z.number(),
      players: z.array(
        z.object({
          id: z.number(),
          name: z.string(),
          gold: z.number(),
        })
      ),
    }),
    z.object({
      type: z.literal("gameEnded"),
      round: z.number(),
      winnerId: z.number(),
      players: z.array(
        z.object({
          id: z.number(),
          name: z.string(),
          gold: z.number(),
        })
      ),
    }),
  ]),
});

export type LogGameRequest = z.infer<typeof LogGameRequest>;

export function logGame(dto: LogGameRequest) {
  mkdirSync(config.logDir, { recursive: true });
  const filePath = path.join(
    config.logDir,
    `${dto.userId}-${dto.sessionId}.jsonl`
  );
  appendFileSync(filePath, JSON.stringify(dto.data) + "\n");
}
