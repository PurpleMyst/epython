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

  def unmarshal(data, references \\ [])

  def unmarshal(<<>>, _) do
    []
  end

  def unmarshal(data, references) when is_binary(data) do
      {value, rest, references} = unmarshal_once(data, references)
      [value | unmarshal(rest, references)]
  end

  defp unmarshal_once(<<ref_flag :: 1, type :: 7, data :: binary>>, references) do
    # I purposefully skipped over the 'I' and 'f' data types seeing as they are
    # not used.
    {unmarshalled_obj, rest, references} = case type do
      ?0 -> {:null, data, references}
      ?N -> {:none, data, references}
      ?F -> {:false, data, references}
      ?T -> {:true, data, references}
      ?S -> {:stopiteration, data, references}
      ?. -> {:ellipsis, data, references}

      ?i -> unmarshal_int32 data, references
      ?g -> unmarshal_float data, references
      ?y -> unmarshal_complex data, references

      ?z -> unmarshal_short_ascii data, references
      ?Z -> unmarshal_short_ascii data, references
      ?a -> unmarshal_string data, references
      ?A -> unmarshal_string data, references
      ?u -> unmarshal_string data, references
      ?t -> unmarshal_string data, references
      ?s -> unmarshal_string data, references

      ?) -> unmarshal_small_tuple data, references
      ?( -> unmarshal_sequence :tuple, data, references
      ?[ -> unmarshal_sequence :list, data, references
      ?{ -> unmarshal_dict data, references
      ?< -> unmarshal_sequence :set, data, references
      ?> -> unmarshal_sequence :frozenset, data, references

      ?c -> unmarshal_code data, references

      ?r -> unmarshal_reference data, references

      _ -> raise ArgumentError, message: "Unknown type: #{inspect [type]}"
    end

    references = if ref_flag != 0 do
      references ++ [unmarshalled_obj]
    else
      references
    end

    {unmarshalled_obj, rest, references}
  end

  defp unmarshal_int32(<< n :: 32-signed-little, rest :: binary >>, references) do
    {{:integer, n}, rest, references}
  end

  defp unmarshal_float(<< n :: float-little, rest :: binary >>, references) do
    {{:float, n}, rest, references}
  end

  defp unmarshal_complex(<< a :: float-little, b :: float-little, rest :: binary >>, references) do
    {{:complex, {a, b}}, rest, references}
  end

  defp unmarshal_short_ascii(<< size :: 8, rest :: binary >>, references) do
    contents = binary_part rest, 0, size
    rester = binary_part rest, size, byte_size(rest) - size
    {{:string, contents}, rester, references}
  end

  defp unmarshal_string(<< size :: 32-little, rest :: binary >>, references) do
    contents = binary_part rest, 0, size
    rester = binary_part rest, size, byte_size(rest) - size
    {{:string, contents}, rester, references}
  end

  defp unmarshal_small_tuple(<< size :: 8, rest :: binary >>, references) do
    if size == 0 do
      {{:tuple, []}, rest, references}
    else
      {contents, rester, references} = Enum.reduce((1..size), {[], rest, references}, &unmarshal_item/2)
      {{:tuple, Enum.reverse contents}, rester, references}
    end
  end

  defp unmarshal_dict(data, references) do
    {pairs, rest, references} = unmarshal_dict_pairs(data, references)
    {{:dict, pairs}, rest, references}
  end

  defp unmarshal_dict_pairs(data, references) do
    case unmarshal_once(data, references) do
      {:null, rest, references} -> {[], rest, references}

      {key, rest, references} ->
        {value, rester, references} = unmarshal_once(rest, references)
        {pairs, resterer, references} = unmarshal_dict_pairs(rester, references)

        {[{key, value} | pairs], resterer, references}
    end
  end

  defp unmarshal_sequence(type, << size :: 32-signed-little, rest :: binary >>, references) when is_atom(type) do
    if size == 0 do
      {{type, []}, rest, references}
    else
      {contents, rester, references} = Enum.reduce((1..size), {[], rest, references}, &unmarshal_item/2)
      {{type, Enum.reverse contents}, rester, references}
    end
  end

  defp unmarshal_item(_, {items, data, references}) do
    {value, rest, references} = unmarshal_once(data, references)
    {[value | items], rest, references}
  end

  defp unmarshal_reference(<< id :: 8*4-little, rest :: binary >>, references) do
    {get_reference(references, id), rest, references}
  end

  # XXX: This is not the same as a PyLong.
  defp unmarshal_long(<< a, b, c, d, rest :: binary>>) do
    {{:integer, :binary.decode_unsigned(<<a, b, c, d>>, :little)}, rest}
  end

  defp unmarshal_code(data, references) do
    {pairs, {rest, references}} =
      @code_object_parts
      |> Enum.map_reduce({data, references}, fn {name, type}, {rest, references} ->
          case type do
            :long ->
              {value, rest} = unmarshal_long(rest)
              {{name, value}, {rest, references}}

            :object ->
              {value, rest, references} = unmarshal_once(rest, references)
              {{name, value}, {rest, references}}
          end
      end)

    {{:code, pairs}, rest, references}
  end

  defp get_reference(l, n) when n <= 1, do: hd(l)
  defp get_reference(l, n),             do: get_reference(tl(l), n - 1)
end
