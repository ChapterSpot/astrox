defmodule Astrox do
  @moduledoc """
  The main module for interacting with Salesforce
  """

  require Logger

  @type client :: map
  @type astrox_response :: map | {number, any} | String.t
  @type method :: :get | :put | :post | :patch | :delete

  @api Application.get_env(:astrox, :api) || Astrox.Api.Http

  @spec json_request(method, String.t, map | String.t, list, list) :: astrox_response
  def json_request(method, url, body, headers, options) do
    @api.raw_request(method, url, format_body(body), headers, options)
  end

  @spec post(String.t, map | String.t, client) :: astrox_response
  def post(path, body \\ "", client) do
    url = client.endpoint <> path
    headers = [{"Content-Type", "application/json"}]
    json_request(:post, url, body, headers ++ client.authorization_header, [])
  end

  @spec patch(String.t, String.t, client) :: astrox_response
  def patch(path, body \\ "", client) do
    url = client.endpoint <> path
    headers = [{"Content-Type", "application/json"}]
    json_request(:patch, url, body, headers ++ client.authorization_header, [])
  end

  @spec delete(String.t, client) :: astrox_response
  def delete(path, client) do
    url = client.endpoint <> path
    @api.raw_request(:delete, url, "", client.authorization_header, [])
  end

  @spec get(String.t, map | String.t, list, client) :: astrox_response
  def get(path, body \\ "", headers \\ [], client) do
    url = client.endpoint <> path
    json_request(:get, url, body, headers ++ client.authorization_header, [])
  end

  @spec versions(client) :: astrox_response
  def versions(%Astrox.Client{} = client) do
    get("/services/data", client)
  end

  @spec services(client) :: astrox_response
  def services(%Astrox.Client{} = client) do
    get("/services/data/v#{client.api_version}", client)
  end

  @basic_services [
    limits: :limits,
    describe_global: :sobjects,
    quick_actions: :quickActions,
    recently_viewed_items: :recent,
    tabs: :tabs,
    theme: :theme,
  ]

  for {function, service} <- @basic_services do
    @spec unquote(function)(client) :: astrox_response
    def unquote(function)(%Astrox.Client{} = client) do
      client
      |> service_endpoint(unquote(service))
      |> get(client)
    end
  end

  @spec describe_sobject(String.t, client) :: astrox_response
  def describe_sobject(sobject, %Astrox.Client{} = client) do
    base = service_endpoint(client, :sobjects)

    "#{base}/#{sobject}/describe/"
    |> get(client)
  end

  def attachment_body(binary_path, %Astrox.Client{} = client) do
    base = service_endpoint(client, :sobjects)

    "#{base}/Attachment/#{binary_path}/Body"
    |> get(client)
  end

  @spec metadata_changes_since(String.t, String.t, client) :: astrox_response
  def metadata_changes_since(sobject, since, client) do
    base = service_endpoint(client, :sobjects)

    "#{base}/#{sobject}/describe/"
    |> get("", [{"If-Modified-Since", since}], client)
  end

  @spec composite_query(map, client) :: astrox_response
  def composite_query(body, %Astrox.Client{} = client) do
    service_endpoint(client, :composite)
    |> post(body, client)
  end

  @spec query(String.t, client) :: astrox_response
  def query(query, %Astrox.Client{} = client) do
    base = service_endpoint(client, :query)
    params = %{"q" => query} |> URI.encode_query

    "#{base}/?#{params}"
    |> get(client)
  end

  @spec query_all(String.t, client) :: astrox_response
  def query_all(query, %Astrox.Client{} = client) do
    base = service_endpoint(client, :queryAll)
    params = %{"q" => query} |> URI.encode_query

    "#{base}/?#{params}"
    |> get(client)
  end

  @spec service_endpoint(client, atom) :: String.t
  defp service_endpoint(%Astrox.Client{services: services}, service) do
    Map.get(services, service)
  end

  defp format_body(""), do: ""
  defp format_body(body), do: Poison.encode!(body)
end
