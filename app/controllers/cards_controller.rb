class CardsController < AppController
  # GET /cards
  # GET /cards.json
  def index
    @cards = Card.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @cards }
    end
  end

  # GET /cards/1
  # GET /cards/1.json
  def show
    @card = Card.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @card }
    end
  end

  # GET /cards/new
  # GET /cards/new.json
  def new
    @card = Card.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @card }
    end
  end

  # GET /cards/1/edit
  def edit
    @card = Card.find(params[:id])
  end

  # POST /cards
  # POST /cards.json
  def create
    @card = Card.new(params[:card])

    respond_to do |format|
      if @card.save
        notify_admin("Card Created (#{@card.last_three_digits})", @card.as_json)
        format.html { redirect_to @card, notice: 'Card was successfully created.' }
        format.json { render json: @card, status: :created, location: @card }
      else
        format.html { render action: "new" }
        format.json { render json: @card.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /cards/1
  # PUT /cards/1.json
  def update
    @card = Card.find(params[:id])

    respond_to do |format|
      if @card.update_attributes(params[:card])
        notify_admin("Card Updated (#{@card.last_three_digits})", @card.as_json)
        format.html { redirect_to @card, notice: 'Card was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @card.errors, status: :unprocessable_entity }
      end
    end
  end

  def download
    @card = Card.find(params[:id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @card }
    end
  end

  def download_file
    @card = Card.find(params[:id])

    statement_items = @card.statement_items.where("transaction_date >= ? and transaction_date <= ?", params[:from_date], params[:to_date])

    csv_string = StatementItemsHelper.generate_csv(statement_items)

    filename = "import-file_#{@card.last_three_digits}_#{params[:from_date]}_#{params[:to_date]}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8;', :filename => filename)
  end

  def notify_admin(subject, body)
    BounceIncomingMailer.bounce("murray@complexes.co.za", subject, body).deliver
    BounceIncomingMailer.bounce(ENV["NOTIFICATION_EMAIL"], subject, body).deliver if ENV["NOTIFICATION_EMAIL"] != nil
  end

  # DELETE /cards/1
  # DELETE /cards/1.json
  def destroy
    @card = Card.find(params[:id])
    @card.destroy

    notify_admin("Card Removed (#{@card.last_three_digits})", @card.as_json)

    respond_to do |format|
      format.html { redirect_to cards_url }
      format.json { head :no_content }
    end
  end
end
