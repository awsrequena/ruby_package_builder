# compile against latest libraries
execute 'apt-get update -qy'
execute 'apt-get upgrade -qy'

[
 'glibc-devel',
 'gcc',
 'openssl-devel',
 'make',
].each do |pkg|
  package pkg
end

gem_package 'fpm' do
  Chef::Log.info "Installing fpm - the Effing package managers, this is the solution."
  options "--no-ri --no-rdoc"
end

def manage_test_user(action, cwd = nil)
  user node[:package_builder][:user] do
    comment 'User for running build tests'
    home cwd unless cwd.nil? || cwd.empty?
    shell '/bin/bash'
  end.run_action( action )
end

def current_time
  Time.now.strftime("%Y%m%dT%H%M%S")
end

def perform(cmd, options = {})
  options = {
    :cwd => '/tmp',
    :user => node[:package_builder][:user]
  }.update(options)

  execute cmd do
    cwd options[:cwd]
    unless options[:user] == 'root'
      environment ({'HOME' => options[:cwd]})
      user options[:user]
    end
  end
end

# the whole build happens in a temp directory to avoid collitions with other builds
Dir.mktmpdir do |target_dir|

  manage_test_user(:create, target_dir)

  directory target_dir do
    owner node[:package_builder][:user]
    action :create
  end

  remote_file "#{target_dir}/#{node[:package_builder][:nodejs][:basename]}.tar.bz2" do
    Chef::Log.info "Downloading sources from #{node[:package_builder][:nodejs][:sources_url]}"
    source node[:package_builder][:nodejs][:sources_url]
    owner node[:package_builder][:user]
  end

  # if this runs as root, we're going to have problems during testing
  perform "tar xvfj #{node[:package_builder][:nodejs][:basename]}.tar.bz2", :cwd => target_dir

  build_dir = "#{target_dir}/#{node[:package_builder][:nodejs][:basename]}"
  build_dest = "#{build_dir}/../make_install_dir"
  directory build_dest

  Chef::Log.info 'Buiding package'
  perform "./configure #{node[:package_builder][:nodejs][:configure]} > #{build_dir}/../configure_#{current_time} 2>&1",
          :cwd => build_dir

  Chef::Log.info 'Installing package'
  # this must run as root
  perform "DESTDIR='#{build_dest}' make -j #{node["cpu"]["total"] - 1} all install > #{build_dir}/../install_#{current_time} 2>&1", :cwd => build_dir, :user => "root"

  Chef::Log.info 'Creating deb package'
  pkg_dir = "/tmp/package_builder/#{node[:platform]}/#{node[:platform_version]}"
  FileUtils.rm_rf pkg_dir and FileUtils.mkdir_p pkg_dir

  perform "/usr/local/bin/fpm --verbose \
            -C builddir \
            -s dir \
            -t rpm \
            --after-install 'execute_ldconfig.sh' \
            --name nodejs \
            --version #{node[:package_builder][:nodejs][:version]} \
            --license 'MIT license, and bundles other liberally licensed OSS components. https://raw.github.com/joyent/node/v#{node[:package_builder][:nodejs][:version]}/LICENSE' \
            --maintainer #{node[:package_builder][:maintainer]} \
            --description 'Node.js is a platform built on Chrome's JavaScript runtime for easily building fast, scalable network applications. Node.js uses an event-driven, non-blocking I/O model that makes it lightweight and efficient, perfect for data-intensive real-time applications that run across distributed devices.' \
            --provides 'node' \
            --provides 'npm' \
            --url '#{node[:package_builder][:nodejs][:base_url].}' \
            --package '#{node[:package_builder][:nodejs][:rpm][:package_name]}' \
            usr"
          ,
	        :cwd => build_dir,
          :user => "root"

  if node[:package_builder][:s3][:upload]
    # TODO: use aws_sdk for this
    Chef::Log.info 'Uploading package into S3 bucket'
    package 's3cmd'

    template '/tmp/.s3cfg' do
      source 's3cfg.erb'
    end

    execute "upload package" do
	    command "s3cmd -c /tmp/.s3cfg put \
                 --acl-public \
                 --guess-mime-type #{node[:package_builder][:nodejs][:rpm][:package_name]} \
                 s3://#{node[:package_builder][:s3][:bucket]}/#{node[:package_builder][:s3][:path]}/"
      cwd build_dir
    end

    file '/tmp/.s3cfg' do
      action :delete
      backup false
    end
  end

  directory build_dir do
    recursive true
    action :delete
    only_if do
      node[:package_builder][:nodejs][:rpm][:cleanup]
    end
  end
end

manage_test_user(:remove) if node[:package_builder][:nodejs][:rpm][:cleanup]
