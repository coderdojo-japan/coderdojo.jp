require 'test_helper'

class CoderDojoTest < ActiveSupport::TestCase
  def setup
    @dojo = CoderDojo.new(name: "Example User", 
                          course: "scratch", 
                          caption: "Weekly Event", 
                          venue: "okinawa", 
                          region: '47', 
                          logo_image_url: "https://www.example.com/logo.png", 
                          redirect_url: "https://www.facebook.com", 
                          user_name: "example", 
                          email: "user@example.com")
  end
  
  test "should be valid" do
    assert @dojo.valid?
  end

  test "name should be present" do
    @dojo.name  = "    "
    assert_not @dojo.valid?
  end
  
  test "course should be present" do
  	@dojo.course = "    "
  	assert_not @dojo.valid?
  end

  test "caption should be present" do
  	@dojo.caption = "    "
  	assert_not @dojo.valid?
  end

  test "venue should be present" do
  	@dojo.venue = "    "
  	assert_not @dojo.valid?
  end

  test "region should be present" do
  	@dojo.region = '    '
  	assert_not @dojo.valid?
  end
  
  test "logo should be present" do
  	@dojo.logo_image_url = "    "
  	assert_not @dojo.valid?
  end

  test "dojo url should be present" do
  	@dojo.redirect_url = "    "
  	assert_not @dojo.valid?
  end

  test "user name should be present" do
  	@dojo.user_name = "    "
  	assert_not @dojo.valid?
  end

end
