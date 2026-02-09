defmodule LiteskillWeb.FallbackControllerTest do
  use LiteskillWeb.ConnCase, async: true

  alias LiteskillWeb.FallbackController

  test "handles {:error, :not_found}", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> FallbackController.call({:error, :not_found})

    assert json_response(conn, 404)["error"] == "not found"
  end

  test "handles {:error, %Ecto.Changeset{}}", %{conn: conn} do
    changeset = %Ecto.Changeset{errors: [title: {"can't be blank", []}], valid?: false}

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> FallbackController.call({:error, changeset})

    assert json_response(conn, 422)["error"] == "validation failed"
  end

  test "handles {:error, reason}", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> FallbackController.call({:error, :some_reason})

    assert json_response(conn, 422)["error"] == ":some_reason"
  end
end
