defprotocol EPython.PyIterable do
  @doc "Create an iterator for a data structure."
  def iter(data)
end

defprotocol EPython.PyIterator do
  @doc "Return the next element in the iterator"
  def next(iterator)
end

