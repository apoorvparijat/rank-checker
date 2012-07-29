require "fetcher-socket"
class RankCheckerController < ApplicationController
  def index
    FetcherSocket::get_rank params["thread_str"], params[:domain], params[:keyword]
    params[:rank] = "0"
    respond_to do |format|
      format.html
      format.json {render :json => params.to_json}
    end
  end
  
  def show
    json_str = FetcherSocket::get_progress params[:id]
    json_str = json_str.chomp if json_str != nil
    respond_to do |format|
      format.html
      format.json {render :json => json_str.to_json}
    end
  end
end