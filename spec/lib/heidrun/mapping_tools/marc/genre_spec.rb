require 'spec_helper'

describe Heidrun::MappingTools::MARC::Genre do

  let(:genres) { [] }

  describe '.language' do
    it 'evaluates monograph correctly' do
      # These `allow`s should be removed to test the behavior of the `#*?`
      # methods. Otherwise, those methods should be tested independently.
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(true)
      allow(subject).to receive(:serial?).and_return(false)
      allow(subject).to receive(:newspapers?).and_return(false)
      allow(subject).to receive(:mono_component_part?).and_return(false)

      expect(subject.language({ leader: 'x' })).to eq(['Book'])
    end

    it 'evaluates newspaper correctly' do
      # These `allow`s should be removed to test the behavior of the `#*?`
      # methods. Otherwise, those methods should be tested independently.
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(false)
      allow(subject).to receive(:serial?).and_return(true)
      allow(subject).to receive(:newspapers?).and_return(true)
      allow(subject).to receive(:mono_component_part?).and_return(false)

      
      expect(subject.language({ leader: 'x', cf_008: ['x'] }))
        .to eq(['Newspapers'])
    end

    it 'evaluates serial correctly' do
      # These `allow`s should be removed to test the behavior of the `#*?`
      # methods. Otherwise, those methods should be tested independently.
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(false)
      allow(subject).to receive(:serial?).and_return(true)
      allow(subject).to receive(:newspapers?).and_return(false)
      allow(subject).to receive(:mono_component_part?).and_return(false)

      expect(subject.language({ leader: 'x', cf_008: ['x'] })).to eq(['Serial'])
    end

    it 'evaluates monograph component part correctly' do
      # These `allow`s should be removed to test the behavior of the `#*?`
      # methods. Otherwise, those methods should be tested independently.
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(false)
      allow(subject).to receive(:serial?).and_return(false)
      allow(subject).to receive(:newspapers?).and_return(false)
      allow(subject).to receive(:mono_component_part?).and_return(true)

      expect(subject.language({ leader: 'x' })).to eq(['Book'])
    end

    it 'defaults to "Serial" for language material' do
      # These `allow`s should be removed to test the behavior of the `#*?`
      # methods. Otherwise, those methods should be tested independently.
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(false)
      allow(subject).to receive(:serial?).and_return(false)
      allow(subject).to receive(:newspapers?).and_return(false)
      allow(subject).to receive(:mono_component_part?).and_return(false)

      expect(subject.language({ leader: 'x' })).to eq(['Serial'])
    end

    it 'returns genre if it can determine the genre' do
      expect(subject.language({ leader: 'xxxxxxam' }))
        .not_to be_empty
    end

    it 'returns empty if it can not determine the genre' do
      expect(subject.language({ leader: 'x' })).to be_empty
    end
  end

  describe '.musical_score' do
    it 'matches notated music' do
      leader = { leader: 'xxxxxxc' }
      expect(subject.musical_score(leader)).to contain_exactly('Musical Score')
    end

    it 'matches manuscript notated music' do
      leader = { leader: 'xxxxxxd' }
      expect(subject.musical_score(leader)).to contain_exactly('Musical Score')
    end

    it 'does not match non-music' do
      leader = { leader: 'xxxxxxx' }
      expect(subject.musical_score(leader)).to be_empty
    end
  end

  describe '.manuscript' do
    it 'matches manuscripts' do
      leader = { leader: 'xxxxxxt' }
      expect(subject.manuscript(leader)).to contain_exactly('Manuscript')
    end

    it 'does not match non-manuscript' do
      leader = { leader: 'xxxxxxx' }
      expect(subject.manuscript(leader)).to be_empty
    end
  end

  describe '.maps' do
    it 'matches cartographic material' do
      leader = { leader: 'xxxxxxe' }
      expect(subject.maps(leader)).to contain_exactly('Maps')
    end

    it 'matches manuscript cartographic material' do
      leader = { leader: 'xxxxxxf' }
      expect(subject.maps(leader)).to contain_exactly('Maps')
    end

    it 'does not match non-map' do
      leader = { leader: 'xxxxxxx' }
      expect(subject.maps(leader)).to be_empty
    end
  end

  describe '.projected' do
    it 'matches on 007 for slide' do
      data = { leader: 'xxxxxxg', cf_007: ['xs']}
      expect(subject.projected(data))
        .to contain_exactly('Photograph / Pictorial Works')
    end

    it 'matches on 007 for transparency' do
      data = { leader: 'xxxxxxg', cf_007: ['xt']}
      expect(subject.projected(data))
        .to contain_exactly('Photograph / Pictorial Works')
    end

    it 'matches on 007 for film/video' do
      data = { leader: 'xxxxxxg', cf_007: ['v']}
      expect(subject.projected(data)).to contain_exactly('Film / Video')
    end

    it 'does not match non-projected medium' do
      leader = { leader: 'xxxxxxx' }
      expect(subject.projected(leader)).to be_empty
    end
  end

  describe '.two_d' do
    it 'matches two-dimensional non-projectable' do
      leader = { leader: 'xxxxxxk' }
      expect(subject.two_d(leader))
        .to contain_exactly('Photograph / Pictorial Works')
    end

    it 'does not match non-manuscript' do
      leader = { leader: 'xxxxxxx' }
      expect(subject.two_d(leader)).to be_empty
    end
  end

  describe '.nonmusical_sound' do
    it 'matches nonmusical sound' do
      leader = { leader: 'xxxxxxi' }
      expect(subject.nonmusical_sound(leader))
        .to contain_exactly('Nonmusic Audio')
    end

    it 'does not match non-nonmusical sound' do
      leader = { leader: 'xxxxxxx' }
      expect(subject.nonmusical_sound(leader)).to be_empty
    end
  end

  describe '.musical_sound' do
    it 'matches musical sound' do
      leader = { leader: 'xxxxxxj' }
      expect(subject.musical_sound(leader))
        .to contain_exactly('Music')
    end

    it 'does not match non-musical sound' do
      leader = { leader: 'xxxxxxx' }
      expect(subject.musical_sound(leader)).to be_empty
    end
  end
end
