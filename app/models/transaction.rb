class Transaction
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  field :student_id, type: Integer
  field :email, type: String
  field :start_date, type: DateTime, default: proc {DateTime.now}
  field :end_date, type: DateTime
  field :return_date, type: DateTime
  field :qty_id, type: Integer

  belongs_to :item

  validates_presence_of :student_id
  validates_length_of :student_id, minimum: 9, maximum: 9
  validates_presence_of :start_date
  validate :check_end_date

  def check_end_date
    max_r = self.item.maximum_reservation_days
    if self.item.rentable
      if self.end_date > self.start_date + max_r.days
        errors.add(:end_date,
                    "can't be more than #{max_r} days from the given Start Date")
        return false
      elsif self.end_date < self.start_date
        errors.add(:end_date,
                    "can't be before the given start date")
        return false
      else
        return true
      end
    end #end of check end_date for nil

  end #end of check_end_date

end
