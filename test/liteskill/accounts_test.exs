defmodule Liteskill.AccountsTest do
  use Liteskill.DataCase, async: true

  alias Liteskill.Accounts
  alias Liteskill.Accounts.User

  @valid_attrs %{
    email: "test@example.com",
    name: "Test User",
    oidc_sub: "sub-123",
    oidc_issuer: "https://idp.example.com"
  }

  describe "find_or_create_from_oidc/1" do
    test "creates a new user when none exists" do
      attrs = unique_oidc_attrs()
      assert {:ok, %User{} = user} = Accounts.find_or_create_from_oidc(attrs)

      assert user.oidc_sub == attrs.oidc_sub
      assert user.name == "Test User"
      assert user.id != nil
    end

    test "returns existing user on duplicate oidc_sub + oidc_issuer" do
      attrs = unique_oidc_attrs()
      {:ok, user1} = Accounts.find_or_create_from_oidc(attrs)
      {:ok, user2} = Accounts.find_or_create_from_oidc(attrs)

      assert user1.id == user2.id
    end

    test "creates separate users for different subjects" do
      {:ok, user1} = Accounts.find_or_create_from_oidc(unique_oidc_attrs())

      {:ok, user2} =
        Accounts.find_or_create_from_oidc(unique_oidc_attrs(%{oidc_sub: "sub-different"}))

      assert user1.id != user2.id
    end

    test "returns error for missing required fields" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.find_or_create_from_oidc(%{oidc_sub: "x", oidc_issuer: "y"})
    end
  end

  describe "get_user!/1" do
    test "returns user by id" do
      {:ok, user} = Accounts.find_or_create_from_oidc(unique_oidc_attrs())
      assert Accounts.get_user!(user.id).id == user.id
    end

    test "raises for unknown id" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(Ecto.UUID.generate())
      end
    end
  end

  describe "register_user/1" do
    test "creates a user with email and password" do
      attrs = %{email: unique_email(), name: "Password User", password: "supersecretpass123"}
      assert {:ok, %User{} = user} = Accounts.register_user(attrs)

      assert user.email == attrs.email
      assert user.name == "Password User"
      assert user.password_hash != nil
      assert user.password == nil
    end

    test "returns error for short password" do
      attrs = %{email: unique_email(), password: "short"}
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "should be at least 12 character(s)" in errors_on(changeset).password
    end

    test "returns error for too-long password" do
      attrs = %{email: unique_email(), password: String.duplicate("a", 73)}
      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "returns error for duplicate email" do
      email = unique_email()
      {:ok, _} = Accounts.register_user(%{email: email, password: "supersecretpass123"})

      assert {:error, changeset} =
               Accounts.register_user(%{email: email, password: "supersecretpass123"})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "returns error for missing email" do
      assert {:error, changeset} = Accounts.register_user(%{password: "supersecretpass123"})
      assert "can't be blank" in errors_on(changeset).email
    end
  end

  describe "authenticate_by_email_password/2" do
    test "returns user for valid credentials" do
      email = unique_email()
      {:ok, user} = Accounts.register_user(%{email: email, password: "supersecretpass123"})

      assert {:ok, authed} = Accounts.authenticate_by_email_password(email, "supersecretpass123")
      assert authed.id == user.id
    end

    test "returns error for wrong password" do
      email = unique_email()
      {:ok, _} = Accounts.register_user(%{email: email, password: "supersecretpass123"})

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_by_email_password(email, "wrongpassword12")
    end

    test "returns error for nonexistent email" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_by_email_password("nobody@example.com", "doesntmatter1")
    end
  end

  describe "get_user_by_email/1" do
    test "returns user by email" do
      email = unique_email()
      {:ok, user} = Accounts.register_user(%{email: email, password: "supersecretpass123"})

      found = Accounts.get_user_by_email(email)
      assert found.id == user.id
    end

    test "returns nil for unknown email" do
      assert Accounts.get_user_by_email("nobody@example.com") == nil
    end
  end

  defp unique_oidc_attrs(overrides \\ %{}) do
    unique = System.unique_integer([:positive])

    Map.merge(
      %{@valid_attrs | email: "test-#{unique}@example.com", oidc_sub: "sub-#{unique}"},
      overrides
    )
  end

  defp unique_email do
    "test-#{System.unique_integer([:positive])}@example.com"
  end
end
