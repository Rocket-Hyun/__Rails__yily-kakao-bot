json.extract! store, :id, :name, :region_code, :lat, :lng, :weekday_voucher, :weekend_voucher, :desc, :store_img, :store_url, :menu, :created_at, :updated_at
json.url store_url(store, format: :json)
