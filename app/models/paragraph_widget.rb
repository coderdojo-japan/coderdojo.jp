class ParagraphWidget < Widget
  attribute :image, :reference
  attribute :headline, :string
  attribute :text, :string
  attribute :color, :enum, values: %w[red green blue], default: 'blue'
end
