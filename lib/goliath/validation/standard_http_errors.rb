module Goliath
  HTTP_ERROR_CODES = HTTP_STATUS_CODES.select{|code,msg| code >= 400 && code <= 599 }
  HTTP_ERROR_CODES.each do |code, msg|
    Goliath::Validation.const_set msg.gsub(/\W+/, '')+'Error', Goliath::Validation::Error.new(code, msg)
  end
end
