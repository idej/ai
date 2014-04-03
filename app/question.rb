class Question
  attr_accessor :id, :conditions, :result, :mark

  def initialize(que)
    @id = que["id"]
    @conditions = que["if"]
    @result = que["then"]
  end
end
