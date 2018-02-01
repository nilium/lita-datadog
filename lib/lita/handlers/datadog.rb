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
        :find_hosts,
        command: true,
        help: {
            t('help.hosts.syntax') => t('help.hosts.desc'),
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

      def find_hosts(response)
        query = response.match_data['query'].strip
        return response.reply(t('hosts.no_query')) if query.empty?
        hosts = get_hosts(query)
        if !hosts
          response.reply(t('errors.request'))
        else
          response.reply(
            t('hosts.success',
              count: hosts.length,
              body: "- #{hosts.join("\n- ")}")
          )
        end
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
