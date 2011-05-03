#!/usr/bin/env ruby
require 'goliath'

# Wait the amount of time given by the 'delay' parameter before responding (default 2.5, max 15.0).
class Sleepy < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay', :default => 2.5, :max => 15.0, :min => 0.0, :as => Float}

  def response(env)
    EM::Synchrony.sleep(env.params['delay'])
    [ 200,
      { 'X-Sleepy-Delay' => env.params['delay'].to_s },
      [ env[:start_time], env.params['delay'], (Time.now.to_f - env[:start_time].to_f) ].inspect
    ]
  end
end
