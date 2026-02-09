defmodule Liteskill.Chat.Events.AssistantChunkReceived do
  @derive Jason.Encoder
  defstruct [
    :message_id,
    :chunk_index,
    :content_block_index,
    :delta_type,
    :delta_text,
    :timestamp
  ]
end
