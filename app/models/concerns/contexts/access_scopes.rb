module Concerns
  module Contexts
    module AccessScopes
      extend ActiveSupport::Concern

      class_methods do
        def restricted_for_resource(resource)
          allowed_api_client_ids = resource.api_client_permissions.pluck(:api_client_id)

          cacp_table = Permissions::ContextApiClientPermission.arel_table
          restricted_context_ids = arel_table
            .project(arel_table[:id])
            .join(cacp_table)
            .on(cacp_table[:context_id].eq(arel_table[:id]))
            .where(cacp_table[:view].eq(true))
            .where(cacp_table[:api_client_id].not_in(allowed_api_client_ids))

          where(arel_table[:id].in(restricted_context_ids))
        end
      end
    end
  end
end
