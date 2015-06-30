require 'spec_helper'
require 'spec_helper_no_tx'

def create_meta_datum
  FactoryGirl.create :meta_datum_groups
end

describe MetaDatum::Groups do

  describe 'with a few groups' do

    before :each do
      PgTasks.truncate_tables
      @collection = FactoryGirl.create :collection
      @meta_key_groups = FactoryGirl.create :meta_key_groups
      @meta_datum = FactoryGirl.create :meta_datum_groups,
                                       collection: @collection,
                                       meta_key: @meta_key_groups
    end

    it 'deleting all groups deletes the meta_datum' do
      expect(MetaDatum.find_by id: @meta_datum.id).to be
      expect(@meta_datum.groups.count).to be >= 1
      @meta_datum.groups.delete_all
      expect(MetaDatum.find_by id: @meta_datum.id).not_to be
    end

  end

  describe 'creating an empty one' do

    before :each do
      PgTasks.truncate_tables
      @collection = FactoryGirl.create :collection
      @meta_key_groups = FactoryGirl.create :meta_key_groups
    end

    it 'will be deleted after closing the transaction' do

      ActiveRecord::Base.transaction do

        @meta_datum = FactoryGirl.create :meta_datum_groups,
                                         collection: @collection,
                                         meta_key: @meta_key_groups,
                                         groups: []

        expect(@meta_datum.groups.count).to be == 0

        expect(MetaDatum.find_by id: @meta_datum.id).to be
      end

      expect(MetaDatum.find_by id: @meta_datum.id).not_to be

    end
  end
end
