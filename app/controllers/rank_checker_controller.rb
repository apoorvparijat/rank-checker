require "fetcher-socket"
class RankCheckerController < ApplicationController
  def index
    rip = request.remote_ip
    rip = rip.to_s.gsub /\./, ""
    user_id = session[:user_id] ? session[:user_id] : 0
    params["thread_str"] = "#{rip}-#{Time.now.to_i}"+"-"+ params["thread_str"] + "-#{user_id}"
    FetcherSocket::get_rank params["thread_str"], params[:domain], params[:keyword]
    params[:rank] = "0"
    respond_to do |format|
      format.html
      format.json {render :json => params.to_json}
    end
  end
  
  def show
    json_str = FetcherSocket::get_progress params["id"]
    json_str = json_str.chomp if json_str != nil
    respond_to do |format|
      format.html
      format.json {render :json => json_str.to_json}
    end
  end
  
  def api
    r = Checker.new
    r.domain = params[:domain]
    rank = r.find_rank_for_keyword params[:keyword]
    respond_to do |format|
      format.html
      format.json {render :json => r.to_json}
    end
  end
end