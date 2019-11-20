defmodule Astrox.Http do
  @moduledoc "Shared types across Astrox"
  alias HTTPoison.{Request, Response}

  @type method :: Request.method()
  @type headers :: Request.headers()
  @type url :: Request.url()
  @type path :: String.t()
  @type body :: Request.body()
  @type params :: Request.params()
  @type options :: Request.options()
  @type response :: Response.t()
  @type request :: Request.t()
end
