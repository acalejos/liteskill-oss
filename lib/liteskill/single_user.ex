defmodule Liteskill.SingleUser do
  @moduledoc """
  Single-user mode helpers.

  When `SINGLE_USER_MODE=true` the app auto-authenticates as the admin user,
  skips the setup wizard, and collapses Admin + Profile into a unified Settings page.
  """

  alias Liteskill.Accounts
  alias Liteskill.Accounts.User

  @doc "Returns true when single-user mode is enabled via config."
  def enabled? do
    Application.get_env(:liteskill, :single_user_mode, false)
  end

  @doc "Returns the admin user, or nil if not yet provisioned."
  def auto_user do
    Accounts.get_user_by_email(User.admin_email())
  end

  @doc """
  Ensures the admin account has a password set so `User.setup_required?/1`
  returns false. Called once at boot when single-user mode is active.
  """
  def auto_provision_admin do
    case auto_user() do
      %User{} = admin ->
        if User.setup_required?(admin) do
          password = random_password()
          Accounts.setup_admin_password(admin, password)
        else
          {:ok, admin}
        end

      # coveralls-ignore-start
      nil ->
        :noop
        # coveralls-ignore-stop
    end
  end

  defp random_password do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
