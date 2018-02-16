# This module is for things that compose instructions.
# Basically helper functions but with more fluff.

defmodule EPython.Transformations do
  def pop_from_stack(frame) do
    [tos | stack] = frame.stack
    {tos, %{frame | stack: stack}}
  end

  def pop_from_stack(frame, n) when n > 0 do
    {values, stack} = Enum.reduce((1..n), {[], frame.stack}, fn _, {values, [tos | stack]} ->
      {[tos | values], stack}
    end)
    {values, %{frame | stack: stack}}
  end

  def push_to_stack(frame, value) do
    # Really hope this is inlined.
    %{frame | stack: [value | frame.stack]}
  end

  def apply_unary(frame, f) when is_function(f) do
    {value, frame} = pop_from_stack frame
    value = f.(value)
    push_to_stack frame, value
  end

  def apply_binary(frame, f) when is_function(f) do
    {[x, y], frame} = pop_from_stack frame, 2
    result = f.(x, y)
    push_to_stack frame, result
  end

  defp put_or_update(map, name, value) when is_map(map) do
    if Map.has_key?(map, name) do
      %{map | name => value}
    else
      Map.put(map, name, value)
    end
  end

  def store_variable(frame, name, value) do
    variables = put_or_update frame.variables, name, value
    %{frame | variables: variables}
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

  def load_variable(frame, name, check_parents \\ false) do
    value = fetch_variable frame, name, check_parents

    if value == nil do
      raise RuntimeError, message: "Could not find variable #{inspect name}"
    else
      value
    end
  end

  def get_module_frame(frame) do
    case frame.previous_frame do
      nil    -> frame
      parent -> get_module_frame parent
    end
  end

end
