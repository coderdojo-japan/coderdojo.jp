# -*- coding: utf-8 -*-
class Contract
  attr_reader :id, :version

  class << self
    def all
      Dir.glob('db/contracts/*.md').map do |filename|
        File.basename(filename, '.*')
      end
    end
  end

  def initialize(filename, version='1.0.0')
    @filename = filename
    @version  = version
  end

  # [FIXME] - セキュリティ上の問題がある
  # バージョンとidは外部からの入力を受け付けているので、攻撃者によって、
  # ファイルシステム上のファイル名が`.md`で終わる任意のファイルの内容を表示されてしまう
  def path
    "db/contracts/#{@filename}.md"
  end

  def exists?
    return false if path.include? "\u0000"
    File.exists?(path)
  end

  def content
    @content ||= File.read(path)
  end
end
