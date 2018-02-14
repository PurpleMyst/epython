defmodule EPython.PyFrame do
  @enforce_keys [:code]
  defstruct [:code, {:pc, 0}, {:variables, %{}}, {:stack, []}]
end

defmodule EPython.PyBuiltinFunction do
  @enforce_keys [:function]

  defstruct [{:name, "<unknown_builtin>"}, :function]
end
