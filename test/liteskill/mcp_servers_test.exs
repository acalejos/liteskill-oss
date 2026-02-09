defmodule Liteskill.McpServersTest do
  use Liteskill.DataCase, async: true

  alias Liteskill.McpServers
  alias Liteskill.McpServers.McpServer

  setup do
    {:ok, owner} =
      Liteskill.Accounts.find_or_create_from_oidc(%{
        email: "owner-#{System.unique_integer([:positive])}@example.com",
        name: "Owner",
        oidc_sub: "owner-#{System.unique_integer([:positive])}",
        oidc_issuer: "https://test.example.com"
      })

    {:ok, other} =
      Liteskill.Accounts.find_or_create_from_oidc(%{
        email: "other-#{System.unique_integer([:positive])}@example.com",
        name: "Other",
        oidc_sub: "other-#{System.unique_integer([:positive])}",
        oidc_issuer: "https://test.example.com"
      })

    %{owner: owner, other: other}
  end

  describe "create_server/1" do
    test "creates server with valid attrs", %{owner: owner} do
      attrs = %{name: "My Server", url: "https://mcp.example.com", user_id: owner.id}

      assert {:ok, server} = McpServers.create_server(attrs)
      assert server.name == "My Server"
      assert server.url == "https://mcp.example.com"
      assert server.user_id == owner.id
      assert server.status == "active"
      assert server.global == false
      assert server.headers == %{}
    end

    test "creates server with all optional fields", %{owner: owner} do
      attrs = %{
        name: "Full Server",
        url: "https://mcp.example.com",
        user_id: owner.id,
        api_key: "secret-key",
        description: "A test server",
        headers: %{"X-Custom" => "value"},
        status: "inactive",
        global: true
      }

      assert {:ok, server} = McpServers.create_server(attrs)
      assert server.api_key == "secret-key"
      assert server.description == "A test server"
      assert server.headers == %{"X-Custom" => "value"}
      assert server.status == "inactive"
      assert server.global == true
    end

    test "fails without required name", %{owner: owner} do
      attrs = %{url: "https://mcp.example.com", user_id: owner.id}

      assert {:error, %Ecto.Changeset{}} = McpServers.create_server(attrs)
    end

    test "fails without required url", %{owner: owner} do
      attrs = %{name: "Server", user_id: owner.id}

      assert {:error, %Ecto.Changeset{}} = McpServers.create_server(attrs)
    end

    test "fails without required user_id" do
      attrs = %{name: "Server", url: "https://mcp.example.com"}

      assert {:error, %Ecto.Changeset{}} = McpServers.create_server(attrs)
    end

    test "fails with invalid status", %{owner: owner} do
      attrs = %{
        name: "Server",
        url: "https://mcp.example.com",
        user_id: owner.id,
        status: "bogus"
      }

      assert {:error, %Ecto.Changeset{}} = McpServers.create_server(attrs)
    end
  end

  describe "list_servers/1" do
    test "lists own servers", %{owner: owner} do
      {:ok, _} =
        McpServers.create_server(%{name: "S1", url: "https://s1.example.com", user_id: owner.id})

      servers = McpServers.list_servers(owner.id)
      assert length(servers) == 1
      assert hd(servers).name == "S1"
    end

    test "includes global servers from other users", %{owner: owner, other: other} do
      {:ok, _} =
        McpServers.create_server(%{
          name: "Global",
          url: "https://global.example.com",
          user_id: other.id,
          global: true
        })

      servers = McpServers.list_servers(owner.id)
      assert length(servers) == 1
      assert hd(servers).name == "Global"
    end

    test "excludes private servers from other users", %{owner: owner, other: other} do
      {:ok, _} =
        McpServers.create_server(%{
          name: "Private",
          url: "https://private.example.com",
          user_id: other.id
        })

      assert McpServers.list_servers(owner.id) == []
    end

    test "orders by name", %{owner: owner} do
      {:ok, _} =
        McpServers.create_server(%{
          name: "Bravo",
          url: "https://b.example.com",
          user_id: owner.id
        })

      {:ok, _} =
        McpServers.create_server(%{
          name: "Alpha",
          url: "https://a.example.com",
          user_id: owner.id
        })

      servers = McpServers.list_servers(owner.id)
      assert Enum.map(servers, & &1.name) == ["Alpha", "Bravo"]
    end
  end

  describe "get_server/2" do
    test "returns own server", %{owner: owner} do
      {:ok, server} =
        McpServers.create_server(%{
          name: "Mine",
          url: "https://mine.example.com",
          user_id: owner.id
        })

      assert {:ok, found} = McpServers.get_server(server.id, owner.id)
      assert found.id == server.id
    end

    test "returns global server from another user", %{owner: owner, other: other} do
      {:ok, server} =
        McpServers.create_server(%{
          name: "Global",
          url: "https://global.example.com",
          user_id: other.id,
          global: true
        })

      assert {:ok, found} = McpServers.get_server(server.id, owner.id)
      assert found.id == server.id
    end

    test "returns not_found for others' private server", %{owner: owner, other: other} do
      {:ok, server} =
        McpServers.create_server(%{
          name: "Private",
          url: "https://private.example.com",
          user_id: other.id
        })

      assert {:error, :not_found} = McpServers.get_server(server.id, owner.id)
    end

    test "returns not_found for nonexistent id", %{owner: owner} do
      assert {:error, :not_found} = McpServers.get_server(Ecto.UUID.generate(), owner.id)
    end
  end

  describe "update_server/3" do
    test "owner can update own server", %{owner: owner} do
      {:ok, server} =
        McpServers.create_server(%{
          name: "Old",
          url: "https://old.example.com",
          user_id: owner.id
        })

      assert {:ok, updated} = McpServers.update_server(server, owner.id, %{name: "New"})
      assert updated.name == "New"
    end

    test "non-owner cannot update", %{owner: owner, other: other} do
      {:ok, server} =
        McpServers.create_server(%{
          name: "Server",
          url: "https://s.example.com",
          user_id: owner.id,
          global: true
        })

      assert {:error, :forbidden} = McpServers.update_server(server, other.id, %{name: "Hacked"})
    end

    test "returns changeset error for invalid update", %{owner: owner} do
      {:ok, server} =
        McpServers.create_server(%{
          name: "Server",
          url: "https://s.example.com",
          user_id: owner.id
        })

      assert {:error, %Ecto.Changeset{}} =
               McpServers.update_server(server, owner.id, %{status: "bogus"})
    end
  end

  describe "delete_server/2" do
    test "owner can delete own server", %{owner: owner} do
      {:ok, server} =
        McpServers.create_server(%{
          name: "Server",
          url: "https://s.example.com",
          user_id: owner.id
        })

      assert {:ok, _} = McpServers.delete_server(server.id, owner.id)
      assert McpServers.list_servers(owner.id) == []
    end

    test "non-owner cannot delete", %{owner: owner, other: other} do
      {:ok, server} =
        McpServers.create_server(%{
          name: "Server",
          url: "https://s.example.com",
          user_id: owner.id,
          global: true
        })

      assert {:error, :forbidden} = McpServers.delete_server(server.id, other.id)
    end

    test "returns not_found for nonexistent id", %{owner: owner} do
      assert {:error, :not_found} = McpServers.delete_server(Ecto.UUID.generate(), owner.id)
    end
  end

  describe "changeset/2" do
    test "validates status inclusion" do
      changeset =
        McpServer.changeset(%McpServer{}, %{
          name: "S",
          url: "https://s.example.com",
          user_id: Ecto.UUID.generate(),
          status: "unknown"
        })

      refute changeset.valid?
      assert errors_on(changeset)[:status]
    end
  end
end
