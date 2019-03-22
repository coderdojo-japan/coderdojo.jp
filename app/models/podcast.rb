class Podcast
  attr_reader :id, :filename
  DIR_PATH  = 'public/podcasts'
  URL_PATH  = 'podcasts'

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

  def exists?(offset: 0)
    return false if path.include? "\u0000"
    File.exists?("#{DIR_PATH}/#{self.filename.to_i + offset}.md")
  end

  def filesize
    @size ||= File.size("#{DIR_PATH}/#{self.filename}.mp3")
  end

  def duration
    return @duration if @duration

    path = "#{DIR_PATH}/#{self.filename}.mp3"
    open_opts = { :encoding => 'utf-8' }
    Mp3Info.open(path, open_opts) do |mp3info|
      @duration = Time.at(mp3info.length).utc.strftime('%H:%M:%S')
    end
  end

  def title
    @title ||= exists? ? self.content.lines.first[2..-1].strip.gsub('<br>', '') : ''
  end

  def description
    @desc  ||= exists? ? self.content.lines.reject{|l| l =~ /^(\n|<)/ }.second.delete('<br>').strip : ''
  end

  def published_at
    @pubDate ||= exists? ? Time.parse(self.content.lines.second.gsub(/<.+?>/, '').delete('収録日: ')) : ''
  end

  def content
    @content ||= exists? ? File.read(path) : ''
  end
end
