ActiveRecord::Schema.define do 
  create_table :campaign_with_nulls do |t|
    t.integer :company_id
    t.integer :medium, :allow_zero, :misc, :Legacy
  end
  create_table :company_with_nulls do |t|
    t.string :name
  end
  create_table :campaign_without_nulls do |t|
    t.integer :company_id
    t.integer :medium, :allow_zero, :misc, :Legacy, :null => false, :default => 0
  end
  create_table :company_without_nulls do |t|
    t.string :name
  end
end

# Pseudo models for testing purposes

class CompanyWithNull < ActiveRecord::Base
  has_many :campaigns,:class_name => 'CampaignWithNull',:foreign_key => 'company_id'
end

class CampaignWithNull < ActiveRecord::Base
  belongs_to :company,:class_name => 'CompanyWithNull'
  bitmask :medium, :as => [:web, :print, :email, :phone]
  bitmask :allow_zero, :as => [:one, :two, :three], :zero => :none
  bitmask :misc, :as => %w(some useless values) do
    def worked?
      true
    end
  end
  bitmask :Legacy, :as => [:upper, :case]
end

class CompanyWithoutNull < ActiveRecord::Base
  has_many :campaigns,:class_name => 'CampaignWithoutNull',:foreign_key => 'company_id'
end

class CampaignWithoutNull < ActiveRecord::Base
  belongs_to :company,:class_name => 'CompanyWithoutNull'
  bitmask :medium, :as => [:web, :print, :email, :phone], :null => false
  bitmask :allow_zero, :as => [:one, :two, :three], :zero => :none, :null => false
  bitmask :misc, :as => %w(some useless values), :null => false do
    def worked?
      true
    end
  end
  bitmask :Legacy, :as => [:upper, :case], :null => false
end