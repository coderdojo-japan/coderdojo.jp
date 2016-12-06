require 'rails_helper'

RSpec.describe 'custom_widget/show.html.erb', type: :view do
  before do
    render
  end

  it "response succesfully with content" do
    expect(response).to be
  end

  it "With coderdojo list" do
    assert_select "p.ng-binding", count:54
  end
end
