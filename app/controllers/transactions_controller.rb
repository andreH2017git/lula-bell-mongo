class TransactionsController < ApplicationController
  def display
    @items = Item.all
  end

  def notice
    @transactions = Transaction.all
  end

  def check_in
    @transaction = Transaction.find(params[:id])
  end

  def create
    @transaction = Transaction.new(transaction_params)
    #Save the object
    if @transaction.save
      #If save succeeds, redirect to the index action
      flash[:notice] = "Transaction created successfully."
      redirect_to(:action => 'display')
    else
      #If save fails, redisplay the form so user can fix problems
      render('new')
    end
  end

  def update
    #Find a new object using form parameters
    @transaction = Transaction.find(params[:id])
    #Update the object
    if @transaction.update_attributes(transaction_params)
      #If save succeeds, redirect to the show action
      flash[:notice] = "Transaction updated successfully."
      redirect_to(:action => 'notice')
    else
      #If save fails, redisplay the form so user can fix problems
      render('edit') # this renews the form template
    end
  end

  def delete
    @transaction = Transaction.find(params[:id])
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    @transaction.destroy

    flash[:notice] = "Transaction destroyed successfully."
    redirect_to(:action => 'notice')
  end

  def check_out
    @item = Item.find(params[:id])
    @transaction = Transaction.new()
  end
  private
  def transaction_params
    params.require(:transaction).permit(:student_id, :email, :start_date, :end_date, :status)
  end
end
