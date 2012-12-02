# lots of stuff taken from https://github.com/intridea/omniauth/blob/0-3-stable/oa-oauth/lib/omniauth/strategies/oauth2/taobao.rb
require 'omniauth-oauth2'
module OmniAuth
  module Strategies
    class Taobao < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :authorize_url => 'https://oauth.taobao.com/authorize',
        :token_url => 'https://oauth.taobao.com/token',
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
        url = 'https://eco.taobao.com/router/rest'

        query_param = {
          :fields => 'user_id,uid,nick,sex,buyer_credit,seller_credit,location,created,last_visit,birthday,type,status,alipay_no,alipay_account,alipay_account,email,consumer_protection,alipay_bind',
          :format => 'json',
          :method => 'taobao.user.get',
          :access_token => @access_token.token,
          :v => '2.0'
        }
        res = Net::HTTP.post_form(URI.parse(url), query_param)
        @raw_info ||= MultiJson.decode(res.body)['user_get_response']['user']
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
      
 
    end
  end
end