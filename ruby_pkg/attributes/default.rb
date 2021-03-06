# global information
default[:package_builder][:user] = 'pkgbuildera'
default[:package_builder][:maintainer] = 'Amazon.com, Inc. <http://aws.amazon.com>'
# S3
default[:package_builder][:s3] = {}
default[:package_builder][:s3][:upload] = false
default[:package_builder][:s3][:bucket] = ''
default[:package_builder][:s3][:path] = "packages/#{node[:platform]}/#{node[:platform_version]}"
default[:package_builder][:ruby][:s3][:aws_access_key] = ""
default[:package_builder][:ruby][:s3][:aws_secret_access_key] = ""
# global ruby packaging
default[:package_builder][:ruby][:version] = '1.9.3'
default[:package_builder][:ruby][:patch_level] = 'p392'
default[:package_builder][:ruby][:base_url] = "http://ftp.ruby-lang.org/pub/ruby"
default[:package_builder][:ruby][:basename] = "ruby-#{node[:package_builder][:ruby][:version]}-#{node[:package_builder][:ruby][:patch_level]}"
default[:package_builder][:ruby][:sources_url] = "#{node[:package_builder][:ruby][:base_url]}/#{node[:package_builder][:ruby][:version].match(/.\../)[0]}/#{node[:package_builder][:ruby][:basename]}.tar.bz2"
default[:package_builder][:ruby][:configure] = "--prefix='/usr/local' --includedir='/usr/local/include' --libdir='/usr/local/lib' --enable-shared --disable-rpath --disable-install-doc"
# deb package specific
default[:package_builder][:ruby][:deb][:pkgrelease] = '3'
default[:package_builder][:ruby][:deb][:arch] = node[:kernel][:machine] == 'x86_64' ? 'amd64' : 'i386'
default[:package_builder][:ruby][:deb][:package_name] = "ruby19_#{node[:package_builder][:ruby][:version]}-#{node[:package_builder][:ruby][:patch_level]}.#{node[:package_builder][:ruby][:deb][:pkgrelease]}_#{node[:package_builder][:ruby][:deb][:arch]}.deb"
default[:package_builder][:ruby][:deb][:cleanup] = false
# rpm package specific
default[:package_builder][:ruby][:rpm][:pkgrelease] = '1'
default[:package_builder][:ruby][:rpm][:arch] = node[:kernel][:machine] == 'x86_64' ? 'x86_64' : 'i686'
default[:package_builder][:ruby][:rpm][:package_name] = "ruby19-#{node[:package_builder][:ruby][:version]}-#{node[:package_builder][:ruby][:patch_level]}-#{node[:package_builder][:ruby][:rpm][:pkgrelease]}.#{node[:package_builder][:ruby][:rpm][:arch]}.rpm"
default[:package_builder][:ruby][:rpm][:cleanup] = false
