# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Store.create(name:"바코드",desc:"바코드는 테이블이 없다.")
Store.create(name:"바틸트",desc:"바틸트는 꽃 칵테일!")
Store.create(name:"헤븐스도어",desc:"헤븐스도어는 고양이!")
Store.create(name:"모어댄위스키",desc:"모어댄위스키는 댄디!")

drinks = ["수연", "칼보네이티드", "쿠쿠"]
drinks.each do |drink|
  @drink = Drink.create(name:drink)
  Store.find_by(name:"바코드").drinks << @drink
end

drinks = ["In Bloom", "바람", "꽃술"]
drinks.each do |drink|
  @drink = Drink.create(name:drink)
  Store.find_by(name:"바틸트").drinks << @drink
end

drinks = ["C&C진저", "피스콜라", "호호"]
drinks.each do |drink|
  @drink = Drink.create(name:drink)
  Store.find_by(name:"헤븐스도어").drinks << @drink
end

drinks = ["갓파더"]
drinks.each do |drink|
  @drink = Drink.create(name:drink)
  Store.find_by(name:"모어댄위스키").drinks << @drink
end
