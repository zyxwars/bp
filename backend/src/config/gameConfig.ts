import type { ChatRequestProvider, Reasoning } from "@openrouter/sdk/models";

/**
 * Game values used in simulation, demo and prompts
 * NOTE: Keep in sync with demo frontend if not running a simulation
 */
export const gameConfig = {
  shipCount: 5,
  startingGold: 3,
  winGold: 20,
  maxHistoryItems: 30,
};

/**
 * Mapping custom names to actual provider options
 * You can edit these or add more, the mappings are used both simulation and demo
 */
export const modelMap: {
  [modelKey: string]: {
    model: string;
    provider: ChatRequestProvider;
    reasoning?: Reasoning;
  };
} = {
  agent1: {
    model: "openai/gpt-5.4-mini",
    provider: { only: ["openai"] },
  },
  agent2: {
    model: "google/gemini-3-flash-preview",
    provider: { only: ["google-vertex"] },
  },
  agent3: {
    model: "anthropic/claude-haiku-4.5",
    provider: { only: ["anthropic"] },
  },
  agent4: {
    model: "x-ai/grok-4.1-fast",
    provider: { only: ["xai"] },
  },
};
