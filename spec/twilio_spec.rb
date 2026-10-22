require 'spec_helper'
require 'nokogiri'

# 電話の自動応答（Twilio）の TwiML。public/ の静的ファイルは POST では返らないので、
# Twilio が次に呼ぶ URL はすべて GET にし、行き先のファイルがあることを確かめる
RSpec.describe 'Twilio TwiML' do
  Dir.glob('public/twilio/*.xml').sort.each do |path|
    describe path do
      let(:twiml) { Nokogiri::XML(File.read(path)) }

      it 'requests the next URL with GET' do
        twiml.xpath('//Gather | //Record').each do |verb|
          expect(verb['action']).to start_with('https://coderdojo.jp/twilio/'),
            "#{verb.name} に action が無いと、Twilio は今の URL を POST で呼び直す"
          expect(verb['method']).to eq('GET')
        end
      end

      it 'points to existing files' do
        twiml.xpath('//*[@action]').each do |verb|
          file = verb['action'].sub('https://coderdojo.jp/', 'public/')
          expect(File).to exist(file)
        end
      end
    end
  end
end
