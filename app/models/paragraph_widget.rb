class ParagraphWidget < Widget
  attribute :image, :reference
  attribute :headline, :string
  attribute :text, :string
  attribute :background_color_select, :enum, values: ["red","green","blue"], default: "red" 
end
