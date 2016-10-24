class BlogPostPage < Obj
  attribute :title, :string
  attribute :image, :reference
  attribute :body, :widgetlist
  attribute :created, :date
  attribute :abstract, :html

  default_for :created do
    Time.zone.now
  end
end
