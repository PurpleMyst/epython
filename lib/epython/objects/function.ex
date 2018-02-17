defmodule EPython.PyBuiltinFunction do
  @enforce_keys [:function]

  defstruct [{:name, "<unknown_builtin>"}, :function]
end

defmodule EPython.PyUserFunction do
  @enforce_keys [:name, :code]

  defstruct [:name, :code]
end