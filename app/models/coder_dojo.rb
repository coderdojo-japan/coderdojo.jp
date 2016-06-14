class CoderDojo < ActiveRecord::Base
  validates :name, 			  presence: true
  validates :course, 		  presence: true
  validates :caption, 		  presence: true
  validates :venue, 		  presence: true
  validates :region, 		  presence: true
  validates :logo_image_url,  presence: true
  validates :redirect_url,    presence: true
  validates :user_name, 	  presence: true
  validates :email,           presence: true
end
