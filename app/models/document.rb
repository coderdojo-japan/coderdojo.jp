class Document
  attr_reader :id, :filename
  DIR_PATH = 'public/docs'
  URL_PATH = '/docs'

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
    begin
      # Return dummy data to save calling GitHub API
      return "2020-02-02T12:34:56+09:00" unless Rails.env.production?

      # Call GitHub API in Production
      uri  = URI.parse("https://api.github.com/repos/coderdojo-japan/coderdojo.jp/commits?path=public/docs/&per_page=1")
      json = Net::HTTP.get(uri)
      data = JSON.parse(json)

      data.first['commit']['committer']['date'].gsub('Z', "+09:00")
    rescue
      # Return dummy data if calling GitHub API failed
      "2020-02-02T12:34:56+09:00"
    end

    # TODO: This does NOT work because of Heroku FS boundary:
    # > fatal: not a git repository (or any parent up to mount point /)
    # > <lastmod>1970-01-01T00:00:00Z</lastmod>
    #
    #Time.at(%x(git --no-pager log -1 --format=%ct "#{self.path}").to_i)
    #    .utc.strftime "%Y-%m-%dT%H:%M:%SZ"
  end

  def url
    "#{URL_PATH}/#{self.filename}"
  end

  def exists?
    return false if path.include? "\u0000"
    Document.all.map(&:filename).include?(filename)
  end

  def title
    return '' unless self.exists?
    @title ||=
      ActionController::Base.helpers.strip_tags(
        Kramdown::Document.new(self.get_first_paragraph, input: 'GFM').to_html
      ).strip
  end

  def description
    return '' unless self.exists?
    @desc ||=
      ActionController::Base.helpers.strip_tags(
        Kramdown::Document.new(self.get_second_paragraph, input: 'GFM').to_html
      ).strip
  end
  def description=(text)
    @desc ||= text
  end

  def content
    @content ||= self.exists? ? File.read(self.path) : ''
  end

  private

  def get_first_paragraph
    self.content.lines.reject{|l| l =~ /^(\n|<)/ }.first.gsub('<br>', '').strip
  end

  def get_second_paragraph
    self.content.lines.reject{|l| l =~ /^(\n|<)/ }.second.gsub('<br>', '').strip
  end
end
