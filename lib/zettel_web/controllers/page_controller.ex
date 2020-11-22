defmodule ZettelWeb.PageController do
  use ZettelWeb, :controller

  alias Zettel.Document

  def index(conn, _params) do
    conn
    |> assign(:document, Document.fetch_document("test path"))
    |> render("index.html")
  end
end
