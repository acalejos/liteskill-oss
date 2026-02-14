defmodule Liteskill.LLM do
  @moduledoc """
  Public API for LLM interactions.

  Uses ReqLLM for transport. `complete/2` is used for non-streaming calls
  (e.g. conversation title generation). Streaming is handled by
  `StreamHandler` directly.
  """

  alias Liteskill.LLM.StreamHandler

  @doc """
  Sends a non-streaming completion request to the configured LLM model.

  ## Options
    - `:model_id` - Override the default model
    - `:max_tokens` - Maximum tokens to generate
    - `:temperature` - Sampling temperature
    - `:system` - System prompt
  """
  def complete(messages, opts \\ []) do
    model_id = Keyword.get(opts, :model_id, config(:bedrock_model_id))
    model = StreamHandler.to_req_llm_model(model_id)
    context = StreamHandler.to_req_llm_context(messages)

    req_opts = [provider_options: bedrock_provider_options()]

    req_opts =
      case Keyword.get(opts, :system) do
        nil -> req_opts
        system -> Keyword.put(req_opts, :system_prompt, system)
      end

    req_opts =
      case Keyword.get(opts, :temperature) do
        nil -> req_opts
        temp -> Keyword.put(req_opts, :temperature, temp)
      end

    req_opts =
      case Keyword.get(opts, :max_tokens) do
        nil -> req_opts
        max -> Keyword.put(req_opts, :max_tokens, max)
      end

    generate_fn = Keyword.get(opts, :generate_fn, &default_generate/3)

    case generate_fn.(model, context, req_opts) do
      {:ok, response} ->
        text = ReqLLM.Response.text(response) || ""

        {:ok,
         %{"output" => %{"message" => %{"role" => "assistant", "content" => [%{"text" => text}]}}}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # coveralls-ignore-start
  defp default_generate(model, context, opts) do
    ReqLLM.generate_text(model, context, opts)
  end

  # coveralls-ignore-stop

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

  defp bedrock_provider_options do
    config = Application.get_env(:liteskill, __MODULE__, [])

    opts = [region: Keyword.get(config, :bedrock_region, "us-east-1"), use_converse: true]

    case Keyword.get(config, :bedrock_bearer_token) do
      nil -> opts
      token -> Keyword.put(opts, :api_key, token)
    end
  end

  defp config(key) do
    Application.get_env(:liteskill, __MODULE__, [])
    |> Keyword.fetch!(key)
  end
end
