# -*- coding: utf-8 -*-
require 'test_helper'

class Toptest < ActionDispatch::IntegrationTest
  test "Sponserd link should be exist" do
      get "/"
      assert_select 'section.sponsers_logo a[href]',count:4
  end
end
