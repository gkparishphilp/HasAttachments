class Attachment < ActiveRecord::Base
  
	belongs_to :owner, :polymorphic => true
	
	scope :for_owner, lambda { |owner| where( ["owner_id = ? AND owner_type = ?", 
									owner.id, owner.class.name ] ) }
	scope :by_type, lambda { |type| where( "attachment_type = ?", type ) }						
	
	scope :active, where( "status = 'active'" )
	
	
	# Class methods
	def self.recent( since = 1.week.ago )
		where( "created_at > ?", since )
	end
	
	def self.create_from_upload( upload, type, opts={} )
		ext = upload.original_filename.match( /\.\w*$/ ).to_s # a period, any number of word chars, then eol
		#should have some way to validate
		# but oh well....
		attachment = Attachment.new :name => upload.original_filename, :format => ext, :attachment_type => type
		attachment.owner = opts[:owner] if opts[:owner]
		
		if attachment.save
			# use public save path by default
			directory = "#{PUBLIC_ATTACHMENT_PATH}"
			# unless the parent object has declared a default path for this attachment_type
			directory = eval "self.owner.#{self.attachment_type}_path" if self.owner.respond_to? "#{self.attachment_type}_path"
			# but a specific private request to this method trumps either
			directory = "#{PRIVATE_ATTACHMENT_PATH}" if opts[:private] == 'true'
		
			directory += "/#{attachment.owner_type.pluralize}/#{attachment.owner_id}/#{attachment.attachment_type.pluralize}/#{attachment.id}/"
		
			directory = create_directory( directory )
		
			name = attachment.name
			path = File.join( directory, name )
			post = File.open( path,"wb" ) { |f| f.write( upload.read ) }

			filesize = File.size( path )
		
			attachment.update_attributes :path => path, :filesize => filesize
		
			return attachment
		else
			return false
		end
		
	end
	
	def self.create_from_url( url )
		
	end
	
	# instance methods
	def active?
		self.status == 'active'
	end
	
	def delete!
		self.update_attribute( :status => 'deleted' )
	end
	
	
	
end