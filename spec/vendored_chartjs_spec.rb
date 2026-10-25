require 'rails_helper'

# /stats のグラフは、vendor に置いた Chart.js（chart.umd.min.js）で描く（ #2009 ）。
# 自分で置いたファイルは Dependabot が上げないので、chartkick gem に同梱された Chart.js と
# 版を比べる。Dependabot が chartkick を上げて同梱の Chart.js が新しくなると、ここが赤くなる。
#
# 赤くなったら: 同じ版の公式リリース（https://github.com/chartjs/Chart.js/releases）の
# chart.js-<版>.tgz から dist/chart.umd.min.js を取り、末尾の sourceMappingURL の 1 行を外して置き換える。
# あわせて、版を書いている次の 2 か所も直す:
# - app/assets/javascripts/charts.js のコメント
# - spec/requests/stats_spec.rb の 'Chart.js v<版>'
# 同じ Chart.js を置いている mitou/jr.mitou.org の assets/js/chart.umd.min.js も一緒に上げる
RSpec.describe 'vendor に置いた Chart.js' do
  def chartjs_version(path)
    File.read(path)[/Chart\.js v(\d+\.\d+\.\d+)/, 1]
  end

  it 'chartkick gem に同梱された Chart.js と同じ版である' do
    vendored_chartjs = Rails.root.join('vendor/assets/javascripts/chart.umd.min.js').to_s
    chartkick = Gem.loaded_specs['chartkick']
    bundled_chartjs = File.join(chartkick.full_gem_path, 'vendor/assets/javascripts/Chart.bundle.js')

    vendored = chartjs_version(vendored_chartjs)
    bundled  = chartjs_version(bundled_chartjs)

    expect(vendored).not_to be_nil, "#{vendored_chartjs} の先頭に「Chart.js v<版>」の表記が見つかりません"
    expect(bundled).not_to be_nil, "chartkick #{chartkick.version} の #{bundled_chartjs} の先頭に「Chart.js v<版>」の表記が見つかりません"
    expect(vendored).to eq(bundled), "vendor の Chart.js は #{vendored}、chartkick #{chartkick.version} に同梱の Chart.js は #{bundled}。上のコメントの手順で vendor の方を上げてください"
  end
end
