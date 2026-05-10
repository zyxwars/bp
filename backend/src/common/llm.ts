/**
 * LLM client and tool helpers
 */
import { OpenRouter } from "@openrouter/sdk";
import {
  type ChatFunctionTool,
  type ChatMessages,
  type ResponseFormat,
} from "@openrouter/sdk/models";
import z from "zod";
import { config } from "../config/config.ts";
import { modelMap } from "../config/gameConfig.ts";
import { Logger } from "./logger.ts";
import type { Result } from "./types.ts";
import { safeParseJson } from "./utils.ts";

const log = new Logger("llm");

const openRouter = new OpenRouter({
  apiKey: config.openRouterApiKey,
});

/**
 * Wrapper for calling llm providers
 */
export async function generateText({
  model,
  messages,
  responseFormat,
  tools,
  sessionId,
  userId,
}: {
  model: string;
  messages: ChatMessages[];
  responseFormat?: ResponseFormat;
  tools?: ChatFunctionTool[];
  sessionId?: string;
  userId?: string;
}) {
  log.info(`model: ${model}`);

  const modelOptions = modelMap[model];
  if (modelOptions === undefined) {
    throw new Error("Unknown model");
  }
  log.debug(`model: ${JSON.stringify(modelOptions)}`);

  const res = await openRouter.chat
    .send({
      chatRequest: {
        messages,
        tools,
        responseFormat,
        // Response healing tries to fix malformed json without additional cost
        plugins: [{ id: "response-healing" }],
        sessionId,
        user: userId,
        ...modelOptions,
        stream: false,
      },
    })
    .catch((e) => {
      console.error(JSON.stringify(modelOptions), e);
      throw e;
    });

  return res.choices[0].message;
}

/**
 * Remove unwanted properties from the schema
 * ex. Anthropic returns error if ~standard is present
 */
function toJsonSchema(schema: z.ZodType): Record<string, unknown> {
  const {
    $schema: _schema,
    ["~standard"]: _standard,
    ...cleanSchema
  } = z.toJSONSchema(schema);
  return cleanSchema;
}

/**
 * Convert string to json and then validate the schema
 */
function parseStringToSchema<T extends z.ZodType>(
  schema: T,
  raw: string
): Result<z.infer<T>> {
  const parsedJson = safeParseJson(raw);
  if (!parsedJson.success) {
    return parsedJson;
  }

  const parsedSchema = schema.safeParse(parsedJson.data);
  if (!parsedSchema.success) {
    return { success: false, error: z.prettifyError(parsedSchema.error) };
  }

  return { success: true, data: parsedSchema.data };
}

/**
 * Utilty for pairing response format with a parser
 */
export function makeResponseFormat<T extends z.ZodType>(
  name: string,
  schema: T
) {
  return {
    responseFormat: {
      type: "json_schema" as const,
      jsonSchema: {
        name,
        strict: true,
        schema: toJsonSchema(schema),
      },
    },
    parse(raw: string) {
      return parseStringToSchema(schema, raw);
    },
  };
}

/**
 * Utilty for pairing tool with a parser
 */
export function makeTool<T extends z.ZodType>(
  name: string,
  parameters: T,
  description?: string
) {
  return {
    name,
    definition: {
      type: "function" as const,
      function: {
        name,
        description,
        parameters: toJsonSchema(parameters),
      },
    } satisfies ChatFunctionTool,
    parse(raw: string) {
      return parseStringToSchema(parameters, raw);
    },
  };
}
