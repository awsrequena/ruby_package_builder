default[:package_builder] = {}
# global information
default[:package_builder][:user] = 'pkgbuildera'
default[:package_builder][:maintainer] = 'Amazon.com, Inc. <http://aws.amazon.com>'
# S3
default[:package_builder][:s3] = {}
default[:package_builder][:s3][:upload] = false
default[:package_builder][:s3][:bucket] = ''
default[:package_builder][:s3][:path] = "packages/#{node[:platform]}/#{node[:platform_version]}"
default[:package_builder][:nodejs][:rpm][:s3][:aws_access_key] = ""
default[:package_builder][:nodejs][:rpm][:s3][:aws_secret_access_key] = ""
# global nodejs packaging
default[:package_builder][:nodejs][:patch_level] = '19'
default[:package_builder][:nodejs][:version] = "0.8.#{node[:package_builder][:nodejs][:patch_level]}"
default[:package_builder][:nodejs][:base_url] = "http://nodejs.org/dist"
default[:package_builder][:nodejs][:basename] = "nodejs-#{node[:package_builder][:nodejs][:version]}"
default[:package_builder][:nodejs][:sources_url] = "#{node[:package_builder][:nodejs][:base_url]}/v#{node[:package_builder][:nodejs][:version]}/node-v#{node[:package_builder][:nodejs][:version]}.tar.gz"
default[:package_builder][:nodejs][:configure] = "--prefix='/usr/local' --includedir='/usr/local/include' --libdir='/usr/local/lib'"
# deb package specific
default[:package_builder][:nodejs][:deb][:pkgrelease] = '3'
default[:package_builder][:nodejs][:deb][:arch] = node[:kernel][:machine] == 'x86_64' ? 'amd64' : 'i386'
default[:package_builder][:nodejs][:deb][:package_name] = "nodejs-#{node[:package_builder][:nodejs][:version]}-#{node[:package_builder][:nodejs][:deb][:pkgrelease]}_#{node[:package_builder][:nodejs][:deb][:arch]}.deb"
default[:package_builder][:nodejs][:deb][:cleanup] = false
# rpm package specific
default[:package_builder][:nodejs][:rpm][:pkgrelease] = '1'
default[:package_builder][:nodejs][:rpm][:arch] = node[:kernel][:machine] == 'x86_64' ? 'x86_64' : 'i686'
default[:package_builder][:nodejs][:rpm][:package_name] = "nodejs-#{node[:package_builder][:nodejs][:version]}-#{node[:package_builder][:nodejs][:rpm][:pkgrelease]}.#{node[:package_builder][:nodejs][:rpm][:arch]}.rpm"
default[:package_builder][:nodejs][:rpm][:cleanup] = false
