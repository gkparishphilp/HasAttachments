class Attachment < ActiveRecord::Base
	include HasAttachments::AttachmentLib
	
	validates	:name, :uniqueness => { :scope => [:owner_id, :owner_type, :attachment_type] }
	
	belongs_to :owner, :polymorphic => true
	
	scope :for_owner, lambda { |owner| where( ["owner_id = ? AND owner_type = ?", 
									owner.id, owner.class.name ] ) }
	scope :by_type, lambda { |type| where( "attachment_type = ?", type ) }						
	
	scope :active, where( "status = 'active'" )
	
	
	# Class methods
	def self.recent( since = 1.week.ago )
		where( "created_at > ?", since )
	end
	
	def self.create_from_resource( resource, type, opts={} )
		if resource =~ /\Ahttp:\/\//
			name, ext = Attachment.new.parse_name( resource )
		else
			name, ext = Attachment.new.parse_name( resource.original_filename )
		end

		attachment = Attachment.new :name => name, :format => ext, :attachment_type => type
		attachment.owner = opts[:owner] if opts[:owner]
		
		if attachment.valid?
			path = attachment.create_path( opts )
		
			name = "#{attachment.name}.#{attachment.format}"
			write_path = File.join( path, name )
			if resource =~ /\Ahttp:\/\//
				image = MiniMagick::Image.open( resource )
				image.write( write_path )
			else
				post = File.open( write_path,"wb" ) { |f| f.write( resource.read ) }
			end
			
			filesize = File.size( write_path )
		
			attachment.filesize = filesize
			attachment.path = path
		end
		
		attachment.save
		
		return attachment
	end
	
	
	# instance methods
	def location( style=nil )
		path = self.path.gsub( /\A.+public/, "" )
		style ? "#{path}#{self.name}_#{style}.#{self.format}" : "#{self.path}#{self.name}.#{self.format}"
	end
	
	def create_path( opts={} )
		# use public save path by default
		directory = "#{PUBLIC_ATTACHMENT_PATH}"
		# unless the parent object has declared a default path for this attachment_type
		directory = eval "self.owner.#{self.attachment_type}_path" if self.owner.respond_to? "#{self.attachment_type}_path"
		# but a specific private request to this method trumps either
		directory = "#{PRIVATE_ATTACHMENT_PATH}" if opts[:private] == 'true'
	
		directory += "/#{self.owner_type.pluralize}/#{self.owner_id}/#{self.attachment_type.pluralize}/"
	
		directory = create_directory( directory )
	end
	
	def active?
		self.status == 'active'
	end
	
	def delete!
		self.update_attribute( :status => 'deleted' )
	end
	
	def process_resize( styles )
		for style_name, style_detail in styles
			directory = self.path
			orig_filename = "#{self.name}.#{self.format}"
			output_filename = "#{self.name}_#{style_name}.#{self.format}"
			
			input_path = File.join( directory, orig_filename )
			output_path = File.join( directory, output_filename )
			
			image = MiniMagick::Image.open( input_path )
			image.resize style_detail
			image.write  output_path
			
		end
	end
	
	def parse_name( name )
		# gets the file-name and file-extension from a url or filepath
		if name =~ /\Ahttp:\/\//
			full_name = name.match( /[\w?.-]+\z/ ).to_s
			full_name.gsub!( /\?.+\z/, "" ) #try to strip args if any
		else
			# one or more digit, word char, parens, or dash, then a dot, then one or more any char then end of string
			full_name = name.match( /[\d\w\(\)-]+\..+\z/ ).to_s 
		end
	
		ext = full_name.match( /\w+\z/ ).to_s # any number of word chars following non-word (ie period), then eol
		name = full_name.match( /[\d\w-]+\./ ).to_s.chop

		return name, ext
	
	end
	
	
end