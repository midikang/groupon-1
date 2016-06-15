class OrdersController < ApplicationController

  before_action :authenticate
  #FIXME_AB: we don' need deal for destroy an order
  before_action :set_deal, only: [:new, :edit, :update]
  before_action :set_pending_order, only: [:edit, :update, :destroy]
  before_action :set_paid_order, only: [:show]

  def index
    #FIXME_AB: need to eager load data, check log
    user = User.where(id: current_user.id).includes(:orders).first
    @orders = user.orders.not_pending.paginate(page: params[:page])
  end

  def new
    current_user.orders.pending.destroy_all
    @order = @deal.orders.new
    @order.user = current_user
    if @order.save
      redirect_to edit_deal_order_path(@deal, @order)
    else
      render "deals/show"
    end
  end

  def edit
  end

  def update
    @order.quantity = params[:quantity]
    if @order.save
      #FIXME_AB: show success message
      redirect_to edit_deal_order_path(@deal, @order), alert: " Successfully added #{ @order.quantity } quantity to your order."
    else
      render :edit
    end
  end

  def show

  end

  def destroy
    if @order.destroy
      redirect_to root_path, notice: 'Order was cancelled.'
    else
      redirect_to :back, alert: 'Fail to cancel the order.'
    end
  end

  private

  def set_deal
    @deal = Deal.live.find_by_id(params[:deal_id])
    if @deal.nil?
      redirect_to deals_path, alert: "No such Deal exists."
    end
  end

  def set_pending_order
    @order = current_user.orders.pending.find_by_id(params[:id])
    if @order.nil?
      redirect_to deals_path, alert: "No such Order exists."
    end
  end

  def set_paid_order
    @order = current_user.orders.not_pending.find_by_id(params[:id])
    if @order.nil?
      redirect_to deals_path, alert: "No such Order exists."
    end
  end

end
