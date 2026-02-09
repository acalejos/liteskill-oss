defmodule LiteskillWeb.PageController do
  use LiteskillWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
