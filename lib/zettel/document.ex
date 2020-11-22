defmodule Zettel.Document do
  def fetch_document(file_path) do
    with {:ok, markdown_content} <- read_local_file_content(file_path),
         [yaml | body_segments] <- markdown_content |> String.split("---\n", trim: true),
         {:ok, metadata} <- parse_yaml_metadata(yaml),
         {:ok, html_content, _} <- body_segments |> Enum.join("---\n") |> markdown_to_html
    do
      %{
        metadata: metadata,
        html: html_content
      }
    else
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error while fetching document"}
    end
  end

  defp parse_yaml_metadata(yaml), do: YamlElixir.read_from_string(yaml)

  defp markdown_to_html(markdown_content) do
    markdown_content
    |> normalize_markdown
    |> Earmark.as_html
  end

  defp normalize_markdown(markdown) do
    markdown
    |> replace_named_wiki_links
    |> replace_unnamed_wiki_links
  end

  defp replace_named_wiki_links(markdown) do
    Regex.replace(~r/\[\[(.*?)\|(.*?)\]\]/, markdown, "[\\2](\\1)")
  end

  defp replace_unnamed_wiki_links(markdown) do
    Regex.replace(~r/\[\[(.*?)\]\]/, markdown, "[\\1](\\1)")
  end

  defp read_local_file_content(_file_path) do
    {:ok, "---\ntitle: Test\n---\n\n[[Some link|my tesxt]]\n\n- Bullet 1\n- Bullet 2"}
  end
end
