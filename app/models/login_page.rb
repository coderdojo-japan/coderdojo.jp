class LoginPage < Obj
  attribute :title, :string
  attribute :body, :widgetlist
  attribute :child_order, :referencelist

  def self.instance
    all.first
  end
end
