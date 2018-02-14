defmodule EPython.Main do
  defp compile_python(filename) do
    case System.cmd "python3.6", ["-m", "compileall", filename] do
      {output, code} when code != 0 ->
        IO.puts "Something went wrong while compiling."
        IO.puts "python's output was:"
        IO.puts output
        exit(code)

      {_, 0} ->
        dir = Path.join(Path.dirname(filename), "__pycache__")
        base = Path.basename(filename, ".py")

        Path.join(dir, base <> ".cpython-36.pyc")
    end
  end

  def main([]) do
    exit "USAGE: epython BYTECODE_FILE"
  end

  def main([filename | _]) do
    filename = case Path.extname(filename) do
      ".py"  -> compile_python filename
      ".pyc" -> filename
      ext    -> exit "Unknown extension #{ext}"
    end

    {:ok, bf} = EPython.BytecodeFile.from_file filename

    EPython.Interpreter.interpret bf
  end
end
