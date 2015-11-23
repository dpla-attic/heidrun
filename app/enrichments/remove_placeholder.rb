##
# Removes placeholder values from a field. Applies to both straight string 
# values and Resources with a matching `providedLabel`. Matches are case
# insensitive by default.
#
# @example 
#   rp = RemovePlaceholder.new('moomin')
#   rp.enrich_value('moomin') # => nil
#   rp.enrich_value('MooMin') # => nil
#   rp.enrich_value('Little My') # => 'Little My'
#
# @example case sensitive
#   rp = RemovePlaceholder.new('moomin', false)
#   rp.enrich_value('moomin') # => nil
#   rp.enrich_value('MooMin') # => 'MooMin'
#   rp.enrich_value('Little My') # => 'Little My'
#
# @example with Resource value
#   rp = RemovePlaceholder.new('moomin')
#   concept = DPLA::MAP::Concept.new
#   concept.providedLabel = 'moomin'
#   rp.enrich_value(concept) # => nil
#
# This method also supports regexp matchers. Write your regexp's with care!
# Expressions combine with case sensitivity on input strings.
#
# @example with regexp
#   rp = RemovePlaceholder.new(/^\d*$/)
#   concept = DPLA::MAP::Concept.new
#   concept.providedLabel = '123'
#   rp.enrich_value(concept) # => nil
#
# @see Audumbla::FieldEnrichment
class RemovePlaceholder
  include Audumbla::FieldEnrichment

  ## 
  # @param [String] placeholder  a string value to regard as a placeholder
  # @param [Boolean] downcase  whether to downcase the placeholder and string
  #   value when checking matching
  def initialize(placeholder = 'xyz', downcase = true)
    @placeholder = placeholder
    @downcase = downcase
  end

  ##
  # Removes values matching the given placeholder value, either directly or
  # with the `#providedLabel` field.
  #
  # @see Audumbla::FieldEnrichment#enrich_value
  def enrich_value(value)
    if value.is_a? String
      return nil if is_placeholder? value
    elsif value.respond_to?(:providedLabel)
      return nil if value.providedLabel.find { |l| !is_placeholder?(l) }.nil?
    end
    return value
  end

  private
  
  ##
  # @param [String] string
  # @return [Boolean] true if the parameter matches the placeholder, 
  #   false otherwise
  def is_placeholder?(string)
    match_str = @downcase ? string.downcase : string
    return @placeholder =~ match_str if @placeholder.is_a? Regexp
    match_str == (@downcase ? @placeholder.downcase : @placeholder)
  end
end
  
  
