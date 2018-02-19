defprotocol EPython.PyStringable do
  @fallback_to_any true
  def stringify(object, state)
end

defimpl EPython.PyStringable, for: BitString do
  def stringify(object, state), do: {object, state}
end

defimpl EPython.PyStringable, for: Any do
  def stringify(object, state), do: {inspect(object), state}
end
