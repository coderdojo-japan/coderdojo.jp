class Document
  attr_reader :id, :version
  DOCS_PATH = 'db/docs'

  class << self
    def all
      Dir.glob("#{DOCS_PATH}/*.md").map do |filename|
        File.basename(filename, '.*')
      end
    end
  end

  def initialize(filename, version='1.0.0')
    @filename = filename
    @version  = version
  end

  def path
    "#{DOCS_PATH}/#{@filename}.md"
  end

  def valid_file_name?
    self.class.all.include?(@filename)
  end

  def exists?
    return false if path.include? "\u0000"
    return false unless valid_file_name?
    File.exists?(path)
  end

  def content
    @content ||= valid_file_name? ? File.read(path) : ''
  end
end
