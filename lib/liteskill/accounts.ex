defmodule Liteskill.Accounts do
  @moduledoc """
  The Accounts context. Manages user records created from OIDC or password authentication.
  """

  alias Liteskill.Accounts.User
  alias Liteskill.Repo

  import Ecto.Query

  @doc """
  Finds an existing user by OIDC subject+issuer or creates a new one.
  Idempotent -- safe to call on every login callback.
  """
  def find_or_create_from_oidc(attrs) do
    sub = Map.fetch!(attrs, :oidc_sub)
    issuer = Map.fetch!(attrs, :oidc_issuer)

    case Repo.one(from u in User, where: u.oidc_sub == ^sub and u.oidc_issuer == ^issuer) do
      nil ->
        %User{}
        |> User.changeset(Map.new(attrs))
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end

  @doc """
  Registers a new user with email and password.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates a user by email and password.
  """
  def authenticate_by_email_password(email, password) do
    user = get_user_by_email(email)

    if User.valid_password?(user, password) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.one(from u in User, where: u.email == ^email)
  end

  @doc """
  Gets a user by ID. Raises if not found.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by ID. Returns nil if not found.
  """
  def get_user(id), do: Repo.get(User, id)
end
