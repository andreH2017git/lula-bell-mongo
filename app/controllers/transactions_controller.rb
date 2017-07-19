class TransactionsController < ApplicationController
  before_action :authorize_admin

  def notice
    @transactions = Transaction.all.order_by(:updated_at => 'desc')
  end

  def check_in
    @transaction = Transaction.find(params[:id])
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @item = @transaction.item

    @item = @transaction.item
    if @item._quantity.empty?
      flash[:alert] = "Out of stock!"
      render 'check_out'
      return
    else
      @transaction.qty_id = @item._quantity.pop()
      if !@item.rentable
        @item.quantity -= 1
      end
    end

    #Save the object
    if @transaction.save && @item.save
      #If save succeeds, redirect to the index action
      flash[:notice] = "Transaction created successfully."
      redirect_to(:action => 'notice')
    else
      #If save fails, redisplay the form so user can fix problems
      render 'check_out'
    end
  end

  def update
    #Find a new object using form parameters
    @transaction = Transaction.find(params[:id])
    @item = @transaction.item
    # update item info
    @item._quantity.push(@transaction.qty_id)

    # update and persist to DB
    if @transaction.update_attributes(transaction_params) && @item.save
      #If save succeeds, redirect to the show action
      flash[:notice] = "Transaction updated successfully."
      redirect_to(:action => 'notice')
    else
      #If save fails, redisplay the form so user can fix problems
      render 'check_in'
    end
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    @item = @transaction.item

    # if the transaction is not checked in
    if !@transaction.return_date
      @item._quantity.push(@transaction.qty_id)
      if !@item.rentable
        @item.quantity += 1
      end
    end
    if @transaction.destroy && @item.save
      flash[:notice] = "Transaction destroyed successfully."
    else
      flash[:alert] = "Transaction could not be deleted."
    end

    redirect_to(:action => 'notice')
  end

  def check_out
    @item = Item.find(params[:id])
    @transaction = Transaction.new()
    unless @item.rentable
      @transaction.end_date = Date.today
    end
  end

  def multiple_check_out
    logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
    logger.tagged("A Tag") {logger.info "#{params.inspect}"}

    if params.has_key?(:sku)
      @item = Item.find_by(_SKU: params[:sku])

      if params.has_key?(:start_date) && params[:start_date][0] != ""
        transaction = Transaction.new
        transaction.student_id = params[:student_id]
        transaction.item_id = @item._id
        transaction.start_date = params[:start_date][0]
        if @item._quantity.empty?
          redirect_to multiple_check_out_path(:student_id => params[:student_id], :sku => params[:sku]), alert: "Out of stock!"
          return
        else
          transaction.qty_id = @item._quantity.pop()
          if !@item.rentable
            @item.quantity -= 1
          end
        end
        if @item.rentable
          if !params.has_key?(:end_date) || params[:end_date][0] == ""
            redirect_to multiple_check_out_path(:student_id => params[:student_id], :sku => params[:sku]), alert: "End date cannot be empty!"
            return
          end
          transaction.end_date = params[:end_date][0]
        end
        if transaction.save && @item.save
          redirect_to multiple_check_out_path(:student_id => params[:student_id]), notice: "Successfully checked out!"
          return
        end
      elsif params.has_key?(:start_date) && params[:start_date][0] == ""
        redirect_to multiple_check_out_path(:student_id => params[:student_id], :sku => params[:sku]), alert: "Start date cannot be empty!"
      end
    end
  end

  private
    def transaction_params
      params.require(:transaction).permit(:student_id, :item_id, :start_date, :end_date, :return_date)
    end
end
