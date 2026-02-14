defmodule Liteskill.LLMTest do
  use ExUnit.Case, async: true

  alias Liteskill.LLM

  setup do
    Application.put_env(:liteskill, Liteskill.LLM,
      bedrock_region: "us-east-1",
      bedrock_model_id: "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
    )

    :ok
  end

  defp fake_response(text) do
    %ReqLLM.Response{
      id: "resp-1",
      model: "test",
      message: ReqLLM.Context.assistant(text),
      finish_reason: :stop,
      usage: %{input_tokens: 10, output_tokens: 5},
      context: ReqLLM.Context.new([])
    }
  end

  defp fake_generate(text) do
    fn _model, _context, _opts ->
      {:ok, fake_response(text)}
    end
  end

  describe "complete/2" do
    test "returns formatted response from ReqLLM" do
      messages = [%{role: :user, content: "Hello"}]

      assert {:ok,
              %{
                "output" => %{
                  "message" => %{"role" => "assistant", "content" => [%{"text" => "Hi there"}]}
                }
              }} =
               LLM.complete(messages, generate_fn: fake_generate("Hi there"))
    end

    test "allows overriding model_id" do
      messages = [%{role: :user, content: "Hi"}]

      generate_fn = fn model, _context, _opts ->
        assert model == %{id: "custom-model", provider: :amazon_bedrock}
        {:ok, fake_response("ok")}
      end

      assert {:ok, _} = LLM.complete(messages, model_id: "custom-model", generate_fn: generate_fn)
    end

    test "passes system prompt option" do
      messages = [%{role: :user, content: "Hi"}]

      generate_fn = fn _model, _context, opts ->
        assert Keyword.get(opts, :system_prompt) == "Be brief"
        {:ok, fake_response("ok")}
      end

      assert {:ok, _} = LLM.complete(messages, system: "Be brief", generate_fn: generate_fn)
    end

    test "passes temperature and max_tokens" do
      messages = [%{role: :user, content: "Hi"}]

      generate_fn = fn _model, _context, opts ->
        assert Keyword.get(opts, :temperature) == 0.5
        assert Keyword.get(opts, :max_tokens) == 100
        {:ok, fake_response("ok")}
      end

      assert {:ok, _} =
               LLM.complete(messages,
                 temperature: 0.5,
                 max_tokens: 100,
                 generate_fn: generate_fn
               )
    end

    test "returns error on failure" do
      messages = [%{role: :user, content: "Hello"}]

      generate_fn = fn _model, _context, _opts ->
        {:error, %{status: 500, body: "Internal error"}}
      end

      assert {:error, %{status: 500}} = LLM.complete(messages, generate_fn: generate_fn)
    end
  end

  test "includes api_key in provider_options when bearer token configured" do
    Application.put_env(:liteskill, Liteskill.LLM,
      bedrock_region: "us-east-1",
      bedrock_model_id: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
      bedrock_bearer_token: "test-token"
    )

    messages = [%{role: :user, content: "Hello"}]

    generate_fn = fn _model, _context, opts ->
      provider_opts = Keyword.get(opts, :provider_options, [])
      assert Keyword.get(provider_opts, :api_key) == "test-token"
      {:ok, fake_response("ok")}
    end

    assert {:ok, _} = LLM.complete(messages, generate_fn: generate_fn)
  end

  describe "available_models/0" do
    test "returns a list of model IDs" do
      models = LLM.available_models()
      assert is_list(models)
      assert length(models) > 0
      assert Enum.all?(models, &is_binary/1)
    end
  end
end
