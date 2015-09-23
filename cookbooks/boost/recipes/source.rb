include_recipe "build-essential"

case node['platform_family']
when "rhel","fedora"
  %w{libicu-devel libbz2-devel python-devel}.each do |pkg|
    package pkg
  end
when "debian"
  %w{libicu-dev libbz2-dev python-dev}.each do |pkg|
    package pkg
  end
end

remote_file "#{Chef::Config[:file_cache_path]}/#{node['boost']['file']}" do
  source node['boost']['source'] + node['boost']['file']
  mode "0644"
  action :create_if_missing
end

bash "install-boost" do
  user "root"
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
  tar xzvf #{node['boost']['file']}
  cd #{node['boost']['build_dir']}
  ./bootstrap.sh && ./bjam install
  EOH
  #not_if "/sbin/ldconfig -v | grep boost"
end

execute "ldconfig" do
  user "root"
  command "/sbin/ldconfig"
  action :nothing
end

cookbook_file "/etc/ld.so.conf.d/boost.conf" do
  owner "root"
  group "root"
  mode 00644
  source "boost.conf"
  backup false
  notifies :run, "execute[ldconfig]", :immediately
end
