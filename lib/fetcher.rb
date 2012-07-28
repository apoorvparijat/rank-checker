require 'socket'                # Get sockets from stdlib
require_relative 'checker'

class FetcherThread
  
  attr_accessor :thread_id,  :domain, :keyword, :rank, :thread_str, :client
  
  def initialize
    @c = Checker.new
  end
  
  def run
      
      @c.domain = @domain
      @rank = @c.getRank @keyword
  end
  
  def progress
    @c.progress
  end
  
  def result
    json = "{progress: #{@c.progress}, rank : #{@rank}, page : #{@c.page}, position: #{@c.position }}"
  end
  
end


class Fetcher
  @@threads = Hash.new
  @@ft = Hash.new
  @@thread_count = 0
  def server
    @@s = TCPServer.open(2000)
    loop do
      client = @@s.accept
      type = client.gets.chomp.to_s
      if(type == "ls") 
        Thread.new {
          if (@@ft.size == 0)
            client.close
            return
          end
          @@ft.each do |key,value|
            client.puts key + " | " + @@ft[key].domain + " | " + @@ft[key].keyword + "\n\t" + @@ft[key].result
          end
          thread_str = client.gets.chomp
          if (!@@ft.has_key?(thread_str))
            client.close
            @@threads[thread_str].stop
            return
          end
          loop do
            result = @@ft[thread_str].result
            p = @@ft[thread_str].progress
            client.puts result
            sleep 0.5
            break if p > 98
          end
          client.puts @@ft[thread_str].result
          client.close
        }
      elsif (type == "rails")
        thread_str = client.gets.chomp
        result = @@ft[thread_str].result
        client.puts result
        client.close
      else
        @@thread_count += 1
        temp_ft = FetcherThread.new
        temp_ft.thread_id = @@thread_count
        temp_ft.thread_str = type
        temp_ft.domain = client.gets.chomp.to_s
        temp_ft.keyword = client.gets.chomp.to_s
        client.puts "Checking rank for #{temp_ft.domain} keyword #{temp_ft.keyword}"
        @@ft[type] = temp_ft
        
        client.puts "Running fetcher thread in background"
        @@threads[type] = Thread.new {
          @@ft[type].run
        }
        client.close
      end
    end
  end
  
end

f = Fetcher.new
f.server


