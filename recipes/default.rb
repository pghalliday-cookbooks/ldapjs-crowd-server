repository = node['ldapjs_crowd_server']['repository']
version = node['ldapjs_crowd_server']['version']

system_certificate_bundle = node['ldapjs_crowd_server']['system_certificate_bundle']
crowd_root_certificate = node['ldapjs_crowd_server']['crowd_root_certificate']
crowd_url = node['ldapjs_crowd_server']['crowd_url']
application_name = node['ldapjs_crowd_server']['application_name']
application_password = node['ldapjs_crowd_server']['application_password']
uid = node['ldapjs_crowd_server']['uid']
dn_suffix = node['ldapjs_crowd_server']['dn_suffix']
bind_dn = node['ldapjs_crowd_server']['bind_dn']
bind_password = node['ldapjs_crowd_server']['bind_password']
search_base = node['ldapjs_crowd_server']['search_base']
port = node['ldapjs_crowd_server']['port']

service_user = 'ldapjs-crowd-server'
service_group = 'ldapjs-crowd-server'
install_path = '/opt/ldapjs-crowd-server'
log_path = '/var/log/ldapjs-crowd-server'
service_name = 'ldapjs-crowd-server'
logfile = '/var/log/ldapjs-crowd-server.log'
service_conf = '/etc/init/ldapjs-crowd-server.conf'
logrotate_conf = '/etc/logrotate.d/ldapjs-crowd-server'
config = File.join install_path, 'config.json'

group service_group do
  system true
end

user service_group do
  gid service_group
  system true
end

directory install_path do
  owner service_user
  recursive true
end

directory log_path do
  owner service_user
  recursive true
end

git install_path do
  user login_user
  repository repository
  revision version
  notifies :run, "bash[npm_install]", :immediately
  notifies :restart, "service[#{service_name}]", :delayed
end

bash 'npm_install' do
  user login_user
  cwd install_path
  code <<-EOH.gsub(/^ {4}/, '')
    rm -rf node_modules
    npm install
  EOH
  action :nothing
end

template service_conf do
  variables(
    user: service_user,
    group: service_group,
    install_path: install_path,
    config: config,
    logfile: logfile
  )
  notifies :restart, "service[#{service_name}]", :delayed
end

template config do
  owner service_user
  group service_group
  variables(
    system_certificate_bundle: system_certificate_bundle,
    crowd_root_certificate: crowd_root_certificate,
    crowd_url: crowd_url,
    application_name: application_name,
    application_password: application_password,
    uid: uid,
    dn_suffix: dn_suffix,
    bind_dn: bind_dn,
    bind_password: bind_password,
    search_base: search_base,
    port: port
  )
  notifies :restart, "service[#{service_name}]", :delayed
end

service service_name do
  supports :status => true, :restart => true, :reload => false
  action [ :enable, :start ]
end

template logrotate_conf do
  variables(
    logfile: logfile,
    service: service_name
  )
end
