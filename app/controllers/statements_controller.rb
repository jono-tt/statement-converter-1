class StatementsController < ApplicationController
  	def index
  		respond_to do |format|
  			format.html
  		end

  	end

  	def upload_file
  		# Ensure output directory is clean before the new file is uploaded
  		cleanup

  		begin
	  		file = params[:upload][:datafile]

			account_statements = StatementProcessor.new(file).process.reject { |s| ! s.is_valid? }
			
		rescue Exception => e
			$stderr.puts "An error of type #{e.class} happened, message is : #{e.message}"
		end

		account_statements.each do | i |

			if File.directory?("output_csv")
				File.open("output_csv/statements/#{i.file_name}", "w+") {|f| f.write(i.to_csv)}
			end
		end

		compress("output_csv", account_statements)
		download
	end

	def compress(path, account_statements)
		input_filenames = []
		account_statements.each do |statement|
			input_filenames << "#{statement.file_name}"
		end

		zipfile_name = "#{path}/archived_statements/statements.zip"

		Zip::ZipFile.open(zipfile_name, Zip::ZipFile::CREATE) do |zipfile|
			input_filenames.each do |filename|
				zipfile.add(filename, path+'/statements/'+filename)
			end
			zipfile.get_output_stream("README"){|os| os.write "Statements grouped by account number"}
		end
	end

	def download
		send_file ("output_csv/archived_statements/statements.zip")
	end

	def cleanup
		FileUtils.rm_rf(Dir.glob('output_csv/archived_statements/*'))
		FileUtils.rm_rf(Dir.glob('output_csv/statements/*'))
	end
end


