/**
 * Shared constants
 */
export const AttackSide = {
  Attack: "attack",
  Defense: "defense",
  Neutral: "neutral",
} as const;

export type AttackSide = typeof AttackSide;
