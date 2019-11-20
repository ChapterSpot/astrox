defmodule Astrox.Auth.OAuth do
  @moduledoc """
  Auth via OAuth
  """

  require Logger

  alias Astrox.Client

  @behaviour Astrox.Auth

  @spec login(map(), Client.t()) :: map()
  def login(%{refresh_token: _} = conf, %Client{} = client) do
    login_payload =
      conf
      |> Map.put(:grant_type, "refresh_token")
      |> Map.delete(:endpoint)

    "/services/oauth2/token?#{URI.encode_query(login_payload)}"
    |> Astrox.post("", client)
    |> handle_login_response()
    |> maybe_add_api_version(client)
  end

  def login(conf, client) do
    login_payload =
      conf
      |> Map.put(:password, "#{conf.password}#{conf.security_token}")
      |> Map.put(:grant_type, "password")
      |> Map.delete(:endpoint)

    "/services/oauth2/token?#{URI.encode_query(login_payload)}"
    |> Astrox.post("", client)
    |> handle_login_response()
    |> maybe_add_api_version(client)
  end

  @spec handle_login_response(any()) :: map()
  defp handle_login_response(%{
         access_token: token,
         token_type: token_type,
         instance_url: endpoint
       }) do
    %{
      authorization_header: authorization_header(token, token_type),
      endpoint: endpoint
    }
  end

  defp handle_login_response({status_code, error_message}) do
    Logger.warn(
      "Cannot log into SFDC API. Please ensure you have Astrox properly configured. Got error code #{
        status_code
      } and message #{inspect(error_message)}"
    )

    %{}
  end

  defp handle_login_response(resp) do
    Logger.warn(
      "Cannot log into SFDC API. Please ensure you have Astrox properly configured. Unexpected response: #{
        inspect(resp)
      }"
    )

    %{}
  end

  defp maybe_add_api_version(client_map, %{api_version: api_version}) do
    Map.put(client_map, :api_version, api_version)
  end

  defp maybe_add_api_version(client_map, _) do
    client_map
  end

  @spec authorization_header(token :: String.t(), type :: String.t()) :: list
  defp authorization_header(nil, _), do: []

  defp authorization_header(token, type) do
    [{"Authorization", type <> " " <> token}]
  end
end
