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

gem_package fpm

def manage_test_user(action, cwd = nil)
  user node[:ruby_package_builder][:user] do
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
    :user => node[:ruby_package_builder][:user]
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
    owner node[:ruby_package_builder][:user]
    action :create
  end

  remote_file "#{target_dir}/#{node[:ruby_package_builder][:rpm][:basename]}.tar.bz2" do
    source node[[:ruby_package_builder][:rpm][:package_url]]
    owner node[:ruby_package_builder][:user]
  end

  # if this runs as root, we're going to have problems during testing
  perform "tar xvfj #{node[:ruby_package_builder][:basename]}.tar.bz2", :cwd => target_dir

  build_dir = "#{target_dir}/#{node[:ruby_package_builder][:basename]}"

  Chef::Log.info 'Buiding package'
  perform "./configure --prefix=#{node[:ruby_package_builder][:rpm][:prefix]} #{node[:ruby_package_builder][:rpm][:configure]} > #{build_dir}/../configure_#{current_time} 2>&1", :cwd => build_dir
  perform "make -j #{node["cpu"]["total"]} > #{build_dir}/../make_#{current_time} 2>&1", :cwd => build_dir

  Chef::Log.info 'Installing package'
  # this must run as root
  perform "make -j #{node["cpu"]["total"]} install > #{build_dir}/../install_#{current_time} 2>&1", :cwd => build_dir, :user => "root"

  Chef::Log.info "Running package's test suite"
  # this must NOT run as root
  perform "make -j #{node["cpu"]["total"]} check > #{build_dir}/../test_#{current_time} 2>&1", :cwd => build_dir

  Chef::Log.info 'Creating rpm package'
  directory ::File.path(buildir, 'make_install_dir')
  perform "fpm -s dir \
            -t rpm \
            -n ruby#{node[:ruby_package_builder][:ruby][:version].match(/(.)\.(.)/)[1,2].join} \
            -v #{node[:ruby_package_builder][:ruby][:version]}#{node[:ruby_package_builder][:ruby][:patch_level]}.#{node[:ruby_package_builder][:rpm][:pkgrelease]} \
            --after-install "../execute_ldconfig.sh" \
            --license 'SBSD (http://www.ruby-lang.org/en/about/license.txt)' \
            --maintainer '#{node[:ruby_package_builder][:maintainer]}' \
            --description 'A dynamic, open source programming language with a focus on simplicity and productivity. It has an elegant syntax that is natural to read and easy to write.' \
            --url 'http://www.ruby-lang.org' \
            -C ../make_install_dir \
            -p ../#{node[:ruby_package_builder][:rpm][:package_name]} \
            usr"

  Chef::Log.info 'Coping deb package into package dir'
  pkg_dir = "/tmp/ruby_package_builder/#{node[:platform]}/#{node[:platform_version]}"
  FileUtils.mkdir_p pkg_dir
  Chef::Log.info "Copying package into #{pkg_dir}"
  FileUtils.mv File.path(build_dir, node[:ruby_package_builder][:rpm][:package_name]), pkg_dir

  if node[:ruby_package_builder][:s3][:upload]
    # TODO: use aws_sdk for this
    Chef::Log.info 'Uploading package into S3 bucket'
    package 's3cmd'

    template '/tmp/.s3cfg' do
      source 's3cfg.erb'
    end

    execute "s3cmd -c /tmp/.s3cfg put --acl-public --guess-mime-type #{node[:ruby_package_builder][:deb]} s3://#{node[:ruby_package_builder][:s3][:bucket]}/#{node[:ruby_package_builder][:s3][:path]}/" do
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
      node[:ruby_package_builder][:cleanup]
    end
  end
end

manage_test_user(:remove) if node[:ruby_package_builder][:cleanup]
