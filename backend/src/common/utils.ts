/**
 * Shared utility functions
 */
import { type Result, StateDto } from "./types.ts";

// https://stackoverflow.com/a/39914235
export function sleep(seconds: number): Promise<void> {
  return new Promise((r) => setTimeout(r, seconds * 1000));
}

// Fisher-Yates Sorting Algorithm
// https://www.freecodecamp.org/news/how-to-shuffle-an-array-of-items-using-javascript-or-typescript/
export function shuffle<T>(array: T[]): T[] {
  array = [...array];

  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }

  return array;
}

/**
 * Parse json and return error as value instead of throwing
 */
export function safeParseJson<T = unknown>(json: string): Result<T> {
  try {
    return { success: true, data: JSON.parse(json) };
  } catch (error) {
    if (error instanceof Error) {
      return { success: false, error: `${error.message}` };
    }

    throw error;
  }
}

export function getPlayerIdByName(state: StateDto, name: string) {
  return state.players.find((p) => p.name === name)?.id;
}
