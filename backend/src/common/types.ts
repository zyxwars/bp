/**
 * Shared types and Zod schemas
 */
import z from "zod";

/**
 * Utility for returning errors
 */
export type Result<T = any> =
  | { success: true; data: T }
  | { success: false; error: string };

// Use DTOs to ensure consistency between simulation and demo
export const PlayerDto = z.object({
  id: z.number(),
  name: z.string(),
  gold: z.int(),
});
export type PlayerDto = z.infer<typeof PlayerDto>;

export const AgentStateDto = z.object({
  model: z.string(),
  strategy: z.string(),
  playerAnalysis: z.record(z.string(), z.string()),
  history: z.array(z.string()),
});
export type AgentStateDto = z.infer<typeof AgentStateDto>;

export const StateDto = z.object({
  sessionId: z.string(),
  userId: z.string(),
  players: z.array(PlayerDto),
  round: z.number(),
  thisPlayerId: z.int(),
  agentState: AgentStateDto,
});
export type StateDto = z.infer<typeof StateDto>;
