defmodule Liteskill.Chat.Events.ConversationTitleUpdated do
  @derive Jason.Encoder
  defstruct [:title, :timestamp]
end
