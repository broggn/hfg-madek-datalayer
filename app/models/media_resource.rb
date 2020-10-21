class MediaResource < ApplicationRecord
  self.table_name = :vw_media_resources
  self.primary_key = :id
  # prevents Rails to treat the table/view as STI table
  self.inheritance_column = :_not_existing_column

  include Concerns::MediaResources::CustomOrderBy

  def self.viewable_by_user_or_public(user)
    scope_helper(:viewable_by_user_or_public, user)
  end

  def self.filter_by(user = nil, filter_opts)
    scope_helper(:filter_by, user, filter_opts)
  end

  def self.scope_helper(method_name, *args)
    part_of_workflow_hash = args
      .detect { |a| a.is_a?(Hash) }&.extract!(:part_of_workflow)
    part_of_workflow = part_of_workflow_hash&.fetch(:part_of_workflow)

    view_scope = \
      unified_scope(MediaEntry.send(method_name, *args).reorder(nil),
                    Collection.send(method_name, *args).reorder(nil),
                    FilterSet.send(method_name, *args).reorder(nil),
                    part_of_workflow)

    sql = "((#{(current_scope or all).to_sql}) INTERSECT " \
           "(#{view_scope.to_sql})) AS vw_media_resources"
    from(sql)
  end

  def self.unified_scope(scope1, scope2, scope3, part_of_workflow = false)
    scope1, scope2, scope3 = [scope1, scope2, scope3].map do |s|
      if part_of_workflow && s.respond_to?(:with_unpublished)
        s = s.with_unpublished
      end
      s
    end

    where(
      "vw_media_resources.id IN (#{scope1.select(:id).to_sql}) " \
      "OR vw_media_resources.id IN (#{scope2.select(:id).to_sql}) " \
      "OR vw_media_resources.id IN (#{scope3.select(:id).to_sql})"
    )
  end

  private_class_method :scope_helper

  def self.joins_meta_data_title
    joins(<<-SQL.strip_heredoc)
      INNER JOIN meta_data
      ON meta_data.meta_key_id = 'madek_core:title'
      AND (
        meta_data.media_entry_id = vw_media_resources.id
        OR meta_data.collection_id = vw_media_resources.id
        OR meta_data.filter_set_id = vw_media_resources.id
      )
    SQL
  end

  # rubocop:disable Metrics/MethodLength
  def self.order_by_last_edit_session
    select(
      <<-SQL
        vw_media_resources.*,
        coalesce(
          media_entries.edit_session_updated_at,
          collections.edit_session_updated_at,
          filter_sets.edit_session_updated_at
        ) AS last_change
      SQL
    )
    .joins(
      <<-SQL
        LEFT JOIN media_entries
        ON (media_entries.id = vw_media_resources.id AND vw_media_resources.type = 'MediaEntry')
      SQL
    )
    .joins(
      <<-SQL
        LEFT JOIN collections
        ON (collections.id = vw_media_resources.id AND vw_media_resources.type = 'Collection')
      SQL
    )
    .joins(
      <<-SQL
        LEFT JOIN filter_sets
        ON (filter_sets.id = vw_media_resources.id AND vw_media_resources.type = 'FilterSet')
      SQL
    )
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def self.order_by_manual_sorting
    select(
      <<-SQL
        vw_media_resources.*,
        coalesce(cmea.position, cca.position, cfsa.position) AS arc_position
      SQL
    )
    .distinct('vw_media_resources.id')
    .joins(
      <<-SQL
        LEFT JOIN collection_media_entry_arcs cmea
        ON (cmea.media_entry_id = vw_media_resources.id AND vw_media_resources.type = 'MediaEntry')
      SQL
    )
    .joins(
      <<-SQL
        LEFT JOIN collection_collection_arcs cca
        ON (cca.child_id = vw_media_resources.id AND vw_media_resources.type = 'Collection')
      SQL
    )
    .joins(
      <<-SQL
        LEFT JOIN collection_filter_set_arcs cfsa
        ON (cfsa.filter_set_id = vw_media_resources.id AND vw_media_resources.type = 'FilterSet')
      SQL
    )
  end
  # rubocop:enable Metrics/MethodLength

  def cast_to_type
    @_casted_to_type ||= becomes(type.constantize)
  end
end
