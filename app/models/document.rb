class Document
  attr_reader :id, :filename
  DIR_PATH = 'db/docs'
  URL_PATH = 'docs'

  class << self
    def all
      Dir.glob("#{DIR_PATH}/*.md").sort.map do |filename|
        self.new(File.basename(filename, '.*'))
      end
    end
  end

  def initialize(filename)
    @filename = filename
  end

  def path
    "#{DIR_PATH}/#{self.filename}.md"
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
    @desc  ||= exists? ? self.content.lines.reject{|l| l =~ /^(\n|<)/ }.second.gsub('<br>', '').strip : ''
  end

  def content
    @content ||= exists? ? File.read(path) : ''
  end
end
