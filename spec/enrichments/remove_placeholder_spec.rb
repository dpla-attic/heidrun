require 'spec_helper'

describe RemovePlaceholder do
  it_behaves_like 'a field enrichment'

  context 'with string value' do
    it 'removes matching values' do
      str = 'xYz'
      expect(subject.enrich_value(str)).to be_nil
    end

    it 'leaves other values alone' do
      str = 'moomin'
      expect(subject.enrich_value(str)).to eq str
    end

    context 'with downcase false' do
      subject { described_class.new('AbC', false) }

      it 'removes matching values' do
        str = 'AbC'
        expect(subject.enrich_value(str)).to be_nil
      end

      it 'leaves other values alone' do
        str = 'abc'
        expect(subject.enrich_value(str)).to eq str
      end
    end

    context 'with regexp' do
      subject { described_class.new(/^\d*$/) }
      
      it 'removes matching values' do
        str = '123'
        expect(subject.enrich_value(str)).to be_nil
      end

      it 'leaves other values alone' do
        str = '12c'
        expect(subject.enrich_value(str)).to eq str
      end
    end
  end

  context 'with Resource value' do
    let(:value) { double('Resource') }

    before do
      allow(value).to receive(:respond_to?)
                       .with(:providedLabel).and_return(true)
    end

    it 'removes matching values' do
      allow(value).to receive(:providedLabel).and_return(['xYz'])
      expect(subject.enrich_value(value)).to be_nil
    end

    it 'leaves other values alone' do
      allow(value).to receive(:providedLabel).and_return(['moomin'])
      expect(subject.enrich_value(value)).to eq value
    end

    it 'leaves multiple values alone' do
      allow(value).to receive(:providedLabel).and_return(['moomin', 'xYz'])
      expect(subject.enrich_value(value)).to eq value
    end

    context 'with regexp' do
      subject { described_class.new(/^\d*$/) }

      it 'removes matching values' do
        allow(value).to receive(:providedLabel).and_return(['123'])
        expect(subject.enrich_value(value)).to be_nil
      end

      it 'leaves other values alone' do
        allow(value).to receive(:providedLabel).and_return(['12c'])
        expect(subject.enrich_value(value)).to eq value
      end

      it 'leaves multiple values alone' do
        allow(value).to receive(:providedLabel).and_return(['123', '12c'])
        expect(subject.enrich_value(value)).to eq value
      end
    end

    context 'with downcase false' do
      subject { described_class.new('AbC', false) }

      it 'removes matching values' do
        allow(value).to receive(:providedLabel).and_return(['AbC'])
        expect(subject.enrich_value(value)).to be_nil
      end

      it 'leaves other values alone' do
        allow(value).to receive(:providedLabel).and_return(['abc'])
        expect(subject.enrich_value(value)).to eq value
      end

      it 'leaves multiple values alone' do
        allow(value).to receive(:providedLabel).and_return(['AbC', 'abc'])
        expect(subject.enrich_value(value)).to eq value
      end
    end
  end
end
