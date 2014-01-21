class EmailProcessor
  ADMIN_EMAIL = "support@complexes.co.za"

  def self.process(email)
    if email.from != "ibsupport@standardbank.co.za"
      error "Email not from StandardBank: #{email.from}"
    else
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
            msg = ""
            emcs.each { | emc_file |
              begin
                Dir.mktmpdir { |tmp_dir|
                  csv_files = self.extract_emc_csv_files(emc_file.path, tmp_dir, card)

                  csv_files.each { |csv_file|
                    import_file(csv_file, card)
                    msg += "File Imported: #{File.basename(csv_file)} \n"
                  }

                  msg += "File Import Complete for: #{File.basename(emc_file.path)}"
                  bounce(msg, "Success - (#{card.last_three_digits})")
                }
              rescue Exception => e
                puts e.to_s
                error(e.to_s, "Error - (#{card.last_three_digits})")
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
  end

  def self.import_file filename, card
    #ROW Starts At 21 (index 20)
    lines = IO.readlines(filename)
    csv_data = ""
    index = 0
    index_of_first_line = 0
    date_index = nil
    date = nil

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
          end
        end
      end
    end

    #parse csv
    rows = CSV.parse(csv_data)

    #get date so we can calculate short dates
    date = Date.parse(rows[date_index][1])

    rows[index_of_first_line..100000].each do | row |
      if row[2] != ""
        #calc the actual date (18 December) with no year :(
        trans_date = Date.parse(row[4] + " " + date.year.to_s)
        if trans_date > date
          trans_date = trans_date.prev_year
        end

        desc = row[0].gsub(/\W*$/, "").gsub("  ", "")

        card.statement_items << StatementItem.new(description: desc, amount: row[2], transaction_type: row[3], transaction_date: trans_date, balance: row[5])
      end
    end
  end
end
