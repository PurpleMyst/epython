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

  def unmarshal(data, refs \\ [])

  def unmarshal(<<>>, _) do
    []
  end

  def unmarshal(data, refs) when is_binary(data) do
      {value, rest, refs} = unmarshal_once(data, refs)
      [value | unmarshal(rest, refs)]
  end

  defp unmarshal_once(<<1 :: 1, type :: 7, data :: binary>>, refs) do
    {unmarshalled_obj, data, refs} = unmarshal_once(<<type>> <> data, refs)
    {unmarshalled_obj, data, refs ++ [unmarshalled_obj]}
  end

  defp unmarshal_once(<<0 :: 1, ?0 :: 7, data :: binary>>, refs), do: {:null, data, refs}
  defp unmarshal_once(<<0 :: 1, ?N :: 7, data :: binary>>, refs), do: {:none, data, refs}
  defp unmarshal_once(<<0 :: 1, ?F :: 7, data :: binary>>, refs), do: {:false, data, refs}
  defp unmarshal_once(<<0 :: 1, ?T :: 7, data :: binary>>, refs), do: {:true, data, refs}
  defp unmarshal_once(<<0 :: 1, ?S :: 7, data :: binary>>, refs), do: {:stopiteration, data, refs}
  defp unmarshal_once(<<0 :: 1, ?. :: 7, data :: binary>>, refs), do: {:ellipsis, data, refs}

  defp unmarshal_once(<<0 :: 1, type :: 7, data :: binary>>, refs) do
    # I purposefully skipped over the 'I' and 'f' data types seeing as they are
    # not used.
    case type do
      ?i -> unmarshal_int32 data, refs
      ?g -> unmarshal_float data, refs
      ?y -> unmarshal_complex data, refs

      ?z -> unmarshal_short_ascii data, refs
      ?Z -> unmarshal_short_ascii data, refs
      ?a -> unmarshal_string data, refs
      ?A -> unmarshal_string data, refs
      ?u -> unmarshal_string data, refs
      ?t -> unmarshal_string data, refs
      ?s -> unmarshal_string data, refs

      ?) -> unmarshal_small_tuple data, refs
      ?( -> unmarshal_sequence :tuple, data, refs
      ?[ -> unmarshal_sequence :list, data, refs
      ?{ -> unmarshal_dict data, refs
      ?< -> unmarshal_sequence :set, data, refs
      ?> -> unmarshal_sequence :frozenset, data, refs

      ?c -> unmarshal_code data, refs

      ?r -> unmarshal_reference data, refs

      _ -> raise ArgumentError, message: "Unknown type: #{inspect [type]}"
    end
  end

  defp unmarshal_int32(<< n :: 32-signed-little, rest :: binary >>, refs) do
    {{:integer, n}, rest, refs}
  end

  defp unmarshal_float(<< n :: float-little, rest :: binary >>, refs) do
    {{:float, n}, rest, refs}
  end

  defp unmarshal_complex(<< a :: float-little, b :: float-little, rest :: binary >>, refs) do
    {{:complex, {a, b}}, rest, refs}
  end

  defp unmarshal_short_ascii(<< size :: 8, rest :: binary >>, refs) do
    contents = binary_part rest, 0, size
    rester = binary_part rest, size, byte_size(rest) - size
    {{:string, contents}, rester, refs}
  end

  defp unmarshal_string(<< size :: 32-little, rest :: binary >>, refs) do
    contents = binary_part rest, 0, size
    rester = binary_part rest, size, byte_size(rest) - size
    {{:string, contents}, rester, refs}
  end

  defp unmarshal_small_tuple(<< size :: 8, rest :: binary >>, refs) do
    if size == 0 do
      {{:tuple, []}, rest, refs}
    else
      {contents, rester, refs} = Enum.reduce((1..size), {[], rest, refs}, &unmarshal_item/2)
      {{:tuple, Enum.reverse contents}, rester, refs}
    end
  end

  defp unmarshal_dict(data, refs) do
    {pairs, rest, refs} = unmarshal_dict_pairs(data, refs)
    {{:dict, pairs}, rest, refs}
  end

  defp unmarshal_dict_pairs(data, refs) do
    case unmarshal_once(data, refs) do
      {:null, rest, refs} -> {[], rest, refs}

      {key, rest, refs} ->
        {value, rester, refs} = unmarshal_once(rest, refs)
        {pairs, resterer, refs} = unmarshal_dict_pairs(rester, refs)

        {[{key, value} | pairs], resterer, refs}
    end
  end

  defp unmarshal_sequence(type, << size :: 32-signed-little, rest :: binary >>, refs) when is_atom(type) do
    if size == 0 do
      {{type, []}, rest, refs}
    else
      {contents, rester, refs} = Enum.reduce((1..size), {[], rest, refs}, &unmarshal_item/2)
      {{type, Enum.reverse contents}, rester, refs}
    end
  end

  defp unmarshal_item(_, {items, data, refs}) do
    {value, rest, refs} = unmarshal_once(data, refs)
    {[value | items], rest, refs}
  end

  defp unmarshal_reference(<< id :: 8*4-little, rest :: binary >>, refs) do
    {get_reference(refs, id), rest, refs}
  end

  # XXX: This is not the same as a PyLong.
  defp unmarshal_long(<< a, b, c, d, rest :: binary>>) do
    {{:integer, :binary.decode_unsigned(<<a, b, c, d>>, :little)}, rest}
  end

  defp unmarshal_code(data, refs) do
    {pairs, {rest, refs}} =
      @code_object_parts
      |> Enum.map_reduce({data, refs}, fn {name, type}, {rest, refs} ->
          case type do
            :long ->
              {value, rest} = unmarshal_long(rest)
              {{name, value}, {rest, refs}}

            :object ->
              {value, rest, refs} = unmarshal_once(rest, refs)
              {{name, value}, {rest, refs}}
          end
      end)

    {{:code, pairs}, rest, refs}
  end

  defp get_reference(l, n) when n <= 1, do: hd(l)
  defp get_reference(l, n),             do: get_reference(tl(l), n - 1)
end
