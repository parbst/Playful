require 'order/import/audio'

class OrdersController < ApplicationController
  respond_to :json, :xml
  around_filter :handle_exceptions

  class OrderError < StandardError; end

  def create
    if params[:order_type].blank?
      raise OrderError.new "Cannot create order, no order type specified"
    end

    ots = {
      Order::Import::Audio::TYPE => Order::Import::Audio,
      Order::Import::Movie::TYPE => Order::Import::Movie,
      Order::Import::TvSeries::TYPE => Order::Import::TvSeries,
      Order::Change::Audio::TYPE => Order::Change::Audio,
      Order::Change::Movie::TYPE => Order::Change::Movie,
      Order::Change::TvSeries::TYPE => Order::Change::TvSeries
    }
    if ots.has_key?(params[:order_type])
      order = Array(ots[params[:order_type]].create_from_params(params)).first
    else
      raise OrderError.new "Unknown order type #{params[:order_type]}"
    end

    head :created, location: order_path(order)
  end

  def show
    @order = Order.find(params[:id])
    respond_to do |format|
      format.json { render json: @order, serializer: OrderSerializer }
    end
  end

  def index
    if params.has_key?(:status)
      @orders = Order.where(:status => params[:status])
    else
      @orders = Order.all
    end
    respond_to do |format|
      format.json { render json: @orders, each_serializer: OrderSerializer }
    end
  end

  def update
    if params.has_key?(:id)
      if params.has_path?('order.status')
        @order = Order.find(params[:id])
        @order.change_status(params[:order][:status])
      end
      head :no_content
    else
      head :not_found
    end
  end

  def destroy
    if params.has_key?(:id)
      Order.destroy(params[:id])
      head :no_content
    else
      head :not_found
    end
  end

  private

  def handle_exceptions
    yield
  rescue Order::Import::ImportError, Order::OrderError, Order::OrderValidationError, ActiveRecord::RecordInvalid => exception
    render :json => {:exception => exception.class.to_s, :message => exception.message, :backtrace => exception.backtrace }, :status => :bad_request
  rescue ActiveRecord::RecordNotFound => exception
    render :json => {:exception => exception.class.to_s, :message => exception.message, :backtrace => exception.backtrace }, :status => :not_found
  end

end
