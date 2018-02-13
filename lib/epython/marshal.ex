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

  def unmarshal(<<>>) do
    []
  end

  def unmarshal(data) when is_binary(data) do
      {value, rest} = unmarshal_once data
      [value | unmarshal rest]
  end

  defp unmarshal_once(<<ref_flag :: 1, type :: 7, data :: binary>>) do
    # TODO: Actually handle references. Right now we note when references are,
    # however I think we should automatically resolve them.

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

      ?z -> unmarshal_short_ascii data
      ?Z -> unmarshal_short_ascii data
      ?a -> unmarshal_string data
      ?A -> unmarshal_string data
      ?u -> unmarshal_string data
      ?t -> unmarshal_string data
      ?s -> unmarshal_string data

      ?) -> unmarshal_small_tuple data
      ?( -> unmarshal_sequence :tuple, data
      ?[ -> unmarshal_sequence :list, data
      ?{ -> unmarshal_dict data
      ?< -> unmarshal_sequence :set, data
      ?> -> unmarshal_sequence :frozenset, data

      ?c -> unmarshal_code data

      ?r -> unmarshal_reference data

      _ -> raise ArgumentError, message: "Unknown type: #{inspect type}"
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

  defp unmarshal_short_ascii(<< size :: 8, rest :: binary >>) do
    contents = binary_part rest, 0, size
    rester = binary_part rest, size, byte_size(rest) - size
    {{:string, contents}, rester}
  end

  defp unmarshal_string(<< size :: 32-little, rest :: binary >>) do
    contents = binary_part rest, 0, size
    rester = binary_part rest, size, byte_size(rest) - size
    {{:string, contents}, rester}
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
    case unmarshal_once data do
      {:null, rest} -> {[], rest}

      {key, rest} ->
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

  # XXX: This is not the same as a PyLong.
  defp unmarshal_long(<< a, b, c, d, rest :: binary>>) do
    {{:integer, :binary.decode_unsigned(<<a, b, c, d>>, :little)}, rest}
  end

  defp unmarshal_code(data) do
    {pairs, rest} =
      @code_object_parts
      |> Enum.map_reduce(data, fn {name, type}, rest ->
          {value, rest} = case type do
            :long   -> unmarshal_long rest
            :object -> unmarshal_once rest
          end

          {{name, value}, rest}
      end)

    {{:code, pairs}, rest}
  end
end
