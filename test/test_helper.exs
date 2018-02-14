{_, 0} =
  System.cmd "python3", ["-m", "compileall", "test/data/codeobject_test.py"]

ExUnit.start()
