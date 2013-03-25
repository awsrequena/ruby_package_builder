# compile against latest libraries
execute 'yum update -qy'

[
 'rpm-build',
 'libtool',
 'readline',
 'libyaml',
 'libyaml-devel',
 'readline-devel',
 'ncurses',
 'ncurses-devel',
 'gdbm',
 'gdbm-devel',
 'glibc-devel',
 'tcl-devel',
 'gcc',
 'unzip',
 'openssl-devel',
 'db4-devel',
 'byacc',
 'make',
 'libffi-devel'
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

  remote_file "#{target_dir}/#{node[:package_builder][:ruby][:basename]}.tar.bz2" do
    Chef::Log.info "Downloading sources from #{node[:package_builder][:ruby][:sources_url]}"
    source node[:package_builder][:ruby][:sources_url]
    owner node[:package_builder][:user]
  end

  # if this runs as root, we're going to have problems during testing
  perform "tar xvfj #{node[:package_builder][:ruby][:basename]}.tar.bz2", :cwd => target_dir

  build_dir = "#{target_dir}/#{node[:package_builder][:ruby][:basename]}"
  build_dest = "#{build_dir}/../make_install_dir"
  directory build_dest

  Chef::Log.info 'Buiding package'
  perform "./configure #{node[:package_builder][:ruby][:configure]} > #{build_dir}/../configure_#{current_time} 2>&1",
          :cwd => build_dir

  perform "make -j #{node["cpu"]["total"] - 1} > #{build_dir}/../make_#{current_time} 2>&1", :cwd => build_dir

  Chef::Log.info 'Installing package'
  # this must run as root
  perform "make -j #{node["cpu"]["total"] - 1} install DESTDIR='#{build_dest}' > #{build_dir}/../install_#{current_time} 2>&1", :cwd => build_dir, :user => "root"

  Chef::Log.info "Running package's test suite"
  # this must NOT run as root
  perform "make -j #{node["cpu"]["total"] - 1 } check > #{build_dir}/../test_#{current_time} 2>&1", :cwd => build_dir

  Chef::Log.info 'Creating rpm package'
  pkg_dir = "/tmp/package_builder/#{node[:platform]}/#{node[:platform_version]}"
  FileUtils.rm_rf pkg_dir and FileUtils.mkdir_p pkg_dir

  Chef::Log.info 'Creating rpm package'
  File.open("#{target_dir}/../execute_ldconfig.sh", 'w') do |f|
    f.write "#! /bin/env sh\n ldconfig"
  end

  perform "/usr/local/bin/fpm -s dir \
            -t rpm \
            --after-install \"#{target_dir}/../execute_ldconfig.sh\" \
            -n \"ruby#{node[:package_builder][:ruby][:version].match(/(.)\.(.)/)[1,2].join}\" \
            -v \"#{node[:package_builder][:ruby][:version]}#{node[:package_builder][:ruby][:patch_level]}.#{node[:package_builder][:ruby][:rpm][:pkgrelease]}\" \
            --license \"SBSD \(http://www.ruby-lang.org/en/about/license.txt\)\" \
            --maintainer \"#{node[:package_builder][:maintainer]}\" \
            --description \"A dynamic, open source programming language with a focus on simplicity and productivity. It has an elegant syntax that is natural to read and easy to write.\" \
            --url \"http://www.ruby-lang.org\" \
            -C \"#{build_dest}\" \
            -p \"#{pkg_dir}/#{node[:package_builder][:ruby][:rpm][:package_name]}\" \
            usr",
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
                 --guess-mime-type #{node[:package_builder][:ruby][:rpm][:package_name]} \
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
      node[:package_builder][:ruby][:rpm][:cleanup]
    end
  end
end

manage_test_user(:remove) if node[:package_builder][:ruby][:rpm][:cleanup]
