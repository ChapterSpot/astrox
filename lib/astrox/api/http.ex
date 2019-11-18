defmodule Astrox.Api.Http do
  @moduledoc """
  HTTP communication with Salesforce API
  """

  @behaviour Astrox.Api
  require Logger
  use HTTPoison.Base

  @user_agent [{"User-agent", "astrox"}]
  @accept [{"Accept", "application/json"}]
  @accept_encoding [{"Accept-Encoding", "gzip,deflate"}]

  @impl Astrox.Api
  def raw_request(method, url, body, headers, options) do
    response =
      method |> request!(url, body, headers, extra_options() ++ options) |> process_response

    Logger.debug("#{__ENV__.module}.#{elem(__ENV__.function, 0)} response=" <> inspect(response))
    response
  end

  @spec extra_options :: list
  defp extra_options() do
    Application.get_env(:astrox, :request_options, [])
  end

  @impl HTTPoison.Base
  def process_response(response) do
    response
    |> maybe_gunzip()
    |> maybe_deflate()
    |> maybe_json_decode()
    |> unpack_body()
  end

  defp maybe_gunzip(
         %HTTPoison.Response{body: body, headers: %{"Content-Encoding" => "gzip"} = headers} =
           resp
       ) do
    %{resp | body: :zlib.gunzip(body), headers: Map.drop(headers, ["Content-Encoding"])}
  end

  defp maybe_gunzip(resp), do: resp

  defp maybe_deflate(
         %HTTPoison.Response{body: body, headers: %{"Content-Encoding" => "deflate"} = headers} =
           resp
       ) do
    zstream = :zlib.open()
    :ok = :zlib.inflateInit(zstream, -15)
    uncompressed_data = zstream |> :zlib.inflate(body) |> Enum.join()
    :zlib.inflateEnd(zstream)
    :zlib.close(zstream)

    %{resp | body: uncompressed_data, headers: Map.drop(headers, ["Content-Encoding"])}
  end

  defp maybe_deflate(resp), do: resp

  defp maybe_json_decode(
         %HTTPoison.Response{
           body: body,
           headers: %{"Content-Type" => "application/json" <> _} = headers
         } = resp
       ) do
    decoded_body = Poison.decode!(body, keys: :atoms)
    %{resp | body: decoded_body, headers: Map.drop(headers, ["Content-Type"])}
  end

  defp maybe_json_decode(resp), do: resp

  defp unpack_body(%HTTPoison.Response{body: body, status_code: 200}), do: body
  defp unpack_body(%HTTPoison.Response{body: body, status_code: status}), do: {status, body}

  @impl HTTPoison.Base
  def process_request_headers(headers), do: headers ++ @user_agent ++ @accept ++ @accept_encoding

  @impl HTTPoison.Base
  def process_headers(headers), do: Map.new(headers)
end
