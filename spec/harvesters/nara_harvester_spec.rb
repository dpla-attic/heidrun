require 'spec_helper'

describe NaraHarvester do

  subject { described_class.new(id_source_fh: StringIO.new) }
  let(:default_uri) { 'https://catalog.archives.gov/api/v1' }
  let(:default_opts) { { 'params' => described_class::DEFAULT_PARAMS } }
  let(:doc) { {'naId' => '1', 'description' => {}, 'objects' => {}} }

  describe '#new' do

    context 'with default opts' do
      it 'has the correct default properties' do
        expect(subject).to have_attributes(uri: default_uri,
                                           name: 'nara',
                                           opts: default_opts)
      end
    end

    context 'with overridden opts' do
      let(:overridden_opts) { { 'params' => 'abc' } }
      subject do
        described_class.new(api: overridden_opts, id_source_fh: StringIO.new)
      end

      it 'allows override of "api" options' do
        expect(subject)
          .to have_attributes(uri: default_uri,
                              name: 'nara',
                              opts: overridden_opts)
      end
    end

    context 'with overridden uri' do
      let(:uri) { 'https://catalog.archives.gov/api/v2000' }
      subject { described_class.new(uri: uri, id_source_fh: StringIO.new) }
      it 'allows override of URI without affecting other options' do
        expect(subject)
          .to have_attributes(uri: uri, name: 'nara', opts: default_opts)
      end
    end

    context 'with overridden name' do
      subject { described_class.new(name: 'a', id_source_fh: StringIO.new) }
      it 'allows override of name parameter' do
        expect(subject).to have_attributes(name: 'a')
      end
    end

    context 'with a missing IDSource file' do
      it 'raises an Errno::ENOENT exception' do
        expect do
          described_class.new(id_source_filename: '/not/there')
        end.to raise_error Errno::ENOENT
      end
    end

    context 'with an unreadable IDSource file' do
      before do
        allow(File).to receive(:open).and_raise Errno::EACCES
      end
      it 'raises an Errno::EACCES exception' do
        expect { described_class.new }.to raise_error Errno::EACCES
      end
    end
  end  # #new

  describe '#enumerate_records' do
    let(:params_1) do
      {
        'params' => {
          'pretty'=>'false', 'resultTypes'=>'item,fileUnit',
          'objects.object.@objectSortNum'=>'1', 'naIds'=>'1,2'
        }
      }
    end
    let(:params_2) do
      {
        'params' => {
          'pretty'=>'false', 'resultTypes'=>'item,fileUnit',
          'objects.object.@objectSortNum'=>'1', 'naIds'=>'3'
        }
      }
    end
    let(:request_resp_1) { 'naids 1, 2 response' }
    let(:request_resp_2) { 'naids 3 response' }
    before do
      # See Krikri::ApiHarvester#request
      allow(subject).to receive(:request).with(params_1)
        .and_return(request_resp_1)
      allow(subject).to receive(:request).with(params_2)
        .and_return(request_resp_2)
      # See NaraHarvester#get_docs
      allow(subject).to receive(:get_docs).with(request_resp_1)
        .and_return([doc, doc])
      allow(subject).to receive(:get_docs).with(request_resp_2)
        .and_return([doc])
    end

    context 'given an IDSource with multiple IDs and batches' do
      let(:id_fh) { StringIO.new("1,\n2,\n3,") }
      subject { described_class.new(id_source_fh: id_fh, batchsize: 2) }

      it 'enumerates the correct number of records' do
        all_records = []
        subject.send(:enumerate_records).each {|r| all_records << r }
        expect(all_records).to eq [doc, doc, doc]
      end

      context 'when encountering an HTTP error' do
        before do
          allow(subject).to receive(:request).with(params_1)
            .and_raise(RestClient::InternalServerError)
        end

        it 'logs the exception and moves on to the next request' do
          all_records = []
          expect(Rails.logger).to receive(:error)
            .with("request failed with params #{params_1['params']}")
          subject.send(:enumerate_records).each {|r| all_records << r }
          # failed request had 2 records, successful one had 1
          expect(all_records.count).to eq 1
        end
      end
    end
  end  # #enumerate_records

  describe '#get_docs' do
    let(:parsed_response) do
      {
        'opaResponse' => {
          'results' => {
            'result' => [doc, doc]
          }
        }
      }
    end

    it 'returns the docs from a parsed response' do
      expect(subject.send(:get_docs, parsed_response)).to eq [doc, doc]
    end
  end
end
