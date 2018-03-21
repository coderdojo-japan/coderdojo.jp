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
  end

  def path
    "#{DOCS_PATH}/#{self.filename}.md"
  end

  def url
    "/#{URL_PATH}/#{self.filename}"
  end

  def exists?
    return false if path.include? "\u0000"
    File.exists?(path)
  end

  def title
    @title ||= exists? ? self.content.lines.first[2..-1].strip.gsub('<br>', '') : ''
  end

  def description
    @description ||= exists? ? self.content.lines.reject{|l| l =~ /^(\n|<)/ }.second.delete('<br>').strip : ''
  end

  def content
    @content ||= exists? ? File.read(path) : ''
  end
end
