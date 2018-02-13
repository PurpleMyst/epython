defmodule EPython.Marshal do
  @flag_ref 0x80

  def unmarshal(<<>>) do
    []
  end

  def unmarshal(<<type, data :: binary>>) do
    use Bitwise

    type = type &&& (~~~@flag_ref)

    case type do
      ?N -> :none
      ?F -> :false
      ?T -> :true
      ?S -> :stopiteration
      ?. -> :ellipsis
      ?i -> {:integer, :binary.decode_unsigned(data, :little)}
      _  -> {:unknown, type, data}
    end
  end
end
