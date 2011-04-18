RACK_ENV = ENV["RACK_ENV"] ||= "development" unless defined? RACK_ENV
::ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..')) unless defined?(::ROOT_DIR)
$LOAD_PATH.unshift("#{ROOT_DIR}/lib") unless $LOAD_PATH.include?("#{ROOT_DIR}/lib")
is_production = !!ENV['GEM_STRICT']

if is_production
  # Verify the environment has been bootstrapped by checking that the
  # .bundle/loadpath file exists.
  if !File.exist?("#{ROOT_DIR}/.bundle/loadpath")
    warn "WARN The gem environment is out-of-date or has yet to be bootstrapped."
    warn "     Run config/bootstrap.rb to remedy this situation."
    fail "gem environment not configued"
  end
else
  # Run a more exhaustive bootstrap check in non-production environments by making
  # sure the Gemfile matches the .bundle/loadpath file checksum.
  #
  # Verify the environment has been bootstrapped by checking that the
  # .bundle/loadpath file exists.
  if !File.exist?("#{ROOT_DIR}/.bundle/loadpath")
    warn "WARN The gem environment is out-of-date or has yet to be bootstrapped."
    warn "     Runnning #{ROOT_DIR}/config/bootstrap.rb to remedy this situation..."
    system "#{ROOT_DIR}/config/bootstrap.rb --local"

    if !File.exist?("#{ROOT_DIR}/.bundle/loadpath")
      warn "WARN The gem environment is STILL out-of-date."
      warn "     Please contact your network administrator."
      fail "gem environment not configued"
    end
  end

  checksum = File.read("#{ROOT_DIR}/.bundle/checksum").to_i rescue nil
  if `cksum <'#{ROOT_DIR}/Gemfile'`.to_i != checksum
    warn "WARN The gem environment is out-of-date or has yet to be bootstrapped."
    warn "     Runnning config/bootstrap.rb to remedy this situation..."
    system "#{ROOT_DIR}/config/bootstrap.rb --local"

    checksum = File.read("#{ROOT_DIR}/.bundle/checksum").to_i rescue nil
    if `cksum <'#{ROOT_DIR}/Gemfile'`.to_i != checksum
      warn "WARN The gem environment is STILL out-of-date."
      warn "     Please contact your network administrator."
      fail "gem environment not configued"
    end
  end
end

# Disallow use of system gems by default in staging and production environments
# or when the GEM_STRICT environment variable is set. This ensures the gem
# environment is totally isolated to only stuff specified in the Gemfile.
if is_production
  ENV['GEM_PATH'] = "#{ROOT_DIR}/vendor/gems"
  ENV['GEM_HOME'] = "#{ROOT_DIR}/vendor/gems"
elsif !ENV['GEM_PATH'].to_s.include?("#{ROOT_DIR}/vendor/gems")
  ENV['GEM_PATH'] =
    ["#{ROOT_DIR}/vendor/gems", ENV['GEM_PATH']].compact.join(':')
end

# Setup bundled gem load path.
paths = File.read("#{ROOT_DIR}/.bundle/loadpath").split("\n")
paths.each do |path|
  next if path =~ /^[ \t]*(?:#|$)/
  path = File.join(ROOT_DIR, path)
  $: << path if !$:.include?(path)
end

# Child processes inherit our load path.
ENV['RUBYLIB'] = $:.compact.join(':')
