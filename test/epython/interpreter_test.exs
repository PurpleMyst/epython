defmodule EPython.InterpreterTest do
  use ExUnit.Case

  test "playground test" do
    {:ok, bf} = EPython.BytecodeFile.from_file "test/data/__pycache__/codeobject_test.cpython-36.pyc"
    EPython.Interpreter.interpret bf
  end
end
