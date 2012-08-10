require "faraday"
require "cgi"

class Checker
	attr_accessor :rank, :domain, :keyword, :position, :page, :progress, :conn, :cookie, :pref, :nid
	
	def initialize
	  self.progress = 0
	  self.position = -1
	  self.page = -1
	  self.cookie = nil
	  self.conn = Faraday.new
    self.conn.headers = {'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4)','Accept' => 'text/html,application/xhtml+xml'}
    self.conn.headers["Cookie"] = ""
 	 end

	def get_search_result_at_page (pn)
		#http = HTTPClient.new(:agent_name => 'Mozilla/5.001 (windows; U; NT4.0; en-US; rv:1.0) Gecko/25250101')
    #headers = [['Accept','text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'],['User-Agent','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4)']]
    @conn.headers["Cookie"] = "PREF="  + @pref  + "; " + "NID="+ @nid + ";" if @cookie != nil
		start = (pn-1)*10
		#puts "request headers -\n #{@conn.headers.to_s}"
		@conn.get("http://www.google.com/search?ie=UTF-8&oe=UTF-8&rls=en&gbv=1&q=#{keyword}&start=#{start}")
	end

	def get_result_position_in (content)
		@position = 0
		not_matched = 0
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
    log_type = "output"
		@keyword = URI.escape(kw)
		domain_regex = Regexp.new ("<cite>.*?"+domain+".*?</cite>") 
		rank = []
		20.times do |x|
		  self.progress = (x/20.0)*100.0
			result = get_search_result_at_page(x+1)
			if(result.headers["set-cookie"])
			  @cookie = CGI::Cookie.parse(result.headers["set-cookie"])
			  @pref = @cookie["PREF"].first
			  @nid = @cookie["NID"].first != nil ? @cookie['NID'].first : @nid
      end
      headers = result.headers.to_s
		  str_msg = "#{result.status} - #{@domain} - #{@keyword}" + "\n #{headers} \n -- #{result.body} \n -- "
      log_msg str_msg, "detailed"
		  
			if(result.status == 302)
        log_type = "error"
			  self.rank = -2
			  self.progress = 100
			  puts "#{result.status} - #{@domain} - #{@keyword}"
  		  puts "--------"
  		  puts result.headers.to_s
  		  puts "--------\n"
			  log_msg "#{result.status} - #{@domain} - #{@keyword}" + "\n #{headers} \n", log_type
			  break;
      end

      content = result.body
			if (domain_regex =~ content)
        self.page = x+1
				self.position = get_result_position_in content
				break if self.position != -1
			end
			sleep 0.8
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
  
  
  def log_msg msg, type
    f = File.open(type + ".log","a")
    f.puts Time.now.to_s + ": " + msg + "\n-------------------\n"
    f.close
  end
  

end

#r = Checker.new
#r.domain = "vaidikkapoor.info"
#rank = r.find_rank_for_keyword "vaidikkapoor"
#puts r.to_json
