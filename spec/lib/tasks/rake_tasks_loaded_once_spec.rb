require 'rails_helper'
require 'rake'

Rake.application = Rake::Application.new
Rails.application.load_tasks

# 登録簿を共有したまま load_tasks を重ねると、各タスクの中身が重ねて登録され、1 回の invoke で
# タスクが 2 回以上走る。news:fetch が二重に走れば db/news.yml を 2 回上書きし、news:upsert が
# 二重に走れば DB への書き込みも 2 回になる。
# 2026年10月23日の実測では、seed によって dojos:update_db_by_yaml・news:fetch などが重なっていた。
# 各 spec が登録簿を新しくしてから読むようになっているかを、この spec が見張る。
# Rails 自身のタスク（db:load_config・tmp など）は、もともと中身を複数持つので対象にしない
RSpec.describe 'rake のタスクの読み込み' do
  it 'lib/tasks のタスクの中身は 1 つだけ登録されている' do
    lib_tasks  = Rails.root.join('lib/tasks').to_s
    duplicated = Rake::Task.tasks.select do |task|
      task.actions.count { |action| action.source_location&.first.to_s.start_with?(lib_tasks) } > 1
    end.map(&:name)

    expect(duplicated).to be_empty, "中身が重ねて登録されたタスク: #{duplicated.first(5).join(', ')}"
  end
end
