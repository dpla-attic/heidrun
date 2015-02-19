Krikri::Mapper.define(:scdl_qdc, :parser => Krikri::QdcParser, :parser_args => '//qdc:qualifieddc') do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/scdl'
    label 'South Carolina Digital Library'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('dc:publisher').first_value
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('dc:identifier')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('dcterms:hasFormat')

    # Per discussion with Gretchen on 1/28/15, we assume that dc:format will
    # only contain values to be associated with `edm:preview`. We could add
    # a mime-type checker enrichment here if we wanted.
    dcformat record.field('dc:format')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    collection :class => DPLA::MAP::Collection, :each => record.field('dcterms:isPartOf'), :as => :coll do
      title coll
    end

    contributor :class => DPLA::MAP::Agent, :each => record.field('dc:contributor'), :as => :contrib do
      providedLabel contrib
    end

    creator :class => DPLA::MAP::Agent, :each => record.field('dc:creator'), :as => :creator do
      providedLabel creator
    end

    date :class => DPLA::MAP::TimeSpan, :each => record.field('dc:date'), :as => :created do
      providedLabel created
    end

    description record.field('dc:description')

    extent record.field('dcterms:extent')

    dcformat record.field('dcterms:medium')

    # Per conversation with Gretchen on 1/18/2015, genre should be populated
    # during enrichment, not at mapping. Values should be taken from dcformat
    # and compared with our list of preferred genre terms.
    #
    # genre record.field('dcterms:medium')

    language :class => DPLA::MAP::Controlled::Language, :each => record.field('dc:language'), :as => :lang do
      prefLabel lang
    end

    spatial :class => DPLA::MAP::Place, :each => record.field('dcterms:spatial'), :as => :place do
      providedLabel place
    end

    relation record.field('dc:source')

    rights record.field('dc:rights')

    subject :class => DPLA::MAP::Concept, :each => record.field('dc:subject'), :as => :subject do
      providedLabel subject
    end

    title record.field('dc:title')

    # Selecting only DCMIType values will be handled in enrichment
    dctype record.field('dc:type')
  end
end
