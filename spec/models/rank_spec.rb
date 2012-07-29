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
        assert_equal rank[1],1
  	  end
    end

    context "for vaidikkapoor?" do
      it "works for not ranking website" do
        @r.domain = "vaidikkapoor.info"
        rank = @r.find_rank_for_keyword "vaidik kapoor"
        assert_equal rank[1],-1
  	  end
    end
    
    context "for utorrent?" do
      it "works for url in <b>" do
        @r.domain = "utorrent.com"
        rank = @r.find_rank_for_keyword "torrent"
        assert_equal rank[1],4
  	  end
    end
    
    context "for traintesting?" do
      it "works for second page" do
        @r.domain = "traintesting"
        rank = @r.find_rank_for_keyword "testing my page"
        assert_equal rank[1],6
  	  end
    end
    
  end
end
