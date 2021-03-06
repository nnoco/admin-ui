require_relative 'base'
require 'date'
require 'thread'

module AdminUI
  class ApplicationsViewModel < AdminUI::Base
    def initialize(logger, cc, varz)
      super(logger)

      @cc   = cc
      @varz = varz
    end

    def do_items
      applications = @cc.applications

      # applications have to exist.  Other record types are optional
      return result unless applications['connected']

      apps_routes      = @cc.apps_routes
      deas             = @varz.deas
      domains          = @cc.domains
      droplets         = @cc.droplets
      events           = @cc.events
      organizations    = @cc.organizations
      routes           = @cc.routes
      service_bindings = @cc.service_bindings
      spaces           = @cc.spaces
      stacks           = @cc.stacks

      deas_connected             = deas['connected']
      events_connected           = events['connected']
      service_bindings_connected = service_bindings['connected']

      domain_hash       = Hash[domains['items'].map { |item| [item[:id], item] }]
      droplet_hash      = Hash[droplets['items'].map { |item| [item[:droplet_hash], item] }]
      organization_hash = Hash[organizations['items'].map { |item| [item[:id], item] }]
      route_hash        = Hash[routes['items'].map { |item| [item[:id], item] }]
      space_hash        = Hash[spaces['items'].map { |item| [item[:id], item] }]
      stack_hash        = Hash[stacks['items'].map { |item| [item[:id], item] }]

      fqdns_hash = {}
      apps_routes['items'].each do |app_route|
        Thread.pass
        route = route_hash[app_route[:route_id]]
        next if route.nil?
        domain = domain_hash[route[:domain_id]]
        next if domain.nil?
        fqdn = domain[:name]
        host = route[:host]
        path = route[:path]
        fqdn = "#{ host }.#{ fqdn }" if host.length > 0
        fqdn = "#{ fqdn }#{ path }" if path # Add path check since older versions will have nil path
        app_id = app_route[:app_id]
        app_fqdns = fqdns_hash[app_id]
        if app_fqdns.nil?
          app_fqdns = []
          fqdns_hash[app_id] = app_fqdns
        end
        app_fqdns.push(fqdn)
      end

      event_counters = {}
      events['items'].each do |event|
        Thread.pass
        if event[:actee_type] == 'app'
          actee = event[:actee]
          event_counters[actee] = 0 if event_counters[actee].nil?
          event_counters[actee] += 1
        elsif event[:actor_type] == 'app'
          actor = event[:actor]
          event_counters[actor] = 0 if event_counters[actor].nil?
          event_counters[actor] += 1
        end
      end

      service_binding_counters = {}
      service_bindings['items'].each do |service_binding|
        Thread.pass
        app_id = service_binding[:app_id]
        service_binding_counters[app_id] = 0 if service_binding_counters[app_id].nil?
        service_binding_counters[app_id] += 1
      end

      application_usage_counters_hash = {}
      deas['items'].each do |dea|
        next unless dea['connected']
        dea['data']['instance_registry'].each_value do |application|
          application.each_value do |instance|
            Thread.pass
            application_id = instance['application_id']
            application_usage_counters = application_usage_counters_hash[application_id]
            if application_usage_counters.nil?
              application_usage_counters = { 'used_memory' => 0,
                                             'used_disk'   => 0,
                                             'used_cpu'    => 0
                                           }
              application_usage_counters_hash[application_id] = application_usage_counters
            end

            application_usage_counters['used_memory'] += instance['used_memory_in_bytes'] unless instance['used_memory_in_bytes'].nil?
            application_usage_counters['used_disk'] += instance['used_disk_in_bytes'] unless instance['used_disk_in_bytes'].nil?
            application_usage_counters['used_cpu'] += instance['computed_pcpu'] unless instance['computed_pcpu'].nil?
          end
        end
      end

      items = []
      hash  = {}

      applications['items'].each do |application|
        Thread.pass

        guid             = application[:guid]
        id               = application[:id]
        app_droplet_hash = application[:droplet_hash]
        droplet          = app_droplet_hash.nil? ? nil : droplet_hash[app_droplet_hash]
        space            = space_hash[application[:space_id]]
        organization     = space.nil? ? nil : organization_hash[space[:organization_id]]
        stack            = stack_hash[application[:stack_id]]

        application_usage_counters = application_usage_counters_hash[guid]
        event_counter              = event_counters[guid]
        fqdns                      = fqdns_hash[id]
        service_binding_counter    = service_binding_counters[id]

        row = []

        row.push(guid)
        row.push(application[:name])
        row.push(guid)
        row.push(application[:state])
        row.push(application[:package_state])

        row.push(application[:created_at].to_datetime.rfc3339)

        if application[:updated_at]
          row.push(application[:updated_at].to_datetime.rfc3339)
        else
          row.push(nil)
        end

        row.push(fqdns)

        if stack
          row.push(stack[:name])
        else
          row.push(nil)
        end

        if application[:buildpack]
          row.push(application[:buildpack])
        elsif application[:detected_buildpack]
          row.push(application[:detected_buildpack])
        else
          row.push(nil)
        end

        if event_counter
          row.push(event_counter)
        elsif events_connected
          row.push(0)
        else
          row.push(nil)
        end

        row.push(application[:instances])

        if service_binding_counter
          row.push(service_binding_counter)
        elsif service_bindings_connected
          row.push(0)
        else
          row.push(nil)
        end

        if application_usage_counters
          row.push(Utils.convert_bytes_to_megabytes(application_usage_counters['used_memory']))
          row.push(Utils.convert_bytes_to_megabytes(application_usage_counters['used_disk']))
          row.push(application_usage_counters['used_cpu'] * 100)
        elsif deas_connected
          row.push(0, 0, 0)
        else
          row.push(nil, nil, nil)
        end

        row.push(application[:memory])
        row.push(application[:disk_quota])

        if organization && space
          row.push("#{ organization[:name] }/#{ space[:name] }")
        else
          row.push(nil)
        end

        items.push(row)

        hash[guid] =
        {
          'application'  => application,
          'droplet'      => droplet,
          'organization' => organization,
          'space'        => space,
          'stack'        => stack
        }
      end

      result(true, items, hash, (1..18).to_a, (1..9).to_a << 18)
    end
  end
end
