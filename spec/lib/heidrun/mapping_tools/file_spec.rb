require 'spec_helper'

RSpec.describe Heidrun::MappingTools::File do
  describe '.extension_to_mimetype' do
    it 'calculates mime types for common extensions' do
      expect(subject.extension_to_mimetype('/path/to/file.pdf'))
        .to eq('application/pdf')

      expect(subject.extension_to_mimetype('/path/to/file.jpg'))
        .to eq('image/jpeg')

      expect(subject.extension_to_mimetype('/path/to/file.html'))
        .to eq('text/html')
    end

    it 'ignores the case of extensions' do
      expect(subject.extension_to_mimetype('/path/to/file.PDF'))
        .to eq('application/pdf')

      expect(subject.extension_to_mimetype('/path/to/file.Pdf'))
        .to eq('application/pdf')
    end

    it 'returns nil when no extension matches' do
      expect(subject.extension_to_mimetype('/path/to/file.definitelynotreal'))
        .to be_nil
    end

    it 'works for URL strings too' do
      expect(subject.extension_to_mimetype('http://example.com/file.pdf'))
        .to eq('application/pdf')
    end

    it 'has no problems with multiple dots' do
      expect(subject.extension_to_mimetype('/file/file.is.a.bit.dotty.pdf'))
        .to eq('application/pdf')
    end

    it 'has no problems with a lack of dots' do
      expect(subject.extension_to_mimetype('/file/no-dots-to-be-seen'))
        .to be_nil
    end
  end
end
