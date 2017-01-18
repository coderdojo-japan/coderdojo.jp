# -*- coding: utf-8 -*-
require 'test_helper'

class ContractTest < ActionDispatch::IntegrationTest
  test "Contract index should be exist" do
    get "/contracts"
    assert_select 'section.keiyaku a[href]', count:1
  end

  test "Teikan should be exist" do
    get "/contracts/teikan"
    assert_response :success
  end
end
