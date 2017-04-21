# frozen_string_literal: true

require 'kibana_url'
require 'rspec'
require 'timecop'

describe KibanaUrl do
  describe 'using without configuration' do
    it 'should raise an exception to inform the developer' do
      expect { KibanaUrl.generate }.to raise_error(
        KibanaUrl::NotConfiguredError
      )
    end
  end

  # Test data inspired from real Kibana URLs set up through their UI.
  describe '#generate' do
    before do
      KibanaUrl.configure do |config|
        config[:kibana_base_url] = 'https://kibana.intranet.net/app/kibana'
        config[:index_patterns] = {
          app: 'application-logs-*',
          aws: 'cloudtrail-*'
        }
      end
    end

    it 'should return default the URL if no params given' do
      expect(KibanaUrl.generate).to eq(
        "https://kibana.intranet.net/app/kibana#/discover?"                \
        "_g=(time:(from:'now-900s',mode:relative,to:'now'))&"              \
        "_a=(columns:!(_source),index:'application-logs-*',interval:auto," \
        "query:(query_string:(analyze_wildcard:!t,query:'%2A')),"          \
        "sort:!(time,desc))"
      )
    end

    it 'should allow for different types of log spouts' do
      expect(KibanaUrl.generate(log_spout: :aws)).to eq(
        "https://kibana.intranet.net/app/kibana#/discover?"          \
        "_g=(time:(from:'now-900s',mode:relative,to:'now'))&"        \
        "_a=(columns:!(_source),index:'cloudtrail-*',interval:auto," \
        "query:(query_string:(analyze_wildcard:!t,query:'%2A')),"    \
        "sort:!(time,desc))"
      )
    end

    it 'should allow for an array of columns' do
      expect(KibanaUrl.generate(columns: ['_index', 'metadata._COMM'])).to eq(
        "https://kibana.intranet.net/app/kibana#/discover?"                \
        "_g=(time:(from:'now-900s',mode:relative,to:'now'))&"              \
        "_a=(columns:!(_index,metadata._COMM),index:'application-logs-*'," \
        "interval:auto,query:(query_string:(analyze_wildcard:!t,"          \
        "query:'%2A')),sort:!(time,desc))"
      )
    end

    it 'should allow for a custom query string' do
      expect(KibanaUrl.generate(query: 'royal with cheese')).to eq(
        "https://kibana.intranet.net/app/kibana#/discover?"                 \
        "_g=(time:(from:'now-900s',mode:relative,to:'now'))&"               \
        "_a=(columns:!(_source),index:'application-logs-*',interval:auto," \
        "query:(query_string:(analyze_wildcard:!t,"                         \
        "query:'royal+with+cheese')),sort:!(time,desc))"
      )
      expect(
        KibanaUrl.generate(
          query: '*quarter-pounder* || ("royal with cheese" && burger)'
        )
      ).to eq(
        "https://kibana.intranet.net/app/kibana#/discover?"                  \
        "_g=(time:(from:'now-900s',mode:relative,to:'now'))&"                \
        "_a=(columns:!(_source),index:'application-logs-*',interval:auto,"   \
        "query:(query_string:(analyze_wildcard:!t,query:'%2Aquarter-pounder" \
        "%2A+%7C%7C+%28%22royal+with+cheese%22+%26%26+burger%29')),"         \
        "sort:!(time,desc))"
      )
    end

    it 'should allow for a custom sort' do
      expect(
        KibanaUrl.generate(
          sort: { log_param_name: 'remote_ip', mode: :asc }
        )
      ).to eq(
        "https://kibana.intranet.net/app/kibana#/discover?"       \
        "_g=(time:(from:'now-900s',mode:relative,to:'now'))&"     \
        "_a=(columns:!(_source),index:'application-logs-*',"      \
        "interval:auto,query:(query_string:(analyze_wildcard:!t," \
        "query:'%2A')),sort:!(remote_ip,asc))"
      )
    end

    it 'should allow for a custom refresh interval' do
      expect(KibanaUrl.generate(refresh_interval: 30)).to eq(
        "https://kibana.intranet.net/app/kibana#/discover?"                \
        "_g=(refreshInterval:(display:'30%20seconds',pause:!f,section:1,"  \
        "value:30000),time:(from:'now-900s',mode:relative,to:'now'))&"     \
        "_a=(columns:!(_source),index:'application-logs-*',interval:auto," \
        "query:(query_string:(analyze_wildcard:!t,query:'%2A')),"          \
        "sort:!(time,desc))"
      )
    end

    it 'should allow for a time scope of type :relative' do
      expect(
        KibanaUrl.generate(
          time_scope: { mode: :relative, from: Time.now - (30 * 60) } # 30 min
        )
      ).to eq(
        "https://kibana.intranet.net/app/kibana#/discover?"                \
        "_g=(time:(from:'now-1800s',mode:relative,to:'now'))&"             \
        "_a=(columns:!(_source),index:'application-logs-*',interval:auto," \
        "query:(query_string:(analyze_wildcard:!t,query:'%2A')),"          \
        "sort:!(time,desc))"
      )
    end

    it 'should allow for a time scope of type :absolute' do
      Timecop.freeze(Time.new(2015, 11, 25, 0, 0, 0)) do
        expect(
          KibanaUrl.generate(
            time_scope: {
              mode: :absolute,
              from: Time.new(2015, 1, 2, 3, 4, 5),
              to: Time.now - 10 # 10 seconds ago
            }
          )
        ).to eq(
          "https://kibana.intranet.net/app/kibana#/discover?"                \
          "_g=(time:(from:'2015-01-02T11:04:05.000Z',mode:absolute,"         \
          "to:'2015-11-25T07:59:50.000Z'))&"                                 \
          "_a=(columns:!(_source),index:'application-logs-*',interval:auto," \
          "query:(query_string:(analyze_wildcard:!t,query:'%2A')),"          \
          "sort:!(time,desc))"
        )
      end
    end
  end
end
