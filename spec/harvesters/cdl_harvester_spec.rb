require 'spec_helper'

describe CdlHarvester do
  describe '#new' do
    it 'uses CDL options by default' do
      expect(described_class.new)
        .to have_attributes(uri: 'https://solr.calisphere.org/solr/query',
                            name: 'cdl',
                            opts: { 'params' => { 'q' => '*:*' } })
    end

    it 'allows override of CDL uri' do
      uri = 'http://example.org/mdl'
      expect(described_class.new(uri: uri))
        .to have_attributes(uri: uri,
                            opts: { 'params' => { 'q' => '*:*' } })
    end

    it 'allows override of CDL params' do
      params = { 'params' => 'abc' }
      expect(described_class.new(api: params))
        .to have_attributes(uri: 'https://solr.calisphere.org/solr/query',
                            opts: params)
    end

    it 'allows override of CDL name' do
      harvester_name = 'moomin'
      expect(described_class.new(name: harvester_name))
              .to have_attributes(name: harvester_name)
    end

    it 'requires authentication parameter' do
      auth = { 'X-Authentication-Token'=>'Mellon' }
      expect(described_class.new(api: auth))
        .to have_attributes(uri: 'https://solr.calisphere.org/solr/query',
                            opts: {'X-Authentication-Token'=>'Mellon',
                               'params' => { 'q' => '*:*' } }  )
    end
  end
end
