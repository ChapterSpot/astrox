defmodule Astrox.Auth do
  @moduledoc """
    Auth behavior
  """

  @callback login(config :: map(), struct) :: map()
end
