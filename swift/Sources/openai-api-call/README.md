# OpenAI API Call Example

This example shows how to use the `openai-api-call` Swift executable to query the OpenAI Responses API with web search capabilities using the gpt-4.1-mini model.

## Prerequisites

Ensure you have a `.env` file at the root of the `swift/` directory containing your API key:

```bash
OPENAI_API_KEY="your_openai_api_key_here"
```

## Running the example

```bash
cd swift
swift run openai-api-call "your research topic"
```

### Examples

```bash
# Research timsort algorithm
swift run openai-api-call "timsort"

# Research quantum computing
swift run openai-api-call "quantum computing"

# Research machine learning trends
swift run openai-api-call "machine learning trends 2024"
```

### Sample output

```json
{
  "top_logprobs" : 0,
  "parallel_tool_calls" : true,
  "top_p" : 1,
  "status" : "completed",
  "metadata" : {

  },
  "prompt_cache_key" : null,
  "temperature" : 1,
  "incomplete_details" : null,
  "object" : "response",
  "previous_response_id" : null,
  "store" : true,
  "background" : false,
  "max_output_tokens" : null,
  "instructions" : null,
  "tools" : [
    {
      "type" : "web_search_preview",
      "search_context_size" : "medium",
      "user_location" : {
        "timezone" : null,
        "country" : "US",
        "region" : null,
        "type" : "approximate",
        "city" : null
      }
    }
  ],
  "service_tier" : "default",
  "id" : "resp_687f30cbb678819993bdfd324b1cce800f01ca4cd1b33f90",
  "safety_identifier" : null,
  "max_tool_calls" : null,
  "usage" : {
    "input_tokens" : 1447,
    "output_tokens" : 130,
    "total_tokens" : 1577,
    "output_tokens_details" : {
      "reasoning_tokens" : 64
    },
    "input_tokens_details" : {
      "cached_tokens" : 1394
    }
  },
  "user" : null,
  "error" : null,
  "reasoning" : {
    "effort" : "medium",
    "summary" : "detailed"
  },
  "model" : "gpt-4.1-mini-2025-04-14",
  "tool_choice" : "auto",
  "text" : {
    "format" : {
      "type" : "text"
    }
  },
  "created_at" : 1753166027,
  "truncation" : "disabled",
  "output" : [
    {
      "id" : "rs_687f30ccd0d88199b813b765ff6f1d2a0f01ca4cd1b33f90",
      "type" : "reasoning",
      "summary" : [
        {
          "type" : "summary_text",
          "text" : "**Clarifying research topic**\n\nThe user mentioned a \"test topic,\" which seems a bit ambiguous. I'm thinking they might be using it as a placeholder or want to demonstrate the research process. To help effectively, I need to clarify what they mean. I'll ask them directly: which topic are they referring to? Or is \"test topic\" the actual subject? It might also be an opportunity for small talk. I’ll make sure to respond and ask for clarification!"
        }
      ]
    },
    {
      "status" : "completed",
      "id" : "msg_687f30d2bd14819984f99e62b653b7d70f01ca4cd1b33f90",
      "content" : [
        {
          "annotations" : [

          ],
          "logprobs" : [

          ],
          "type" : "output_text",
          "text" : "Sure—I'd be happy to help. Could you clarify what specific “test topic” you’d like me to research (e.g., a scientific technique, a medical diagnostic test, a policy pilot program, etc.)? The more detail you provide, the more precise and useful the summary will be."
        }
      ],
      "type" : "message",
      "role" : "assistant"
    }
  ]
}
```
