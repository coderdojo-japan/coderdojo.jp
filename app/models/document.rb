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

    def first
      self.all.first
    end

    def last
      self.all.last
    end
  end

  def initialize(filename)
    @filename = filename
  end

  def path
    "#{DIR_PATH}/#{self.filename}.md"
  end

  def updated_at
    uri  = URI.parse("https://api.github.com/repos/coderdojo-japan/coderdojo.jp/commits?path=db/docs/&per_page=1")
    json = Net::HTTP.get(uri)
    data = JSON.parse(json)

    # This is the latest commit date in /db/docs directory
    data.first['commit']['committer']['date'].gsub('Z', "+09:00")


    # TODO: This does NOT work because of Heroku FS boundary:
    # > fatal: not a git repository (or any parent up to mount point /)
    # > <lastmod>1970-01-01T00:00:00Z</lastmod>
    #
    #Time.at(%x(git --no-pager log -1 --format=%ct "#{self.path}").to_i)
    #    .utc.strftime "%Y-%m-%dT%H:%M:%SZ"
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
