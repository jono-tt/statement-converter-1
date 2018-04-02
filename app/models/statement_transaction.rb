class StatementTransaction
	attr_accessor :line

	def initialize(line, opening_balance_date)
		@line = line
		@opening_balance_date = opening_balance_date
	end

	def to_row_array
		[date, amount, "", "", "", description]
	end

	def date
                # 020180301
                Date.parse(@line[1].to_i.to_s)
	end

	def abbreviation
		@line[2].strip
	end

	def amount
		@line[3].to_f
	end

	def description
		@line[4].gsub(/#/, "").strip + " - " + @line[5].gsub(/#/, "").strip
	end

	def beneficiary
		@line[5].strip
	end
end
