defmodule EPython.Marshal do
  @flag_ref 0x80

  def unmarshal(<<>>) do
    []
  end

  def unmarshal(<<type, data :: binary>>) do
    use Bitwise

    # TODO: Handle references
    type = type &&& (~~~@flag_ref)

    # I purposefully skipped over the 'I' and 'f' data types seeing as they are
    # not used.
    case type do
      ?N -> :none
      ?F -> :false
      ?T -> :true
      ?S -> :stopiteration
      ?. -> :ellipsis

      ?i -> {:integer, :binary.decode_unsigned(data, :little)}

      ?g -> {:float, decode_float data}

      _  -> {:unknown, type, data}
    end
  end

  defp decode_float(<< n :: float-little >>), do: n
end
