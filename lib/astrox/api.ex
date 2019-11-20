defmodule Astrox.API do
  @moduledoc """
  Behavior for requests to Salesforce API
  """

  alias Astrox.Http

  @callback raw_request(
              Http.method(),
              Http.url(),
              Http.body(),
              Http.headers(),
              Http.options()
            ) :: Http.response()
end
