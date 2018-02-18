defmodule EPython.PyList do
  # TODO: Should we make the contents of a PyList not a linked list?
  @enforce_keys [:contents]

  defstruct [:contents]

  def append(%EPython.PyList{contents: contents}, value) do
    %EPython.PyList{contents: contents ++ [value]}
  end
end

defimpl String.Chars, for: EPython.PyList do
  def to_string(%EPython.PyList{contents: contents}) do
    inspect contents
  end
end

defimpl EPython.PyOperable, for: EPython.PyList do
  def add(%EPython.PyList{contents: c1}, %EPython.PyList{contents: c2}) do
    %EPython.PyList{contents: c1 ++ c2}
  end

  def sub(_x, _y), do: :notimplemented

  def mul(_, 0), do: %EPython.PyList{contents: []}
  def mul(%EPython.PyList{contents: contents}, n) when is_integer(n) do
    contents = Enum.map_join((1..n), fn _ -> contents end)
    %EPython.PyList{contents: contents}
  end

  def floor_div(_x, _y), do: :notimplemented

  def true_div(_x, _y), do: :notimplemented

  def mod(_x, _y), do: :notimplemented

  def pow(_x, _y), do: :notimplemented
end

defimpl EPython.PySequence, for: EPython.PyList do
  defp fetchitem([head | _], 0), do: head
  defp fetchitem([_ | tail], n) when n > 0, do: fetchitem(tail, n - 1)

  def getitem(%EPython.PyList{contents: contents}, n), do: fetchitem(contents, n)

  def length(%EPython.PyList{contents: contents}), do: Kernel.length(contents)
end

defimpl EPython.PyMutableSequence, for: EPython.PyList do
  def setitem(%EPython.PyList{contents: contents}, index, value) do
    contents = List.replace_at(contents, index, value)
    %EPython.PyList{contents: contents}
  end
end

defmodule EPython.PyListIterator do
  defstruct [{:contents, []}]
end

defimpl EPython.PyIterable, for: EPython.PyList do
  def iter(%EPython.PyList{contents: contents}), do: %EPython.PyListIterator{contents: contents}
end

defimpl EPython.PyIterable, for: EPython.PyListIterator do
  def iter(iterator), do: iterator
end

defimpl EPython.PyIterator, for: EPython.PyListIterator do
  def next(%EPython.PyListIterator{contents: [head | tail]}), do: {head, %EPython.PyListIterator{contents: tail}}
  def next(%EPython.PyListIterator{contents: []}), do: throw :stopiteration
end
