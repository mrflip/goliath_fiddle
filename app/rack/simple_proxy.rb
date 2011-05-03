#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'
require 'goliath'
require 'em-synchrony/em-http'

# Problems with EM::HttpRequest at massive concurrency
#
# $ ./app/rack/sleepy_simple.rb -sv -p 9002 -e prod
# $ ./app/rack/simple_proxy.rb  -sv -p 9000 -e prod
#
# ab -c200 -n200 'http://127.0.0.1:9002'
#
#
# [61953:ERROR] 2011-05-02 21:45:14 :: double resume
# [61953:ERROR] 2011-05-02 21:45:14 :: (eval):8:in `resume'
# (eval):8:in `block in get'
# /Users/flip/.rvm/gems/ruby-1.9.2-p136/gems/eventmachine-1.0.0.beta.3/lib/em/deferrable.rb:72:in `call'
# /Users/flip/.rvm/gems/ruby-1.9.2-p136/gems/eventmachine-1.0.0.beta.3/lib/em/deferrable.rb:72:in `errback'
# (eval):8:in `get'
# ./app/rack/simple_proxy.rb:16:in `response'
# /Users/flip/ics/backend/goliath_fiddle/lib/goliath/api.rb:155:in `block in call'
# [61953:INFO] 2011-05-02 21:45:14 :: Status: 400, Content-Length: 25, Response Time: 0.94ms
#
class SimpleProxy < Goliath::API
  BASE_URL     = 'http://localhost:9002/?delay=1.0'

  def response(env)
    resp = EM::HttpRequest.new(BASE_URL).get

    [200, { }, resp.response]
  end
end
