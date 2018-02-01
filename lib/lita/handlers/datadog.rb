module Lita
  module Handlers
    class Datadog < Handler
      config :api_key, required: true
      config :application_key, required: true
      config :timerange, default: 3600
      config :waittime, default: 0

      include Lita::Helpers::Utilities
      include Lita::Helpers::Graphs

      route(
        /^dd\s+graph\s+(?<args>.+)$/,
        :graph,
        command: true,
        help: {
          t('help.graph.syntax') => t('help.graph.desc')
        }
      )

      route(
        /^dd\s+hosts(?:\s+(?<query>\S*))?$/,
        :hosts,
        command: true,
        help: {
          t('help.hosts.syntax') => t('help.hosts.desc')
        }
      )

      route(
        /^dd\s+metrics(?:\s+(?<query>\S*))?$/,
        :metrics,
        command: true,
        help: {
          t('help.metrics.syntax') => t('help.metrics.desc')
        }
      )

      route(
        /^dd\s+mute\s+(?<hostname>\S*)(\s+message:"(?<message>.*)")?$/,
        :mute,
        command: true,
        help: {
          t('help.mute.syntax') => t('help.mute.desc')
        }
      )

      route(
        /^dd\s+unmute\s+(?<hostname>\S*)$/,
        :unmute,
        command: true,
        help: {
          t('help.unmute.syntax') => t('help.unmute.desc')
        }
      )

      def graph(response)
        content = snapshot(parse_arguments(response.match_data['args']))
        response.reply(content)
      end

      def hosts(response)
        query = response.match_data['query']
        reply_to_facet_search(response, :hosts, query)
      end

      def metrics(response)
        query = response.match_data['query']
        reply_to_facet_search(response, :metrics, query)
      end

      def reply_to_facet_search(response, facet, query)
        return response.reply(t('errors.no_query')) if !query || query.empty?
        results = search(facet, query)
        return response.reply(t('errors.request')) unless results
        body = "- #{results.join("\n- ")}"
        response.reply(t("#{facet}.success", count: results.length, body: body))
      end

      def mute(response)
        hostname = response.match_data['hostname']
        message = response.match_data['message']
        args = {}
        args['message'] = message unless message.nil?
        if mute_host(hostname, args)
          response.reply(t('mute.success', host: hostname))
        else
          response.reply(t('errors.request'))
        end
      end

      def unmute(response)
        hostname = response.match_data['hostname']
        if unmute_host(hostname)
          response.reply(t('unmute.success', host: hostname))
        else
          response.reply(t('errors.request'))
        end
      end
    end

    Lita.register_handler(Datadog)
  end
end
