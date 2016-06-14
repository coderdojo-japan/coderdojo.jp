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
    @dojo.name = "     "
    assert_not @dojo.valid?
  end
  
end
