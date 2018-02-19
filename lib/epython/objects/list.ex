# XXX: We could use Stream instead of Enum in a few places here.
import EPython.Transformations

defmodule EPython.PyList do
  @enforce_keys [:contents]

  defstruct [:contents]

  def new(contents) do
    contents =
      Enum.reduce(Enum.with_index(contents), %{}, fn {x, i}, m ->
        Map.put(m, i, x)
      end)

    %EPython.PyList{contents: contents}
  end

  def append(%EPython.PyList{contents: contents}, value) do
    contents = Map.put(contents, map_size(contents),  value)
    %EPython.PyList{contents: contents}
  end

  def to_list(%EPython.PyList{contents: contents}) do
    # XXX: This is one of the places where we could use a Stream.
    Enum.map((0..map_size(contents) - 1), &Map.fetch!(contents, &1))
  end
end

defimpl String.Chars, for: EPython.PyList do
  def to_string(pylist) do
    # XXX: It might be more efficent to print out each element ourselves.
    inspect EPython.PyList.to_list(pylist)
  end
end

defimpl EPython.PyOperable, for: EPython.PyList do
  def add(%EPython.PyList{contents: c1}, %EPython.PyList{contents: c2}) do
    # TODO: We have much of the same code as PyList.append here, we should make
    # a transformation.
    c2 = Enum.into(Stream.map(c2, fn {i, x} -> {i + map_size(c1), x} end), %{})
    contents = Map.merge(c1, c2)

    %EPython.PyList{contents: contents}
  end

  def sub(_x, _y), do: :notimplemented

  def mul(_, 0) do
    EPython.PyList.new []
  end

  def mul(%EPython.PyList{contents: contents}, n) when is_integer(n) do
    contents =
      (0..n - 1)
      |> Stream.map(fn k ->
        Stream.map(contents, fn {i, x} -> {k * map_size(contents) + i, x} end)
        |> Enum.into(%{})
      end)
      |> Enum.reduce(&Map.merge/2)
    %EPython.PyList{contents: contents}
  end

  def floor_div(_x, _y), do: :notimplemented

  def true_div(_x, _y), do: :notimplemented

  def mod(_x, _y), do: :notimplemented

  def pow(_x, _y), do: :notimplemented
end

defimpl EPython.PySequence, for: EPython.PyList do
  def getitem(%EPython.PyList{contents: contents}, index) do
    # TODO: Implement slices.
    item = contents[index]

    if item == nil do
      raise RuntimeError, message: "Index #{index} out of bounds for #{inspect contents}"
    else
      item
    end
  end

  def length(%EPython.PyList{contents: contents}) do
    map_size(contents)
  end
end

defimpl EPython.PyMutableSequence, for: EPython.PyList do
  def setitem(%EPython.PyList{contents: contents}, index, value) do
    contents = %{contents | index => value}
    %EPython.PyList{contents: contents}
  end
end

defmodule EPython.PyListIterator do
  @enforce_keys [:contents]
  defstruct [:contents]
end

defimpl EPython.PyIterable, for: EPython.PyList do
  def iter(pylist) do
    %EPython.PyListIterator{contents: EPython.PyList.to_list(pylist)}
  end
end

defimpl EPython.PyIterable, for: EPython.PyListIterator do
  def iter(iterator), do: iterator
end

defimpl EPython.PyIterator, for: EPython.PyListIterator do
  def next(%EPython.PyListIterator{contents: [head | tail]}) do
    {head, %EPython.PyListIterator{contents: tail}}
  end

  def next(%EPython.PyListIterator{contents: []}) do
    throw :stopiteration
  end
end

defimpl EPython.PyObject, for: EPython.PyList do
  def parent(_), do: nil

  def getattr(_object, reference, "append") do
    %EPython.PyMethod{
      name: "append",
      object: reference,
      function: fn [reference, value], state ->
        {pylist, state} = resolve_reference state, reference, false
        pylist = EPython.PyList.append pylist, value
        {:none, pylist, state}
      end,
    }
  end

  def getattr(object, _reference, name) do
    # TODO: Look in parent.
    raise ArgumentError, message: "Unknown attribute #{inspect name} with #{inspect object}"
  end
end
