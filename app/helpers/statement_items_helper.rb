module StatementItemsHelper
  def self.generate_csv(statement_items)
    csv_string = CSV.generate do |csv|
      statement_items.each do |entry|
        if entry.transaction_type == "DR"
          val = "-#{entry.amount}"
        else
          val = "#{entry.amount}"
        end

        csv << [entry.transaction_date, val, "", "", "", entry.description ]
      end
    end

    return csv_string
  end
end
