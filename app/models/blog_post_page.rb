class BlogPostPage < Obj
  attribute :title, :string
  attribute :body, :widgetlist
  attribute :created, :date

  default_for :created do
    Time.zone.now
  end
end
