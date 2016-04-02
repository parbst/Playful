class SharesController < ApplicationController
  respond_to :json, :xml

  def index
    @shares = Share.all
    respond_to do |format|
      format.json { render json: @shares, each_serializer: ShareSerializer }
    end
  end

  def show
    @share = Share.find(params[:id])
    respond_with(@share)
  end

  protected

#  def default_serializer_options
#    { root: 'shares' }
#  end
end