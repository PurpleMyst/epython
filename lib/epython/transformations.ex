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

  def peek_stack(state, offset) do
    Enum.at(state.topframe.stack, offset)
  end

  def is_pyobject(%EPython.PyList{}), do: true
  def is_pyobject(_), do: false

  def apply_to_stack(state, f, target \\ nil) do
    # TODO: when we implement user-defined classes, do we need to handle those
    # specially?

    # TODO: Is there a better way to get a function's arity?
    # TODO: If not, turn this into a loop.
    arity = cond do
      is_function(f, 1) -> 1
      is_function(f, 2) -> 2
      is_function(f, 3) -> 3
    end

    {raw_args = args, state} = pop_from_stack state, arity
    {args, state} = resolve_references state, args, false  # TODO: true or false?
    result = apply(f, args)

    case target do
      {:tos, offset} ->
        # I don't think that it matters here that this has linear time.
        # We only ever look for at most the second-to-top item.

        case Enum.at raw_args, offset do
          %EPython.PyReference{id: id} ->
            objects = %{state.objects | id => result}
            %{state | objects: objects}

          _ ->
            if is_pyobject(result) do
              raise ArgumentError, message: "This shouldn't happen."
            else
              push_to_stack state, result
            end
        end

      nil ->
        {result, state} =
          if is_pyobject(result) do
            create_reference state, result
          else
            {result, state}
          end

        if result == :notimplemented do
          raise RuntimeError, "Could not apply #{inspect f} for #{inspect args}"
        else
          push_to_stack state, result
        end
    end
  end

  defp put_or_update(map, name, value) when is_map(map) do
    if Map.has_key?(map, name) do
      %{map | name => value}
    else
      Map.put(map, name, value)
    end
  end

  def store_variable(state, name, value) do
    frame = state.topframe
    variables = put_or_update frame.variables, name, value

    frame = %{frame | variables: variables}
    state = %{state | topframe: frame}
    increment_refcount state, value
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
      parent -> fetch_module_frame parent
    end
  end

  def get_module_frame(state) do
    fetch_module_frame state.topframe
  end

  def create_block(state, delta, type) do
    frame = state.topframe
    # TODO: Figure out how to set level.
    block = %EPython.PyBlock{type: type, level: nil, handler: frame.pc + delta}
    frame = %{frame | blocks: [block | frame.blocks]}
    %{state | topframe: frame}
  end

  def create_reference(state, object) do
    id = state.next_id
    objects = state.objects

    objects = Map.put(objects, id, object)
    reference = %EPython.PyReference{id: id}

    state = %{state | objects: objects}
    state = %{state | next_id: id + 1}

    {reference, state}
  end

  def resolve_reference(state, ref, should_increment_refcount \\ true)

  def resolve_reference(state, ref = %EPython.PyReference{id: id}, should_increment_refcount) do
    object = state.objects[id]

    if object == nil do
      raise RuntimeError, message: "Unknown id #{inspect id}"
    else
      state =
        if should_increment_refcount do
          increment_refcount state, ref
        else
          state
        end

      {object, state}
    end
  end

  def resolve_reference(state, object, _) do
    {object, state}
  end

  def resolve_references(state, refs, increment_refcount \\ true)

  def resolve_references(state, [reference | rest], increment_refcount) do
    {object, state} = resolve_reference state, reference, increment_refcount
    {objects, state} = resolve_references state, rest, increment_refcount
    {[object | objects], state}
  end

  def resolve_references(state, [], _) do
    {[], state}
  end

  def increment_refcount(state, %EPython.PyReference{id: id}) do
    refcounts = Map.update state.refcounts, id, 1, &(&1 - 1)
    %{state | refcounts: refcounts}
  end

  def increment_refcount(state, _) do
    state
  end

  def decrement_refcount(state, %EPython.PyReference{id: id}) do
    refcounts = Map.update! state.refcounts, id, &(&1 - 1)

    # TODO: Merge the two paths?
    # TODO: Manage cyclical references.
    if refcounts[id] == 0 do
      refcounts = Map.delete(refcounts, id)
      objects = Map.delete(state.objects, id)
      state = %{state | objects: objects}
      %{state | refcounts: refcounts}
    else
      %{state | refcounts: refcounts}
    end
  end

  def decrement_refcount(state, _) do
    state
  end

  def jump_forward(state, delta) do
    frame = state.topframe
    # apparently there's no need to subtract 2 cause the cpython interpreter
    # also always adds 2 to the pc so JUMP_FORWARD takes that into account and
    # it's really dumb.
    frame = %{frame | pc: frame.pc + delta}

    %{state | topframe: frame}
  end
end
