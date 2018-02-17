defmodule EPython.PyFrame do
  @enforce_keys [:code]

  defstruct [:code, {:blocks, []}, {:pc, 0}, {:variables, %{}}, {:stack, []}, :previous_frame]
end

defmodule EPython.PyBlock do
  @enforce_keys [:type, :level]

  defstruct [:type, :level]
end
