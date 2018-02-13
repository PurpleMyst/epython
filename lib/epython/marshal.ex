defmodule EPython.Marshal do
  @flag_ref 0x80

  def unmarshal(<<>>) do
    []
  end

  def unmarshal(data) when is_binary(data) do
      {value, rest} = unmarshal_once data
      [value | unmarshal rest]
  end

  defp unmarshal_once(<<type, data :: binary>>) do
    use Bitwise

    # TODO: Handle references
    type = type &&& (~~~@flag_ref)

    # I purposefully skipped over the 'I' and 'f' data types seeing as they are
    # not used.
    case type do
      ?N -> {:none, data}
      ?F -> {:false, data}
      ?T -> {:true, data}
      ?S -> {:stopiteration, data}
      ?. -> {:ellipsis, data}

      ?i -> decode_int32 data
      ?g -> decode_float data
      ?y -> decode_complex data

      ?) -> decode_small_tuple data
      ?( -> decode_sequence :tuple, data
      ?[ -> decode_sequence :list, data
      ?> -> decode_sequence :frozenset, data

      _  -> {{:unknown, type}, data}
    end
  end

  defp decode_int32(<< n :: 32-signed-little, rest :: binary >>) do
    {{:integer, n}, rest}
  end

  defp decode_float(<< n :: float-little, rest :: binary >>) do
    {{:float, n}, rest}
  end

  defp decode_complex(<< a :: float-little, b :: float-little, rest :: binary >>) do
    {{:complex, {a, b}}, rest}
  end

  defp decode_small_tuple(<< size :: 8, rest :: binary >>) do
    {contents, rester} = Enum.reduce((1..size), {[], rest}, &unmarshal_item/2)
    {{:tuple, Enum.reverse contents}, rester}
  end

  defp decode_sequence(type, << size :: 32-signed-little, rest :: binary >>) when is_atom(type) do
    {contents, rester} = Enum.reduce((1..size), {[], rest}, &unmarshal_item/2)
    {{type, Enum.reverse contents}, rester}
  end

  defp unmarshal_item(_, {items, data}) do
    {value, rest} = unmarshal_once data
    {[value | items], rest}
  end
end
