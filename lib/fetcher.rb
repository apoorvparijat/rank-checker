# Get sockets from stdlib
require 'socket'
require 'rubygems'
require 'active_record'
require 'logger'
require_relative 'checker'
ActiveRecord::Base.establish_connection(  
:adapter => "mysql2",  
:host => "localhost",  
:database => "rank-checker_development"  
)
ActiveRecord::Base.logger = Logger.new(STDERR)

require_relative '../app/models/rank'
##
# FetcherThread instance is handled by threads. For each request, new FetcherThread object is created and the execution is allowed 
# to be handled by threads.
class FetcherThread
  include Logging
  attr_accessor :thread_id,  :domain, :keyword, :rank, :client, :accessed
  ## is a unique identifier for the request and the thread.
  attr_accessor :thread_str
  
  ##
  # creates a new object for checker and sets the @accessed flat to false
  def initialize
    @c = Checker.new
    @accessed = false
  end
  
  ##
  # the method configures the +checker+ object with the domain name and calls the Checker#getRank method on it.
  # The code of this function is run by thread.
  def run
    
    @c.domain = @domain
    client.puts "here"
    #@rank = @c.getRank @keyword
    # TODO: split +thread_str+ with delimiter "-". Last substring is the user_id. Use this to save the result in database against the +user_id+.
    user_id = @thread_str.split("-")
    client.puts "here"
    client.puts Rank.nil?
    #r = Rank.new
    #Rank.create(:domain => @domain, :keyword => @keyword, :page => @c.page, :rank => @rank, :position => @c.position, :url => @c.url, :path => @c.path, :user_id => user_id)
    client.puts "here"
    client.puts user_id[3]
    
  end
  
  ##
  # the method returns _json_ representation of the current state of the _Checker_ object along with the +progress+
  def result
    json = "{\"message\":\"#{@c.progressMsg}\",\"progress\": #{@c.progress.to_i}, \"rank\" : \"#{@rank}\", \"page\" : \"#{@c.page}\", \"position\": \"#{@c.position }\",\"url\":\"#{@c.url}\",\"path\":\"#{@c.path}\"}"
  end
  
end

##
# has the code for _Fetcher_ server.
# Code to start the server:
#   f = Fetcher.new
#   f.server
class Fetcher
  include Logging
  @@threads = Hash.new
  @@ft = Hash.new
  @@thread_count = 0
  
  ##
  # method to handle admin access to the client
  #
  # ==== Params
  # - +client+ : socket connection object
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
  
  ##
  # method to list all the connected clients
  def list_all client
    c = 1
    @@ft.each do |key,value|
        client.puts "#{c}. " + key + " | " + @@ft[key].domain + " | " + @@ft[key].keyword + " | " + @@ft[key].accessed.to_s + "\n\t" + @@ft[key].result
        c += 1;
    end
  end
  
  ##
  # method to start listening to start the socket server. It has the code to receive client connections.
  # Connection can be of 3 types 
  # - admin: admin connection helps in getting a list of active clients and tracking a particular client
  # This connection awaits client input
  # - rails: rails connection allows for quickly checking the progress of a particular client. The +result+ of the FetcherThread is 
  # displayed and the code returns.
  # - telnet-client: this type of connection exists to test the server. It accepts +domain+, +keyword+ and a unique +queue_id+ and returns
  # after queueing the request to the server
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
        if (@@ft.has_key?(thread_str))
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
        temp_ft.client = client
        #client.puts "Checking rank for #{temp_ft.domain} keyword #{temp_ft.keyword}"
        @@ft[type] = temp_ft
        
        #client.puts "Running fetcher thread in background"
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
  
  ##
  # the method starts a new thread that runs forever. The job of this thread is to clean the finished request.
  # This is done by setting the hash value for that +queue_id+ to nil. 
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
