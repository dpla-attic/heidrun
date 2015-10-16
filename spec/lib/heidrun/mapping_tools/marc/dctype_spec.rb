require 'spec_helper'

describe Heidrun::MappingTools::MARC::DCType do
  describe '.get_337a' do
    it 'is empty with no value' do
      value = {}
      expect(subject.get_337a(value)).to be_empty
    end

    it 'echos 337a' do
      value = { df_337a: ['abc' 'def'] }
      expect(subject.get_337a(value)).to contain_exactly(*value[:df_337a])
    end
  end

  describe '.get_type' do
    it 'is empty with no match' do
      leader = { leader: '01234567' }
      expect(subject.get_type(leader)).to be_empty
    end

    it 'is text with text value' do
      leader = { leader: '012345a7' }
      expect(subject.get_type(leader)).to contain_exactly('Text')
    end

    context 'with image' do
      it 'is moving image with film/video 007' do
        ldr = { leader: '01136nkm  22002773a 4500', cf_007: ['v'] }
        expect(subject.get_type(ldr)).to contain_exactly('Moving Image')
      end

      it 'is both with non- and film/video 007 ' do
        ldr = { leader: '01136nkm  22002773a 4500', cf_007: ['c', 'v'] }
        expect(subject.get_type(ldr)).to contain_exactly('Moving Image', 'Image')
      end

      it 'is image without film/video 007' do
        ldr = { leader: '01136nkm  22002773a 4500', cf_007: ['cr  n ---ma mp'] }
        expect(subject.get_type(ldr)).to contain_exactly('Image')
      end

      it 'is neither with no 007' do
        ldr = { leader: '01136nkm  22002773a 4500' }
        expect(subject.get_type(ldr)).to be_empty
      end
    end

    it 'returns empty with no leader' do
      expect(subject.get_type({})).to be_empty
    end
  end
end

