defprotocol EPython.PySequence do
  def getitem(sequence, index)
  def length(sequence)
end
