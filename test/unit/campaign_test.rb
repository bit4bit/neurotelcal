require 'test_helper'

class CampaignTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "plivos from distributor" do
  end

  test "active_channels" do
    c = Campaign.first
    assert c.active_channels > 0
  end

  test "using channels empty" do
    c = Campaign.first
    assert c.using_channels == 0
  end
  
  
end
