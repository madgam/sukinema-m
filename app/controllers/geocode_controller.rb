require 'json'
require 'net/http'
require 'resolv-replace'
require 'uri'

class GeocodeController < ApplicationController

    def initialize(appid)
        @appid = appid
    end

    private

    def _get(url, headers)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.open_timeout = 5
        http.read_timeout = 125
        res = http.start do |http|
            http.get(uri.request_uri, headers)
        end

        # 左辺にクラス、右辺にインスタンス
        if Net::HTTPSuccess === res
            res.body
        else
            res.value # 例外を発生させる
        end
    end

    def _json_to_latlon(json)
        result = {}
        data = JSON.parse(json)
        if data['ResultInfo']['Count'] > 0 then
            data['Feature'].each do |f|
                if f['Geometry']['Type'] == 'point'
                    ll = f['Geometry']['Coordinates'].split(',')
                    result = {'latitude' => ll[1], 'longitude' => ll[0]}
                end
            end
        end
        result
    end

    public

    def search(query)
        base_url = 'https://map.yahooapis.jp/search/local/V1/localSearch'
        params = {
            'query' => query,
            'output' => 'json',
            'results' => '3',
            'sort' => 'score'
        }
        url = base_url + '?' + URI.encode_www_form(params)
        headers = {'User-Agent' => "Yahoo AppID: #{@appid}"}
        json = _get(url, headers)
        _json_to_latlon(json)
    end
end
