defmodule Liteskill.Chat.Events.ToolCallStarted do
  @derive Jason.Encoder
  defstruct [:message_id, :tool_use_id, :tool_name, :input, :timestamp]
end
