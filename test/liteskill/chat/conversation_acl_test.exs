defmodule Liteskill.Chat.ConversationAclTest do
  use Liteskill.DataCase, async: true

  alias Liteskill.Chat.ConversationAcl

  describe "changeset/2" do
    test "valid with user_id" do
      changeset =
        ConversationAcl.changeset(%ConversationAcl{}, %{
          conversation_id: Ecto.UUID.generate(),
          user_id: Ecto.UUID.generate(),
          role: "member"
        })

      assert changeset.valid?
    end

    test "valid with group_id" do
      changeset =
        ConversationAcl.changeset(%ConversationAcl{}, %{
          conversation_id: Ecto.UUID.generate(),
          group_id: Ecto.UUID.generate(),
          role: "member"
        })

      assert changeset.valid?
    end

    test "invalid without both user_id and group_id" do
      changeset =
        ConversationAcl.changeset(%ConversationAcl{}, %{
          conversation_id: Ecto.UUID.generate(),
          role: "member"
        })

      refute changeset.valid?
      assert "either user_id or group_id must be set" in errors_on(changeset).user_id
    end

    test "invalid with both user_id and group_id" do
      changeset =
        ConversationAcl.changeset(%ConversationAcl{}, %{
          conversation_id: Ecto.UUID.generate(),
          user_id: Ecto.UUID.generate(),
          group_id: Ecto.UUID.generate(),
          role: "member"
        })

      refute changeset.valid?
      assert "only one of user_id or group_id can be set" in errors_on(changeset).user_id
    end

    test "validates role inclusion" do
      changeset =
        ConversationAcl.changeset(%ConversationAcl{}, %{
          conversation_id: Ecto.UUID.generate(),
          user_id: Ecto.UUID.generate(),
          role: "superadmin"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).role
    end

    test "valid with owner role" do
      changeset =
        ConversationAcl.changeset(%ConversationAcl{}, %{
          conversation_id: Ecto.UUID.generate(),
          user_id: Ecto.UUID.generate(),
          role: "owner"
        })

      assert changeset.valid?
    end

    test "valid with viewer role" do
      changeset =
        ConversationAcl.changeset(%ConversationAcl{}, %{
          conversation_id: Ecto.UUID.generate(),
          user_id: Ecto.UUID.generate(),
          role: "viewer"
        })

      assert changeset.valid?
    end

    test "requires conversation_id" do
      changeset =
        ConversationAcl.changeset(%ConversationAcl{}, %{
          user_id: Ecto.UUID.generate(),
          role: "member"
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).conversation_id
    end
  end
end
