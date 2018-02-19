defprotocol EPython.PyRepresentable do
  @fallback_to_any true
  def represent(object, state)
end

defimpl EPython.PyRepresentable, for: BitString do
  def represent(object, state), do: {inspect(to_charlist object), state}
end

defimpl EPython.PyRepresentable, for: Any do
  def represent(object, state), do: {inspect(object), state}
end
