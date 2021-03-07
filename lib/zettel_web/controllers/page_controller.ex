defmodule ZettelWeb.PageController do
  use ZettelWeb, :controller

  alias Zettel.Document

  def index(conn, %{"path" => path}) do
    file_path = request_path_to_document_name(path)

    cond do
      !String.match?(file_path, ~r/\.md/) ->
        {:ok, content} = file_path |> read_local_file_content
        conn
        |> put_resp_content_type(Plug.MIME.path(file_path))
        |> send_resp(:ok, content)
      true -> conn |> assign(:action, action_from_request_path(path)) |> render_document(file_path)
    end
  end

  def save(conn, %{"path" => path, "hash" => hash, "content" => content}) do
    :ok = request_path_to_document_name(path) |> Document.save_document(String.replace(content, "/r", ""), hash)
    conn
      |> redirect(to: "/" <> request_path_to_document_name(path))
  end

  defp render_document(conn, file_path) do
    conn
    |> assign(:document, file_path |> Document.fetch_document)
    |> assign(:token, get_csrf_token)
    |> dynamic_render
  end

  defp dynamic_render(conn) do
    render(conn, "#{conn.assigns.action}.html")
  end

  defp action_from_request_path(request_path) do
    IO.inspect request_path
    cond do
      request_path == [] -> :show
      Path.basename(Path.join(request_path)) == "edit" -> :edit
      true -> :show
    end
  end

  defp request_path_to_document_name([]), do: request_path_to_document_name(["index"])
  defp request_path_to_document_name(request_path) do
    Path.join(request_path)
    |> String.replace(~r/\/edit$/, "")
    |> add_file_extension
  end

  defp read_local_file_content(file_path) do
    Application.get_env(:zettel, Zettel.Document)[:documents_path]
    |> Path.join(file_path)
    |> IO.inspect
    |> File.read
  end

  defp add_file_extension(file_name) do
    cond do
      Path.extname(file_name) != "" -> file_name
      true -> "#{file_name}.md"
    end
  end
end
