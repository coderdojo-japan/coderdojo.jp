class Stretch3sController < ApplicationController
  def new
    @stretch3 = Stretch3.new
  end

  def create
    @stretch3 = Stretch3.new(stretch3_params)
    if @stretch3.save
      # NOTE: coderdojo.jp ドメインから遷移すると Stretch3 側で ChatGPT2Scratch の API キーが不要になる処理が走る
      redirect_to 'https://stretch3.github.io', allow_other_host: true
    else
      render :new
    end
  end

  private

  def stretch3_params
    params.require(:stretch3).except(:term_of_use).permit(:email, :parent_name, :participant_name, :dojo_name)
  end
end
