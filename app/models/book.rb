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
      Dir.glob("#{DIR_PATH}/#{title}/*.html.erb").sort.map do |filename|
        self.new(title, File.basename(filename, '.*'))
      end
    end

    def exist?(title, filename)
      self.find(title).map(&:filename).include?(filename)
    end
  end

  def path
    "#{DIR_PATH}/#{self.title}/#{self.filename}"
  end

  def exist?
    Book.find(self.title).map(&:filename).include?(self.filename)
  end
end
