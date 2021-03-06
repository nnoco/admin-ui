require 'nats/client'
require 'uri'
require 'yajl'

module AdminUI
  class NATS
    def initialize(config, logger, email)
      @config = config
      @logger = logger
      @email  = email

      FileUtils.mkpath File.dirname(@config.data_file)

      @semaphore = Mutex.new
      @condition = ConditionVariable.new

      @cache = {}

      thread = Thread.new do
        loop do
          schedule_discovery
        end
      end

      thread.priority = -2
    end

    def get
      @semaphore.synchronize do
        @condition.wait(@semaphore) while @cache['items'].nil?
        @cache.clone
      end
    end

    def remove(uris)
      @semaphore.synchronize do
        @cache = read_or_initialize_cache

        removed = false
        uris.each do |uri|
          removed = true unless @cache['items'].delete(uri).nil?
          removed = true unless @cache['notified'].delete(uri).nil?
        end

        write_cache if removed
      end
    end

    private

    def schedule_discovery
      nats_discovery_results = nats_discovery

      disconnected = []

      @semaphore.synchronize do
        save_data(nats_discovery_results, disconnected)

        send_email(disconnected)

        @condition.broadcast
        @condition.wait(@semaphore, @config.nats_discovery_interval)
      end
    end

    def nats_discovery
      result = {}
      result['items'] = {}

      begin
        @logger.debug("[#{ @config.nats_discovery_interval } second interval] Starting NATS discovery...")

        @start_time = Time.now.to_f

        @last_discovery_time = 0

        thread = Thread.new do
          while (@last_discovery_time == 0 && (Time.now.to_f - @start_time < @config.nats_discovery_interval)) || (Time.now.to_f - @last_discovery_time < @config.nats_discovery_timeout)
            sleep(@config.nats_discovery_timeout)
          end
          ::NATS.stop
        end

        thread.priority = -2

        ::NATS.start(uri: @config.mbus, ping_interval: @config.nats_discovery_timeout) do
          # Set the connected to true to handle case where NATS is back up but no components are.
          # This gets rid of the disconnected error message on the UI without waiting for the nats_discovery_interval.
          @semaphore.synchronize do
            @cache['connected'] = true
          end

          ::NATS.request('vcap.component.discover') do |item|
            @last_discovery_time = Time.now.to_f
            item_json = Yajl::Parser.parse(item)
            result['items'][item_uri(item_json)] = item_json
          end
        end

        result['connected'] = true
      rescue => error
        result['connected'] = false

        @logger.debug("Error during NATS discovery: #{ error.inspect }")
        @logger.debug(error.backtrace.join("\n"))
      end

      result
    end

    # The call to this method must be in a synchronized block
    def read_or_initialize_cache
      if File.exist?(@config.data_file)
        begin
          read = IO.read(@config.data_file)
          begin
            parsed = Yajl::Parser.parse(read)
            if parsed.is_a?(Hash)
              if parsed.key?('items')
                return parsed if parsed.key?('notified')
                @logger.debug("Error during NATS parse data: 'notified' key not present")
              else
                @logger.debug("Error during NATS parse data: 'items' key not present")
              end
            else
              @logger.debug('Error during NATS parse data: parsed data not a hash')
            end
          rescue => error
            @logger.debug("Error during NATS parse data: #{ error.inspect }")
            @logger.debug(error.backtrace.join("\n"))
          end
        rescue => error
          @logger.debug("Error during NATS read data: #{ error.inspect }")
          @logger.debug(error.backtrace.join("\n"))
        end
      end
      { 'items' => {}, 'notified' => {} }
    end

    # The call to this method must be in a synchronized block
    def write_cache
      File.open(@config.data_file, 'w') do |file|
        file.write(Yajl::Encoder.encode(@cache, pretty: true))
      end
    rescue => error
      @logger.debug("Error during NATS write data: #{ error.inspect }")
      @logger.debug(error.backtrace.join("\n"))
    end

    def save_data(nats_discovery_results, disconnected)
      @logger.debug('Saving NATS data...')

      begin
        @cache = read_or_initialize_cache

        # Special-casing code to handle same component restarting with different ephemeral port.
        # Remove all old references which also have new references prior to merge.
        new_item_keys = {}
        nats_discovery_results['items'].each do |uri, item|
          new_item_keys[item_key(uri, item)] = nil
        end

        @cache['items'].each do |uri, item|
          if new_item_keys.include?(item_key(uri, item))
            @cache['items'].delete(uri)
            @cache['notified'].delete(uri)
          end
        end

        @cache['connected'] = nats_discovery_results['connected']
        @cache['items'].merge!(nats_discovery_results['items'])

        update_connection_status('NATS',
                                 @config.mbus.partition('@').last[0..-1],
                                 @cache['connected'],
                                 disconnected)

        @cache['items'].each do |uri, item|
          update_connection_status(item['type'],
                                   uri,
                                   nats_discovery_results['items'][uri],
                                   disconnected)
        end

        write_cache
      rescue => error
        @logger.debug("Error during NATS save data: #{ error.inspect }")
        @logger.debug(error.backtrace.join("\n"))
      end
    end

    def send_email(disconnected)
      return unless @email.configured? && disconnected.length > 0
      thread = Thread.new do
        begin
          @email.send_email(disconnected)
        rescue => error
          @logger.debug("Error during send email: #{ error.inspect }")
          @logger.debug(error.backtrace.join("\n"))
        end
      end

      thread.priority = -2
    end

    def update_connection_status(type, uri, connected, disconnectedList)
      return unless monitored?(type)
      if connected
        @cache['notified'].delete(uri)
      else
        component_entry = component_entry(type, uri)
        if component_entry['count'] < @config.component_connection_retries
          @logger.debug("The #{ type } component #{ uri } is not responding, its status will be checked again next refresh")
        elsif component_entry['count'] == @config.component_connection_retries
          @logger.debug("The #{ type } component #{ uri } has been recognized as disconnected")
          disconnectedList.push(component_entry)
        else
          @logger.debug("The #{ type } component #{ uri } is still not responding")
        end
      end
    end

    def monitored?(component)
      @config.monitored_components.each do |type|
        return true if component =~ /#{ type }/ || type.casecmp('ALL') == 0
      end
      false
    end

    def component_entry(type, uri)
      result = @cache['notified'][uri]
      result = { 'count' => 0, 'type' => type, 'uri' => uri } if result.nil?
      result['count'] += 1
      @cache['notified'][uri] = result

      result
    end

    def item_uri(item)
      "http://#{ item['host'] }/varz"
    end

    # Determine key for comparison.  Type and index are insufficient.  Host must be included (without port) as well.
    def item_key(uri_string, item)
      uri = URI.parse(uri_string)
      "#{ item['type'] }:#{ item['index'] }:#{ uri.host }"
    end
  end
end
