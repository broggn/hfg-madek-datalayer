# load seed data from YAML file and apply it to DB
####################################################################################

DB_SEEDS ||= YAML.load_file(Rails.root.join('db','seeds_and_defaults.yml'))
  .deep_symbolize_keys

CORE_VOCAB = DB_SEEDS[:MADEK_CORE_VOCABULARY]
DEFAULT_LOCALE = Settings.madek_default_locale

####################################################################################
ActiveRecord::Base.transaction do

  # Core Vocab #####################################################################

  # needs disabled triggers to temporarily make it mutable
  ActiveRecord::Base.connection.execute 'SET session_replication_role = replica;'

  Vocabulary.find_or_create_by(id: CORE_VOCAB[:id]).update_attributes!(
    CORE_VOCAB.slice(:label, :description, :admin_comment)
      .map {|k, v| [k, v.try(:strip)] }.to_h)

  CORE_VOCAB[:meta_keys].each do |id, attrs|
    MetaKey.find_or_initialize_by(id: id).update_attributes!(attrs)
  end
  # enable DB triggers!
  ActiveRecord::Base.connection.execute 'SET session_replication_role = DEFAULT;'

  # RDF Classes
  ['Keyword', 'License'].each do |name|
    RdfClass.find_or_create_by!(id: name)
  end

  # NOTE: No default Context(s), as they are not needed as seeds
  # for testing, there is personas; for prod stock defaults are applied on install

  # CLEANUP ########################################################################

  # find ContextKeys that "overide" a string (like label)
  # with the SAME string and delete those duplicated string(s)
  # (for each language/locale)
  %w(labels descriptions hints).each do |column_name|
    Settings.madek_available_locales.each do |lang|
      ContextKey.includes(:meta_key).find_each do |ck|
        if ck.labels[lang] == ck.meta_key.labels[lang]
          ck.update_column(:labels, { DEFAULT_LOCALE => nil })
        end
        if ck.descriptions[lang] == ck.meta_key.descriptions[lang]
          ck.update_column(:descriptions, { DEFAULT_LOCALE => nil })
        end
        if ck.hints[lang] == ck.meta_key.hints[lang]
          ck.update_column(:hints, { DEFAULT_LOCALE => nil })
        end
      end
    end
  end

end
