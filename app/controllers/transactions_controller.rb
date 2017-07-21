class TransactionsController < ApplicationController
  before_action :authorize_admin

  def notice
    unreturned = Transaction.where(return_date: nil).desc(:updated_at)
    returned = Transaction.where(:return_date.ne =>  nil).desc(:updated_at)
    @transactions = unreturned+returned
  end

  def create
    qty_tosave = params[:quantity].to_i

    if check_out_n_items(qty_tosave)
      flash[:notice] = "Check out successful."
      redirect_to(:action => 'notice')
      return
    else
        flash.now[:alert] = "Couldn't find #{qty_tosave} " +
                            "#{'item'.pluralize(qty_tosave)} for " +
                            "the given dates!"
        render 'check_out'
        return
    end
  end

  def check_in
    @transaction = Transaction.find(params[:id])
  end

  def update
    #Find a new object using form parameters
    @transaction = Transaction.find(params[:id])
    @item = @transaction.item
    # update and persist to DB
    if @transaction.update_attributes(transaction_params)
      #If save succeeds, redirect to the show action
      flash[:notice] = "Transaction updated successfully."
      redirect_to(:action => 'notice')
    else
      #If save fails, redisplay the form so user can fix problems
      render 'check_in'
    end
  end

  def direct_checkin
    #Find a new object using form parameters
    transaction = Transaction.find(params[:id])
    checkin_transaction(transaction)
    redirect_to(:action => 'notice')
  end

  def destroy
    transaction = Transaction.find(params[:id])
    result = delete_transaction(transaction)
    if result
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
    if params.has_key?(:transaction)
      @transaction = Transaction.new(transaction_params)
    else
      @transaction = Transaction.new()
    end

    if params.has_key?(:sku)
      @item = Item.find_by(_SKU: params[:sku])

      if params.has_key?(:checkout)
        if params[:transaction].has_key?(:end_date) &&
           params[:transaction][:end_date] == ""
          redirect_to multiple_check_out_path(transaction: transaction_params,
                                              sku: params[:sku], qty: params[:qty]),
                                              alert: "End date cannot be empty!"
          return
        end

        qty = params[:qty].to_i
        if check_out_n_items(qty)
          redirect_to multiple_check_out_path(transaction: transaction_params),
                                              notice: "Checked out successfully!"
        else
          redirect_to multiple_check_out_path(transaction: transaction_params,
                                              sku: params[:sku], qty: params[:qty]),
                                              alert: "No available items for the given dates!"
        end
      end
    end
    '''
    if params.has_key?(:sku)
      @item = Item.find_by(_SKU: params[:sku])

      if !params.has_key?(:submit)
        if params.has_key?(:start_date) && params[:start_date][0] != ""
          transaction = Transaction.new
          transaction.student_id = params[:student_id]
          transaction.item_id = @item._id
          transaction.start_date = params[:start_date][0]
          transaction.email = params[:email] if params[:email] != ""
          if @item.rentable
            if !params.has_key?(:end_date) || params[:end_date][0] == ""
              redirect_to multiple_check_out_path(student_id: params[:student_id],
                                                  sku: params[:sku], email: params[:email]),
                                                  alert: "End date cannot be empty!"
              return
            end
            transaction.end_date = params[:end_date][0]
          else
            transaction.end_date = transaction.start_date
          end

          picked_id = pick_available_checkout(@item, transaction.start_date, transaction.end_date)
          if !(picked_id) || picked_id==0
            redirect_to multiple_check_out_path(student_id: params[:student_id],
                                                sku: params[:sku], email: params[:email]),
                                                alert: "No available item for the given dates!"
            return
          else
            @item._quantity.delete(picked_id)
            transaction.qty_id = picked_id
            if !@item.rentable
              @item.quantity -= 1
            end
          end

          if transaction.save && @item.save
            redirect_to multiple_check_out_path(student_id: params[:student_id], email: params[:email]),
                                                notice: "Successfully checked out!"
            return
          end
        elsif params.has_key?(:start_date) && params[:start_date][0] == ""
          redirect_to multiple_check_out_path(student_id: params[:student_id],
                                              sku: params[:sku], email: params[:email]),
                                              alert: "Start date cannot be empty!"
        end
      end
    end
    '''
  end


  def student
    #just form for Student id (just input for student id)
  end

  def student_items
    @std_id = params[:input]
    @transactions = Transaction.where(:student_id => @std_id)
  end

  def student_checkin
    #Find a new object using form parameters
    transaction = Transaction.find(params[:id])
    checkin_transaction(transaction)
    @std_id = params[:student_id]
    @transactions = Transaction.where(:student_id => @std_id)
    render 'student_items'
    return
  end

  def student_destroy
    transaction = Transaction.find(params[:id])
    @std_id = params[:student_id]
    @transactions = Transaction.where(:student_id => @std_id)
    delete_transaction(transaction)
    redirect_to(:action => 'notice')
  end

  private
    def transaction_params
      params.require(:transaction).permit(:student_id, :item_id, :start_date,
                                              :end_date, :return_date, :email)
    end

    def delete_transaction(transaction)
      item = transaction.item
      # if the transaction is not checked in
      if !transaction.return_date
        item._quantity.push(transaction.qty_id)
        if !item.rentable
          item.quantity += 1
        end
      end

      return transaction.destroy && item.save
    end

    def checkin_transaction(transaction)
      item = transaction.item
      # update item info
      if (item.rentable && transaction.return_date.nil?)
        item._quantity.push(transaction.qty_id)
      end

      transaction.return_date = DateTime.now

      if transaction.save && item.save
        flash.now[:notice] = "Checked in successfully."
      else
        #If save fails, redisplay the form so user can fix problems
        flash.now[:alert] = "Check in failed"
      end
    end

    def check_out_unrentable(transaction,item)
      picked_id = item._quantity.pop()
      if picked_id.nil?
        return false
      else
        transaction.qty_id = picked_id
        item.quantity -= 1
        return (transaction.save && item.save)
      end
    end

    def check_out_rentable(transaction,item)
      start_date = transaction.start_date
      end_date = transaction.end_date

      picked_id = pick_available_checkout(item,start_date,end_date)

      if !(picked_id) || picked_id==0
        return false
      else
        item._quantity.delete(picked_id)
        transaction.qty_id = picked_id
        return (transaction.save && item.save)
      end
    end

    def undo_transactions(transactions)
      transactions.each do |t|
        delete_transaction(t)
      end
    end

    def check_out_n_items(qty_tosave)
      saved_transactions = []
      (1..qty_tosave).each do
        @transaction = Transaction.new(transaction_params)
        @item = @transaction.item
        if @item.rentable
          result = check_out_rentable(@transaction,@item)
        else
          result = check_out_unrentable(@transaction,@item)
        end

        if result
          saved_transactions.push(@transaction)
        else
          undo_transactions(saved_transactions)
          return false
        end
      end
      return true
    end

end
