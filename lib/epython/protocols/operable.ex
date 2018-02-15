defprotocol EPython.PyOperable do
  def add(x, y)
  def sub(x, y)
  def mul(x, y)
  def floor_div(x, y)
  def true_div(x, y)
  def mod(x, y)
end

defimpl EPython.PyOperable, for: Integer do
  # TODO: Add checks for arithmetic errors.

  def add(x, y), do: x + y

  def sub(x, y), do: x - y

  def mul(x, y), do: x * y

  def floor_div(x, y), do: :math.floor(x / y)

  def true_div(x, y), do: x / y

  def mod(x, y), do: rem(x, y)
end

defimpl EPython.PyOperable, for: Float do
  # TODO: Add checks for arithmetic errors.

  def add(x, y), do: x + y

  def sub(x, y), do: x - y

  def mul(x, y), do: x * y

  def floor_div(x, y), do: :math.floor(x / y)

  def true_div(x, y), do: x / y

  def mod(x, y), do: rem(x, y)
end

defimpl EPython.PyOperable, for: String.t do
  def add(x, y), do: x <> y

  def sub(_, _), do: :notimplemented

  # TODO: Add type check.
  def mul(x, y), do: Enum.join(Enum.map((1..y), fn -> x end))

  def floor_div(_, _), do: :notimplemented

  def true_div(_, _), do: :notimplemented

  # TODO: Add string interpolation.
  def mod(_x, _y), do: :notimplemented
end
