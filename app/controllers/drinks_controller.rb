class DrinksController < ActionController::Base
  before_action :set_store
  before_action :set_drink, only: [:show, :edit, :update, :destroy]
  before_action :authenticate


  @@USERS = { "yily" => "dhkdlffl" }

  # GET /drinks
  # GET /drinks.json
  def index
    @drinks = @store.drinks.all
  end

  # GET /drinks/1
  # GET /drinks/1.json
  def show
  end

  # GET /drinks/new
  def new
    @drink = @store.drinks.new
  end

  # GET /drinks/1/edit
  def edit
  end

  # POST /drinks
  # POST /drinks.json
  def create
    @drink = @store.drinks.new(drink_params)

    respond_to do |format|
      if @drink.save
        format.html { redirect_to @store }
        format.json { render :show, status: :created, location: @drink }
      else
        format.html { render :new }
        format.json { render json: @drink.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /drinks/1
  # PATCH/PUT /drinks/1.json
  def update
    respond_to do |format|
      if @drink.update(drink_params)
        format.html { redirect_to @store }
        format.json { render :show, status: :ok, location: @drink }
      else
        format.html { render :edit }
        format.json { render json: @drink.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /drinks/1
  # DELETE /drinks/1.json
  def destroy
    @drink.destroy
    respond_to do |format|
      format.html { redirect_to store_path(@store) }
      format.json { head :no_content }
    end
  end

  private

    def set_store
      @store = Store.find(params[:store_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_drink
      @drink = @store.drinks.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def drink_params
      params.require(:drink).permit(:name, :desc, :drink_img)
    end

    def authenticate
      authenticate_or_request_with_http_digest do |username|
        @@USERS[username]
      end
    end
end
