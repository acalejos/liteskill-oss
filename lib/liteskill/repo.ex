defmodule Liteskill.Repo do
  use Ecto.Repo,
    otp_app: :liteskill,
    adapter: Ecto.Adapters.Postgres
end
