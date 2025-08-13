class Book
  attr_reader :title, :filename
  DIR_PATH = 'app/views/books'

  def initialize(title, filename)
    @title    = title
    @filename = filename
  end

  class << self
    def all
      Dir.glob("#{DIR_PATH}/*").sort
    end

    def find(title)
      Dir.glob("#{DIR_PATH}/#{title}/*.html.erb").sort.map do |page|
        self.new(title, File.basename(page, '.*'))
      end
    end

    def exist?(title, page)
      return false unless page.present?
  
      view_paths = [
        Rails.root.join("app/views/books/#{title}/#{page}.html.erb"),
        Rails.root.join("app/views/#{title}/#{page}.html.erb")
      ]
  
      view_paths.any? { |path| File.exist?(path) }
    end
  end

  def path
    "#{DIR_PATH}/#{self.title}/#{self.filename}"
  end

  def exist?
    Book.find(self.title).map(&:filename).include?(self.filename)
  end
end
