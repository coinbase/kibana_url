# Kibana URL

Kibana URLs are complex strings but it can be useful to create them programmatically based on data in your application. This gem helps construct working Kibana URLs configured to specific queries, index, time scopes, and more.

This was developed on Kibana 4.6.3 (but may work on other versions too).

## Install
```bash
gem install kibana_url
```

## Usage
See below for all the options.

```ruby
url_string = KibanaUrl.generate(
  query: '"needle in the haystack"',
  time_scope: { mode: :relative, from: Time.now - (60 * 60) }, # 1 hour ago
  refresh_interval: 60 # every 1 minute
)
```

## Configure
```ruby
KibanaUrl.configure do |config|
  # Provide a base URL for your Kibana endpoint (required).
  config[:kibana_base_url] = 'https://kibana.intranet.net/app/kibana'

  # Provide a mapping of common names and Elasticsearch log indexes (required).
  config[:index_patterns] = {
    app: 'application-logs-*', # first entry becomes default for URLs generated
    aws: 'cloudtrail-*',
  }
end
```

## All Possible Options
These are optional keyword arguments to the `generate()` method.

##### `log_spout`
  - Purpose: These will specify which Elasticsearch log index to use.
  - Type: `Symbol`
  - Valid values: keys from `:index_patterns` in the gem configuration.
  - Default: First key in the map.

##### `columns`
  - Purpose: List of columns you want to show for each log.
  - Type: `Array` of `String`
  - Default: `['_source']`

##### `query`
  - Purpose: The string the would go into the Kibana search bar to filter logs.
  - Type: `String`
  - Default: `*`

##### `sort`
  - Purpose: Specifies the way you want the logs to be sorted.
  - Type: `Hash` with keys `:log_param_name`, `:mode`.
  - Valid values: `:mode` can be `:asc` or `:desc`, `:log_param_name` can be the name of any log field.
  - Default: `{ log_param_name: 'time', mode: :desc }`.

##### `refresh_interval`
  - Purpose: How often you want the search to refresh.
  - Type: `Integer`
  - Default: `nil` (which is no auto-refreshing action.)

##### `time_scope`
  - Purpose: Time window over which to query.
  - Type: `Hash` with keys `:mode` (optional), `:from` (optional), `:to` (optional)
  - Valid values:
    - `:mode` specifies the type of time scope.
    - `:relative` will be from some given `:from` time ago up to the present time and `:absolute` is from a specific time ago up to another specific time.
    - An example of a relative time scope for 5 hours ago - `{ mode: :relative, from: 5 * 60 * 60 }`.
    - An example of an absolute time scope from 1000 PST to 1400 PST on June 20, 2012 - `{ mode: :relative, from: Time.new(2012, 06, 20, 10, 0, 0, "-07:00"), to: Time.new(2012, 06, 20, 14, 0, 0, "-07:00") }`
  - Default: relative time scope of 15 minutes ago.

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/coinbase/kibana_url.

## License
The gem is available open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
