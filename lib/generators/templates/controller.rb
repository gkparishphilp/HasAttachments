def create
	@book = Book.new params[:book]
	if @book.save
		process_attachments_for( @book )
	else
		pop_flash "There was a problem with the book:", :notice, @book
	end
	
	if flash[:notice].blank?
		redirect_to @book
	else
		render :new
	end

end

def process_attachments_for( obj )
	for key in params.keys do
		if key =~ /attached_(.+)_/
			resource = params[key] unless params[key].blank?
			attach = Attachment.create_from_resource( resource, $1, :owner => obj )
			pop_flash "There was a problem with the #{attach.name} Attachment", :notice, attach unless attach.errors.empty?
		end
	end
end

# populates the flash with message and error messages if any
def pop_flash( message, code = :success, *object )
	if flash[code].nil?
		flash[code] = "<b>#{message}</b>"
	else
		flash[code] += "<br><b>#{message}</b>"
	end
	object.each do |obj|
		obj.errors.each do |field, msg|
			flash[code] += "<br>" + field.to_s + ": " if field
			flash[code] += " " + msg 
		end
	end
end