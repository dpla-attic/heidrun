
if !Krikri::Mapper::Registry.registered?(:esdn_mods)
  Krikri::Mapper.define(:esdn_mods) do
    sourceResource :class => DPLA::MAP::SourceResource do
    end
  end
end
