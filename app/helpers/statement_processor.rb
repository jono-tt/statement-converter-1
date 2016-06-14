class StatementProcessor 
	attr_accessor :file

	def initialize(file)
		@file = file
	end

	def process
		my_array_of_arrays = []
		CSV.foreach(@file.path) do |row|
			my_array_of_arrays << row
		end

		account_statements = []
		acc_trans_items = nil
		my_array_of_arrays.each do |line|
			if line[0].starts_with('ALL')
				#This is a new Account Statement
				if(acc_trans_items)
					account_statements << AccountStatement.new(acc_trans_items)
				end

				acc_trans_items = [line]

			elsif(acc_trans_items)
				acc_trans_items << line
			end
		end

		#add the rest where there is no last "ALL"
		account_statements << AccountStatement.new(acc_trans_items) if acc_trans_items
		account_statements
	end
end