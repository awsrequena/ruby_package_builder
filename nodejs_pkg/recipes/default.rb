case node[:platform]
when 'ubuntu','debian'
  include_recipe 'nodejs_pkg::deb'
when 'centos','redhat','fedora','amazon'
  include_recipe 'nodejs_pkg::rpm'
end
