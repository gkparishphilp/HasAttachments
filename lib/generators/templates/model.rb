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
		attachment.save
		
		directory = "#{RAILS_ROOT}/public/system/attachments/"
		Dir.mkdir( directory ) unless File.exists? directory
		
		directory += "#{attachment.owner_type}/"
		Dir.mkdir( directory ) unless File.exists? directory
		
		directory += "#{attachment.owner_id}/"
		Dir.mkdir( directory ) unless File.exists? directory
		
		directory += "#{attachment.attachment_type.pluralize}/"
		Dir.mkdir( directory ) unless File.exists? directory
		
		directory += "#{attachment.id}/"
		Dir.mkdir( directory ) unless File.exists? directory
		
		name = attachment.name
		path = File.join( directory, name )
		post = File.open( path,"wb" ) { |f| f.write( upload.read ) }

		filesize = File.size( path )
		
		attachment.update_attributes :path => path, :filesize => filesize
		
		return attachment
		
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