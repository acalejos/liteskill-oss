defmodule LiteskillWeb.Plugs.Auth do
  @moduledoc """
  Authentication plugs for session-based user loading and access control.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Liteskill.Accounts

  def init(action), do: action

  def call(conn, :fetch_current_user), do: fetch_current_user(conn)
  def call(conn, :require_authenticated_user), do: require_authenticated_user(conn)

  def fetch_current_user(conn, _opts \\ []) do
    case get_session(conn, :user_id) do
      nil ->
        assign(conn, :current_user, nil)

      user_id ->
        case Accounts.get_user(user_id) do
          nil -> assign(conn, :current_user, nil)
          user -> assign(conn, :current_user, user)
        end
    end
  end

  def require_authenticated_user(conn, _opts \\ []) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "authentication required"})
      |> halt()
    end
  end
end
