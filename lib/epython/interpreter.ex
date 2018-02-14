defmodule EPython.InterpreterState do
  defstruct [:code, :pc, :variables, :stack]
end

defmodule EPython.Interpreter do
  defp opname(0), do: "<0>"
  defp opname(1), do: "POP_TOP"
  defp opname(2), do: "ROT_TWO"
  defp opname(3), do: "ROT_THREE"
  defp opname(4), do: "DUP_TOP"
  defp opname(5), do: "DUP_TOP_TWO"
  defp opname(6), do: "<6>"
  defp opname(7), do: "<7>"
  defp opname(8), do: "<8>"
  defp opname(9), do: "NOP"
  defp opname(10), do: "UNARY_POSITIVE"
  defp opname(11), do: "UNARY_NEGATIVE"
  defp opname(12), do: "UNARY_NOT"
  defp opname(13), do: "<13>"
  defp opname(14), do: "<14>"
  defp opname(15), do: "UNARY_INVERT"
  defp opname(16), do: "BINARY_MATRIX_MULTIPLY"
  defp opname(17), do: "INPLACE_MATRIX_MULTIPLY"
  defp opname(18), do: "<18>"
  defp opname(19), do: "BINARY_POWER"
  defp opname(20), do: "BINARY_MULTIPLY"
  defp opname(21), do: "<21>"
  defp opname(22), do: "BINARY_MODULO"
  defp opname(23), do: "BINARY_ADD"
  defp opname(24), do: "BINARY_SUBTRACT"
  defp opname(25), do: "BINARY_SUBSCR"
  defp opname(26), do: "BINARY_FLOOR_DIVIDE"
  defp opname(27), do: "BINARY_TRUE_DIVIDE"
  defp opname(28), do: "INPLACE_FLOOR_DIVIDE"
  defp opname(29), do: "INPLACE_TRUE_DIVIDE"
  defp opname(30), do: "<30>"
  defp opname(31), do: "<31>"
  defp opname(32), do: "<32>"
  defp opname(33), do: "<33>"
  defp opname(34), do: "<34>"
  defp opname(35), do: "<35>"
  defp opname(36), do: "<36>"
  defp opname(37), do: "<37>"
  defp opname(38), do: "<38>"
  defp opname(39), do: "<39>"
  defp opname(40), do: "<40>"
  defp opname(41), do: "<41>"
  defp opname(42), do: "<42>"
  defp opname(43), do: "<43>"
  defp opname(44), do: "<44>"
  defp opname(45), do: "<45>"
  defp opname(46), do: "<46>"
  defp opname(47), do: "<47>"
  defp opname(48), do: "<48>"
  defp opname(49), do: "<49>"
  defp opname(50), do: "GET_AITER"
  defp opname(51), do: "GET_ANEXT"
  defp opname(52), do: "BEFORE_ASYNC_WITH"
  defp opname(53), do: "<53>"
  defp opname(54), do: "<54>"
  defp opname(55), do: "INPLACE_ADD"
  defp opname(56), do: "INPLACE_SUBTRACT"
  defp opname(57), do: "INPLACE_MULTIPLY"
  defp opname(58), do: "<58>"
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
  defp opname(74), do: "<74>"
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
  defp opname(99), do: "<99>"
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
  defp opname(117), do: "<117>"
  defp opname(118), do: "<118>"
  defp opname(119), do: "CONTINUE_LOOP"
  defp opname(120), do: "SETUP_LOOP"
  defp opname(121), do: "SETUP_EXCEPT"
  defp opname(122), do: "SETUP_FINALLY"
  defp opname(123), do: "<123>"
  defp opname(124), do: "LOAD_FAST"
  defp opname(125), do: "STORE_FAST"
  defp opname(126), do: "DELETE_FAST"
  defp opname(127), do: "STORE_ANNOTATION"
  defp opname(128), do: "<128>"
  defp opname(129), do: "<129>"
  defp opname(130), do: "RAISE_VARARGS"
  defp opname(131), do: "CALL_FUNCTION"
  defp opname(132), do: "MAKE_FUNCTION"
  defp opname(133), do: "BUILD_SLICE"
  defp opname(134), do: "<134>"
  defp opname(135), do: "LOAD_CLOSURE"
  defp opname(136), do: "LOAD_DEREF"
  defp opname(137), do: "STORE_DEREF"
  defp opname(138), do: "DELETE_DEREF"
  defp opname(139), do: "<139>"
  defp opname(140), do: "<140>"
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
  defp opname(159), do: "<159>"
  defp opname(160), do: "<160>"
  defp opname(161), do: "<161>"
  defp opname(162), do: "<162>"
  defp opname(163), do: "<163>"
  defp opname(164), do: "<164>"
  defp opname(165), do: "<165>"
  defp opname(166), do: "<166>"
  defp opname(167), do: "<167>"
  defp opname(168), do: "<168>"
  defp opname(169), do: "<169>"
  defp opname(170), do: "<170>"
  defp opname(171), do: "<171>"
  defp opname(172), do: "<172>"
  defp opname(173), do: "<173>"
  defp opname(174), do: "<174>"
  defp opname(175), do: "<175>"
  defp opname(176), do: "<176>"
  defp opname(177), do: "<177>"
  defp opname(178), do: "<178>"
  defp opname(179), do: "<179>"
  defp opname(180), do: "<180>"
  defp opname(181), do: "<181>"
  defp opname(182), do: "<182>"
  defp opname(183), do: "<183>"
  defp opname(184), do: "<184>"
  defp opname(185), do: "<185>"
  defp opname(186), do: "<186>"
  defp opname(187), do: "<187>"
  defp opname(188), do: "<188>"
  defp opname(189), do: "<189>"
  defp opname(190), do: "<190>"
  defp opname(191), do: "<191>"
  defp opname(192), do: "<192>"
  defp opname(193), do: "<193>"
  defp opname(194), do: "<194>"
  defp opname(195), do: "<195>"
  defp opname(196), do: "<196>"
  defp opname(197), do: "<197>"
  defp opname(198), do: "<198>"
  defp opname(199), do: "<199>"
  defp opname(200), do: "<200>"
  defp opname(201), do: "<201>"
  defp opname(202), do: "<202>"
  defp opname(203), do: "<203>"
  defp opname(204), do: "<204>"
  defp opname(205), do: "<205>"
  defp opname(206), do: "<206>"
  defp opname(207), do: "<207>"
  defp opname(208), do: "<208>"
  defp opname(209), do: "<209>"
  defp opname(210), do: "<210>"
  defp opname(211), do: "<211>"
  defp opname(212), do: "<212>"
  defp opname(213), do: "<213>"
  defp opname(214), do: "<214>"
  defp opname(215), do: "<215>"
  defp opname(216), do: "<216>"
  defp opname(217), do: "<217>"
  defp opname(218), do: "<218>"
  defp opname(219), do: "<219>"
  defp opname(220), do: "<220>"
  defp opname(221), do: "<221>"
  defp opname(222), do: "<222>"
  defp opname(223), do: "<223>"
  defp opname(224), do: "<224>"
  defp opname(225), do: "<225>"
  defp opname(226), do: "<226>"
  defp opname(227), do: "<227>"
  defp opname(228), do: "<228>"
  defp opname(229), do: "<229>"
  defp opname(230), do: "<230>"
  defp opname(231), do: "<231>"
  defp opname(232), do: "<232>"
  defp opname(233), do: "<233>"
  defp opname(234), do: "<234>"
  defp opname(235), do: "<235>"
  defp opname(236), do: "<236>"
  defp opname(237), do: "<237>"
  defp opname(238), do: "<238>"
  defp opname(239), do: "<239>"
  defp opname(240), do: "<240>"
  defp opname(241), do: "<241>"
  defp opname(242), do: "<242>"
  defp opname(243), do: "<243>"
  defp opname(244), do: "<244>"
  defp opname(245), do: "<245>"
  defp opname(246), do: "<246>"
  defp opname(247), do: "<247>"
  defp opname(248), do: "<248>"
  defp opname(249), do: "<249>"
  defp opname(250), do: "<250>"
  defp opname(251), do: "<251>"
  defp opname(252), do: "<252>"
  defp opname(253), do: "<253>"
  defp opname(254), do: "<254>"
  defp opname(255), do: "<255>"

  defp execute_instructions(state) do
    if state.pc < byte_size(state.code[:code]) do
      <<opcode, arg>> = binary_part state.code[:code], state.pc, 2

      execute_instruction(opcode, arg, state) |> execute_instructions()
    else
      state
    end
  end

  defp execute_instruction(opcode, arg, _state) do
    raise ArgumentError, message: "Unknown instruction #{opcode} with opname #{inspect opname(opcode)} and arg #{arg}"
  end

  def interpret(bf) do
    code = bf.code_obj
    state = %EPython.InterpreterState{code: code, pc: 0, variables: %{}, stack: []}
    execute_instructions state
  end
end
