class BlogPage < Obj
  attribute :title, :string
  attribute :image, :reference
  attribute :body, :widgetlist
  attribute :child_order, :referencelist
end
