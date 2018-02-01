module Lita
  module Helpers
    # Helpers to go alongside fetching & parsing things
    module Utilities
      def mute_host(hostname, args)
        client = Dogapi::Client.new(config.api_key, config.application_key)
        return false unless client

        return_code, contents = client.mute_host(hostname, args)

        if return_code.to_s != '200'
          log.warning("URL (#{return_code}): #{contents['errors'].join("\n")}")
          return false
        end

        true
      end

      def unmute_host(hostname)
        client = Dogapi::Client.new(config.api_key, config.application_key)
        return false unless client

        return_code, contents = client.unmute_host(hostname)

        if return_code.to_s != '200'
          log.warning("URL (#{return_code}): #{contents['errors'].join("\n")}")
          return false
        end

        true
      end

      def get_graph_url(metric_query, start_ts, end_ts, event_query)
        client = Dogapi::Client.new(config.api_key, config.application_key)

        return nil unless client

        return_code, contents = client.graph_snapshot(metric_query, start_ts,
                                                      end_ts, event_query)

        if return_code.to_s != '200'
          log.warning("URL (#{return_code}): #{contents['errors'].join("\n")}")
          return nil
        end

        contents
      end

      def search(facet, query)
        return nil unless %i[hosts metrics].include? facet
        client = Dogapi::Client.new(config.api_key, config.application_key)
        return nil unless client
        search_with_client(client, facet, query)
      end

      def search_with_client(client, facet, query)
        query = "#{facet}:#{query}"
        return_code, result = client.search(query)
        if return_code != 200
          log.warning("URL (#{return_code}): #{contents['errors'].join("\n")}")
          return nil
        end
        result['results'][facet.to_s]
      end

      def parse_arguments(arg_string)
        end_ts   = parse_end(arg_string)
        start_ts = parse_start(arg_string, end_ts)
        metric   = parse_metric(arg_string)
        event    = parse_event(arg_string)
        { metric: metric, start: start_ts, end: end_ts, event: event }
      end

      def parse_end(string)
        found = /(to|end):"(.+?)"/.match(string)
        found ? Chronic.parse(found[2]).to_i : Time.now.to_i
      end

      def parse_start(string, end_ts)
        found = /(from|start):"(.+?)"/.match(string)
        found ? Chronic.parse(found[2]).to_i : end_ts - config.timerange
      end

      def parse_metric(string)
        found = /metric:"(.+?)"/.match(string)
        found ? found[1] : 'system.load.1{*}'
      end

      def parse_event(string)
        found = /event:"(.+?)"/.match(string)
        found ? found[1] : ''
      end
    end
  end
end
