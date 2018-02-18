defmodule EPython.PyBuiltinFunction do
  @enforce_keys [:function]

  defstruct [{:name, "<unknown_builtin>"}, :function]
end

defmodule EPython.PyUserFunction do
  @enforce_keys [:name, :code, :default_posargs, :default_kwargs]

  defstruct [
    :name,  # The name of the function
    :code,  # The code object of the function
    :default_posargs,  # The default positional arguments of the function
    :default_kwargs, # The default keyword-only arguments of the function
  ]
end

defimpl EPython.PyCallable, for: EPython.PyBuiltinFunction do
  def call(func, args, state) do
      {result, state} = func.function.(args, state)
      EPython.Transformations.push_to_stack state, result
  end
end

defimpl EPython.PyCallable, for: EPython.PyUserFunction do
  def call(func, args, state) do
      state = Enum.reduce(args, state, &EPython.Transformations.increment_refcount(&2, &1))
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
