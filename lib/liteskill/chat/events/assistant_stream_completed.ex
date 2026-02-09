defmodule Liteskill.Chat.Events.AssistantStreamCompleted do
  @derive Jason.Encoder
  defstruct [
    :message_id,
    :full_content,
    :stop_reason,
    :input_tokens,
    :output_tokens,
    :latency_ms,
    :timestamp
  ]
end
