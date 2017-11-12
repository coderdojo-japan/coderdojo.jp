module ScrivitoMockHelpers
  def mock_obj(klass, attributes={})
    obj = klass.new

    attributes.each do |name, value|
      allow(obj).to receive(name) { value }
    end

    obj
  end

  def mock_widget(klass, attributes={})
    widget = klass.new

    attributes.each do |name, value|
      allow(widget).to receive(name) { value }
    end

    widget
  end
end
