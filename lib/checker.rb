require "faraday"

class Checker
	attr_accessor :rank, :domain, :keyword, :position, :page, :progress
	
	def initialize
	  self.progress = 0
	  self.position = -1
	  self.page = -1
  end

	def get_search_result 
		http = HTTPClient.new
		http.get "http://www.google.com/search", :q => keyword
	end


	def get_search_result_at_page (pn)
		#http = HTTPClient.new(:agent_name => 'Mozilla/5.001 (windows; U; NT4.0; en-US; rv:1.0) Gecko/25250101')
		conn = Faraday.new
    #headers = [['Accept','text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'],['User-Agent','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4)']]
    conn.headers = {'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4)','Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'}
    
		start = (pn-1)*10
		conn.get("http://www.google.com/search?q=#{keyword}&start=#{start}")
	end

	def get_result_position_in (content)
		@position = 0
		not_matched = 0
		#content.scan(/<li class=\"g\">(.*?)<\/li>/) do |matched|
		content.scan(/<li class=\"g\">(.*?)<\/li>/) do |matched|
			matched.each do |m|
				#puts m + "\n------------"
				m.gsub! /(<[b]>|<\/[b]>|")/, ''
				@position += 1
				if(Regexp.new("<cite>[^/]*?"+ domain + "/.*?</cite>") =~ m)
					return position
				else
				  not_matched = 1
				end
			end
		end
		return not_matched == 1 ? -1 : position
	end

	def find_rank_for_keyword (kw)
		@keyword = URI.escape(kw)
		domain_regex = Regexp.new ("<cite>.*?"+domain+".*?</cite>") 
		rank = []
		20.times do |x|
		  self.progress = (x/20.0)*100.0
			content = get_search_result_at_page(x+1).body
			if (domain_regex =~ content)
        self.page = x+1
				self.position = get_result_position_in content
				break if self.position != -1
			end
		end
    @rank = (@page-1)*10 + @position 
		rank << self.page << self.position
		self.progress = 100
		return rank

	end

	def to_s
		if @position == -1
      return "Not ranking"
		end
		
		@rank = (@page-1)*10 + @position 
		str = "Domain '#{domain}' ranks for keyword '#{keyword}' at '#{position}' position on page '#{page}'.\n Rank is #{rank}"	
	end
	
	def getRank keyword
	  find_rank_for_keyword keyword
    if(position == -1)
      return 0
    end
	  @rank = (@page-1)*10 + @position
  end
  
  def to_json
    if @position == -1
      return "{}"
		end
		
		json = "{\"domain\":\"#{domain}\",\"keyword\":\"#{keyword}\",\"position\":\"#{position}\",\"page\":\"#{page}\",\"rank\":\"#{@rank}\"}"
  end

end

r = Checker.new
r.domain = "vaidikkapoor.info"
rank = r.find_rank_for_keyword "vaidikkapoor"
puts r.to_json
