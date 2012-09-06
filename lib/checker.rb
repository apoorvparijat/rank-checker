require "faraday"
require "cgi"

##
# Global logging module used for logging
# 
# ==== Params
# 
# - +msg+ Message to be logged
# - +speaker+ Where the message is coming from
# - +filename+ Name of the file _msg_ is supposed to be stored in
module Logging
  def logger  msg, speaker, filename
    return if filename == "debug"
 	  f = File.open("/tmp/fs-#{filename}.log","a");
 	  f.puts(Time.now.to_s + ": " + speaker + ": " + msg)
 	  f.close
  end
end

##
# Connects to search engines, loops through pages until it finds the domain for a given keyword
#--
# TODO: Add support for different Google domains.
# TODO: Add support for Bing
#++
#
# In order to run the program, use this stub:
#   r = Checker.new
#   r.domain = "facebook.com"
#   rank = r.find_rank_for_keyword "apoorv parijat"
#   puts r.to_json
class Checker
  
  
	attr_accessor :rank, :domain, :keyword, :position, :page, :progress, :conn, :cookie, :progressMsg
	
	##
	# Cookies set by Google
	#--
	# TODO: Remove the Google cookies from class attributes list. Make them local or figure out some other way.
	attr_accessor :pref, :nid
	
	##
	# Relative path of the ranking page.
	attr_accessor :path
	
	##
	# Complete url of the ranking page.
	attr_accessor :url
	
	include Logging
	
	##
  # +initialize+ method used to create new connection object to be used for future connections
  # 
	def initialize
	  self.progress = 0
	  self.position = -1
	  self.page = -1
	  self.cookie = nil
	  self.conn = Faraday.new
    self.conn.headers = {'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4)','Accept' => 'text/html,application/xhtml+xml'}
    self.conn.headers["Cookie"] = ""
    
  end
  
  ##
  # Get result from Google at page +pn+
  # 
  # ==== Params
  #
  # +pn+ Page number to be queried.
  #
	def get_search_result_at_page (pn)
    @conn.headers["Cookie"] = "PREF="  + @pref  + "; " + "NID="+ @nid + ";" if @cookie != nil
		start = (pn-1)*10
		@conn.get("http://www.google.com/search?ie=UTF-8&oe=UTF-8&rls=en&gbv=1&q=#{keyword}&start=#{start}")
	end

  ##
  # Once the page has been fetched and *domain* is found in the page, this function is called to find the position of the <li> which 
  # has the domain.
  #
  # ==== Params
  # 
  # +content+ HTML fetched from the function get_search_result_at_page
	def get_result_position_in (content)
		@position = 0
		not_matched = 0
		content.scan(/<li class=\"g\">(.*?)<\/li>/) do |matched|
			matched.each do |m|
				m.gsub! /(<[b]>|<\/[b]>|")/, ''
				m.gsub! /(http:\/\/|https:\/\/)/,''
				@position += 1
				citeDomain = Regexp.new("<cite>([^/]*?"+ domain + "(/.*?))</cite>")
				matchedData = citeDomain.match(m)
				if(matchedData)
				  @url,@path = matchedData[1],matchedData[2]
					return position
				else
				  not_matched = 1
				end
			end
		end
		return not_matched == 1 ? -1 : position
	end

  ##
  # Loops 20 times and calls get_search_result_at_page for first 20 pages.
  #
  # It then checks whether the domain is listed on this page. If it does, a call to get_result_position_in method is made
  # which finds out the position of the +li+ element containing the domain.
  #
  # ==== Params
  #
  # +kw+ _keyword_ to be searched for.
  #
  # ==== Return
  #
  # +rank+ An array whos first element is the _page_ and second element is the _position_ on which the domain has been found.
  #
  #-- 
  # TODO: Shorten the function find_rank_for_keyword
  #
	def find_rank_for_keyword (kw)
    log_type = "output"
		@keyword = URI.escape(kw)
		domain_regex = Regexp.new ("<cite>.*?"+domain+".*?</cite>") 
		rank = []
		20.times do |x|
		  @progressMsg = "Checking page " + x.to_s + " .."
		  self.progress = (x/20.0)*100.0
			result = get_search_result_at_page(x+1)
			if(result.headers["set-cookie"])
			  @cookie = CGI::Cookie.parse(result.headers["set-cookie"])
			  @pref = @cookie["PREF"].first
			  @nid = @cookie["NID"].first != nil ? @cookie['NID'].first : @nid
      end
      headers = result.headers.to_s
		  
			if(result.status == 302)
        log_type = "error"
			  self.rank = -2
			  self.progress = 100
			  puts "#{result.status} - #{@domain} - #{@keyword}"
  		  puts "--------"
  		  puts result.headers.to_s
  		  puts "--------\n"
			  logger "\n#{result.status} - #{@domain} - #{@keyword}" + "\n #{headers} \n", "checker" ,log_type
			  str_msg = "#{result.status} - #{@domain} - #{@keyword}" + "\n #{headers} \n -- #{result.body} \n -- "
			  logger str_msg, "checker" , "detailed"
			  @progressMsg = "<span class='error'>Google.com redirecting request.</span>"
			  break;
      end

      content = result.body
			if (domain_regex =~ content)
        self.page = x+1
				self.position = get_result_position_in content
				break if self.position != -1
			end
			sleep 0.3
		end
    @rank = (@page-1)*10 + @position 
		rank << self.page << self.position
		@progressMsg = "Done"
		self.progress = 100
		return rank

	end

  ##
  # converts the rank details in human readable format.
  #
	def to_s
		if @position == -1
      return "Not ranking"
		end
		
		@rank = (@page-1)*10 + @position 
		str = "Domain '#{domain}' ranks for keyword '#{keyword}' at '#{position}' position on page '#{page}'.\n Rank is #{rank}"	
	end
	
	##
	# calls find_rank_for_keyword function and returns rank.
	# 
	# ==== Params
	#
	# +keyword+ _keyword_ to be searched for in the search engines.
	#
	def getRank keyword
	  logger "About to call - find_rank_for_keyword.", "checker", "debug"
	  @progressMsg = "Started checking google.com"
	  find_rank_for_keyword keyword
	  logger "Returned from - find_rank_for_keyword.", "checker", "debug"
    if(position == -1)
      return 0
    end
	  @rank = (@page-1)*10 + @position
  end
  
  ##
  # Converts the rank details to json format
  #
  # ==== Returns
  #
  # +json+ contains _domain_, _keyword_, _position_, _page_, _rank_, _url_, _path_
  #
  def to_json
    if @position == -1
      return "{}"
		end
		
		json = "{\"domain\":\"#{domain}\",\"keyword\":\"#{keyword}\",\"position\":\"#{position}\",\"page\":\"#{page}\",\"rank\":\"#{@rank}\",\"url\":\"#{@url}\",\"path\":\"#{@path}\"}"
  end

end

#r = Checker.new
#r.domain = "facebook.com"
#rank = r.find_rank_for_keyword "apoorv parijat"
#puts r.to_json