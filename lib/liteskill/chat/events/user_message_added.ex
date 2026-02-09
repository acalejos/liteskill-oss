defmodule Liteskill.Chat.Events.UserMessageAdded do
  @derive Jason.Encoder
  defstruct [:message_id, :content, :timestamp]
end
