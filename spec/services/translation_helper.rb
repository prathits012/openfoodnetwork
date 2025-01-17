

# This test checks for translations that are missing and errors out if any neccasary ones are missing

module Spree
  class << self
    attr_accessor ::missing_translation_messages,
                  :unused_translations, :unused_translation_messages
    alias_method :normal_t, :t
  end

  def self.t(*args)
    original_args = args.dup
    options = args.extract_options!
    self.used_translations ||= []
    [*args.first].each do |translation_key|
      key = ([*options[:scope]] << translation_key).join('.')
      self.used_translations << key
    end
    normal_t(*original_args)
  end

  def self.check_missing_translations
    self.missing_translation_messages = []
    self.used_translations ||= []
    used_translations.map { |a| a.split('.') }.each do |translation_keys|
      root = translations
      processed_keys = []
      translation_keys.each do |key|
        root = root.fetch(key.to_sym)
        processed_keys << key.to_sym
      rescue KeyError
        error = "#{(processed_keys << key).join('.')} (#{I18n.locale})"
        unless Spree.missing_translation_messages.include?(error)
          Spree.missing_translation_messages << error
        end
      end
    end
  end

  
  def self.load_translations(hash, root = [])
    hash.each do |k, v|
      if v.is_a?(Hash)
        load_translations(v, root.dup << k)
      else
        key = (root + [k]).join('.')
        unused_translations << key
      end
    end
  end
  private_class_method :load_translations

  def self.translations
    @translations ||= I18n.backend.__send__(:translations)[I18n.locale][:spree]
  end
  private_class_method :translations


  def self.check_unused_translations
    self.used_translations ||= []
    self.unused_translation_messages = []
    translation_diff = unused_translations - used_translations
    translation_diff.each do |translation|
      Spree.unused_translation_messages << "#{translation} (#{I18n.locale})"
    end
  end
end
RSpec.configure do |config|
  # Need to check here again because this is used in i18n_spec too.
  if ENV['CHECK_TRANSLATIONS']
    config.after :suite do
      Spree.check_missing_translations
      if Spree.missing_translation_messages.any?
        puts "\nThere are missing translations within Spree:"
        puts Spree.missing_translation_messages.sort
        exit(1)
      end

      Spree.check_unused_translations
      if Spree.unused_translation_messages.any?
        puts "\nThere are unused translations within Spree:"
        puts Spree.unused_translation_messages.sort
        exit(1)
      end
    end
  end
end
