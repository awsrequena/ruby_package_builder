case node[:platfom]
when 'ubuntu','debian'
  include_recipe 'ruby::deb'
when 'centos','redhat','fedora','amazon'
  include_recipe 'ruby::rpm'
end
