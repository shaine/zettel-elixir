defmodule Zettel.Document do
  def fetch_document(file_path) do
    with {:ok, file_content} <- read_local_file_content(file_path),
         %{yaml: yaml, markdown: markdown} <- split_metadata_from_content(file_content),
         {:ok, hash} <- get_hash(file_content),
         {:ok, content_metadata} <- parse_yaml_metadata(yaml),
         {:ok, html, _} <- markdown_to_html(markdown)
    do
      %{
        content_metadata: content_metadata,
        file_metadata: %{
          hash: hash,
          file_name: file_path
        },
        html: html,
        document: file_content
      }
    else
      {:error, :enoent} -> {:error, "Cannot find file #{file_path}"}
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error while fetching document"}
    end
  end

  def save_document(file_path, file_content, _hash) do
    Application.get_env(:zettel, Zettel.Document)[:documents_path]
    |> Path.join(file_path)
    |> File.write(file_content)
  end

  defp split_metadata_from_content(file_content) do
    cond do
      content_starts_with_metadata?(file_content) ->
        file_content
        |> String.split("---\n", trim: true)
        |> raw_content_components
      true -> raw_content_components(file_content)
    end
  end

  defp content_starts_with_metadata?(content), do: String.match?(content, ~r/^---/)

  defp raw_content_components([yaml | markdown_segments]) do
    %{
      yaml: yaml,
      markdown: Enum.join(markdown_segments, "---\n")
    }
  end

  defp raw_content_components(markdown), do: %{yaml: nil, markdown: markdown}

  defp parse_yaml_metadata(nil), do: {:ok, nil}
  defp parse_yaml_metadata(yaml) do
    yaml
    |> quote_yaml_values
    |> YamlElixir.read_from_string
  end

  defp quote_yaml_values(yaml) do
    Regex.replace(~r/^(\w+?: )(.*)$/m, yaml, "\\1\"\\2\"")
  end

  defp markdown_to_html(markdown) do
    markdown
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

  defp read_local_file_content(file_path) do
    Application.get_env(:zettel, Zettel.Document)[:documents_path]
    |> Path.join(file_path)
    |> File.read
  end

  defp get_hash(file_content) do
    {:ok, Murmur.hash_x86_32(file_content)}
  end
end
