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
    result = case type do
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

      ?) -> unmarshal_small_tuple data, references
      ?( -> unmarshal_sequence :tuple, data, references
      ?[ -> unmarshal_sequence :list, data, references
      ?{ -> unmarshal_dict data, references
      ?< -> unmarshal_sequence :set, data, references
      ?> -> unmarshal_sequence :frozenset, data, references

      ?c -> unmarshal_code data, references

      ?r -> unmarshal_reference data, references

      _ -> raise ArgumentError, message: "Unknown type: #{inspect type}"
    end

    references = case result do
      {_, _} -> references
      {_, _, new_references} -> new_references
    end

    references = if ref_flag != 0 do
      references ++ [elem(result, 0)]
    else
      references
    end

    case result do
      {unmarshalled_obj, rest} -> {unmarshalled_obj, rest, references}
      {unmarshalled_obj, rest, _} -> {unmarshalled_obj, rest, references}
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

  defp unmarshal_small_tuple(<< size :: 8, rest :: binary >>, references) do
    if size == 0 do
      {{:tuple, []}, rest}
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
      {{type, []}, rest}
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
    {get_reference(references, id), rest}
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
