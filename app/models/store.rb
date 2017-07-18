class Store < ApplicationRecord
  has_many :drinks, dependent: :destroy
  has_many :vouchers, through: :drinks, source: :vouchers

  def today_vouchers
    vouchers.where('vouchers.created_at >= ?', (Time.now-9.hours).beginning_of_day)
  end

  def week_vouchers_size
    # 12시 넘어서 6시간 전까지 전날로 봄
    if (Time.now - 6.hours).on_weekday?
      weekday_voucher
    else
      weekend_voucher
    end
  end

  def vouchers_left_size
    week_vouchers_size - today_vouchers.size
  end
end
