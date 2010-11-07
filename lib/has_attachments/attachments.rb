module HasAttachments #:nodoc:
	module Attachments

		def self.included( base )
			base.extend ClassMethods
		end

		module ClassMethods
			# Class methods go here
			def has_attached( attachment_type, opts = {} )

				include HasAttachments::Attachments::InstanceMethods
				include HasAttachments::AttachmentLib
				
				has_many :attachments, :as => :owner, :dependent => :destroy

				attachment_type = attachment_type.to_s
				unless self.respond_to? attachment_type
					# refactor out to a singular? method on String
					if attachment_type.singularize == attachment_type
						self.class_eval do
							has_one "#{attachment_type}".to_sym, :as => :owner, :dependent => :destroy, :class_name => "Attachment", :conditions => [ "attachment_type = ?", attachment_type ]
						end
					else
						self.class_eval do
							has_many "#{attachment_type}".to_sym, :as => :owner, :dependent => :destroy, :class_name => "Attachment", :conditions => [ "attachment_type = ?", attachment_type ]
						end
					end	
				end
				
				if opts[:private] == 'true'
					self.class_eval <<-END
						def #{attachment_type}_path
							return PRIVATE_ATTACHMENT_PATH
						end
					END
				else
					self.class_eval <<-END
						def #{attachment_type}_path
							return PUBLIC_ATTACHMENT_PATH
						end
					END
				end
				
				if opts[:formats]
					Attachment.class_eval <<-END
						def validate_#{attachment_type}_format
							unless #{opts[:formats]}.include? self.format
								self.errors.add( :format, "invalid format" ) 
								return false
							end
						end
					END
					Attachment.instance_eval <<-END
						before_save :validate_#{attachment_type}_format
					END
				end
				
			end
			
		end

		module InstanceMethods
			# Put instance methods here
			
			def attachment_skwawk
				"I Have Attachments!!!!!"
			end
			
			def method_missing( m, *args )
				if m.to_s[/attach_(.+)/]
					type = $1
					obj = args.first
					self.attachments.create :attachment_type => $1
				elsif  m.to_s[/attached_(.+)/]
					return eval "self.#{$1}" #  || self.attachments.by_type $1
				else
					super
				end
			end
			
		end
	
	
	end
end