defmodule EPython.PyList do
  @enforce_keys [:contents]

  defstruct [:contents]

  def new(contents) do
    arr = :array.from_list(contents)
    %EPython.PyList{contents: arr}
  end

  def append(%EPython.PyList{contents: contents}, value) do
    contents = :array.set(:array.size(contents), value, contents)
    %EPython.PyList{contents: contents}
  end
end

defimpl String.Chars, for: EPython.PyList do
  def to_string(%EPython.PyList{contents: contents}) do
    # XXX: It might be more efficent to print out each element ourselves.
    inspect :array.to_list(contents)
  end
end

defimpl EPython.PyOperable, for: EPython.PyList do
  defp add_arrays(c1, c2) do
    Enum.reduce(c2, c1, fn item, contents ->
      :array.set(:array.size(contents), item)
    end)
  end

  def add(%EPython.PyList{contents: c1}, %EPython.PyList{contents: c2}) do
    # TODO: We have much of the same code as PyList.append here, we should make
    # a transformation.
    contents = add_arrays c1, c2
    %EPython.PyList{contents: contents}
  end

  def sub(_x, _y), do: :notimplemented

  def mul(_, 0) do
    EPython.PyList.new []
  end

  def mul(%EPython.PyList{contents: contents}, n) when is_integer(n) do
    contents = Enum.map((1..n), fn _ -> contents end) |> Enum.reduce(&add_arrays/2)
    %EPython.PyList{contents: contents}
  end

  def floor_div(_x, _y), do: :notimplemented

  def true_div(_x, _y), do: :notimplemented

  def mod(_x, _y), do: :notimplemented

  def pow(_x, _y), do: :notimplemented
end

defimpl EPython.PySequence, for: EPython.PyList do
  def getitem(%EPython.PyList{contents: contents}, index) do
    :array.get(index, contents)
  end

  def length(%EPython.PyList{contents: contents}) do
    :array.size(contents)
  end
end

defimpl EPython.PyMutableSequence, for: EPython.PyList do
  def setitem(%EPython.PyList{contents: contents}, index, value) do
    contents = :array.set(index, value, contents)
    %EPython.PyList{contents: contents}
  end
end

defmodule EPython.PyListIterator do
  @enforce_keys [:contents]
  defstruct [:contents]
end

defimpl EPython.PyIterable, for: EPython.PyList do
  # XXX: Do we need to turn the array into a list?
  def iter(%EPython.PyList{contents: contents}) do
    %EPython.PyListIterator{contents: :array.to_list(contents)}
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
