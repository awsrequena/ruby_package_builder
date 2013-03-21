case node[:platfom]
when 'ubuntu','debian'
  include_recipe 'deb'
when 'centos','redhat','fedora','amazon'
  include_recipe 'rpm'
end
