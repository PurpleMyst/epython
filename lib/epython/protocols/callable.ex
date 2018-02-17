defprotocol EPython.PyCallable do
  @doc "Call a function"
  def call(func, args, state)
end
