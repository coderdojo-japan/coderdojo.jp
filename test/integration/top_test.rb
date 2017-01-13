# -*- coding: utf-8 -*-
require 'test_helper'

class Toptest < ActionDispatch::IntegrationTest
  test "Sponser links should be exist" do
      get "/"
      assert_select 'section.sponsors_logo a[href]', count:4
  end
end
