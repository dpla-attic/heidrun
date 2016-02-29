require 'spec_helper'

describe Heidrun::Application do
  let(:config) { described_class.config }
  before do
    allow(Settings).to receive(:log_level).and_return(:debug)
  end

  it 'configures log level' do
    expect(config.log_level).to eq :debug
  end
end
