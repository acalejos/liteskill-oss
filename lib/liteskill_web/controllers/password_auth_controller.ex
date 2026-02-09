defmodule LiteskillWeb.PasswordAuthController do
  use LiteskillWeb, :controller

  alias Liteskill.Accounts

  def register(conn, params) do
    attrs = %{
      email: params["email"],
      name: params["name"],
      password: params["password"]
    }

    case Accounts.register_user(attrs) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_status(:created)
        |> json(%{data: %{id: user.id, email: user.email, name: user.name}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation failed", details: inspect(changeset.errors)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> json(%{data: %{id: user.id, email: user.email, name: user.name}})

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid credentials"})
    end
  end
end
