require 'test_helper'

class BitmaskAttributesTest < ActiveSupport::TestCase
  
  context "Campaign" do
    teardown do
      Company.destroy_all
      Campaign.destroy_all
    end

    should "return all defined values of a given bitmask attribute" do
      assert_equal Campaign.values_for_medium, [:web, :print, :email, :phone]
    end

    should "can assign single value to bitmask" do
      assert_stored Campaign.new(:medium => :web), :web
    end

    should "can assign multiple values to bitmask" do
      assert_stored Campaign.new(:medium => [:web, :print]), :web, :print
    end

    should "can add single value to bitmask" do
      campaign = Campaign.new(:medium => [:web, :print])
      assert_stored campaign, :web, :print
      campaign.medium << :phone
      assert_stored campaign, :web, :print, :phone
    end

    should "ignores duplicate values added to bitmask" do
      campaign = Campaign.new(:medium => [:web, :print])
      assert_stored campaign, :web, :print
      campaign.medium << :phone
      assert_stored campaign, :web, :print, :phone
      campaign.medium << :phone
      assert_stored campaign, :web, :print, :phone
      campaign.medium << "phone"
      assert_stored campaign, :web, :print, :phone
      assert_equal 1, campaign.medium.select { |value| value == :phone }.size
      assert_equal 0, campaign.medium.select { |value| value == "phone" }.size
    end

    should "can assign new values at once to bitmask" do
      campaign = Campaign.new(:medium => [:web, :print])
      assert_stored campaign, :web, :print
      campaign.medium = [:phone, :email]
      assert_stored campaign, :phone, :email
    end

    should "can save bitmask to db and retrieve values transparently" do
      campaign = Campaign.new(:medium => [:web, :print])
      assert_stored campaign, :web, :print
      assert campaign.save
      assert_stored Campaign.find(campaign.id), :web, :print
    end

    should "can add custom behavor to value proxies during bitmask definition" do
      campaign = Campaign.new(:medium => [:web, :print])
      assert_raises NoMethodError do
        campaign.medium.worked?
      end
      assert_nothing_raised do
        campaign.misc.worked?
      end
      assert campaign.misc.worked?
    end

    should "cannot use unsupported values" do
      assert_unsupported { Campaign.new(:medium => [:web, :print, :this_will_fail]) }
      campaign = Campaign.new(:medium => :web)
      assert_unsupported { campaign.medium << :this_will_fail_also }
      assert_unsupported { campaign.medium = [:so_will_this] }
    end

    should "can determine bitmasks using convenience method" do
      assert Campaign.bitmask_for_medium(:web, :print)
      assert_equal(
        Campaign.bitmasks[:medium][:web] | Campaign.bitmasks[:medium][:print],
        Campaign.bitmask_for_medium(:web, :print)
      )
    end
    
    should "assert use of unknown value in convenience method will result in exception" do
      assert_unsupported { Campaign.bitmask_for_medium(:web, :and_this_isnt_valid)  }
    end

    should "hash of values is with indifferent access" do
      string_bit = nil
      assert_nothing_raised do
        assert (string_bit = Campaign.bitmask_for_medium('web', 'print'))
      end
      assert_equal Campaign.bitmask_for_medium(:web, :print), string_bit
    end

    should "save bitmask with non-standard attribute names" do
      campaign = Campaign.new(:Legacy => [:upper, :case])
      assert campaign.save
      assert_equal [:upper, :case], Campaign.find(campaign.id).Legacy
    end

    should "ignore blanks fed as values" do
      campaign = Campaign.new(:medium => [:web, :print, ''])
      assert_stored campaign, :web, :print
    end
    
    context "checking" do
      setup { @campaign = Campaign.new(:medium => [:web, :print]) }

      context "for a single value" do
        should "be supported by an attribute_for_value convenience method" do
          assert @campaign.medium_for_web?
          assert @campaign.medium_for_print?
          assert !@campaign.medium_for_email?
        end
        
        should "be supported by the simple predicate method" do
          assert @campaign.medium?(:web)
          assert @campaign.medium?(:print)
          assert !@campaign.medium?(:email)
        end
      end
      
      context "for multiple values" do
        should "be supported by the simple predicate method" do
          assert @campaign.medium?(:web, :print)
          assert !@campaign.medium?(:web, :email)
        end
      end
    end

    context "named scopes" do
      setup do
        @company = Company.create(:name => "Test Co, Intl.")
        @campaign1 = @company.campaigns.create :medium => [:web, :print]        
        @campaign2 = @company.campaigns.create
        @campaign3 = @company.campaigns.create :medium => [:web, :email] 
      end

      should "support retrieval by any value" do
        assert_equal [@campaign1, @campaign3], @company.campaigns.with_medium
      end

      should "support retrieval by one matching value" do
        assert_equal [@campaign1], @company.campaigns.with_medium(:print)
      end
      
      should "support retrieval by any matching value (OR)" do
        assert_equal [@campaign1, @campaign3], @company.campaigns.with_any_medium(:print, :email)
      end
      
      should "support retrieval by all matching values" do
        assert_equal [@campaign1], @company.campaigns.with_medium(:web, :print)
        assert_equal [@campaign3], @company.campaigns.with_medium(:web, :email)
      end

      should "support retrieval for no values" do
        assert_equal [@campaign2], @company.campaigns.without_medium
        assert_equal [@campaign2], @company.campaigns.no_medium
      end
      
      should "support retrieval without a specific value" do
        assert_equal [@campaign2, @campaign3], @company.campaigns.without_medium(:print)
      end

      should "support retrieval without specific values" do
        @campaign4 = @company.campaigns.create :medium => [:phone]
        assert_equal [@campaign2], @company.campaigns.without_medium(:print, :email, :phone)
        assert_equal [@campaign2, @campaign4], @company.campaigns.without_medium(:print, :email)
      end      
    end

    should "can check if at least one value is set" do
      campaign = Campaign.new(:medium => [:web, :print])
      assert campaign.medium?
      
      campaign = Campaign.new
      assert !campaign.medium?
    end

    should "find by bitmask values" do
      campaign = Campaign.new(:medium => [:web, :print])
      assert campaign.save
      
      assert_equal(
        Campaign.find(:all, :conditions => ['medium & ? <> 0', Campaign.bitmask_for_medium(:print)]),
        Campaign.medium_for_print
      )
      
      assert_equal Campaign.medium_for_print.first, Campaign.medium_for_print.medium_for_web.first
      
      assert_equal [], Campaign.medium_for_email
      assert_equal [], Campaign.medium_for_web.medium_for_email
    end

    should "find no values" do
      campaign = Campaign.create(:medium => [:web, :print])
      assert campaign.save
      
      assert_equal [], Campaign.no_medium
      
      campaign.medium = []
      assert campaign.save
      
      assert_equal [campaign], Campaign.no_medium
    end


    private

      def assert_unsupported(&block)
        assert_raises(ArgumentError, &block)
      end

      def assert_stored(record, *values)
        values.each do |value|
          assert record.medium.any? { |v| v.to_s == value.to_s }, "Values #{record.medium.inspect} does not include #{value.inspect}"
        end
        full_mask = values.inject(0) do |mask, value|
          mask | Campaign.bitmasks[:medium][value]
        end
        assert_equal full_mask, record.medium.to_i
      end

  end
end