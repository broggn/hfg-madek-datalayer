module Concerns
  module SharedScopes
    extend ActiveSupport::Concern

    included do
      scope :filter_by_visibility_public, lambda {
        where(get_metadata_and_previews: true)
      }

      scope :filter_by_visibility_user_or_group, lambda {
        where(get_metadata_and_previews: false).where(
          sql_for_user_or_group_permission
        )
      }

      scope :filter_by_visibility_api, lambda {
        where(get_metadata_and_previews: false).where(
          sql_for_api_permission
        )
      }

      scope :filter_by_visibility_private, lambda {
        where(get_metadata_and_previews: false).where.not(
          sql_for_user_or_group_permission
        ).where.not(
          sql_for_api_permission
        )
      }

      scope :filter_by_editability_metadata, lambda { |user|
        where(sql_for_edit_metadata(user))
      }

      scope :filter_by_editability_not_metadata, lambda { |user|
        where.not(sql_for_edit_metadata(user))
      }

      scope :filter_by_editability_deletable, lambda { |user|
        where(sql_for_deletable(user))
      }

      scope :filter_by_editability_not_deletable, lambda { |user|
        where.not(sql_for_deletable(user))
      }

      scope :filter_by_editability_permissions, lambda { |user|
        where(sql_for_edit_permissions(user))
      }

      scope :filter_by_editability_not_permissions, lambda { |user|
        where.not(sql_for_edit_permissions(user))
      }

      private

      def self.sql_for_deletable(user)
        singular = name.underscore
        plural = singular.pluralize
        <<-SQL
          (#{plural}.responsible_user_id = '#{user.id}')
        SQL
      end

      # rubocop:disable Metrics/MethodLength
      def self.sql_for_edit_metadata(user)
        singular = name.underscore
        plural = singular.pluralize
        <<-SQL
          (#{plural}.responsible_user_id = '#{user.id}')
          --  or I have a permission
          OR EXISTS (
            SELECT 1
            FROM   #{singular}_user_permissions
            WHERE  #{singular}_user_permissions.#{singular}_id = #{plural}.id
            AND #{singular}_user_permissions.edit_metadata = 't'
            AND #{singular}_user_permissions.user_id = '#{user.id}' )
          -- or one of my groups has a permission
          OR EXISTS (
            SELECT 1
            FROM #{singular}_group_permissions
            INNER JOIN groups ON #{singular}_group_permissions.group_id = groups.id
            INNER JOIN groups_users ON groups_users.group_id = groups.id
            WHERE  #{singular}_group_permissions.#{singular}_id = #{plural}.id
            AND #{singular}_group_permissions.edit_metadata = 't'
            AND groups_users.user_id = '#{user.id}' )
        SQL
      end
      # rubocop:enable Metrics/MethodLength

      def self.sql_for_edit_permissions(user)
        singular = name.underscore
        plural = singular.pluralize
        <<-SQL
          (#{plural}.responsible_user_id = '#{user.id}')
          --  or I have a permission
          OR EXISTS (
            SELECT 1
            FROM   #{singular}_user_permissions
            WHERE  #{singular}_user_permissions.#{singular}_id = #{plural}.id
            AND #{singular}_user_permissions.edit_permissions = 't'
            AND #{singular}_user_permissions.user_id = '#{user.id}' )
        SQL
      end

      def self.sql_for_api_permission
        singular = name.underscore
        plural = singular.pluralize
        <<-SQL
          exists (
            select
              *
            from
              #{singular}_api_client_permissions
            where
              #{singular}_api_client_permissions.#{singular}_id = #{plural}.id
          )
        SQL
      end

      def self.sql_for_user_or_group_permission
        singular = name.underscore
        plural = singular.pluralize
        <<-SQL
          exists (
            select
              *
            from
              #{singular}_group_permissions
            where
              #{singular}_group_permissions.#{singular}_id = #{plural}.id
          )
          or
          exists (
            select
              *
            from
              #{singular}_user_permissions
            where
              #{singular}_user_permissions.#{singular}_id = #{plural}.id
          )
        SQL
      end
    end
  end
end
