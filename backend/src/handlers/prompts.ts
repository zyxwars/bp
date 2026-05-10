/**
 * Prompts used for both the demo and simulation
 *
 * The prompt creation was aided by generative AI
 * */
import type { ChatMessages } from "@openrouter/sdk/models";
import z from "zod";
import { StateDto } from "../common/types.ts";
import { gameConfig } from "../config/gameConfig.ts";

export const USE_A_TOOL_ERROR = "Use a tool to make your move";

export const USE_ONLY_PROVIDED_TOOLS_ERROR =
  "Tool not available, use only provided tools";

export const privateThought = z
  .string()
  .describe(
    "Brief explanation of your strategy and reasoning for your decision."
  );

export const publicDiscussion = z
  .string()
  .describe(
    "Add message about the current situation and your actions to the public discussion. Keep the message short."
  );

function formatHistory(history: string[], emptyText: string): string {
  if (history.length === 0) {
    return emptyText;
  }

  return history.map((item) => `- ${item}`).join("\n");
}

export function makePrompt(
  state: StateDto,
  phaseContext: string
): ChatMessages[] {
  const gameState = `Round: ${state.round}
Player names: ${state.players.map((p) => p.name).join(", ")}
You are: ${state.players[state.thisPlayerId].name}
Player gold:
${state.players
  .map(
    (p) =>
      `- ${p.name} ${p.id === state.thisPlayerId ? "(You) " : ""}- Gold: ${
        p.gold
      }`
  )
  .join("\n")}`;

  const history = formatHistory(
    state.agentState.history,
    "No history recorded yet."
  );

  const strategyAndSentiments = `## CURRENT STRATEGY AND SENTIMENTS
Strategy: ${state.agentState.strategy || "No strategy recorded yet."}
Sentiments towards other players:
${
  Object.entries(state.agentState.playerAnalysis)
    .map(([name, sentiment]) => `- ${name}: ${sentiment}`)
    .join("\n") || "No sentiments recorded yet."
}`;

  return [
    {
      role: "system",
      content: `You are a strategic player in a game involving bluffing, alliances, and diplomacy. Use your private reasoning history for consistency, but never reveal private reasoning directly in public messages.`,
    },
    {
      role: "user",
      content: `## GAME OVERVIEW
You are competing to be the first player to accumulate ${gameConfig.winGold} gold. If multiple players reach ${gameConfig.winGold} simultaneously, the player with the most gold wins.

## CORE MECHANICS
At the start of each round, every player commands ${gameConfig.shipCount} ships. You must secretly decide how many ships to send exploring versus keep at home.

- Exploring ships each find 1 gold at the end of the round (guaranteed income).
- Ships kept at home are used for attacking and defending during combat.
- Ships return home at the end of the round and the number of ships stays the same every round

## ROUND STRUCTURE

### 1. Exploration Phase
- All players secretly choose how many ships to send exploring. Players may bluff or misrepresent this number to other players.

### 2. Attack Phase
- One player is randomly selected as the Attacker. They choose a target (Defender) and may invite other players to join their attack.
- The chosen player must attack.

- The Defender may also invite other players to help defend.
- Invited players choose which side to support (attacker or defender or neutral).
- Only ships kept at home (not sent exploring) can participate in combat.

### 3. Combat Resolution
- The side with more home ships wins, tie-breaker goes to defenders.
- Winners take half of each losing-side player's current gold.
- Losing-side players lose half their gold.
- Players who joined the winning side split the spoils equally.

### 4. Exploration Resolution
- After combat, all players collect gold from their exploring ships (1 gold per ship sent).
- All ships return home and next round starts

## GAME STATE
${gameState}

${strategyAndSentiments}

## HISTORY
${history}

${phaseContext}`,
    },
  ];
}
