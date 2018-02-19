defprotocol EPython.PyObject do
  def parent(object)

  def getattr(object, reference, name)
end
