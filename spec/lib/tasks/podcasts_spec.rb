require 'rails_helper'
require 'rake'

RSpec.describe 'DojoCast:', podcast: true do
  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require 'tasks/podcasts'
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    @rake[task].reenable
  end

  describe 'podcasts:upsert' do
    let(:task) { 'podcasts:upsert' }

    before :each do
      Podcast.destroy_all
    end

    it '既存のanchorfm_sample.rssでRakeタスクがエラーなく動作し、エピソードが複数登録される' do
      expect { Rake::Task['podcasts:upsert'].reenable; Rake::Task['podcasts:upsert'].invoke }
        .not_to raise_error

      expect(Podcast.count).to be > 0
      expect(Podcast.pluck(:title)).to include('001 - 日本の CoderDojo の成り立ち')
    end
  end
end
