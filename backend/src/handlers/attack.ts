/**
 * Attack decision handler
 */
import z from "zod";
import { config } from "../config/config.ts";
import { LlmResponseError } from "../common/exceptions.ts";
import { generateText, makeTool } from "../common/llm.ts";
import { StateDto } from "../common/types.ts";
import { getPlayerIdByName } from "../common/utils.ts";
import {
  makePrompt,
  privateThought,
  publicDiscussion,
  USE_A_TOOL_ERROR,
  USE_ONLY_PROVIDED_TOOLS_ERROR,
} from "./prompts.ts";

const decideAttackTool = makeTool(
  "decideAttack",
  z.object({
    privateThought,
    defender: z.string().describe("Name of player you want to attack"),
    invitedPlayers: z
      .array(z.string())
      .describe("Names of players you want to invite to help you attack"),
    publicDiscussion,
  }),
  "Decide which player to attack"
);

function attackPrompt(dto: AttackRequest) {
  return makePrompt(
    dto.state,
    `ATTACK PHASE:
- You were chosen as the attacker.
- Make your move using a tool`
  );
}

export const AttackRequest = z.object({
  state: StateDto,
});
export type AttackRequest = z.infer<typeof AttackRequest>;

export type AttackResponse = {
  privateThought: string;
  defenderId: number;
  invitedPlayerIds: number[];
  discussion: string;
};

export async function attack(dto: AttackRequest): Promise<AttackResponse> {
  const messages = attackPrompt(dto);

  // Retry request if response is malformed
  for (let i = 0; i < config.maxLlmRetries; i++) {
    const res = await generateText({
      model: dto.state.agentState.model,
      sessionId: dto.state.sessionId,
      userId: dto.state.userId,
      messages,
      tools: [decideAttackTool.definition],
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
    if (toolCall.function.name == decideAttackTool.name) {
      const parsedTool = decideAttackTool.parse(toolCall.function.arguments);
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

      const defenderId = getPlayerIdByName(dto.state, toolParams.defender);
      if (defenderId === undefined) {
        messages.push({
          role: "tool",
          toolCallId: toolCall.id,
          content: `Player '${toolParams.defender} not found, choose a valid player`,
        });
        continue;
      } else if (defenderId === dto.state.thisPlayerId) {
        messages.push({
          role: "tool",
          toolCallId: toolCall.id,
          content: "Can't attack yourself, choose a different player",
        });
        continue;
      }

      const invalidInvitedPlayers = toolParams.invitedPlayers.filter(
        (invitedName) => getPlayerIdByName(dto.state, invitedName) === undefined
      );
      if (invalidInvitedPlayers.length > 0) {
        messages.push({
          role: "tool",
          toolCallId: toolCall.id,
          content: `The following invited players were not found: ${invalidInvitedPlayers.join(
            ", "
          )}. Choose valid players only.`,
        });
        continue;
      }

      const invitedPlayerIds = toolParams.invitedPlayers.map(
        (invitedName) => getPlayerIdByName(dto.state, invitedName)!
      );

      return {
        privateThought: toolParams.privateThought,
        discussion: toolParams.publicDiscussion,
        defenderId,
        invitedPlayerIds,
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
