require 'spec_helper'

describe Keyword do

  context 'merge' do
    it 'both receiver and originator are attached to different meta datums' do
      k1 = FactoryBot.create(:keyword)
      k2 = FactoryBot.create(:keyword)
      k3 = FactoryBot.create(:keyword)
      k4 = FactoryBot.create(:keyword)
      md1 = FactoryBot.create(:meta_datum_keywords, keywords: [k1, k2])
      md2 = FactoryBot.create(:meta_datum_keywords, keywords: [k3, k4])
      k2.merge_to(k3)
      expect(Keyword.find_by_id(k2.id)).not_to be
      expect(md1.reload.keywords.to_set).to eq [k1, k3].to_set
      expect(md2.reload.keywords.to_set).to eq [k3, k4].to_set
    end

    it 'both receiver and originator are attached to the same meta datum' do
      k1 = FactoryBot.create(:keyword)
      k2 = FactoryBot.create(:keyword)
      md1 = FactoryBot.create(:meta_datum_keywords, keywords: [k1, k2])
      k1.merge_to(k2)
      expect(Keyword.find_by_id(k1.id)).not_to be
      expect(md1.reload.keywords).to eq [k2]
    end
  end
end

