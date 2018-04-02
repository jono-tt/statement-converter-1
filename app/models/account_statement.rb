class AccountStatement
	attr_accessor :lines

	def initialize(lines)
		@lines = lines
	end

	def branch_name
		@lines[0][5].strip
	end

	def branch_number
		@lines[0][1].strip.split(//).last(4).join
	end

	def account_name
		@lines[1][5].strip
	end

	def account_number
		@lines[1][1].strip
	end

	def file_name
		"#{account_number}_#{account_name}.csv".gsub(/\s/, "-").downcase
	end

	def opening_balance
		opening_balance_row[3].to_f
	end

	def closing_balance
		closing_balance_row[3].to_f
	end

	def transactions
		items = []

		@lines[2..-1].each do |line|
			unless ["OPEN", "CLOSE"].include? line[2].strip
				items << StatementTransaction.new(line, opening_balance_date)
			end
		end

		return items
	end

        def is_valid?
                opening_balance_row[2].include? "OPEN"
        end

	def to_csv
		lines = [opening_line]
		transactions.each do | transaction |
			lines << transaction.to_row_array
		end

		output = []
		lines.each do |line|
			#Using gem 'csv' for converting row's columns into "CSV" line
			output << line.to_csv
		end

                output.join("")
	end

	private

	def opening_balance_row
		@lines[2]
	end

	def closing_balance_row
		@lines[@lines.length - 1]
	end

        def opening_line
                ["Acc No:", account_number, "Open Date:", opening_balance_date.strftime("%Y-%m-%d"), "Open Balance:", opening_balance, "Closing Balance:", closing_balance]
        end

        # for old converter
	def open_balance_line
		[opening_balance_date.strftime("%Y-%m-%d"), "", opening_balance, "", "", "####### OPENING BALANCE: R #{opening_balance} #######"]
	end
	def close_balance_line
		[closing_balance_date.strftime("%Y-%m-%d"), "", "", closing_balance, "", "####### CLOSING BALANCE: R #{closing_balance} #######"]
	end

	def opening_balance_date
                Date.parse(opening_balance_row[1].to_i.to_s)
	end

	def closing_balance_date
		Date.parse(closing_balance_row[1].to_i.to_s)
	end

end
