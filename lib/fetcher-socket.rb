require 'socket'

class FetcherSocket
  
  def self.get_progress string
    host = "localhost"
    port = 2000
    s = TCPSocket.open(host,port)
    s.puts "rails"
    s.puts string

    json = s.gets
    
    json
  end
  
  def self.get_rank string, domain, keyword
    host = "localhost"
    port = 2000
    s = TCPSocket.open(host,port)
    s.puts string
    s.puts domain
    s.puts keyword
  end
  
end

#puts FetcherSocket::get_rank "vk", "vadikkapoor.info", "vaidik kapoor"
#puts FetcherSocket::get_progress "vk"