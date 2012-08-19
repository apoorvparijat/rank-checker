require 'spec_helper'

describe Rank do
	it "has domain" do
		FactoryGirl.create(:rank).should be_valid
	end
	
	describe "works " do
	  before :each do
	    @r = Checker.new
    end
    
    context "for browsershots.org?" do
      it "works for browsershots.org" do
        @r.domain = "browsershots.org"
        rank = @r.find_rank_for_keyword "testing my page"
        assert_equal rank[1],1
  	  end
    end

    context "for vaidikkapoor.info?" do
      it "works for ranking 1 website" do
        @r.domain = "vaidikkapoor.info"
        rank = @r.find_rank_for_keyword "vaidik kapoor"
        assert_equal rank[1],1
  	  end
    end
    
    context "for utorrent.com?" do
      it "works for url in <b>" do
        @r.domain = "utorrent.com"
        rank = @r.find_rank_for_keyword "torrent"
        assert_equal rank[1],2
  	  end
    end
    
    context "for traintesting?" do
      it "works for second page" do
        @r.domain = "traintesting.com"
        rank = @r.find_rank_for_keyword "testing my page"
        assert_equal rank[1],10
  	  end
    end
    
  end
end
