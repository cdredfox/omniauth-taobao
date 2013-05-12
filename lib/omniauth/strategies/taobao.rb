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

      uid { buyer_raw_info['user_id'] }

      info do
        {
          'uid' => buyer_raw_info['user_id'],
          'nickname' => buyer_raw_info['nick'],
          #'email' => raw_info['email'],
          'buyer_user_info' => buyer_raw_info,
          'seller_user_info'=> seller_raw_info,
          'extra' => {
            'buyer_user_hash' => buyer_raw_info,
            'seller_user_hash'=>seller_raw_info,
          },
        }
      end


      def seller_raw_info
        query_param = {
          :fields => 'user_id,nick,sex,seller_credit,type,has_more_pic,item_img_num,item_img_size,prop_img_num,prop_img_size,auto_repost,promoted_type,status,alipay_bind,consumer_protection,avatar,liangpin,sign_food_seller_promise,has_shop,is_lightning_consignment,has_sub_stock,is_golden_seller,vip_info,magazine_subscribe,vertical_market,online_gaming',
          :format => 'json',
          :method=>'taobao.user.seller.get',
          :access_token => @access_token.token,
          :v => '2.0'
        }
        return raw_info(query_param,'user_seller_get_response')
      end

      def buyer_raw_info
        query_param = {
          :fields => 'user_id,nick,sex,buyer_credit,avatar,has_shop,vip_info',
          :format => 'json',
          :method=>'taobao.user.buyer.get',
          :access_token => @access_token.token,
          :v => '2.0'
        }
        return raw_info(query_param)      
      end

      def raw_info(query_param,result_key='user_buyer_get_response')
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
        @raw_info ||= MultiJson.decode(res.body)[result_key]['user']
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
