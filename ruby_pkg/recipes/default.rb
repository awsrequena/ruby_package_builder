case node[:platform]
when 'ubuntu','debian'
  include_recipe 'ruby_pkg::deb'
when 'centos','redhat','fedora','amazon'
  include_recipe 'ruby_pkg::rpm'
end
