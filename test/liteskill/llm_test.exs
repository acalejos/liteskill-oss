defmodule Liteskill.LLMTest do
  use ExUnit.Case, async: true

  alias Liteskill.LLM

  setup do
    Application.put_env(:liteskill, Liteskill.LLM,
      bedrock_region: "us-east-1",
      bedrock_model_id: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
      bedrock_bearer_token: "test-token"
    )

    :ok
  end

  describe "complete/2" do
    test "delegates to BedrockClient.converse" do
      Req.Test.stub(Liteskill.LLM.BedrockClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"output" => "hi"}))
      end)

      messages = [%{role: :user, content: "Hello"}]

      assert {:ok, %{"output" => "hi"}} =
               LLM.complete(messages, plug: {Req.Test, Liteskill.LLM.BedrockClient})
    end

    test "allows overriding model_id" do
      Req.Test.stub(Liteskill.LLM.BedrockClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      messages = [%{role: :user, content: "Hi"}]

      assert {:ok, _} =
               LLM.complete(messages,
                 model_id: "custom-model",
                 plug: {Req.Test, Liteskill.LLM.BedrockClient}
               )
    end
  end

  describe "complete_stream/3" do
    test "delegates to BedrockClient.converse_stream" do
      Req.Test.stub(Liteskill.LLM.BedrockClient, fn conn ->
        conn
        |> Plug.Conn.send_resp(200, "")
      end)

      messages = [%{role: :user, content: "Hello"}]
      callback = fn _event -> :ok end

      assert :ok =
               LLM.complete_stream(messages, callback,
                 plug: {Req.Test, Liteskill.LLM.BedrockClient}
               )
    end
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
