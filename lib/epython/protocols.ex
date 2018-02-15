defprotocol EPython.PyIterable do
  @doc "Create an iterator for a data structure."
  def iter(data)
end

defprotocol EPython.PyIterator do
  @doc "Return the next element in the iterator"
  def next(iterator)
end

defprotocol EPython.PyCallable do
  @doc "Call a function"
  def call(func, args, state)
end

# some default implementations are provided here for elixir types.
defimpl EPython.PyCallable, for: EPython.PyBuiltinFunction do
  def call(func, args, state) do
      frame = state.topframe
      result = func.function.(args)

      stack = [result | frame.stack]
      frame = %{frame | stack: stack}

      %{state | topframe: frame}
  end
end

defimpl EPython.PyCallable, for: EPython.PyUserFunction do
  def call(func, args, state) do
      frame = state.topframe
      pairs = Enum.zip(Tuple.to_list(func.code[:varnames]), args)

      variables = Enum.reduce(pairs, %{}, fn {name, value}, variables ->
        Map.put(variables, name, value)
      end)

      frame = %{frame | stack: frame.stack}
      func_frame = %EPython.PyFrame{code: func.code, variables: variables, previous_frame: frame}

      %{state | topframe: func_frame}
  end
end
