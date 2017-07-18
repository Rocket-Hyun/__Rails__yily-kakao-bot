class User < ApplicationRecord
  has_many :vouchers, dependent: :destroy
end
