#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'goliath'
require 'rack/abstract_format'
require 'yajl/json_gem'

#
# Wait the amount of time given by the 'delay' parameter before responding (default 2.5, max 15.0).
#
class SleepySimple < Goliath::API
  use Goliath::Rack::Params
  use Rack::AbstractFormat, 'application/json'
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay',         :default => 2.5, :max => 15.0, :min => 0.0, :as => Float}

  def response(env)
    EM::Synchrony.sleep(env.params['delay'])
    [ 200,
      { 'X-Sleepy-Delay' => env.params['delay'].to_s },
      JSON.generate({ :start => env[:start_time].to_f, :delay => env.params['delay'], :actual => (Time.now.to_f - env[:start_time].to_f)})
    ]
  end
end
