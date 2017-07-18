json.extract! user, :id, :name, :user_key, :number, :sex, :age, :state_code, :is_premium, :created_at, :updated_at
json.url user_url(user, format: :json)
