require "httpclient"
require 'htmlentities'

class Checker
	attr_accessor :domain, :keyword, :position, :page, :progress
	
	def initialize
	  progress = 0
  end

	def get_search_result 
		http = HTTPClient.new
		http.get "http://www.google.com/search", :q => keyword
	end


	def get_search_result_at_page (pn)
		http = HTTPClient.new(:agent_name => 'Mozilla/5.001 (windows; U; NT4.0; en-US; rv:1.0) Gecko/25250101')
		http.follow_redirect_count = 2
		start = (pn-1)*10
		@keyword = URI.escape(@keyword)
		http.get "http://www.google.com/search?q=#{keyword}&start=#{start}"
	end

	def get_result_position_in (content)
		position = 0
		not_matched = 0
		#content.scan(/<li class=\"g\">(.*?)<\/li>/) do |matched|
		content.scan(/<li class=\"g\">(.*?)<\/li>/) do |matched|
			matched.each do |m|
				#puts m + "\n------------"
				m.gsub! /(<[b]>|<\/[b]>|")/, ''
				position += 1
				if(Regexp.new("<cite>.*?"+ domain + ".*?</cite>") =~ m)
					return position
				else
				  not_matched = 1
				end
			end
		end
		return not_matched == 1 ? -1 : position
	end

	def find_rank_for_keyword (kw)
		self.keyword = kw
		domain_regex = Regexp.new ("<cite>.*?"+domain+".*?</cite>") 
		rank = []
		20.times do |x|
		  self.progress = (x/20.0)*100.0
			content = get_search_result_at_page(x+1).content
			if (domain_regex =~ content)
				self.page = x+1
				self.position = get_result_position_in content
				break
			end
		end
		if self.position == 0
			puts "Not ranking."
		end

		rank << self.page << self.position
		self.progress = 100
		return rank

	end

	def to_s
		if !page
			puts "Not ranking"
			return
		end
		rank = (page-1)*10 + position
		str = "Domain '#{domain}' ranks for keyword '#{keyword}' at '#{position}' position on page '#{page}'.\n Rank is #{rank}"	
	end
	
	def getRank keyword
	  find_rank_for_keyword keyword
    if(!page)
      return 0
    end
	  rank = (page-1)*10 + position
  end

end

#r = Checker.new
#r.domain = "browsershots.org"
#rank = r.find_rank_for_keyword "testing my page"
#puts r.to_s
