require 'spec_helper'
require 'yajl/json_gem'
require 'goliath'

require 'goliath/rack/validation_error_as_json'

class ValidationErrorSpec < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::ValidationErrorAsJson
  use Goliath::Rack::Validation::RequiredParam, {:key => 'test'}

  def response(env)
    [200, {}, 'OK']
  end
end

describe ValidationErrorSpec do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'returns JSON with :force_json option' do
    with_api(ValidationErrorSpec) do
      get_request({}, err) do |c|
        c.response.should == '{"error":"Test identifier missing"}'
      end
    end
  end
end
