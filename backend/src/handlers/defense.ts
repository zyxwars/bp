/**
 * Defense decision handler
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

const decideDefenseTool = makeTool(
  "decideDefense",
  z.object({
    privateThought,
    invitedPlayers: z
      .array(z.string())
      .describe("Names of players you want to invite to help you defend"),
    publicDiscussion,
  }),
  "Decide which players to invite to help you defend"
);

function defensePrompt(dto: DefenseRequest) {
  return makePrompt(
    dto.state,
    `DEFENSE PHASE:
- ${dto.state.players[dto.attackerId].name} is attacking you.
- Make your move using a tool`
  );
}

export const DefenseRequest = z.object({
  state: StateDto,
  attackerId: z.int(),
});
export type DefenseRequest = z.infer<typeof DefenseRequest>;

export type DefenseResponse = {
  privateThought: string;
  invitedPlayerIds: number[];
  discussion: string;
};

export async function defense(dto: DefenseRequest): Promise<DefenseResponse> {
  const messages = defensePrompt(dto);

  // Retry request if response is malformed
  for (let i = 0; i < config.maxLlmRetries; i++) {
    const res = await generateText({
      model: dto.state.agentState.model,
      sessionId: dto.state.sessionId,
      userId: dto.state.userId,
      messages,
      tools: [decideDefenseTool.definition],
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
    if (toolCall.function.name == decideDefenseTool.name) {
      const parsedTool = decideDefenseTool.parse(toolCall.function.arguments);
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
