class ParagraphWidget < Widget
  attribute :headline, :string
  attribute :text, :string
  attribute :image, :reference
  attribute :color, :enum, values: 'blue'
end
