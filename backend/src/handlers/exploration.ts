/**
 * Exploration decision handler
 */
import z from "zod";
import { config } from "../config/config.ts";
import { LlmResponseError } from "../common/exceptions.ts";
import { generateText, makeTool } from "../common/llm.ts";
import { StateDto } from "../common/types.ts";
import {
  makePrompt,
  privateThought,
  publicDiscussion,
  USE_A_TOOL_ERROR,
  USE_ONLY_PROVIDED_TOOLS_ERROR,
} from "./prompts.ts";
import { gameConfig } from "../config/gameConfig.ts";

const decideExplorationTool = makeTool(
  "decideExploration",
  z.object({
    privateThought,
    strategy: z
      .string()
      .describe(`Your overall strategy for this round and future rounds.`),
    playerAnalysis: z
      .array(
        z.object({
          playerName: z
            .string()
            .describe("The name of the player you are analyzing"),
          sentimentAndTrust: z
            .string()
            .describe(
              "Notes about your sentiment towards this player, their trustworthiness, or alliance potential"
            ),
        })
      )
      .describe("Your analysis of each other player in the game"),
    explorationShipCount: z
      .int()
      .min(0)
      .max(gameConfig.shipCount)
      .describe("How many ships to send away exploring this round"),
    publicDiscussion,
  }),
  "Analyze the game and decide how many ships to send exploring this round"
);

function explorationPrompt(dto: ExplorationRequest) {
  return makePrompt(
    dto.state,
    `EXPLORATION PHASE:
- Make your move using a tool`
  );
}

export const ExplorationRequest = z.object({
  state: StateDto,
});
export type ExplorationRequest = z.infer<typeof ExplorationRequest>;

export type ExplorationResponse = {
  strategy: string;
  playerAnalysis: Record<string, string>;
  privateThought: string;
  explorationShipCount: number;
  discussion: string;
};

export async function exploration(
  dto: ExplorationRequest
): Promise<ExplorationResponse> {
  const messages = explorationPrompt(dto);

  // Retry request if response is malformed
  for (let i = 0; i < config.maxLlmRetries; i++) {
    const res = await generateText({
      model: dto.state.agentState.model,
      sessionId: dto.state.sessionId,
      userId: dto.state.userId,
      messages,
      tools: [decideExplorationTool.definition],
    });

    messages.push(res);

    // Require tool call
    const toolCall = res.toolCalls?.[0];
    if (!toolCall) {
      messages.push({
        role: "user",
        content: USE_A_TOOL_ERROR,
      });
      continue;
    }

    // Parse tool call
    if (toolCall.function.name === decideExplorationTool.name) {
      const parsedTool = decideExplorationTool.parse(
        toolCall.function.arguments
      );
      if (!parsedTool.success) {
        messages.push({
          role: "tool",
          toolCallId: toolCall.id,
          content: parsedTool.error,
        });
        continue;
      }

      // Validate tool call params
      const toolParams = parsedTool.data;

      // Transform player sentiments to a cleaner format
      // The llm is using a format more easiliy validated with json schema
      const playerAnalysis: Record<string, string> = {};
      for (const player of toolParams.playerAnalysis) {
        playerAnalysis[player.playerName] = player.sentimentAndTrust;
      }

      return {
        strategy: toolParams.strategy,
        playerAnalysis,
        privateThought: toolParams.privateThought,
        discussion: toolParams.publicDiscussion,
        explorationShipCount: toolParams.explorationShipCount,
      };
    } else {
      messages.push({
        role: "tool",
        toolCallId: toolCall.id,
        content: USE_ONLY_PROVIDED_TOOLS_ERROR,
      });
    }
  }

  throw new LlmResponseError(dto.state.agentState.model, messages);
}
