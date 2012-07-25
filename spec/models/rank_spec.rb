require 'spec_helper'

describe Rank do
	it "has domain" do
		FactoryGirl.create(:rank).should be_valid
	end
	
	describe "works " do
	  before :each do
	    @r = Checker.new
    end
    context "for browsershots?" do
      it "works for browsershots" do
        @r.domain = "browsershots"
        rank = @r.find_rank_for_keyword "testing my page"
        assert_equal rank[0],1
  	  end
    end

    context "for vaidikkapoor?" do
      it "works for vaidikkapoor" do
        @r.domain = "vaidikkapoor.info"
        rank = @r.find_rank_for_keyword "vaidik kapoor"
        assert_equal rank[0],nil
  	  end
    end
  end
end
