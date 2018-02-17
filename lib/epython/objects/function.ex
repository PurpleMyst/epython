defmodule EPython.PyBuiltinFunction do
  @enforce_keys [:function]

  defstruct [{:name, "<unknown_builtin>"}, :function]
end

defmodule EPython.PyUserFunction do
  @enforce_keys [:name, :code]

  defstruct [:name, :code]
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
