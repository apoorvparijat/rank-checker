require "httpclient"


class Checker
	attr_accessor :domain, :keyword, :position, :page

	def get_search_result 
		http = HTTPClient.new
		http.get "http://www.google.com/search", :q => keyword
	end


	def get_search_result_at_page (pn)
		http = HTTPClient.new
		http.get "http://www.google.com/search", {:q => keyword, :start => (pn-1)*10 }
	end

	def get_result_position_in (content)
		position = 0
		#content.scan(/<li class=\"g\">(.*?)<\/li>/) do |matched|
		content.scan(/<li class=\"g\">(.*?)<\/li>/) do |matched|
			matched.each do |m|
				#puts m + "\n------------"
				position += 1
				if(Regexp.new("<cite>[^<>]*?"+domain+"[^<>]*?</cite>") =~ m)
					return position
				end
			end
		end
		return position
	end

	def find_rank_for_keyword (kw)
		self.keyword = kw
		domain_regex = Regexp.new ("<cite>[^<>]*?"+domain+"[^<>]*?</cite>") 
		rank = []
		5.times do |x|
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
#r.domain = "vaidikkapoor.info"
#rank = r.find_rank_for_keyword "vaidik kapoor"
#puts r.to_s
