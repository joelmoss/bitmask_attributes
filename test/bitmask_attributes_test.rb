require 'test_helper'

class BitmaskAttributesTest < ActiveSupport::TestCase

  def self.context_with_classes(label, campaign_class, company_class)
    context label do
      setup do
        @campaign_class = campaign_class
        @company_class = company_class
      end

      teardown do
        @company_class.destroy_all
        @campaign_class.destroy_all
      end

      should "return all defined values of a given bitmask attribute" do
        assert_equal @campaign_class.values_for_medium, [:web, :print, :email, :phone]
      end

      should "can assign single value to bitmask" do
        assert_stored @campaign_class.new(:medium => :web), :web
      end

      should "can assign multiple values to bitmask" do
        assert_stored @campaign_class.new(:medium => [:web, :print]), :web, :print
      end

      should "can add single value to bitmask" do
        campaign = @campaign_class.new(:medium => [:web, :print])
        assert_stored campaign, :web, :print
        campaign.medium << :phone
        assert_stored campaign, :web, :print, :phone
      end

      should "ignores duplicate values added to bitmask" do
        campaign = @campaign_class.new(:medium => [:web, :print])
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
        campaign = @campaign_class.new(:medium => [:web, :print])
        assert_stored campaign, :web, :print
        campaign.medium = [:phone, :email]
        assert_stored campaign, :phone, :email
      end

      should "can assign raw bitmask values" do
        campaign = @campaign_class.new
        campaign.medium_bitmask = 3
        assert_stored campaign, :web, :print
        campaign.medium_bitmask = 0
        assert_empty campaign.medium
      end

      should "can save bitmask to db and retrieve values transparently" do
        campaign = @campaign_class.new(:medium => [:web, :print])
        assert_stored campaign, :web, :print
        assert campaign.save
        assert_stored @campaign_class.find(campaign.id), :web, :print
      end

      should "can add custom behavor to value proxies during bitmask definition" do
        campaign = @campaign_class.new(:medium => [:web, :print])
        assert_raises NoMethodError do
          campaign.medium.worked?
        end
        assert_nothing_raised do
          campaign.misc.worked?
        end
        assert campaign.misc.worked?
      end

      should "cannot use unsupported values" do
        assert_unsupported { @campaign_class.new(:medium => [:web, :print, :this_will_fail]) }
        campaign = @campaign_class.new(:medium => :web)
        assert_unsupported { campaign.medium << :this_will_fail_also }
        assert_unsupported { campaign.medium = [:so_will_this] }
      end

      should "can only use Fixnum values for raw bitmask values" do
        campaign = @campaign_class.new(:medium => :web)
        assert_unsupported { campaign.medium_bitmask = :this_will_fail }
      end

      should "cannot use unsupported values for raw bitmask values" do
        campaign = @campaign_class.new(:medium => :web)
        number_of_attributes = @campaign_class.bitmasks[:medium].size
        assert_unsupported { campaign.medium_bitmask = (2 ** number_of_attributes) }
        assert_unsupported { campaign.medium_bitmask = -1 }
      end

      should "can determine bitmasks using convenience method" do
        assert @campaign_class.bitmask_for_medium(:web, :print)
        assert_equal(
          @campaign_class.bitmasks[:medium][:web] | @campaign_class.bitmasks[:medium][:print],
          @campaign_class.bitmask_for_medium(:web, :print)
        )
      end

      should "assert use of unknown value in convenience method will result in exception" do
        assert_unsupported { @campaign_class.bitmask_for_medium(:web, :and_this_isnt_valid)  }
      end

      should "can determine bitmask entries using inverse convenience method" do
        assert @campaign_class.medium_for_bitmask(3)
        assert_equal([:web, :print], @campaign_class.medium_for_bitmask(3))
      end

      should "assert use of non Fixnum value in inverse convenience method will result in exception" do
        assert_unsupported { @campaign_class.medium_for_bitmask(:this_isnt_valid)  }
      end

      should "hash of values is with indifferent access" do
        string_bit = nil
        assert_nothing_raised do
          assert (string_bit = @campaign_class.bitmask_for_medium('web', 'print'))
        end
        assert_equal @campaign_class.bitmask_for_medium(:web, :print), string_bit
      end

      should "save bitmask with non-standard attribute names" do
        campaign = @campaign_class.new(:Legacy => [:upper, :case])
        assert campaign.save
        assert_equal [:upper, :case], @campaign_class.find(campaign.id).Legacy
      end

      should "ignore blanks fed as values" do
        assert_equal 0b11,@campaign_class.bitmask_for_medium(:web, :print, '')
        campaign = @campaign_class.new(:medium => [:web, :print, ''])
        assert_stored campaign, :web, :print
      end

      context "checking" do
        setup { @campaign = @campaign_class.new(:medium => [:web, :print]) }

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
          @company = @company_class.create(:name => "Test Co, Intl.")
          @campaign1 = @company.campaigns.create :medium => [:web, :print]
          @campaign2 = @company.campaigns.create
          @campaign3 = @company.campaigns.create :medium => [:web, :email]
          @campaign4 = @company.campaigns.create :medium => [:web]
          @campaign5 = @company.campaigns.create :medium => [:web, :print, :email]
          @campaign6 = @company.campaigns.create :medium => [:web, :print, :email, :phone]
          @campaign7 = @company.campaigns.create :medium => [:email, :phone]
        end

        should "support retrieval by any value" do
          assert_equal [@campaign1, @campaign3, @campaign4, @campaign5, @campaign6, @campaign7], @company.campaigns.with_medium
        end

        should "support retrieval by one matching value" do
          assert_equal [@campaign1, @campaign5, @campaign6], @company.campaigns.with_medium(:print)
        end

        should "support retrieval by any matching value (OR)" do
          assert_equal [@campaign1, @campaign3, @campaign5, @campaign6, @campaign7], @company.campaigns.with_any_medium(:print, :email)
        end

        should "support retrieval by all matching values" do
          assert_equal [@campaign1, @campaign5, @campaign6], @company.campaigns.with_medium(:web, :print)
          assert_equal [@campaign3, @campaign5, @campaign6], @company.campaigns.with_medium(:web, :email)
        end

        should "support retrieval for no values" do
          assert_equal [@campaign2], @company.campaigns.without_medium
          assert_equal [@campaign2], @company.campaigns.no_medium
        end

        should "support retrieval without a specific value" do
          assert_equal [@campaign2, @campaign3, @campaign4, @campaign7], @company.campaigns.without_medium(:print)
          assert_equal [@campaign2, @campaign7], @company.campaigns.without_medium(:web, :print)
          assert_equal [@campaign2, @campaign3, @campaign4], @company.campaigns.without_medium(:print, :phone)
        end

        should "support retrieval by exact value" do
          assert_equal [@campaign4], @company.campaigns.with_exact_medium(:web)
          assert_equal [@campaign1], @company.campaigns.with_exact_medium(:web, :print)
          assert_equal [@campaign2], @company.campaigns.with_exact_medium
        end

        should "not retrieve retrieve a subsequent zero value for an unqualified with scope " do
          assert_equal [@campaign1, @campaign3, @campaign4, @campaign5, @campaign6, @campaign7], @company.campaigns.with_medium
          @campaign4.medium = []
          @campaign4.save
          assert_equal [@campaign1, @campaign3, @campaign5, @campaign6, @campaign7], @company.campaigns.with_medium
          assert_equal [@campaign1, @campaign3, @campaign5, @campaign6, @campaign7], @company.campaigns.with_any_medium
        end

        should "not retrieve retrieve a subsequent zero value for a qualified with scope " do
          assert_equal [@campaign1, @campaign3, @campaign4, @campaign5, @campaign6], @company.campaigns.with_medium(:web)
          @campaign4.medium = []
          @campaign4.save
          assert_equal [@campaign1, @campaign3, @campaign5, @campaign6], @company.campaigns.with_medium(:web)
          assert_equal [@campaign1, @campaign3, @campaign5, @campaign6], @company.campaigns.with_any_medium(:web)
        end
      end

      should "can check if at least one value is set" do
        campaign = @campaign_class.new(:medium => [:web, :print])
        assert campaign.medium?

        campaign = @campaign_class.new
        assert !campaign.medium?
      end

      should "find by bitmask values" do
        campaign = @campaign_class.new(:medium => [:web, :print])
        assert campaign.save

        assert_equal(
          @campaign_class.find(:all, :conditions => ['medium & ? <> 0', @campaign_class.bitmask_for_medium(:print)]),
          @campaign_class.medium_for_print
        )

        assert_equal @campaign_class.medium_for_print.first, @campaign_class.medium_for_print.medium_for_web.first

        assert_equal [], @campaign_class.medium_for_email
        assert_equal [], @campaign_class.medium_for_web.medium_for_email
      end

      should "find no values" do
        campaign = @campaign_class.create(:medium => [:web, :print])
        assert campaign.save

        assert_equal [], @campaign_class.no_medium

        campaign.medium = []
        assert campaign.save

        assert_equal [campaign], @campaign_class.no_medium
      end

      should "allow zero in values without changing result" do
        assert_equal 0,@campaign_class.bitmask_for_allow_zero(:none)
        assert_equal 0b111,@campaign_class.bitmask_for_allow_zero(:one,:two,:three,:none)

        campaign = @campaign_class.new(:allow_zero => :none)
        assert campaign.save
        assert_equal [],campaign.allow_zero

        campaign.allow_zero = :none
        assert campaign.save
        assert_equal [],campaign.allow_zero

        campaign.allow_zero = [:one,:none]
        assert campaign.save
        assert_equal [:one],campaign.allow_zero
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
            mask | @campaign_class.bitmasks[:medium][value]
          end
          assert_equal full_mask, record.medium.to_i
        end

    end
  end

  should "accept a default value option" do
    assert_equal DefaultValue.new.default_sym, [:y]
    assert_equal DefaultValue.new.default_array, [:y, :z]
    assert_equal DefaultValue.new(:default_sym => :x).default_sym, [:x]
    assert_equal DefaultValue.new(:default_array => [:x]).default_array, [:x]
  end
  
  should "save empty bitmask when default defined" do
    default = DefaultValue.create
    assert_equal [:y], default.default_sym
    default.default_sym = []
    default.save
    assert_empty default.default_sym
    default2 = DefaultValue.find(default.id)
    assert_empty default2.default_sym
  end

  context_with_classes 'Campaign with null attributes', CampaignWithNull, CompanyWithNull
  context_with_classes 'Campaign without null attributes', CampaignWithoutNull, CompanyWithoutNull
  context_with_classes 'SubCampaign with null attributes', SubCampaignWithNull, CompanyWithNull
  context_with_classes 'SubCampaign without null attributes', SubCampaignWithoutNull, CompanyWithoutNull
end
