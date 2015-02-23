# The strange looking glob allows us to traverse one level of symlinks on
# supported platforms; see http://stackoverflow.com/questions/357754

Dir[Rails.root.join('vendor', 'mappings', '**{,/*/**}', '*.rb')].each do |f|
  require f
end