module Concerns
  module LocalizedFields
    extend ActiveSupport::Concern

    class_methods do
      attr_reader :localized_fields

      def localize_fields(*args)
        @localized_fields = []

        args.each do |field|
          @localized_fields << field.to_sym

          method_name = field.to_s.singularize

          define_method method_name do |locale = nil|
            send(field)[determine_locale(locale)]
          end

          define_method "#{method_name}=" do |value|
            send(field)[determine_locale(nil)] = value
          end
        end
      end
    end

    private

    def _assign_attribute(k, v)
      if self.class.localized_fields.map(&:to_s).include?(k)
        values = v.symbolize_keys
        values.each_pair do |locale, value|
          send(k)[locale.to_s] = value
        end
      else
        super
      end
    end

    def determine_locale(locale)
      locale.nil? ? Settings.madek_default_locale : locale.to_s
    end
  end
end
