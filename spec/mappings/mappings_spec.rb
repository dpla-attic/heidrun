require 'spec_helper'

module Heidrun
  describe Mappings do
    include ::Heidrun::Mappings

    let(:record) { build(:oai_dc_record) }

    describe '#map' do
      it 'creates a DPLA::MAP record' do
        expect(subject.map(record)).to be_a DPLA::MAP::Aggregation
      end
    end
  end
end