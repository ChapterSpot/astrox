defmodule Astrox.Auth do
  @moduledoc """
    Auth behavior
  """

  @callback login(map, struct) :: map
end
