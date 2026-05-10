/**
 * Custom error types
 */
import type { ChatMessages } from "@openrouter/sdk/models";

export class LlmResponseError extends Error {
  public readonly model: string;
  public readonly messages: ChatMessages[];

  public constructor(model: string, messages: ChatMessages[]) {
    super("Llm failed to respond");
    this.model = model;
    this.messages = messages;
  }
}
