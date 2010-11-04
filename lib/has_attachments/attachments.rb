module HasAttachments #:nodoc:
	module Attachments

		def self.included( base )
			base.extend ClassMethods
		end

		module ClassMethods
			# Class methods go here
			def has_attached( *args )
				args.flatten! if args
				args.compact! if args
				include HasAttachments::Attachments::InstanceMethods
				include HasAttachments::AttachmentLib
				
				has_many :attachments, :as => :owner, :dependent => :destroy
				
				for attachment_type in args do
					attachment_type = attachment_type.to_s
					return if self.respond_to? attachment_type
					# refactor out to a singular? method on String
					if attachment_type.singularize == attachment_type
						self.class_eval do
							has_one "#{attachment_type}".to_sym, :as => :owner, :dependent => :destroy, :class_name => "Attachment", :conditions => [ "attachment_type = ?", attachment_type.singularize ]
						end
					else
						self.class_eval do
							has_many "#{attachment_type}".to_sym, :as => :owner, :dependent => :destroy, :class_name => "Attachment", :conditions => [ "attachment_type = ?", attachment_type.singularize ]
						end
					end
					
				end
				
			end
			
		end

		module InstanceMethods
			# Put instance methods here
			
			def attachment_skwawk
				"I Have Attachments!!!!!"
			end
			
			# method missing
			# attach_?
				# create attachment for owner with type = ?
			# attached_?
				# return self.?
			
		end
	
	
	end
end