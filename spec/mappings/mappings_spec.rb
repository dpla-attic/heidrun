require 'spec_helper'

describe 'mappings' do
  let(:record) { build(:oai_dc_record) }

  describe '#map' do
    it 'has registered mappings' do
      expect(Krikri::Mapper::Registry.keys).not_to be_empty
    end

    context 'with mapping' do
      before do
        Krikri::Mapper.define(:rspec_test_mapping) {}
      end

      it 'creates a DPLA::MAP record', krikri_integration: true do
        expect(Krikri::Mapper.map(:rspec_test_mapping, record))
          .to contain_exactly(an_instance_of(DPLA::MAP::Aggregation))
      end
    end
  end
end
