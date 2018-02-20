defmodule EPython.Marshal do
  @code_object_parts [
                      argcount: :long,
                      kwonlyargcount: :long,
                      nlocals: :long,
                      stacksize: :long,
                      flags: :long,
                      code: :object,
                      consts: :object,
                      names: :object,
                      varnames: :object,
                      freevars: :object,
                      cellvars: :object,
                      filename: :object,
                      name: :object,
                      firstlineno: :long,
                      lnotab: :object,
                     ]

  def unmarshal(data, refs \\ %{})

  def unmarshal(<<>>, _) do
    []
  end

  def unmarshal(data, refs) when is_binary(data) do
    {value, rest, refs} = unmarshal_once(data, refs)
    [value | unmarshal(rest, refs)]
  end

  defp unmarshal_once(<<1 :: 1, type :: 7, data :: binary>>, refs) do
    {unmarshalled_obj, data, refs} = unmarshal_once(<<type>> <> data, refs)
    next_id = Enum.max(Map.keys(refs), fn -> 0 end) + 1
    {unmarshalled_obj, data, Map.put(refs, next_id, unmarshalled_obj)}
  end

  # singletons
  defp unmarshal_once(<<0 :: 1, ?0 :: 7, data :: binary>>, refs), do: {:null, data, refs}
  defp unmarshal_once(<<0 :: 1, ?N :: 7, data :: binary>>, refs), do: {:none, data, refs}
  defp unmarshal_once(<<0 :: 1, ?F :: 7, data :: binary>>, refs), do: {:false, data, refs}
  defp unmarshal_once(<<0 :: 1, ?T :: 7, data :: binary>>, refs), do: {:true, data, refs}
  defp unmarshal_once(<<0 :: 1, ?S :: 7, data :: binary>>, refs), do: {:stopiteration, data, refs}
  defp unmarshal_once(<<0 :: 1, ?. :: 7, data :: binary>>, refs), do: {:ellipsis, data, refs}

  # int32
  defp unmarshal_once(<< 0 :: 1, ?i :: 7, n :: 32-signed-little, rest :: binary >>, refs) do
    {n, rest, refs}
  end

  # float64
  defp unmarshal_once(<< 0 :: 1, ?g :: 7, n :: float-little, rest :: binary >>, refs) do
    {n, rest, refs}
  end

  # complex
  defp unmarshal_once(<< 0 :: 1, ?y :: 7, a :: float-little, b :: float-little, rest :: binary >>, refs) do
    {{a, b}, rest, refs}
  end

  # short ascii
  defp unmarshal_once(<< 0 :: 1, type :: 7, size :: 8, rest :: binary >>, refs) when type in 'zZ' do
    contents = binary_part rest, 0, size
    rester = binary_part rest, size, byte_size(rest) - size
    {contents, rester, refs}
  end

  # strings
  defp unmarshal_once(<< 0 :: 1, type :: 7, size :: 32-little, rest :: binary >>, refs) when type in 'aAuts' do
    contents = binary_part rest, 0, size
    rester = binary_part rest, size, byte_size(rest) - size
    {contents, rester, refs}
  end

  # small tuple
  defp unmarshal_once(<< 0 :: 1, ?) :: 7, size :: 8, rest :: binary >>, refs) do
    if size == 0 do
      {{}, rest, refs}
    else
      {contents, rester, refs} = Enum.reduce((1..size), {[], rest, refs}, &unmarshal_item/2)
      {List.to_tuple(Enum.reverse(contents)), rester, refs}
    end
  end

  # dict
  defp unmarshal_once(<< 0 :: 1, ?{ :: 7, data :: binary >>, refs) do
    {pairs, rest, refs} = unmarshal_dict_pairs(data, refs)
    {Map.new(pairs), rest, refs}
  end

  # code
  defp unmarshal_once(<< 0 :: 1, ?c :: 7, data :: binary>>, refs) do
    {pairs, {rest, refs}} =
      @code_object_parts
      |> Enum.map_reduce({data, refs}, fn {name, type}, {rest, refs} ->
          case type do
            :long ->
              {value, rest} = unmarshal_int64(rest)
              {{name, value}, {rest, refs}}

            :object ->
              {value, rest, refs} = unmarshal_once(rest, refs)
              {{name, value}, {rest, refs}}
          end
      end)

    {pairs, rest, refs}
  end

  # references
  defp unmarshal_once(<< 0 :: 1, ?r :: 7, id :: 8*4-little, rest :: binary >>, refs) do
    {Map.fetch!(refs, id), rest, refs}
  end

  # sequences
  defp unmarshal_once(<<0 :: 1, type :: 7, data :: binary>>, refs) when type in '([<>' do
    {list, rest, refs} = unmarshal_sequence(data, refs)

    sequence = case type do
      ?( -> List.to_tuple(list)
      ?[ -> list
      c when c in '<>' -> MapSet.new(list)
    end

    {sequence, rest, refs}
  end

  defp unmarshal_once(<< 0 :: 1, type :: 7, _ :: binary >>, _) do
     raise ArgumentError, message: "Unknown type: #{inspect [type]}"
  end

  # I purposefully skipped over the 'I' and 'f' data types seeing as they are
  # not used.

  # Here begin the helper functions.
  defp unmarshal_dict_pairs(data, refs) do
    case unmarshal_once(data, refs) do
      {:null, rest, refs} -> {[], rest, refs}

      {key, rest, refs} ->
        {value, rester, refs} = unmarshal_once(rest, refs)
        {pairs, resterer, refs} = unmarshal_dict_pairs(rester, refs)

        {[{key, value} | pairs], resterer, refs}
    end
  end

  defp unmarshal_sequence(<< size :: 32-signed-little, rest :: binary >>, refs) do
    if size == 0 do
      {[], rest, refs}
    else
      {contents, rester, refs} = Enum.reduce((1..size), {[], rest, refs}, &unmarshal_item/2)
      {Enum.reverse(contents), rester, refs}
    end
  end

  defp unmarshal_item(_, {items, data, refs}) do
    {value, rest, refs} = unmarshal_once(data, refs)
    {[value | items], rest, refs}
  end

  defp unmarshal_int64(<< a, b, c, d, rest :: binary>>) do
    {:binary.decode_unsigned(<<a, b, c, d>>, :little), rest}
  end
end
