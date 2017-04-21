# frozen_string_literal: true

require 'cgi'
require 'contracts'

### EXAMPLE URL ###
# https://kibana.example.net/app/kibana#/discover?
# _g=(refreshInterval:(display:'5%20minutes',pause:!f,section:2,value:300000),
# time:(from:now-15h,mode:relative,to:now))&
# _a=(columns:!(container_name,hostname,message,metadata.application),
# index:'logs-*',interval:auto,query:(query_string:(analyze_wildcard:!t,
# query:'foo%20bar')),sort:!(time,desc))

# Constructs URLs for Kibana queries.
module KibanaUrl
  include Contracts::Core
  include Contracts::Builtin

  class NotConfiguredError < StandardError; end

  # stuff after the base URL
  STANDARD_PATH = '#/discover'

  # possible sort modes
  SORT_MODES = %i[asc desc].freeze

  # possible time scoping modes
  TIME_SCOPE_MODES = %i[relative absolute].freeze
  # nil to not use custom time_scoping - defaults to 15 minutes ago to now
  # :relative, a time from some Time to now
  # :absolute, a time from some Time to some Time.

  class << self
    attr_accessor :config

    def configure
      self.config ||= {}
      yield config
    end

    # Generates a Kibana URL configured to particular query.
    # Args:
    #   spout_name - key from the hash configured as index_patterns.
    #   columns - array of column names (Strings) to view for each log.
    #   query - string for the query to search on.
    #   sort - how the logs should be sorted. Options are:
    #     * log_param_name -  what you are sorting on
    #     * mode - :asc or :desc (see SORT_MODES above)
    #   refresh_interval_param - number of seconds how often to refresh
    #                          - supports Integer or Nil (default)
    #   time_scope - Hash to specify a custom time scope. Keys:
    #                 * from: Time (or subclass)
    #                 * to: Time (or subclass)
    #                 * mode: see TIME_SCOPE_MODES above for description.
    # Calling just generate(), with no args, will give a default Kibana URL.
    Contract KeywordArgs[
      log_spout: Optional[Symbol],
      columns: Optional[ArrayOf[String]],
      query: Optional[String],
      sort: Optional[{ log_param_name: String, mode: Enum[*SORT_MODES] }],
      refresh_interval: Optional[Maybe[Integer]],
      time_scope: Optional[KeywordArgs[
        mode: Enum[*TIME_SCOPE_MODES],
        from: Optional[Time],
        to: Optional[Time]
      ]]
    ] => String
    def generate(
      log_spout: config&.[](:index_patterns)&.keys&.first,
      columns: ['_source'],
      query: '*',
      sort: { log_param_name: 'time', mode: :desc },
      refresh_interval: nil,
      time_scope: { mode: :relative }
    )
      if config.nil? ||
         config[:index_patterns].empty? || config[:kibana_base_url].empty?
        raise NotConfiguredError
      end

      # There are two params in Kibana URLs.
      # Each have multiple arguments comma separated.
      a_params = []
      a_params << columns_param(columns)
      a_params << spout_param(log_spout)
      a_params << interval_param
      a_params << query_param(query)
      a_params << sort_param(sort)
      a_params_str = a_params.compact.join(',') # comma delimit params

      g_params = []
      g_params << refresh_interval_param(refresh_interval)
      g_params << time_scope_param(time_scope)
      g_params_str = g_params.compact.join(',') # comma delimit params

      "#{config[:kibana_base_url]}#{STANDARD_PATH}?" \
        "_g=(#{g_params_str})&_a=(#{a_params_str})"
    end

    private

    # Method to construct columns params in query.
    # "columns:!(col_1,col_2,...,col_n)"
    def columns_param(column_names)
      column_names.map! { |name| escape(name) }
      "columns:!(#{column_names.join(',')})"
    end

    # Method determines correct index pattern (stream from which to draw logs).
    # "index:'<spout name>'"
    def spout_param(spout_name)
      "index:'#{config[:index_patterns][spout_name]}'"
    end

    # Method for interval - unclear what this does.
    # "interval:auto"
    def interval_param
      "interval:auto"
    end

    # Method for query param.
    # "query:(query_string:(analyze_wildcard:!t,query:'<url escaped query>'))"
    def query_param(raw_query_str)
      "query:(query_string:(analyze_wildcard:" \
        "!t,query:'#{escape(raw_query_str)}'))"
    end

    # Method to set a particular sort on the logs.
    # "sort:!(<log param name>,<sort mode: :desc or :asc>)"
    def sort_param(log_param_name: 'time', mode: :desc)
      "sort:!(#{escape(log_param_name)},#{mode})"
    end

    # Method to set the refresh interval.
    # "refreshInterval:(display:'<num seconds string>'," \
    # "pause:!f,section:1,value:<num milliseconds>)"
    def refresh_interval_param(seconds)
      return nil unless seconds
      "refreshInterval:(display:'#{seconds}%20seconds'," \
        "pause:!f,section:1,value:#{seconds * 1000})"
    end

    # Method to set a time scope for the query.
    # Creates "time:(from:<from Time>,mode:<mode>,to:<from Time>)" or nil
    def time_scope_param(
      mode: :relative,
      from: Time.now - (15 * 60),
      to: Time.now
    )
      if mode == :relative
        to_str = 'now'
        num_seconds_ago = Time.now.to_i - from.to_i
        from_str = "now-#{num_seconds_ago}s"
      elsif mode == :absolute
        to_str = date_time_str(to)
        from_str = date_time_str(from)
      end
      "time:(from:'#{from_str}',mode:#{mode},to:'#{to_str}')"
    end

    # Translates a time into a date-time string for Kibana
    def date_time_str(time)
      "#{time.utc.strftime('%Y-%m-%d')}T#{time.utc.strftime('%H:%M:%S.%L')}Z"
    end

    # Alias for URL escaping.
    def escape(str)
      CGI.escape(str)
    end
  end
end
