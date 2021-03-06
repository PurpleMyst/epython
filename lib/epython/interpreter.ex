defmodule EPython.InterpreterState do
  defstruct [
    :topframe,
    {:objects, %{}},
    {:refcounts, %{}},
    {:next_id, 0},
  ]
end

defmodule EPython.Interpreter do
  import EPython.Transformations

  def builtins do
    %{
      # TODO: Currently I set `should_increment_refcount` to false to simulate
      # a frame being created and destroyed. Can we do this in a better way?

      "print" =>
         %EPython.PyBuiltinFunction{
           name: "print",
           function: fn args, state ->
             {args, state} = resolve_references state, args, false
             {reprs, state} = Enum.map_reduce(args, state, &EPython.PyStringable.stringify/2)
             IO.puts Enum.join(reprs, " ")
             {:none, state}
           end
         },

      "len" =>
         %EPython.PyBuiltinFunction{
           name: "len",
           function: fn [sequence], state ->
             {sequence, state} = resolve_reference state, sequence, false
             {EPython.PySequence.length(sequence), state}
           end
         },
     }
  end

  # opnames {{{1
  defp opname(1), do: "POP_TOP"
  defp opname(2), do: "ROT_TWO"
  defp opname(3), do: "ROT_THREE"
  defp opname(4), do: "DUP_TOP"
  defp opname(5), do: "DUP_TOP_TWO"
  defp opname(9), do: "NOP"
  defp opname(10), do: "UNARY_POSITIVE"
  defp opname(11), do: "UNARY_NEGATIVE"
  defp opname(12), do: "UNARY_NOT"
  defp opname(15), do: "UNARY_INVERT"
  defp opname(16), do: "BINARY_MATRIX_MULTIPLY"
  defp opname(17), do: "INPLACE_MATRIX_MULTIPLY"
  defp opname(19), do: "BINARY_POWER"
  defp opname(20), do: "BINARY_MULTIPLY"
  defp opname(22), do: "BINARY_MODULO"
  defp opname(23), do: "BINARY_ADD"
  defp opname(24), do: "BINARY_SUBTRACT"
  defp opname(25), do: "BINARY_SUBSCR"
  defp opname(26), do: "BINARY_FLOOR_DIVIDE"
  defp opname(27), do: "BINARY_TRUE_DIVIDE"
  defp opname(28), do: "INPLACE_FLOOR_DIVIDE"
  defp opname(29), do: "INPLACE_TRUE_DIVIDE"
  defp opname(50), do: "GET_AITER"
  defp opname(51), do: "GET_ANEXT"
  defp opname(52), do: "BEFORE_ASYNC_WITH"
  defp opname(55), do: "INPLACE_ADD"
  defp opname(56), do: "INPLACE_SUBTRACT"
  defp opname(57), do: "INPLACE_MULTIPLY"
  defp opname(59), do: "INPLACE_MODULO"
  defp opname(60), do: "STORE_SUBSCR"
  defp opname(61), do: "DELETE_SUBSCR"
  defp opname(62), do: "BINARY_LSHIFT"
  defp opname(63), do: "BINARY_RSHIFT"
  defp opname(64), do: "BINARY_AND"
  defp opname(65), do: "BINARY_XOR"
  defp opname(66), do: "BINARY_OR"
  defp opname(67), do: "INPLACE_POWER"
  defp opname(68), do: "GET_ITER"
  defp opname(69), do: "GET_YIELD_FROM_ITER"
  defp opname(70), do: "PRINT_EXPR"
  defp opname(71), do: "LOAD_BUILD_CLASS"
  defp opname(72), do: "YIELD_FROM"
  defp opname(73), do: "GET_AWAITABLE"
  defp opname(75), do: "INPLACE_LSHIFT"
  defp opname(76), do: "INPLACE_RSHIFT"
  defp opname(77), do: "INPLACE_AND"
  defp opname(78), do: "INPLACE_XOR"
  defp opname(79), do: "INPLACE_OR"
  defp opname(80), do: "BREAK_LOOP"
  defp opname(81), do: "WITH_CLEANUP_START"
  defp opname(82), do: "WITH_CLEANUP_FINISH"
  defp opname(83), do: "RETURN_VALUE"
  defp opname(84), do: "IMPORT_STAR"
  defp opname(85), do: "SETUP_ANNOTATIONS"
  defp opname(86), do: "YIELD_VALUE"
  defp opname(87), do: "POP_BLOCK"
  defp opname(88), do: "END_FINALLY"
  defp opname(89), do: "POP_EXCEPT"
  defp opname(90), do: "STORE_NAME"
  defp opname(91), do: "DELETE_NAME"
  defp opname(92), do: "UNPACK_SEQUENCE"
  defp opname(93), do: "FOR_ITER"
  defp opname(94), do: "UNPACK_EX"
  defp opname(95), do: "STORE_ATTR"
  defp opname(96), do: "DELETE_ATTR"
  defp opname(97), do: "STORE_GLOBAL"
  defp opname(98), do: "DELETE_GLOBAL"
  defp opname(100), do: "LOAD_CONST"
  defp opname(101), do: "LOAD_NAME"
  defp opname(102), do: "BUILD_TUPLE"
  defp opname(103), do: "BUILD_LIST"
  defp opname(104), do: "BUILD_SET"
  defp opname(105), do: "BUILD_MAP"
  defp opname(106), do: "LOAD_ATTR"
  defp opname(107), do: "COMPARE_OP"
  defp opname(108), do: "IMPORT_NAME"
  defp opname(109), do: "IMPORT_FROM"
  defp opname(110), do: "JUMP_FORWARD"
  defp opname(111), do: "JUMP_IF_FALSE_OR_POP"
  defp opname(112), do: "JUMP_IF_TRUE_OR_POP"
  defp opname(113), do: "JUMP_ABSOLUTE"
  defp opname(114), do: "POP_JUMP_IF_FALSE"
  defp opname(115), do: "POP_JUMP_IF_TRUE"
  defp opname(116), do: "LOAD_GLOBAL"
  defp opname(119), do: "CONTINUE_LOOP"
  defp opname(120), do: "SETUP_LOOP"
  defp opname(121), do: "SETUP_EXCEPT"
  defp opname(122), do: "SETUP_FINALLY"
  defp opname(124), do: "LOAD_FAST"
  defp opname(125), do: "STORE_FAST"
  defp opname(126), do: "DELETE_FAST"
  defp opname(127), do: "STORE_ANNOTATION"
  defp opname(130), do: "RAISE_VARARGS"
  defp opname(131), do: "CALL_FUNCTION"
  defp opname(132), do: "MAKE_FUNCTION"
  defp opname(133), do: "BUILD_SLICE"
  defp opname(135), do: "LOAD_CLOSURE"
  defp opname(136), do: "LOAD_DEREF"
  defp opname(137), do: "STORE_DEREF"
  defp opname(138), do: "DELETE_DEREF"
  defp opname(141), do: "CALL_FUNCTION_KW"
  defp opname(142), do: "CALL_FUNCTION_EX"
  defp opname(143), do: "SETUP_WITH"
  defp opname(144), do: "EXTENDED_ARG"
  defp opname(145), do: "LIST_APPEND"
  defp opname(146), do: "SET_ADD"
  defp opname(147), do: "MAP_ADD"
  defp opname(148), do: "LOAD_CLASSDEREF"
  defp opname(149), do: "BUILD_LIST_UNPACK"
  defp opname(150), do: "BUILD_MAP_UNPACK"
  defp opname(151), do: "BUILD_MAP_UNPACK_WITH_CALL"
  defp opname(152), do: "BUILD_TUPLE_UNPACK"
  defp opname(153), do: "BUILD_SET_UNPACK"
  defp opname(154), do: "SETUP_ASYNC_WITH"
  defp opname(155), do: "FORMAT_VALUE"
  defp opname(156), do: "BUILD_CONST_KEY_MAP"
  defp opname(157), do: "BUILD_STRING"
  defp opname(158), do: "BUILD_TUPLE_UNPACK_WITH_CALL"
  # }}}

  defp execute_instructions(state) do
    frame = state.topframe

    if frame.pc < byte_size(frame.code[:code]) do
      <<opcode, arg>> = binary_part frame.code[:code], frame.pc, 2
      #IO.puts "#{frame.pc}: #{opname opcode} #{arg} (#{inspect frame.stack})"

      # We increment the program counter here by 2 every time.
      # This is so that we don't need to increase it in *every* instruction
      # function.
      frame = %{frame | pc: frame.pc + 2}
      state = %{state | topframe: frame}

      state = execute_instruction(opcode, arg, state)
      execute_instructions state
    else
      state
    end
  end

  # POP_TOP
  defp execute_instruction(1, _arg, state) do
    {value, state} = pop_from_stack state
    decrement_refcount state, value
  end

  # ROT_TWO
  defp execute_instruction(2, _arg, state) do
    {[x, y], state} = pop_from_stack state, 2
    state = push_to_stack state, y
    push_to_stack state, x
  end

  # TODO: Do we need a protocol for these?
  # UNARY_POSITIVE
  defp execute_instruction(10, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.mul(&1, 1)
  end

  # UNARY_NEGATIVE
  defp execute_instruction(11, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.mul(&1, -1)
  end

  # BINARY_POWER
  defp execute_instruction(19, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.pow/2
  end

  # BINARY_MULTIPLY
  defp execute_instruction(20, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.mul/2
  end

  # BINARY_MODULO
  # TODO: Test the semantics of modulo with negative numbers.
  defp execute_instruction(22, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.mod/2
  end

  # BINARY_ADD
  defp execute_instruction(23, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.add/2
  end

  # BINARY_SUBTRACT
  defp execute_instruction(24, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.sub/2
  end

  # BINARY_SUBSCR
  defp execute_instruction(25, _arg, state) do
    apply_to_stack state, &EPython.PySequence.getitem/2
  end

  # BINARY_FLOOR_DIVIDE
  defp execute_instruction(26, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.floor_div/2
  end

  # BINARY_TRUE_DIVIDE
  defp execute_instruction(27, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.true_div/2
  end

  # INPLACE_ADD
  defp execute_instruction(55, _arg, state) do
    apply_to_stack state, &EPython.PyOperable.add/2, {:tos, 0}
  end

  # STORE_SUBSCR
  defp execute_instruction(60, _arg, state) do
    apply_to_stack state, &EPython.PyMutableSequence.setitem(&2, &3, &1), {:tos, 1}
  end

  # GET_ITER
  defp execute_instruction(68, _arg, state) do
    apply_to_stack state, &EPython.PyIterable.iter/1
  end

  # BREAK_LOOP
  defp execute_instruction(80, _arg, state) do
    # TODO: Make a set_pc transformation.
    frame = state.topframe
    [block | blocks] = frame.blocks
    frame = %{frame | blocks: blocks}
    frame = %{frame | pc: block.handler}
    %{state | topframe: frame}
  end

  # RETURN_VALUE
  defp execute_instruction(83, _arg, state) do
    frame = state.topframe

    case frame.previous_frame do
      nil ->
        # RETURN_VALUEs at the module level are kind of a strange thing.
        # I just return the state as-is (with some sanity checks) for now,
        # but I'm not sure if a RETURN_VALUE can occur before the end of the
        # module.
        if hd(frame.stack) == :none do
          state
        else
          raise RuntimeError, message: "Tried to RETURN_VALUE at module level that wasn't :none"
        end

      parent ->
        state = %{state | topframe: parent}
        state = Enum.reduce(Map.values(frame.variables), state, &decrement_refcount(&2, &1))

        push_to_stack state, hd(frame.stack)
    end
  end

  # POP_BLOCK
  defp execute_instruction(87, _arg, state) do
    frame = state.topframe
    frame = %{frame | blocks: tl(frame.blocks)}
    %{state | topframe: frame}
  end

  # STORE_NAME
  defp execute_instruction(90, arg, state) do
    {value, state} = pop_from_stack state
    name = elem(state.topframe.code[:names], arg)
    store_variable state, name, value
  end

  # UNPACK_SEQUENCE
  defp execute_instruction(92, arg, state) do
    if arg == 0 do
      state
    else
      {sequence, state} = pop_from_stack state

      # TODO: Use PyIterator/PyIterable here.
      sequence = if(is_tuple(sequence), do: Tuple.to_list(sequence), else: sequence)
      sequence = Enum.reverse(Enum.to_list(sequence))

      # TODO: Check that there are no more values to unpack.
      stack = state.topframe.stack
      {_, stack} = Enum.reduce((1..arg), {sequence, stack}, fn _, {[item | rest], stack} ->
        {rest, [item | stack]}
      end)

      frame = %{state.topframe | stack: stack}
      %{state | topframe: frame}
    end
  end

  # FOR_ITER
  defp execute_instruction(93, arg, state) do
    {iterator, state} = pop_from_stack state

    # TODO: Do we need to use throw here?
    try do
      EPython.PyIterator.next iterator
    catch
      :stopiteration -> jump_forward state, arg
    else
      {value, iterator} ->
        state = push_to_stack state, iterator
        push_to_stack state, value
    end
  end

  # LOAD_CONST
  defp execute_instruction(100, arg, state) do
    frame = state.topframe
    const = elem(frame.code[:consts], arg)
    # TODO: Increment refcount?
    push_to_stack state, const
  end

  # LOAD_NAME
  defp execute_instruction(101, arg, state) do
    name = elem(state.topframe.code[:names], arg)
    value = load_variable state, name, true
    push_to_stack state, value
  end

  # BUILD_LIST
  defp execute_instruction(103, arg, state) do
    {contents, state} = pop_from_stack state, arg
    list = EPython.PyList.new(contents)
    {reference, state} = create_reference state, list
    push_to_stack state, reference
  end

  # LOAD_ATTR
  defp execute_instruction(106, arg, state) do
    name = elem(state.topframe.code[:names], arg)
    {reference, state} = pop_from_stack state
    {object, state} = resolve_reference state, reference, false
    result = EPython.PyObject.getattr(object, reference, name)
    push_to_stack state, result
  end

  # COMPARE_OP
  defp execute_instruction(107, arg, state) do
    func = case arg do
      0 -> &</2
      1 -> &<=/2
      2 -> &==/2
      3 -> &!=/2
      4 -> &>/2
      5 -> &>=/2
      6 -> &fake_in/2
      7 -> &(not fake_in(&1, &2))
      #8 -> x is y
      #9 -> x is not y
      #10 -> 'exception match'
      #11 -> 'BAD'
    end

    apply_to_stack state, func
  end

  # JUMP_FORWARD
  defp execute_instruction(110, arg, state) do
    jump_forward state, arg
  end

  # JUMP_ABSOLUTE
  defp execute_instruction(113, arg, state) do
    frame = %{state.topframe | pc: arg}

    %{state | topframe: frame}
  end

  # POP_JUMP_IF_FALSE, POP_JUMP_IF_TRUE
  defp execute_instruction(opcode, arg, state) when opcode == 114 or opcode == 115 do
    {head, state} = pop_from_stack state

    should_jump =
      if opcode == 114 do  # POP_JUMP_IF_FALSE
        not truthy?(head)
      else
        truthy?(head)
      end

    pc =
      if should_jump do
        arg
      else
        state.topframe.pc
      end

    frame = %{state.topframe | pc: pc}
    %{state | topframe: frame}
  end

  # LOAD_GLOBAL
  defp execute_instruction(116, arg, state) do
    module_frame = get_module_frame state

    name = elem(state.topframe.code[:names], arg)
    value = load_variable module_frame, name

    push_to_stack state, value
  end

  # SETUP_LOOP
  defp execute_instruction(120, arg, state) do
    create_block state, arg, :loop
  end

  # LOAD_FAST
  defp execute_instruction(124, arg, state) do
    frame = state.topframe

    name = elem(frame.code[:varnames], arg)
    value = load_variable frame, name

    push_to_stack state, value
  end

  # STORE_FAST
  defp execute_instruction(125, arg, state) do
    {value, state} = pop_from_stack state

    name = elem(state.topframe.code[:varnames], arg)
    store_variable state, name, value
  end

  # CALL_FUNCTION
  defp execute_instruction(131, arg, state) do
    {args, state} = pop_from_stack state, arg
    {func, state} = pop_from_stack state

    args =
      case func do
        %EPython.PyUserFunction{} ->
          argcount = length(args)
          expected_argcount = func.code[:argcount]

          # We need to skip over any of the arguments having defaults that have
          # been specified.
          required_arguments = expected_argcount - length(func.default_posargs)
          default_specified = argcount - required_arguments
          default_posargs = Enum.drop(func.default_posargs, default_specified)

          args = args ++ default_posargs

          if length(args) != expected_argcount do
            raise ArgumentError, message: "Too many arguments for #{inspect func.name} (#{inspect args})"
          else
            args
          end

        _ -> args
      end

    EPython.PyCallable.call(func, args, state)
  end

  # MAKE_FUNCTION
  defp execute_instruction(132, arg, state) do
    use Bitwise

    {[fcode, fname], state} = pop_from_stack state, 2

    {default_kwargs, state} =
      if (arg &&& 2) != 0 do
        pop_from_stack state
      else
        {{}, state}
      end

    {default_posargs, state} =
      if (arg &&& 1) != 0 do
        pop_from_stack state
      else
        {{}, state}
      end

    func =
      %EPython.PyUserFunction{
        name: fname,
        code: fcode,
        default_posargs: Tuple.to_list(default_posargs),
        default_kwargs: Tuple.to_list(default_kwargs),
      }

    push_to_stack state, func
  end

  # LIST_APPEND
  defp execute_instruction(145, arg, state) do
    # TODO: Optimize list comprehensions.
    %EPython.PyReference{id: id} = list = peek_stack state, arg
    {list, state} = resolve_reference state, list, false
    {value, state} = pop_from_stack state
    list = EPython.PyList.append list, value
    objects = %{state.objects | id => list}
    %{state | objects: objects}
  end

  defp execute_instruction(opcode, arg, _state) do
    raise ArgumentError, message: "Unknown instruction #{opcode} with opname #{inspect opname(opcode)} and arg #{arg}"
  end

  # TODO: Move these to a protocol.
  # truthy?(integer)
  defp truthy?(0), do: false
  defp truthy?(n) when is_integer(n), do: true

  # truthy?(float)
  defp truthy?(0.0), do: false
  defp truthy?(n) when is_float(n), do: true

  # truthy?(atom)
  defp truthy?(:true), do: true
  defp truthy?(:ellipsis), do: true
  defp truthy?(:stopiteration), do: true
  defp truthy?(n) when is_atom(n), do: false

  # TODO: Use PyIterable/PyIterator here.
  defp fake_in(x, y) do
    y =
      if is_tuple(y) do
        Tuple.to_list(y)
      else
        y
      end

    x in y
  end


  def interpret(bf) do
    code = bf.code_obj
    state = %EPython.InterpreterState{topframe: %EPython.PyFrame{code: code}}

    execute_instructions state
  end
end
# vim: foldmethod=marker
