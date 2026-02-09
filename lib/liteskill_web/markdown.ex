defmodule LiteskillWeb.Markdown do
  @moduledoc """
  Converts Markdown content to safe HTML for rendering in the chat UI.
  """

  @mdex_opts [
    extension: [
      table: true,
      strikethrough: true,
      autolink: true,
      tasklist: true,
      footnotes: true
    ],
    render: [
      github_pre_lang: true
    ],
    syntax_highlight: [
      formatter: {:html_inline, theme: "onedark"}
    ]
  ]

  @doc """
  Renders a complete markdown string to an HTML-safe Phoenix.HTML struct.
  """
  def render(nil), do: {:safe, ""}
  def render(""), do: {:safe, ""}

  def render(markdown) when is_binary(markdown) do
    {:safe, MDEx.to_html!(markdown, @mdex_opts)}
  end

  @doc """
  Renders a streaming (potentially incomplete) markdown fragment.
  Uses mdex's streaming mode which auto-closes unclosed nodes.
  """
  def render_streaming(nil), do: {:safe, ""}
  def render_streaming(""), do: {:safe, ""}

  def render_streaming(markdown) when is_binary(markdown) do
    html =
      MDEx.new(Keyword.merge(@mdex_opts, streaming: true, markdown: markdown))
      |> MDEx.to_html!()

    {:safe, html}
  end
end
