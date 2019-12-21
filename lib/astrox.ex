defmodule Astrox do
  @moduledoc """
  The main module for interacting with Salesforce
  """

  require Logger

  alias Astrox.{Client, Http}

  @api Application.get_env(:astrox, :api) || Astrox.API.RestAPI

  @type astrox_response :: map | {number, any} | String.t()

  @spec json_request(Http.method(), Http.url(), Http.body(), Http.headers(), Http.options()) ::
          astrox_response
  def json_request(method, url, body, headers \\ [], options \\ []) do
    @api.raw_request(method, url, format_body(body), headers, options)
  end

  @spec post(Http.path(), Http.body(), Client.t(), Http.headers(), Http.options()) ::
          astrox_response()
  def post(path, body, client, headers \\ [], options \\ []) do
    url = client.endpoint <> path
    headers = [{"Content-Type", "application/json"} | headers]
    json_request(:post, url, body, headers ++ client.authorization_header, options)
  end

  @spec patch(Http.path(), Http.body(), Client.t(), Http.headers(), Http.options()) ::
          astrox_response()
  def patch(path, body, client, headers \\ [], options \\ []) do
    url = client.endpoint <> path
    headers = [{"Content-Type", "application/json"} | headers]
    json_request(:patch, url, body, headers ++ client.authorization_header, options)
  end

  @spec delete(Http.path(), Client.t(), Http.headers(), Http.options()) :: astrox_response()
  def delete(path, client, headers \\ [], options \\ []) do
    url = client.endpoint <> path
    @api.raw_request(:delete, url, "", headers ++ client.authorization_header, options)
  end

  @spec get(Http.path(), Client.t(), Http.headers(), Http.options()) :: astrox_response()
  def get(path, client, headers \\ [], options \\ []) do
    url = client.endpoint <> path
    json_request(:get, url, "", headers ++ client.authorization_header, options)
  end

  @spec versions(Client.t()) :: astrox_response()
  def versions(%Client{} = client) do
    get("/services/data", client)
  end

  @spec services(Client.t()) :: astrox_response()
  def services(%Client{} = client) do
    get("/services/data/v#{client.api_version}", client)
  end

  @basic_services [
    limits: :limits,
    describe_global: :sobjects,
    quick_actions: :quickActions,
    recently_viewed_items: :recent,
    tabs: :tabs,
    theme: :theme
  ]

  for {function, service} <- @basic_services do
    @spec unquote(function)(Client.t()) :: astrox_response()
    def unquote(function)(%Client{} = client) do
      client
      |> service_endpoint(unquote(service))
      |> get(client)
    end
  end

  @spec describe_sobject(String.t(), Client.t()) :: astrox_response()
  def describe_sobject(sobject, %Client{} = client) do
    base = service_endpoint(client, :sobjects)

    "#{base}/#{sobject}/describe/"
    |> get(client)
  end

  @spec attachment_body(String.t(), Client.t()) :: astrox_response()
  def attachment_body(binary_path, %Client{} = client) do
    base = service_endpoint(client, :sobjects)

    "#{base}/Attachment/#{binary_path}/Body"
    |> get(client)
  end

  @spec metadata_changes_since(String.t(), String.t(), Client.t()) :: astrox_response()
  def metadata_changes_since(sobject, since, client) do
    base = service_endpoint(client, :sobjects)
    headers = [{"If-Modified-Since", since}]

    "#{base}/#{sobject}/describe/"
    |> get(client, headers)
  end

  @spec composite_query(Http.body(), Client.t()) :: astrox_response()
  def composite_query(body, %Client{} = client) do
    client
    |> service_endpoint(:composite)
    |> post(body, client)
  end

  @spec query(String.t(), Client.t()) :: astrox_response()
  def query(query, %Client{} = client) do
    base = service_endpoint(client, :query)
    params = %{"q" => query} |> URI.encode_query()

    "#{base}/?#{params}"
    |> get(client)
  end

  @spec query_all(String.t(), Client.t()) :: astrox_response()
  def query_all(query, %Astrox.Client{} = client) do
    base = service_endpoint(client, :queryAll)
    params = %{"q" => query} |> URI.encode_query()

    "#{base}/?#{params}"
    |> get(client)
  end

  @spec service_endpoint(Client.t(), atom) :: String.t()
  defp service_endpoint(%Client{services: services}, service) do
    Map.get(services, service)
  end

  @spec format_body(any) :: String.t()
  defp format_body(""), do: ""
  defp format_body(body), do: Poison.encode!(body)
end
