ActiveRecord::Schema.define do
  create_table :campaign_with_nulls do |t|
    t.integer :company_id
    t.integer :medium, :allow_zero, :misc, :Legacy
    t.string :type # STI
  end
  create_table :company_with_nulls do |t|
    t.string :name
  end
  create_table :campaign_without_nulls do |t|
    t.integer :company_id
    t.integer :medium, :allow_zero, :misc, :Legacy, :null => false, :default => 0
    t.string :type # STI
  end
  create_table :company_without_nulls do |t|
    t.string :name
  end
  create_table :default_values do |t|
    t.integer :default_sym, :default_array
  end
end

# Pseudo models for testing purposes

class CompanyWithNull < ActiveRecord::Base
  has_many :campaigns,:class_name => 'CampaignWithNull',:foreign_key => 'company_id'
end

class CampaignWithNull < ActiveRecord::Base
  belongs_to :company,:class_name => 'CompanyWithNull'
  bitmask :medium, :as => [:web, :print, :email, :phone]
  bitmask :allow_zero, :as => [:one, :two, :three], :zero_value => :none
  bitmask :misc, :as => %w(some useless values) do
    def worked?
      true
    end
  end
  bitmask :Legacy, :as => [:upper, :case]
end

class SubCampaignWithNull < CampaignWithNull
end

class CompanyWithoutNull < ActiveRecord::Base
  has_many :campaigns,:class_name => 'CampaignWithoutNull',:foreign_key => 'company_id'
end

class CampaignWithoutNull < ActiveRecord::Base
  belongs_to :company,:class_name => 'CompanyWithoutNull'
  bitmask :medium, :as => [:web, :print, :email, :phone], :null => false
  bitmask :allow_zero, :as => [:one, :two, :three], :zero_value => :none, :null => false
  bitmask :misc, :as => %w(some useless values), :null => false do
    def worked?
      true
    end
  end
  bitmask :Legacy, :as => [:upper, :case], :null => false
end

class SubCampaignWithoutNull < CampaignWithNull
end

class DefaultValue < ActiveRecord::Base
  bitmask :default_sym, :as => [:x, :y, :z], :default => :y
  bitmask :default_array, :as => [:x, :y, :z], :default => [:y, :z]
end
