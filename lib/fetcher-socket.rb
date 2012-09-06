require 'socket'

##
# Class used by rails app to queue fetching jobs to the fetcher server.
# The class is specifically used by RankCheckerController class
# 
# Usage
#   puts FetcherSocket::get_rank "vk", "vadikkapoor.info", "vaidik kapoor"
#   puts FetcherSocket::get_progress "vk"
class FetcherSocket
  
  class << self
    ##
    # method which when called by rails with id as +string+, returns the complete result of FetcherThread#result
    #
    # ==== Params
    # - +string+ thread_id coming from front end
    #
    # ==== Returns
    # - +json+ result from FetcherThread#result
    def get_progress string
      host = "localhost"
      port = 2000
      s = TCPSocket.open(host,port)
      s.puts "rails"
      s.puts string

      json = s.gets
    
      json
    end
  
    ##
    # method used to queue job.
    #
    # ==== Parmas
    # - +string+ : +thread_str+ to uniquely idenftify the request
    # - +domain+ : domain to search ranking for
    # - +keyword+ : keyword to search for in search engine
    def get_rank string, domain, keyword
      host = "localhost"
      port = 2000
      s = TCPSocket.open(host,port)
      s.puts string
      s.puts domain
      s.puts keyword
    end
  end
  
end

