require_relative 'base'
require 'date'
require 'thread'

module AdminUI
  class SpaceQuotasViewModel < AdminUI::Base
    def initialize(logger, cc)
      super(logger)

      @cc = cc
    end

    def do_items
      space_quota_definitions = @cc.space_quota_definitions

      # space_quota_definitions have to exist.  Other record types are optional
      return result unless space_quota_definitions['connected']

      organizations = @cc.organizations
      spaces        = @cc.spaces

      spaces_connected = spaces['connected']

      organization_hash = Hash[organizations['items'].map { |item| [item[:id], item] }]

      space_counters = {}

      spaces['items'].each do |space|
        Thread.pass
        space_quota_definition_id = space[:space_quota_definition_id]
        space_counters[space_quota_definition_id] = 0 if space_counters[space_quota_definition_id].nil?
        space_counters[space_quota_definition_id] += 1
      end

      items = []
      hash  = {}

      space_quota_definitions['items'].each do |space_quota_definition|
        Thread.pass

        guid          = space_quota_definition[:guid]
        organization  = organization_hash[space_quota_definition[:organization_id]]

        space_counter = space_counters[space_quota_definition[:id]]

        row = []

        row.push(guid)
        row.push(space_quota_definition[:name])
        row.push(guid)
        row.push(space_quota_definition[:created_at].to_datetime.rfc3339)

        if space_quota_definition[:updated_at]
          row.push(space_quota_definition[:updated_at].to_datetime.rfc3339)
        else
          row.push(nil)
        end

        row.push(space_quota_definition[:total_services])
        row.push(space_quota_definition[:total_routes])
        row.push(space_quota_definition[:memory_limit])
        row.push(space_quota_definition[:instance_memory_limit])
        row.push(space_quota_definition[:non_basic_services_allowed])

        if space_counter
          row.push(space_counter)
        elsif spaces_connected
          row.push(0)
        else
          row.push(nil)
        end

        if organization
          row.push(organization[:name])
          row.push(organization[:guid])
        else
          row.push(nil, nil)
        end

        items.push(row)

        hash[guid] =
        {
          'organization'           => organization,
          'space_quota_definition' => space_quota_definition
        }
      end

      result(true, items, hash, (1..12).to_a, [1, 2, 3, 4, 9, 11, 12])
    end
  end
end
