/**
 * Attack-side decision handler
 */
import z from "zod";
import { AttackSide } from "../common/constants.ts";
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

const decideAttackSideTool = makeTool(
  "decideAttackSide",
  z.object({
    privateThought,
    side: z
      .enum([AttackSide.Attack, AttackSide.Defense, AttackSide.Neutral])
      .describe(
        "Whether you want to join the attack, join the defense, or stay neutral"
      ),
    publicDiscussion,
  }),
  "Decide which side to join in combat"
);

function attackSidePrompt(dto: AttackSideRequest) {
  const attacker = dto.state.players[dto.attackerId].name;
  const defender = dto.state.players[dto.defenderId].name;

  let inviteMessage: string;
  if (dto.hasAttackerSideInvite && dto.hasDefenderSideInvite) {
    inviteMessage = `You are invited by both ${attacker} (Attacker) and ${defender} (Defender) to join their side.`;
  } else if (dto.hasAttackerSideInvite) {
    inviteMessage = `You are invited by ${attacker} (Attacker) to join their side against ${defender}.`;
  } else {
    inviteMessage = `You are invited by ${defender} (Defender) to join their side against ${attacker}.`;
  }

  return makePrompt(
    dto.state,
    `JOIN ATTACK PHASE:
- ${inviteMessage}
- Make your move using a tool`
  );
}

export const AttackSideRequest = z.object({
  state: StateDto,
  attackerId: z.int(),
  defenderId: z.int(),
  hasAttackerSideInvite: z.boolean(),
  hasDefenderSideInvite: z.boolean(),
});
export type AttackSideRequest = z.infer<typeof AttackSideRequest>;

export type AttackSideResponse = {
  privateThought: string;
  side: (typeof AttackSide)[keyof AttackSide];
  discussion: string;
};
export async function attackSide(
  dto: AttackSideRequest
): Promise<AttackSideResponse> {
  const messages = attackSidePrompt(dto);

  // Retry request if response is malformed
  for (let i = 0; i < config.maxLlmRetries; i++) {
    const res = await generateText({
      model: dto.state.agentState.model,
      sessionId: dto.state.sessionId,
      userId: dto.state.userId,
      messages,
      tools: [decideAttackSideTool.definition],
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
    if (toolCall.function.name === decideAttackSideTool.name) {
      const parsedTool = decideAttackSideTool.parse(
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

      if (toolParams.side === AttackSide.Attack && !dto.hasAttackerSideInvite) {
        messages.push({
          role: "tool",
          toolCallId: toolCall.id,
          content: "You were not invited by the attacker, choose a valid side",
        });
        continue;
      } else if (
        toolParams.side === AttackSide.Defense &&
        !dto.hasDefenderSideInvite
      ) {
        messages.push({
          role: "tool",
          toolCallId: toolCall.id,
          content: "You were not invited by the defender, choose a valid side",
        });
        continue;
      }

      return {
        privateThought: toolParams.privateThought,
        side: toolParams.side,
        discussion: toolParams.publicDiscussion,
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
