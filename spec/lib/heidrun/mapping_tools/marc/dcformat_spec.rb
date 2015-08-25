require 'spec_helper'

describe Heidrun::MappingTools::MARC::DCFormat do
  describe '.from_leader' do
    it 'raises a NoElementError if not given a leader' do
      expect { subject.from_leader({}) }
        .to raise_error(Heidrun::MappingTools::MARC::NoElementError)
    end

    it 'matches sixth leader position' do
      expect(subject.from_leader({leader: '012345a'})).to eq 'Language material'
    end

    it 'gives nil on no match' do
      expect(subject.from_leader({leader: '012345b'})).to be_nil
    end
  end

  describe '.from_cf007' do
    it 'raises a NoElementError if not given a control field 007' do
      expect { subject.from_cf007({}) }
        .to raise_error(Heidrun::MappingTools::MARC::NoElementError)
    end

    it 'matches first position' do
      expect(subject.from_cf007({cf_007: ['a', 'c']}))
        .to contain_exactly('Map', 'Electronic resource')
    end

    it 'squashes empty values' do
      expect(subject.from_cf007({cf_007: ['a', 'b', 'c']}))
        .to contain_exactly('Map', 'Electronic resource')
    end
  end
end
