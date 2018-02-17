defprotocol EPython.PyCallable do
  @doc "Call a function"
  def call(func, args, state)
end

defimpl EPython.PyCallable, for: EPython.PyBuiltinFunction do
  def call(func, args, state) do
      {result, state} = func.function.(args, state)
      EPython.Transformations.push_to_stack state, result
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
