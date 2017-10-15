class Document
  attr_reader :id, :filename
  DOCS_PATH = 'db/docs'
  URL_PATH  = 'docs'

  class << self
    def all
      Dir.glob("#{DOCS_PATH}/*.md").map do |filename|
        Document.new(File.basename(filename, '.*'))
      end
    end
  end

  def initialize(filename)
    @filename = filename
    @content  = content
    @title    = title
  end

  def path
    "#{DOCS_PATH}/#{self.filename}.md"
  end

  def url
    "#{URL_PATH}/#{self.filename}"
  end

  def exists?
    return false if path.include? "\u0000"
    File.exists?(path)
  end

  def title
    self.content.lines.first[2..-1].strip
  end

  def content
    @content ||= exists? ? File.read(path) : ''
  end
end
