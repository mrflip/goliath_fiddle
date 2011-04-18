require 'spec_helper'
require 'yajl'
require 'goliath'

class ValidRaisesJson < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::ValidationError, :force_json => true
  use Goliath::Rack::Validation::RequiredParam, {:key => 'test'}

  def response(env)
    [200, {}, 'OK']
  end
end

describe ValidRaisesJson do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'returns JSON with :force_json option' do
    with_api(ValidRaisesJson) do
      get_request({}, err) do |c|
        c.response.should == '{"error":"Test identifier missing"}'
      end
    end
  end
end
