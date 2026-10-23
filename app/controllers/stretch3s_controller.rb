class Stretch3sController < ApplicationController
  before_action :set_dojo_options

  def new
    @stretch3 = Stretch3.new
  end

  def create
    @stretch3 = Stretch3.new(stretch3_params)
    if @stretch3.save
      # NOTE: coderdojo.jp ドメインから遷移すると Stretch3 側で ChatGPT2Scratch の API キーが不要になる処理が走る
      redirect_to 'https://stretch3.github.io', allow_other_host: true
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  # 個人情報（メールアドレス・保護者と利用者の名前）は受け取らない
  def stretch3_params
    params.require(:stretch3).permit(:dojo_id)
  end

  # 活動中の道場を、都道府県ごとにまとめて選択肢にする
  def set_dojo_options
    @dojo_options = Dojo.active.default_order.includes(:prefecture)
                        .group_by { |dojo| dojo.prefecture.name }
                        .transform_values { |dojos| dojos.map { |dojo| [dojo.name, dojo.id] } }
  end
end
