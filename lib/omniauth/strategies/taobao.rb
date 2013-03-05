# lots of stuff taken from https://github.com/intridea/omniauth/blob/0-3-stable/oa-oauth/lib/omniauth/strategies/oauth2/taobao.rb
require 'omniauth-oauth2'
module OmniAuth
  module Strategies
    class Taobao < OmniAuth::Strategies::OAuth2

      authorize_url='https://oauth.tbsandbox.com/authorize'
      token_url='https://oauth.tbsandbox.com/token'
      

      if Rails.env.production?
        authorize_url='https://oauth.taobao.com/authorize'
        token_url='https://oauth.taobao.com/token' 
      end

      option :client_options, {
        :authorize_url => authorize_url,
        :token_url => token_url,
      }

      
      def request_phase
        options[:state] ||= '1'
        super
      end

      uid { raw_info['uid'] }

      info do
        {
          'uid' => raw_info['uid'],
          'nickname' => raw_info['nick'],
          'email' => raw_info['email'],
          'user_info' => raw_info,
          'extra' => {
            'user_hash' => raw_info,
          },
        }
      end

      def raw_info
        query_param = {
          :fields => 'user_id,uid,nick,sex,buyer_credit,seller_credit,location,created,last_visit,birthday,type,status,alipay_no,alipay_account,alipay_account,consumer_protection,alipay_bind',
          :format => 'json',
          :method => 'taobao.user.get',
          :access_token => @access_token.token,
          :v => '2.0'
        }
        api_url='https://gw.api.tbsandbox.com/router/rest'
        if Rails.env.production?
          api_url = 'https://eco.taobao.com/router/rest'  
        end
        uri = URI.parse(api_url)
        uri.query = URI.encode_www_form(query_param)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri.request_uri)
        res = http.request(request)
        @raw_info ||= MultiJson.decode(res.body)['user_get_response']['user']
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
      
 
    end
  end
end
module OpenSSL
  module SSL
    remove_const :VERIFY_PEER
  end
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE