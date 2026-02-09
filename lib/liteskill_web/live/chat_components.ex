defmodule LiteskillWeb.ChatComponents do
  @moduledoc """
  Reusable function components for the chat UI.
  """

  use Phoenix.Component

  import LiteskillWeb.CoreComponents, only: [icon: 1]

  attr :message, :map, required: true

  def message_bubble(assigns) do
    ~H"""
    <%= if @message.role == "user" do %>
      <div class="flex w-full mb-4 justify-end">
        <div class="max-w-[75%] rounded-2xl rounded-br-sm px-4 py-3 bg-primary text-primary-content">
          <p class="whitespace-pre-wrap break-words text-sm">{@message.content}</p>
        </div>
      </div>
    <% else %>
      <div class="mb-4 text-base-content">
        <div id={"prose-#{@message.id}"} phx-hook="CopyCode" class="prose prose-sm max-w-none">
          {LiteskillWeb.Markdown.render(@message.content)}
        </div>
      </div>
    <% end %>
    """
  end

  attr :conversation, :map, required: true
  attr :active, :boolean, default: false

  def conversation_item(assigns) do
    ~H"""
    <div class={[
      "group flex items-center gap-1 rounded-lg transition-colors",
      if(@active,
        do: "bg-primary/10 text-primary font-medium",
        else: "hover:bg-base-200 text-base-content"
      )
    ]}>
      <button
        phx-click="select_conversation"
        phx-value-id={@conversation.id}
        class="flex-1 text-left px-3 py-2 text-sm truncate cursor-pointer"
      >
        {@conversation.title}
      </button>
      <button
        phx-click="delete_conversation"
        phx-value-id={@conversation.id}
        data-confirm="Archive this conversation?"
        class="opacity-0 group-hover:opacity-100 pr-2 text-base-content/40 hover:text-error transition-opacity cursor-pointer"
      >
        <.icon name="hero-trash-micro" class="size-3.5" />
      </button>
    </div>
    """
  end

  def streaming_indicator(assigns) do
    ~H"""
    <div class="flex justify-start mb-4">
      <div class="bg-base-200 rounded-2xl rounded-bl-sm px-4 py-3">
        <div class="flex gap-1 items-center">
          <span class="w-2 h-2 bg-base-content/40 rounded-full animate-bounce [animation-delay:-0.3s]" />
          <span class="w-2 h-2 bg-base-content/40 rounded-full animate-bounce [animation-delay:-0.15s]" />
          <span class="w-2 h-2 bg-base-content/40 rounded-full animate-bounce" />
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :show, :boolean, required: true
  attr :on_close, :string, required: true
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      :if={@show}
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center"
      phx-mounted={@show && Phoenix.LiveView.JS.focus_first(to: "##{@id}-content")}
    >
      <div class="fixed inset-0 bg-black/50" phx-click={@on_close} />
      <div
        id={"#{@id}-content"}
        class="relative bg-base-100 rounded-xl shadow-xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto"
      >
        <div class="flex items-center justify-between p-4 border-b border-base-300">
          <h3 class="text-lg font-semibold">{@title}</h3>
          <button phx-click={@on_close} class="btn btn-ghost btn-sm btn-square">
            <.icon name="hero-x-mark-micro" class="size-5" />
          </button>
        </div>
        <div class="p-4">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :server, :map, required: true
  attr :owned, :boolean, required: true

  def mcp_server_card(assigns) do
    ~H"""
    <div class="card bg-base-100 border border-base-300 shadow-sm">
      <div class="card-body p-4">
        <div class="flex items-start justify-between gap-2">
          <div class="flex-1 min-w-0">
            <h3 class="font-semibold text-sm truncate">{@server.name}</h3>
            <p class="text-xs text-base-content/60 truncate mt-0.5">{@server.url}</p>
          </div>
          <span class={[
            "badge badge-sm",
            if(@server.status == "active", do: "badge-success", else: "badge-ghost")
          ]}>
            {@server.status}
          </span>
        </div>
        <p :if={@server.description} class="text-xs text-base-content/70 mt-1 line-clamp-2">
          {@server.description}
        </p>
        <div class="flex items-center gap-1 mt-2">
          <span :if={@server.global} class="badge badge-xs badge-info">global</span>
        </div>
        <div class="card-actions justify-end mt-2">
          <button
            phx-click="inspect_tools"
            phx-value-id={@server.id}
            class="btn btn-ghost btn-xs"
          >
            <.icon name="hero-code-bracket-micro" class="size-4" /> Tools
          </button>
          <button
            :if={@owned}
            phx-click="edit_mcp"
            phx-value-id={@server.id}
            class="btn btn-ghost btn-xs"
          >
            <.icon name="hero-pencil-square-micro" class="size-4" /> Edit
          </button>
          <button
            :if={@owned}
            phx-click="delete_mcp"
            phx-value-id={@server.id}
            data-confirm="Delete this MCP server?"
            class="btn btn-ghost btn-xs text-error"
          >
            <.icon name="hero-trash-micro" class="size-4" /> Delete
          </button>
        </div>
      </div>
    </div>
    """
  end

  # --- Server Picker ---

  attr :available_tools, :list, required: true
  attr :selected_server_ids, :any, required: true
  attr :show, :boolean, required: true
  attr :auto_confirm, :boolean, required: true
  attr :tools_loading, :boolean, default: false

  def server_picker(assigns) do
    servers =
      assigns.available_tools
      |> Enum.group_by(& &1.server_id)
      |> Enum.map(fn {server_id, tools} ->
        first = hd(tools)
        %{id: server_id, name: first.server_name, tool_count: length(tools)}
      end)

    assigns =
      assign(assigns,
        selected_count: MapSet.size(assigns.selected_server_ids),
        servers: servers
      )

    ~H"""
    <div class="relative">
      <button
        type="button"
        phx-click="toggle_tool_picker"
        class={[
          "btn btn-ghost btn-sm gap-1",
          if(@selected_count > 0, do: "text-primary", else: "text-base-content/50")
        ]}
      >
        <.icon name="hero-server-stack-micro" class="size-4" />
        <span :if={@selected_count > 0} class="badge badge-primary badge-xs">
          {@selected_count}
        </span>
      </button>

      <div
        :if={@show}
        class="absolute bottom-full left-0 mb-2 w-72 bg-base-100 border border-base-300 rounded-xl shadow-lg z-50 max-h-96 overflow-y-auto"
        phx-click-away="toggle_tool_picker"
      >
        <div class="p-3 border-b border-base-300 flex items-center justify-between">
          <span class="text-sm font-semibold">MCP Servers</span>
          <button
            :if={@selected_count > 0}
            type="button"
            phx-click="clear_tools"
            class="btn btn-ghost btn-xs text-base-content/50"
          >
            Clear
          </button>
        </div>

        <div :if={@tools_loading} class="p-4 text-center text-sm text-base-content/50">
          Loading servers...
        </div>

        <div
          :if={!@tools_loading && @servers == []}
          class="p-4 text-center text-sm text-base-content/50"
        >
          <p>No MCP servers found</p>
          <button
            type="button"
            phx-click="refresh_tools"
            class="btn btn-ghost btn-xs mt-2 gap-1"
          >
            <.icon name="hero-arrow-path-micro" class="size-3" /> Retry
          </button>
        </div>

        <div :if={!@tools_loading && @servers != []} class="py-1">
          <div
            :for={server <- @servers}
            class="flex items-center gap-2 px-3 py-2 hover:bg-base-200"
          >
            <label class="flex items-center gap-2 flex-1 min-w-0 cursor-pointer">
              <input
                type="checkbox"
                phx-click="toggle_server"
                phx-value-server-id={server.id}
                checked={MapSet.member?(@selected_server_ids, server.id)}
                class="checkbox checkbox-sm checkbox-primary"
              />
              <div class="flex-1 min-w-0">
                <div class="text-sm font-medium truncate">{server.name}</div>
                <div class="text-xs text-base-content/60">
                  {server.tool_count} {if server.tool_count == 1, do: "tool", else: "tools"}
                </div>
              </div>
            </label>
            <button
              type="button"
              phx-click="inspect_tools"
              phx-value-id={server.id}
              class="text-base-content/40 hover:text-info"
            >
              <.icon name="hero-information-circle-micro" class="size-4" />
            </button>
          </div>
        </div>

        <div class="p-3 border-t border-base-300">
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              phx-click="toggle_auto_confirm"
              checked={@auto_confirm}
              class="toggle toggle-xs toggle-primary"
            />
            <span class="text-xs text-base-content/70">Auto-confirm tool calls</span>
          </label>
        </div>
      </div>
    </div>
    """
  end

  # --- Tool Call Display ---

  attr :tool_call, :map, required: true
  attr :show_actions, :boolean, default: false

  def tool_call_display(assigns) do
    ~H"""
    <div class="flex justify-start mb-3">
      <div class="max-w-[85%] bg-base-200/50 border border-base-300 rounded-lg px-3 py-2 text-xs">
        <div class="flex items-center gap-2">
          <.icon name="hero-wrench-screwdriver-micro" class="size-3.5 text-base-content/50" />
          <span class="font-medium">{@tool_call.tool_name}</span>
          <span class={[
            "badge badge-xs",
            case @tool_call.status do
              "started" -> "badge-warning"
              "completed" -> "badge-success"
              _ -> "badge-ghost"
            end
          ]}>
            {@tool_call.status}
          </span>
        </div>

        <details :if={@tool_call.input && @tool_call.input != %{}} class="mt-1">
          <summary class="cursor-pointer text-base-content/50 hover:text-base-content/70">
            Input
          </summary>
          <pre class="mt-1 p-2 bg-base-300/50 rounded text-[0.65rem] overflow-x-auto whitespace-pre-wrap">{Jason.encode!(@tool_call.input, pretty: true)}</pre>
        </details>

        <details :if={@tool_call.output} class="mt-1">
          <summary class="cursor-pointer text-base-content/50 hover:text-base-content/70">
            Output
          </summary>
          <pre class="mt-1 p-2 bg-base-300/50 rounded text-[0.65rem] overflow-x-auto whitespace-pre-wrap">{Jason.encode!(@tool_call.output, pretty: true)}</pre>
        </details>

        <div :if={@show_actions && @tool_call.status == "started"} class="flex gap-2 mt-2">
          <button
            phx-click="approve_tool_call"
            phx-value-tool-use-id={@tool_call.tool_use_id}
            class="btn btn-success btn-xs gap-1"
          >
            <.icon name="hero-check-micro" class="size-3" /> Approve
          </button>
          <button
            phx-click="reject_tool_call"
            phx-value-tool-use-id={@tool_call.tool_use_id}
            class="btn btn-error btn-xs gap-1"
          >
            <.icon name="hero-x-mark-micro" class="size-3" /> Reject
          </button>
        </div>
      </div>
    </div>
    """
  end

  # --- Selected Server Badges ---

  attr :available_tools, :list, required: true
  attr :selected_server_ids, :any, required: true

  def selected_server_badges(assigns) do
    selected_servers =
      assigns.available_tools
      |> Enum.group_by(& &1.server_id)
      |> Enum.filter(fn {server_id, _} ->
        MapSet.member?(assigns.selected_server_ids, server_id)
      end)
      |> Enum.map(fn {server_id, tools} -> %{id: server_id, name: hd(tools).server_name} end)

    assigns = assign(assigns, selected_servers: selected_servers)

    ~H"""
    <div :if={@selected_servers != []} class="flex flex-wrap gap-1 px-1 pb-1">
      <span
        :for={server <- @selected_servers}
        class="badge badge-sm badge-outline badge-primary gap-1"
      >
        {server.name}
        <button
          type="button"
          phx-click="toggle_server"
          phx-value-server-id={server.id}
          class="hover:text-error"
        >
          <.icon name="hero-x-mark-micro" class="size-3" />
        </button>
      </span>
    </div>
    """
  end

  # --- Tool Detail ---

  attr :tool, :map, required: true

  def tool_detail(assigns) do
    properties = get_in(assigns.tool, ["inputSchema", "properties"]) || %{}
    required_fields = get_in(assigns.tool, ["inputSchema", "required"]) || []

    params =
      Enum.map(properties, fn {name, schema} ->
        %{
          name: name,
          type: schema["type"] || "any",
          description: schema["description"],
          required: name in required_fields
        }
      end)
      |> Enum.sort_by(&(!&1.required))

    assigns = assign(assigns, params: params)

    ~H"""
    <div class="collapse collapse-arrow border border-base-300 bg-base-200/30 rounded-lg">
      <input type="checkbox" />
      <div class="collapse-title py-2 px-3 min-h-0">
        <span class="font-mono text-sm font-semibold">{@tool["name"]}</span>
      </div>
      <div class="collapse-content px-3 pb-3 text-xs">
        <p :if={@tool["description"]} class="text-base-content/70 mb-3">
          {@tool["description"]}
        </p>
        <div :if={@params != []} class="space-y-2">
          <h4 class="font-semibold text-base-content/80">Parameters</h4>
          <div :for={param <- @params} class="flex flex-col gap-0.5 pl-2 border-l-2 border-base-300">
            <div class="flex items-center gap-2">
              <code class="text-primary font-semibold">{param.name}</code>
              <span class="badge badge-xs badge-ghost">{param.type}</span>
              <span :if={param.required} class="badge badge-xs badge-warning">required</span>
            </div>
            <p :if={param.description} class="text-base-content/60">{param.description}</p>
          </div>
        </div>
        <p :if={@params == []} class="text-base-content/50 italic">No parameters</p>
      </div>
    </div>
    """
  end
end
