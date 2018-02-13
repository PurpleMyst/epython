defmodule EPython.CodeObject do
  defstruct [:magic, :names, :varnames, :constants, :code]

  def from_file(filename) do
    case File.read(filename) do
      {:ok, contents} -> {:ok, parse_contents contents}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_contents(contents) do
    IO.inspect contents
  end
end
