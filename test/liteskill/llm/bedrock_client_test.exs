defmodule Liteskill.LLM.BedrockClientTest do
  use ExUnit.Case, async: true

  alias Liteskill.LLM.BedrockClient

  setup do
    Application.put_env(:liteskill, Liteskill.LLM,
      bedrock_region: "us-east-1",
      bedrock_model_id: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
      bedrock_bearer_token: "test-token"
    )

    :ok
  end

  describe "converse/3" do
    test "returns parsed body on 200 response" do
      Req.Test.stub(BedrockClient, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["messages"] == [
                 %{"role" => "user", "content" => [%{"text" => "Hello"}]}
               ]

        assert decoded["inferenceConfig"]["maxTokens"] == 4096
        assert decoded["inferenceConfig"]["temperature"] == 1.0

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"output" => %{"message" => %{"content" => [%{"text" => "Hi!"}]}}})
        )
      end)

      messages = [%{role: :user, content: "Hello"}]

      assert {:ok, %{"output" => _}} =
               BedrockClient.converse("test-model", messages, plug: {Req.Test, BedrockClient})
    end

    test "returns error on non-200 response" do
      Req.Test.stub(BedrockClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(429, Jason.encode!(%{"message" => "rate limited"}))
      end)

      messages = [%{role: :user, content: "Hello"}]

      assert {:error, %{status: 429}} =
               BedrockClient.converse("test-model", messages, plug: {Req.Test, BedrockClient})
    end

    test "formats messages with string keys and passthrough" do
      Req.Test.stub(BedrockClient, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert length(decoded["messages"]) == 3

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      messages = [
        %{role: :user, content: "Hello"},
        %{"role" => "assistant", "content" => "Hi there!"},
        %{"role" => "user", "content" => [%{"text" => "How are you?"}]}
      ]

      assert {:ok, _} =
               BedrockClient.converse("test-model", messages, plug: {Req.Test, BedrockClient})
    end

    test "includes system prompt when provided" do
      Req.Test.stub(BedrockClient, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["system"] == [%{"text" => "Be helpful"}]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      messages = [%{role: :user, content: "Hi"}]

      assert {:ok, _} =
               BedrockClient.converse("test-model", messages,
                 system: "Be helpful",
                 plug: {Req.Test, BedrockClient}
               )
    end

    test "excludes toolConfig when tools is empty list" do
      Req.Test.stub(BedrockClient, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["toolConfig"] == nil

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      messages = [%{role: :user, content: "Hi"}]

      assert {:ok, _} =
               BedrockClient.converse("test-model", messages,
                 tools: [],
                 plug: {Req.Test, BedrockClient}
               )
    end

    test "uses custom max_tokens and temperature" do
      Req.Test.stub(BedrockClient, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["inferenceConfig"]["maxTokens"] == 1024
        assert decoded["inferenceConfig"]["temperature"] == 0.5

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      messages = [%{role: :user, content: "Hi"}]

      assert {:ok, _} =
               BedrockClient.converse("test-model", messages,
                 max_tokens: 1024,
                 temperature: 0.5,
                 plug: {Req.Test, BedrockClient}
               )
    end
  end

  describe "converse_stream/4" do
    test "returns :ok on 200 response" do
      Req.Test.stub(BedrockClient, fn conn ->
        conn
        |> Plug.Conn.send_resp(200, "")
      end)

      messages = [%{role: :user, content: "Hello"}]
      callback = fn _event -> :ok end

      assert :ok =
               BedrockClient.converse_stream("test-model", messages, callback,
                 plug: {Req.Test, BedrockClient}
               )
    end

    test "returns error on non-200 response" do
      Req.Test.stub(BedrockClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(503, Jason.encode!(%{"message" => "service unavailable"}))
      end)

      messages = [%{role: :user, content: "Hello"}]
      callback = fn _event -> :ok end

      assert {:error, %{status: 503}} =
               BedrockClient.converse_stream("test-model", messages, callback,
                 plug: {Req.Test, BedrockClient}
               )
    end
  end
end
