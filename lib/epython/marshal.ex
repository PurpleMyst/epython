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
      ?N -> [:none | unmarshal data]
      ?F -> [:false | unmarshal data]
      ?T -> [:true | unmarshal data]
      ?S -> [:stopiteration | unmarshal data]
      ?. -> [:ellipsis | unmarshal data]

      ?i -> apply_decoder &decode_int32/1, data
      ?g -> apply_decoder &decode_float/1, data
      ?y -> apply_decoder &decode_complex/1, data

      _  -> [{:unknown, type, data}]
    end
  end

  defp apply_decoder(decoder, data) do
    {value, rest} = decoder.(data)
    [value | unmarshal rest]
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
end
