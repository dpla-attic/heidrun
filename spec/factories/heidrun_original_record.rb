# coding: utf-8
FactoryGirl.define do

  factory :heidrun_original_record, class: Krikri::OriginalRecord do
    content ''
    initialize_with { new('abc') }
  end

  factory :heidrun_oai_dc_record, parent: :heidrun_original_record do
    content <<-EOS
<?xml version="1.0" encoding="UTF-8"?>

<OAI-PMH
xmlns="http://www.openarchives.org/OAI/2.0/"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
<responseDate>2015-01-08T22:35:58Z</responseDate>
<request verb="ListRecords" metadataPrefix="oai_dc">
http://www.biodiversitylibrary.org/oai
</request>
<ListRecords>
    <record>
    <header>
      <identifier>oai:biodiversitylibrary.org:item/7</identifier>
      <datestamp>2013-12-24T06:47:22Z</datestamp>
      <setSpec>item</setSpec>
    </header>
    <metadata>
<oai_dc:dc xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ &#13;&#10;&#9;&#9;&#9;&#9;http://www.openarchives.org/OAI/2.0/oai_dc.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/">
<dc:title>Examen classis dioeciae.</dc:title>
<dc:creator>Thunberg, Carl Peter,      1743-1828</dc:creator>
<dc:creator>Kjellenberg, Fredrik Ulrik,      1795-1862</dc:creator>
<dc:creator>Söderberg, Christopher,      1804-1833</dc:creator>
<dc:subject>(Nathaniel),</dc:subject>
<dc:subject>1786-1854</dc:subject>
<dc:subject>Australia</dc:subject>
<dc:subject>Bogor</dc:subject>
<dc:subject>China</dc:subject>
<dc:subject>Dimorphism (Plants)</dc:subject>
<dc:subject>Forests and forestry</dc:subject>
<dc:subject>Herbarium</dc:subject>
<dc:subject>India</dc:subject>
<dc:subject>Indonesia</dc:subject>
<dc:subject>Musci</dc:subject>
<dc:subject>New Guinea</dc:subject>
<dc:subject>Papau New Guinea</dc:subject>
<dc:subject>Papua New Guinea</dc:subject>
<dc:subject>Plants</dc:subject>
<dc:subject>Wallich, N</dc:subject>
<dc:description>v. 1 [series pt. 5]</dc:description>
<dc:publisher>Upsali&#230; :excudebant Palmblad et c.,1825.</dc:publisher>
<dc:contributor>Missouri Botanical Garden, Peter H. Raven Library</dc:contributor>
<dc:date>1900-1902</dc:date>
<dc:type>text</dc:type>
<dc:type>Book</dc:type>
<dc:identifier>http://www.biodiversitylibrary.org/item/7</dc:identifier>
<dc:language>Dutch</dc:language>
</oai_dc:dc>
    </metadata>
    </record>
    </ListRecords>
</OAI-PMH>
EOS
  end

  factory :heidrun_mods_record, parent: :heidrun_original_record do
    content <<-EOS
<?xml version="1.0" encoding="UTF-8" ?><OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"><responseDate>2015-01-12T18:56:07Z</responseDate><request verb="GetRecord" metadataPrefix="mods" identifier="oai:repox.ist.utl.pt:p15281coll12:oai:cdm16373.contentdm.oclc.org:p15281coll12/100">http://repox.metro.org:8080/repox/OAIHandler</request><GetRecord><record xmlns="http://www.openarchives.org/OAI/2.0/"><header><identifier>oai:repox.ist.utl.pt:p15281coll12:oai:cdm16373.contentdm.oclc.org:p15281coll12/100</identifier><datestamp>2015-01-07</datestamp><setSpec>p15281coll12</setSpec></header><metadata>
<mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd" version="3.4"><titleInfo><title>Freeport, Long Island</title></titleInfo><note type="content">Colorized postcard of south Freeport, taken with water in the foreground and homes and the Crystal Lake Hotel in the background. The houses in the background are located on South Ocean Avenue.</note><location><url usage="primary display" access="object in context">http://cdm16373.contentdm.oclc.org/cdm/ref/collection/p15281coll12/id/100</url></location><location><url access="preview">http://cdm16373.contentdm.oclc.org/utils/getthumbnail/collection/p15281coll12/id/100</url></location><accessCondition>This digital image may be freely used for educational uses, as long as it is not altered in any way. No commercial reproduction or distribution of this image is permitted without permission of the Freeport Historical Museum, 350 S. Main Street, Freeport, NY 11520 or email: fpthismus@juno.com</accessCondition><subject><topic>Crystal Lake Hotel--Freeport (N.Y.)</topic></subject><subject><topic>Dwellings</topic></subject><subject><topic>Houses</topic></subject><subject><topic>Hotels</topic></subject><subject><geographic>Freeport, New York</geographic></subject><note type="ownership">Freeport Memorial Library</note></mods></metadata><about><oaiProvenance:provenance xmlns:oaiProvenance="http://www.openarchives.org/OAI/2.0/provenance" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/provenance http://www.openarchives.org/OAI/2.0/provenance.xsd"><oaiProvenance:originDescription harvestDate="2015-01-07" altered="true"><oaiProvenance:baseURL>http://cdm16373.contentdm.oclc.org/oai/oai.php</oaiProvenance:baseURL><oaiProvenance:identifier>oai:cdm16373.contentdm.oclc.org:p15281coll12/100</oaiProvenance:identifier><oaiProvenance:datestamp>2015-01-07</oaiProvenance:datestamp><oaiProvenance:metadataNamespace>http://www.openarchives.org/OAI/2.0/</oaiProvenance:metadataNamespace></oaiProvenance:originDescription></oaiProvenance:provenance></about></record></GetRecord></OAI-PMH>
EOS
  end
end
