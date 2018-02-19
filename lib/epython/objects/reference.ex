defmodule EPython.PyReference do
  @enforce_keys [:id]

  defstruct [:id]
end

defimpl EPython.PyRepresentable, for: EPython.PyReference do
  def represent(reference, state) do
    {object, state} = EPython.Transformations.resolve_reference state, reference
    EPython.PyRepresentable.represent object, state
  end
end
