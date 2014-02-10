class EmailProcessor
  ADMIN_EMAIL = "import@complexes.co.za"

  def self.process(email)
    #Subject: 
    # Your Standard Bank Provisional Statement - 2014-01-13(Card No......130)
    match = email.subject.match(/.*(\d{3})\)/)

    if match != nil
      card = Card.find_by_last_three_digits(match[1])

      if(card != nil)
        emcs = email.attachments.select { |file| file.original_filename.match(/emc$/) }

        if(emcs.length == 0)
          error "Unable to find any attachments"
        else
          emcs.each { | emc_file |
            msg = ""
            imported_files = []
            files_processed = 0

            begin
              Dir.mktmpdir { |tmp_dir|
                csv_files = self.extract_emc_csv_files(emc_file.path, tmp_dir, card)

                csv_files.each { |csv_file|
                  imported_file = import_file(csv_file, card)
                  imported_files.push imported_file

                  msg += "File Imported: #{imported_file[:statement_type]}: #{File.basename(csv_file)} \n"
                  files_processed += 1
                }

                msg += "File Import Complete for: #{File.basename(emc_file.path)}"
              }
            rescue Exception => e
              error(e.to_s, "Error - (#{card.account_name}: #{card.last_three_digits})")
              return
            end

            if files_processed > 0
              bounce_with_attachment(msg, "Success - (#{card.account_name}: #{card.last_three_digits})", "#{card.account_name}-c#{card.last_three_digits}_#{File.basename(emc_file.path)}", imported_files)
            else
              error "No csv files found to process", "Error - (#{card.account_name}: #{card.last_three_digits})"
            end
          }
        end
      else
        error "Unable to find card for digits: #{match[1]}"
      end
    else
      error "Unable to find last three digits in the subject: #{email.subject}"
    end
  end

  def self.extract_emc_csv_files(file, tmp_dir, card)
    output = `striata-readerc -outdir="#{tmp_dir}" -username="#{card.card_number}" -password="#{card.password}" "#{file}"`

    if $?.exitstatus != 0
      raise "Decrypt Error: #{output}"
    end

    #we can get all the extracted CSV files
    dir = Rails.root.join(tmp_dir, '*.csv')
    return Dir.glob(dir)
  end

  def self.error(msg, subject = "Error")
    msg = "Error: #{msg}"
    Rails.logger.error(msg)
    bounce(msg, subject)
  end

  def self.bounce(msg, type)
    Rails.logger.info "Sending bounce message: #{ADMIN_EMAIL} - #{msg}"
    BounceIncomingMailer.bounce(ADMIN_EMAIL, "Statement Converter: #{type}", msg).deliver
    BounceIncomingMailer.bounce(ENV["NOTIFICATION_EMAIL"], "Statement Converter: #{type}", msg).deliver if ENV["NOTIFICATION_EMAIL"] != nil
  end

  def self.bounce_with_attachment(msg, type, attachment_base_name, imported_files)
    imported_files
    attachments = []

    imported_files.each { | imported_file |
      content = StatementItemsHelper.generate_csv(imported_file[:statement_items])

      if content.empty?
        content = "No Statement Items"
      end

      attachments.push({
        :filename => "#{attachment_base_name}_#{imported_file[:statement_type]}.csv",
        :mime_type => "application/csv",
        :content => content
      })
    }

    Rails.logger.info "Sending bounce message with attachment: #{ADMIN_EMAIL} - #{msg}"
    BounceIncomingMailer.bounce(ADMIN_EMAIL, "Statement Converter: #{type}", msg, attachments).deliver
    BounceIncomingMailer.bounce(ENV["NOTIFICATION_EMAIL"], "Statement Converter: #{type}", msg, attachments).deliver if ENV["NOTIFICATION_EMAIL"] != nil
  end

  def self.import_file filename, card
    #ROW Starts At 21 (index 20)
    lines = IO.readlines(filename)
    csv_data = ""
    index = 0
    index_of_first_line = 0
    date_index = nil
    date = nil
    types_index = nil
    statement_type = nil

    lines.each do |line|
      if(line.index(",") != nil)
        line = line.gsub("\n", "").gsub("\r", "")

        #must not end in '","'
        if (line[line.length - 2] + line[line.length - 1]) != ",\""
          index += 1
          csv_data += line + "\n"

          if(line.index("BALANCE BROUGHT FORWARD") != nil)
            index_of_first_line = index
          elsif(line.index("\"Date:\",") != nil)
            date_index = index - 1
          elsif(line.index("\"Type:\",") != nil)
            types_index = index - 1
          end
        end
      end
    end

    #parse csv
    rows = CSV.parse(csv_data)

    #get date so we can calculate short dates
    date = Date.parse(rows[date_index][1])
    statement_type = rows[types_index][1]
    statement_items = []

    #ADD THE OPENING BALANCE
    row = rows[index_of_first_line - 1]
    balance = BigDecimal(row[5].gsub(/^\d*$/, "").gsub("  ", ""), 12)
    open_balance_item = StatementItem.new(description: "####### OPENING BALANCE: #{balance} #######", amount: "100000000", transaction_type: "CR", transaction_date: date, balance: balance, statement_type: statement_type)
    statement_items << open_balance_item
    card.statement_items << open_balance_item

    #ADD ALL TRANSACTION ROWS
    rows[index_of_first_line..100000].each do | row |
      if row[2] != ""
        #calc the actual date (18 December) with no year :(
        trans_date = Date.parse(row[4] + " " + date.year.to_s)
        if trans_date > date
          trans_date = trans_date.prev_year
        end

        desc = row[0].gsub(/\W*$/, "").gsub("  ", "")

        statement_item = StatementItem.new(description: desc, amount: row[2], transaction_type: row[3], transaction_date: trans_date, balance: row[5], statement_type: statement_type)
        statement_items << statement_item
        card.statement_items << statement_item
      end
    end

    #UPDATE OPEN BALANCE DATE
    if statement_items[1] != nil
      open_balance_item.transaction_date = statement_items[1].transaction_date
      open_balance_item.save
    end

    #ADD CLOSE BALANCE
    last_item = statement_items[statement_items.length - 1]
    close_balance_item = StatementItem.new(description: "####### CLOSING BALANCE: #{last_item.balance} #######", amount: "100000000", transaction_type: "CR", transaction_date: date, balance: last_item.balance, statement_type: statement_type)
    statement_items << close_balance_item
    card.statement_items << close_balance_item

    return { statement_type: statement_type, statement_items: statement_items }
  end
end
