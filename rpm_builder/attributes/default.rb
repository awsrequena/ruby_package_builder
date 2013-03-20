default[:ruby_package_builder][:maintainer] = 'Amazon.com, Inc. <http://aws.amazon.com>'

default[:ruby_package_builder][:user] = 'pkgbuildera'

default[:ruby_package_builder][:ruby][:version] = '1.9.3'
default[:ruby_package_builder][:ruby][:patch_level] = 'p392'

default[:ruby_package_builder][:rpm][:basename] = "ruby-#{node[:ruby_package_builder][:version]}-#{node[:ruby_package_builder][:patch]}"
default[:ruby_package_builder][:rpm][:pkgrelease] = '1'
default[:ruby_package_builder][:rpm][:prefix] = '/usr/local'
default[:ruby_package_builder][:rpm][:configure] = '--enable-shared --disable-install-doc'
default[:ruby_package_builder][:rpm][:arch] = node[:kernel][:machine] == 'x86_64' ? 'amd64' : 'i386'
default[:ruby_package_builder][:rpm][:base_url] = "http://ftp.ruby-lang.org/pub/ruby/"
default[:ruby_package_builder][:rpm][:package_url] = "#{node[:ruby_package_builder][:rpm][:base_url]}/#{node[:ruby_package_builder][:ruby][:version].match(/.\../)[0]}/#{node[:ruby_package_builder][:rpm][:basename]}.tar.bz2"
default[:ruby_package_builder][:rpm][:package_name] = "ruby1.9_#{node[:ruby_package_builder][:rpm][:version]}-#{node[:ruby_package_builder][:rpm][:patch]}.#{node[:ruby_package_builder][:rpm][:pkgrelease]}_#{node[:ruby_package_builder][:rpm][:arch]}.rpm"
default[:ruby_package_builder][:rpm][:cleanup] = false
default[:ruby_package_builder][:rpm][:s3] = {}
default[:ruby_package_builder][:rpm][:s3][:upload] = false
default[:ruby_package_builder][:rpm][:s3][:bucket] = ''
default[:ruby_package_builder][:rpm][:s3][:path] = "packages/#{node[:platform]}/#{node[:platform_version]}"
default[:ruby_package_builder][:rpm][:s3][:aws_access_key] = ""
default[:ruby_package_builder][:rpm][:s3][:aws_secret_access_key] = ""
