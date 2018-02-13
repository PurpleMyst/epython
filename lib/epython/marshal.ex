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

    # TODO: Actually handle references. Right now we note when references are,
    # however I think we should automatically resolve them.
    type = type &&& (~~~@flag_ref)

    # I purposefully skipped over the 'I' and 'f' data types seeing as they are
    # not used.
    case type do
      ?0 -> {:null, data}
      ?N -> {:none, data}
      ?F -> {:false, data}
      ?T -> {:true, data}
      ?S -> {:stopiteration, data}
      ?. -> {:ellipsis, data}

      ?i -> unmarshal_int32 data
      ?g -> unmarshal_float data
      ?y -> unmarshal_complex data

      ?) -> unmarshal_small_tuple data
      ?( -> unmarshal_sequence :tuple, data
      ?[ -> unmarshal_sequence :list, data
      ?{ -> unmarshal_dict data
      ?> -> unmarshal_sequence :frozenset, data

      ?r -> unmarshal_reference data

      _  -> {{:unknown, type}, data}
    end
  end

  defp unmarshal_int32(<< n :: 32-signed-little, rest :: binary >>) do
    {{:integer, n}, rest}
  end

  defp unmarshal_float(<< n :: float-little, rest :: binary >>) do
    {{:float, n}, rest}
  end

  defp unmarshal_complex(<< a :: float-little, b :: float-little, rest :: binary >>) do
    {{:complex, {a, b}}, rest}
  end

  defp unmarshal_small_tuple(<< size :: 8, rest :: binary >>) do
    if size == 0 do
      {{:tuple, []}, rest}
    else
      {contents, rester} = Enum.reduce((1..size), {[], rest}, &unmarshal_item/2)
      {{:tuple, Enum.reverse contents}, rester}
    end
  end

  defp unmarshal_dict(data) do
    {pairs, rest} = unmarshal_dict_pairs data
    {{:dict, pairs}, rest}
  end

  defp unmarshal_dict_pairs(data) do
    {key, rest} = unmarshal_once data

    if key == :null then
       {[], rest}
    else
      {value, rester} = unmarshal_once rest
      {pairs, resterer} = unmarshal_dict_pairs rester

      {[{key, value} | pairs], resterer}
    end
  end

  defp unmarshal_sequence(type, << size :: 32-signed-little, rest :: binary >>) when is_atom(type) do
    if size == 0 do
      {{type, []}, rest}
    else
      {contents, rester} = Enum.reduce((1..size), {[], rest}, &unmarshal_item/2)
      {{type, Enum.reverse contents}, rester}
    end
  end

  defp unmarshal_item(_, {items, data}) do
    {value, rest} = unmarshal_once data
    {[value | items], rest}
  end

  defp unmarshal_reference(<< id :: 8*4-little, rest :: binary >>) do
    {{:reference, id}, rest}
  end
end
