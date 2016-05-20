class ParagraphWidget < Widget
  attribute :image, :reference
  attribute :headline, :string
  attribute :text, :string
  attribute :color, :enum, values: %w[red green blue], default: 'blue'
  attribute :size, :enum, values: ["small","medium","large"]

end
