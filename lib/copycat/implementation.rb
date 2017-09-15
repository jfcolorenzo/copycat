module Copycat
  module Implementation
    # this method overrides part of the i18n gem, lib/i18n/backend/simple.rb
    def lookup(locale, key, scope = [], options = {})
      return super unless ActiveRecord::Base.connected? && CopycatTranslation.table_exists?

      scoped_key = I18n.normalize_keys(nil, key, scope, options[:separator]).join(".")

      cct = nil

      if Copycat.use_cache
        cct = Rails.cache.fetch("_cc_#{locale.to_s}_#{scoped_key}") do
          CopycatTranslation.where(locale: locale.to_s, key: scoped_key).first
        end
      end

      if cct.nil?
        cct = CopycatTranslation.where(locale: locale.to_s, key: scoped_key).first
      end

      if cct
        log_copycat_keys(locale, key, scope, options, scoped_key, cct)
        return cct.value
      end

      value = super(locale, key, scope, options)
      if value.is_a?(String) || value.nil?
        CopycatTranslation.create(locale: locale.to_s, key: scoped_key, value: value)
      end
      value
    end

    private

    def log_copycat_keys(locale, key, scope, options, scoped_key, cct)
      return unless Rails.env.development? || Rails.env.staging?
      return if scope == :'simple_form.labels'
      Rails.logger.info("Translation key: \e[0;32m#{scoped_key}\033[0m, Locale: '#{locale.to_s}', Value: \"#{cct.value}\", edit: \e[0;34m#{Rails.application.routes.url_helpers.edit_copycat_translation_url(cct)}\033[0m")
    end
  end
end
