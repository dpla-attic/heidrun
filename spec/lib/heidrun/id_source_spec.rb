require 'spec_helper'

describe Heidrun::IDSource do

  subject { described_class.new(StringIO.new("1,\n2,\n3,"), 2) }

  describe '#batches' do
    it 'returns ids in correctly-sized batches' do
      all_batches = []
      subject.batches.each {|b| all_batches << b }
      expect(all_batches).to eq [["1", "2"], ["3"]]
    end
  end

  describe '#count' do
    it 'returns the correct count' do
      expect(subject.count).to eq 3
    end
  end
end
