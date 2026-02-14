defmodule Liteskill.McpServers.Client do
  @moduledoc """
  MCP JSON-RPC 2.0 HTTP client for Streamable HTTP transport.

  Supports `tools/list` and `tools/call` methods.
  Accepts a `plug:` option for testability with Req.Test.
  """

  @doc """
  Discover tools from an MCP server.

  Returns `{:ok, [tool]}` where each tool is a map with
  `"name"`, `"description"`, and `"inputSchema"` keys.
  """
  def list_tools(server, opts \\ []) do
    body = %{"jsonrpc" => "2.0", "method" => "tools/list", "id" => 1}

    case post(server, body, opts) do
      {:ok, %{"result" => %{"tools" => tools}}} ->
        {:ok, tools}

      {:ok, %{"error" => error}} ->
        {:error, error}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Call a tool on an MCP server.

  Returns `{:ok, result}` where result contains `"content"` from the server.
  """
  def call_tool(server, tool_name, arguments, opts \\ []) do
    body = %{
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => %{"name" => tool_name, "arguments" => arguments},
      "id" => 1
    }

    case post(server, body, opts) do
      {:ok, %{"result" => result}} ->
        {:ok, result}

      {:ok, %{"error" => error}} ->
        {:error, error}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp post(server, body, opts) do
    req_opts = Keyword.take(opts, [:plug])

    all_opts =
      [
        url: server.url,
        json: body,
        headers: build_headers(server)
      ] ++ req_opts

    case Req.post(Req.new(receive_timeout: 30_000), all_opts) do
      {:ok, %{status: 200, body: resp_body}} ->
        {:ok, resp_body}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, %{status: status, body: resp_body}}

      # coveralls-ignore-next-line
      {:error, reason} ->
        {:error, reason}
    end
  end

  @blocked_headers MapSet.new([
                     "authorization",
                     "host",
                     "content-type",
                     "content-length",
                     "transfer-encoding",
                     "connection",
                     "cookie",
                     "set-cookie",
                     "x-forwarded-for",
                     "x-forwarded-host",
                     "x-forwarded-proto",
                     "proxy-authorization"
                   ])

  defp build_headers(server) do
    base =
      if server.api_key && server.api_key != "" do
        [{"authorization", "Bearer #{server.api_key}"}]
      else
        []
      end

    custom =
      case server.headers do
        nil ->
          []

        h when h == %{} ->
          []

        h when is_map(h) ->
          h
          |> Enum.map(fn {k, v} -> {String.downcase(to_string(k)), to_string(v)} end)
          |> Enum.reject(fn {k, v} ->
            MapSet.member?(@blocked_headers, k) or has_control_chars?(k) or has_control_chars?(v)
          end)
      end

    [{"content-type", "application/json"}, {"accept", "application/json, text/event-stream"}] ++
      base ++ custom
  end

  defp has_control_chars?(str) do
    String.contains?(str, ["\r", "\n", "\0"])
  end
end
