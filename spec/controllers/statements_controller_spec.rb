require 'spec_helper'

describe StatementsController do

	it 'uploades a file' do
		statements_controller = StatementsController.new

		uploaded_file = statements_controller.upload_file

		expect(uploaded_file.content_type).to eq 'text/csv'
	end

end
