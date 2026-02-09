defmodule Liteskill.LLM do
  @moduledoc """
  Public API for LLM interactions.

  Wraps the Bedrock client to provide a clean interface for completions.
  """

  alias Liteskill.LLM.BedrockClient

  @doc """
  Sends a non-streaming completion request to the configured Bedrock model.

  ## Options
    - `:model_id` - Override the default model
    - `:max_tokens` - Maximum tokens to generate (default: 4096)
    - `:temperature` - Sampling temperature (default: 1.0)
    - `:system` - System prompt
  """
  def complete(messages, opts \\ []) do
    model_id = Keyword.get(opts, :model_id, config(:bedrock_model_id))
    BedrockClient.converse(model_id, messages, opts)
  end

  @doc """
  Sends a streaming completion request. Calls `callback` with each parsed event.

  The callback receives `{event_type, payload}` tuples:
    - `{:message_start, %{...}}`
    - `{:content_block_start, %{...}}`
    - `{:content_block_delta, %{...}}`
    - `{:content_block_stop, %{...}}`
    - `{:message_stop, %{...}}`
    - `{:metadata, %{...}}`
  """
  def complete_stream(messages, callback, opts \\ []) do
    model_id = Keyword.get(opts, :model_id, config(:bedrock_model_id))
    BedrockClient.converse_stream(model_id, messages, callback, opts)
  end

  @doc """
  Returns the list of available model IDs.
  """
  def available_models do
    [
      "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
      "us.anthropic.claude-3-5-haiku-20241022-v1:0",
      "us.anthropic.claude-sonnet-4-20250514-v1:0"
    ]
  end

  defp config(key) do
    Application.get_env(:liteskill, __MODULE__, [])
    |> Keyword.fetch!(key)
  end
end
