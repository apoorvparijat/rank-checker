require 'socket'                # Get sockets from stdlib
require_relative 'checker'

class FetcherThread
  
  attr_accessor :thread_id,  :domain, :keyword, :rank, :thread_str, :client, :accessed
  
  def initialize
    @c = Checker.new
    @accessed = false
  end
  
  def run
      
      @c.domain = @domain
      @rank = @c.getRank @keyword
  end
  
  def result
    json = "{\"progress\": #{@c.progress}, \"rank\" : \"#{@rank}\", \"page\" : \"#{@c.page}\", \"position\": \"#{@c.position }\"}"
  end
  
end


class Fetcher
  @@threads = Hash.new
  @@ft = Hash.new
  @@thread_count = 0
  
  def admin_access client
    
    list_all client
    
    loop do
      thread_str = client.gets.chomp
      if (thread_str == "")
        client.puts "Client list."
        list_all client
      elsif (thread_str == ".")
        client.close
        break
      else
        if (!@@ft.has_key?(thread_str))
          client.puts "-- No such client. --"
        else
          loop do
            result = @@ft[thread_str].result
            p = @@ft[thread_str].progress
            client.puts result
            sleep 0.5
            break if p > 98
          end
          client.puts @@ft[thread_str].result
        end
      end
    end
  end
  
  def list_all client
    c = 1
    @@ft.each do |key,value|
        client.puts "#{c}. " + key + " | " + @@ft[key].domain + " | " + @@ft[key].keyword + " | " + @@ft[key].accessed.to_s + "\n\t" + @@ft[key].result
        c += 1;
    end
  end
  
  def server
    init_cleanup
    @@s = TCPServer.open(2000)
    loop do
      client = @@s.accept
      type = client.gets.chomp.to_s
      if(type == "ls" || type == "") 
        Thread.new {
          admin_access client
          sleep 1
          @@ft[thread_str].accessed = false
        }
      elsif (type == "rails")
        thread_str = client.gets.chomp
        if (!@@ft.has_key?(thread_str))
        else
          result = @@ft[thread_str].result
          client.puts result
        end
        client.close
      else
        @@thread_count += 1
        temp_ft = FetcherThread.new
        temp_ft.thread_id = @@thread_count
        temp_ft.thread_str = type
        while(!temp_ft.domain = client.gets.chomp.to_s)
          temp_ft.domain = client.gets.chomp.to_s
        end
        temp_ft.keyword = client.gets.chomp.to_s
        client.puts "Checking rank for #{temp_ft.domain} keyword #{temp_ft.keyword}"
        @@ft[type] = temp_ft
        
        client.puts "Running fetcher thread in background"
        @@threads[type] = Thread.new {
          @@ft[type].run
	  logger "#{@@ft[type].thread_id}- #{@@ft[type].domain} | #{@@ft[type].keyword} \n\t #{@@ft[type].result}","background-thread","common"
          sleep 3
          @@ft[type].accessed = true
        }
        #client.close
      end
    end
  end

  def logger  msg, speaker, filename
	f = File.open("#{filename}.log","a");
	f.puts(Time.now.to_s + ": " + speaker + ": " + msg)
	f.close
  end
 
  def init_cleanup
    @@cleanup_thread = Thread.new{
      puts "clean up initialized"
      loop do
        @@ft.each do |thread_str, thread|
          if (thread.accessed)
            @@ft.delete(thread_str)
            puts "#{thread_str} removed"
          end
        end
        sleep 1
      end
    }
  end
  
end

f = Fetcher.new
f.server


