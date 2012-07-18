class RankCheckerController < ApplicationController
  def index
    t = Thread.new {
      checker = Checker.new
      checker.domain = params[:domain]
      params[:rank] = checker.getRank params[:keyword]
      params[:page] = checker.page
      params[:position] = checker.position
    }
    t.join

    respond_to do |format|
      format.html
      format.json {render :json => params.to_json}
    end
  end
end