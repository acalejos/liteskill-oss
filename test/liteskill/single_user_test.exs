defmodule Liteskill.SingleUserTest do
  use Liteskill.DataCase, async: false

  alias Liteskill.SingleUser
  alias Liteskill.Accounts
  alias Liteskill.Accounts.User

  describe "enabled?/0" do
    test "returns false by default" do
      refute SingleUser.enabled?()
    end

    test "returns true when configured" do
      original = Application.get_env(:liteskill, :single_user_mode, false)
      Application.put_env(:liteskill, :single_user_mode, true)

      on_exit(fn ->
        Application.put_env(:liteskill, :single_user_mode, original)
      end)

      assert SingleUser.enabled?()
    end
  end

  describe "auto_user/0" do
    test "returns admin user when it exists" do
      Accounts.ensure_admin_user()
      user = SingleUser.auto_user()
      assert %User{} = user
      assert user.email == User.admin_email()
    end
  end

  describe "auto_provision_admin/0" do
    test "sets password on admin when setup is required" do
      admin = Accounts.ensure_admin_user()
      assert User.setup_required?(admin)

      assert {:ok, updated} = SingleUser.auto_provision_admin()
      refute User.setup_required?(updated)
      assert updated.password_hash != nil
    end

    test "is a no-op when admin already has a password" do
      admin = Accounts.ensure_admin_user()
      {:ok, admin} = Accounts.setup_admin_password(admin, "a_secure_password1")
      refute User.setup_required?(admin)

      assert {:ok, same} = SingleUser.auto_provision_admin()
      assert same.id == admin.id
    end
  end
end
