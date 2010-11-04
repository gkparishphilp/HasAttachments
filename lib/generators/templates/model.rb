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
	
	# instance methods
	def active?
		self.status == 'active'
	end
	
	def delete!
		self.update_attribute( :status => 'deleted' )
	end
  
end