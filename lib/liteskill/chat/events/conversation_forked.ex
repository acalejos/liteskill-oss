defmodule Liteskill.Chat.Events.ConversationForked do
  @derive Jason.Encoder
  defstruct [:new_conversation_id, :parent_stream_id, :fork_at_version, :user_id, :timestamp]
end
