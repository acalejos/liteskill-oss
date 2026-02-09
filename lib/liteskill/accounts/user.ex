defmodule Liteskill.Accounts.User do
  @moduledoc """
  Schema for authenticated users, backed by OIDC or password authentication.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string
    field :oidc_sub, :string
    field :oidc_issuer, :string
    field :oidc_claims, :map, default: %{}
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs), do: oidc_changeset(user, attrs)

  def oidc_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url, :oidc_sub, :oidc_issuer, :oidc_claims])
    |> validate_required([:email, :oidc_sub, :oidc_issuer])
    |> unique_constraint([:oidc_sub, :oidc_issuer])
    |> unique_constraint(:email)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :password])
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 12, max: 72)
    |> unique_constraint(:email)
    |> hash_password()
  end

  def valid_password?(%__MODULE__{password_hash: hash}, password)
      when is_binary(hash) and is_binary(password) do
    Argon2.verify_pass(password, hash)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:password_hash, Argon2.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end
end
