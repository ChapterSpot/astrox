defmodule Astrox.Api do
  @moduledoc """
  Behavior for requests to Salesforce API
  """

  @type method :: :get | :put | :post | :patch | :delete
  @type astrox_response :: map | {number, any} | String.t

  @callback raw_request(method, String.t, map | String.t, list, list) :: astrox_response
end
