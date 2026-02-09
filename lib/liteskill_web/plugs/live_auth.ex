defmodule LiteskillWeb.Plugs.LiveAuth do
  @moduledoc """
  LiveView on_mount hooks for authentication.

  Used in live_session to protect LiveView routes.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias Liteskill.Accounts

  def on_mount(:require_authenticated, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:halt, redirect(socket, to: "/login")}

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            {:halt, redirect(socket, to: "/login")}

          user ->
            {:cont, assign(socket, :current_user, user)}
        end
    end
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:cont, assign(socket, :current_user, nil)}

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            {:cont, assign(socket, :current_user, nil)}

          _user ->
            {:halt, redirect(socket, to: "/")}
        end
    end
  end
end
