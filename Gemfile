source "http://rubygems.org"

gemspec
#gem 'hpfog', :path => '~/projects/ruby_fog_os' # Comment out for delivery
gem 'hpfog', :git => 'https://git01.hpcloud.net/SDK-CLI-Docs/ruby_fog_os.git', :branch => 'develop' # Comment out for delivery

group :development do
  gem "yard", "~> 0.6.0"
  gem "watchr"
end

group :test do
  gem 'simplecov', '>= 0.4.0', :require => false
end

group :ci do
  gem 'ci_reporter', "~> 1.6.4"
end
