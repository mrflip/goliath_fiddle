RACK_ENV = ENV["RACK_ENV"] ||= "development" unless defined? RACK_ENV
module Goliath
  Goliath::ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..')) unless defined?(Goliath::ROOT_DIR)
  def self.root_path *dirs
    File.join(Goliath::ROOT_DIR, *dirs)
  end
end
$LOAD_PATH.unshift(Goliath.root_path("lib")) unless $LOAD_PATH.include?(Goliath.root_path("lib"))
is_production = !!ENV['GEM_STRICT']

if is_production
  # Verify the environment has been bootstrapped by checking that the
  # .bundle/loadpath file exists.
  if !File.exist?(Goliath.root_path(".bundle/loadpath"))
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
  if !File.exist?(Goliath.root_path(".bundle/loadpath"))
    warn "WARN The gem environment is out-of-date or has yet to be bootstrapped."
    warn "     Runnning #{Goliath.root_path("config/bootstrap.rb")} to remedy this situation..."
    system Goliath.root_path("config/bootstrap.rb --local")

    if !File.exist?(Goliath.root_path(".bundle/loadpath"))
      warn "WARN The gem environment is STILL out-of-date."
      warn "     Please contact your network administrator."
      fail "gem environment not configued"
    end
  end

  checksum = File.read(Goliath.root_path(".bundle/checksum")).to_i rescue nil
  if `cksum <'#{Goliath.root_path}/Gemfile'`.to_i != checksum
    warn "WARN The gem environment is out-of-date or has yet to be bootstrapped."
    warn "     Runnning config/bootstrap.rb to remedy this situation..."
    system Goliath.root_path("config/bootstrap.rb --local")

    checksum = File.read(Goliath.root_path(".bundle/checksum")).to_i rescue nil
    if `cksum <'#{Goliath.root_path}/Gemfile'`.to_i != checksum
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
  ENV['GEM_PATH'] = Goliath.root_path("vendor/gems")
  ENV['GEM_HOME'] = Goliath.root_path("vendor/gems")
elsif !ENV['GEM_PATH'].to_s.include?(Goliath.root_path("vendor/gems"))
  ENV['GEM_PATH'] =
    [Goliath.root_path("vendor/gems"), ENV['GEM_PATH']].compact.join(':')
end

# Setup bundled gem load path.
paths = File.read(Goliath.root_path(".bundle/loadpath")).split("\n")
paths.each do |path|
  next if path =~ /^[ \t]*(?:#|$)/
  path = Goliath.root_path(path)
  $: << path if !$:.include?(path)
end

# Child processes inherit our load path.
ENV['RUBYLIB'] = $:.compact.join(':')
