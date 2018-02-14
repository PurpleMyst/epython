defmodule EPython.Main do
  def main([]) do
    IO.puts "USAGE: epython BYTECODE_FILE"
  end

  def main([filename | _]) do
    {:ok, bf} = EPython.BytecodeFile.from_file filename

    EPython.Interpreter.interpret bf
  end
end
