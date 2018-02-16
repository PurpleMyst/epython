# This module is for things that compose instructions.
# Basically helper functions but with more fluff.

defmodule EPython.Transformations do
  def pop_from_stack(state) do
    frame = state.topframe
    [tos | stack] = frame.stack
    frame = %{frame | stack: stack}
    {tos, %{state | topframe: frame}}
  end

  def pop_from_stack(state, 0), do: {[], state}

  def pop_from_stack(state, n) when n > 0 do
    frame = state.topframe
    {values, stack} = Enum.reduce((1..n), {[], frame.stack}, fn _, {values, [tos | stack]} ->
      {[tos | values], stack}
    end)
    frame = %{frame | stack: stack}
    {values, %{state | topframe: frame}}
  end

  def push_to_stack(state, value) do
    frame = state.topframe
    frame = %{frame | stack: [value | frame.stack]}
    %{state | topframe: frame}
  end

  def apply_unary(state, f) when is_function(f) do
    {value, state} = pop_from_stack state
    value = f.(value)
    push_to_stack state, value
  end

  def apply_binary(state, f) when is_function(f) do
    {[x, y], state} = pop_from_stack state, 2
    push_to_stack state, f.(x, y)
  end

  defp put_or_update(map, name, value) when is_map(map) do
    if Map.has_key?(map, name) do
      %{map | name => value}
    else
      Map.put(map, name, value)
    end
  end

  def store_variable(state, name, value) do
    # TODO: Increment reference count.
    frame = state.topframe
    variables = put_or_update frame.variables, name, value
    frame = %{frame | variables: variables}
    %{state | topframe: frame}
  end

  defp fetch_variable(frame, name, check_parents) do
    if Map.has_key?(frame.variables, name) do
      frame.variables[name]
    else
      if not check_parents or frame.previous_frame == nil do
        EPython.Interpreter.builtins()[name]
      else
        fetch_variable frame.previous_frame, name, check_parents
      end
    end
  end

  def load_variable(where, name, check_parents \\ false) do
    where = case where do
      %EPython.InterpreterState{} -> where.topframe
      _ -> where
    end

    value = fetch_variable where, name, check_parents

    if value == nil do
      raise RuntimeError, message: "Could not find variable #{inspect name}"
    else
      value
    end
  end

  defp fetch_module_frame(frame) do
    case frame.previous_frame do
      nil    -> frame
      parent -> get_module_frame parent
    end
  end

  def get_module_frame(state) do
    fetch_module_frame state.topframe
  end

  def create_block(state, delta, type) do
    frame = state.topframe
    block = %EPython.PyBlock{type: type, level: frame.pc + delta}
    frame = %{frame | blocks: [block | frame.blocks]}
    %{state | topframe: frame}
  end
end
