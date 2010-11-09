def create
	@book = Book.new(params[:book])
	if @book.save
		if params[:attached_avatar]
			attach = Attachment.create_from_upload( params[:attached_avatar], 'avatar', :owner => @book ) 
			if attach.errors.empty?
				redirect_to @book
			else
				flash[:notice] = "Attachemnt not saved: #{attach.errors}...."
				redirect_to :action => 'new'
			end
		end
	end
end