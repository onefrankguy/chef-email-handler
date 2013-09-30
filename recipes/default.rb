include_recipe 'chef_handler'

handler_path = node['chef_handler']['handler_path']
handler = ::File.join handler_path, 'send_email'

cookbook_file "#{handler}.rb" do
  source 'send_email.rb'
end

chef_handler 'BeFrank::SendEmail' do
  source handler
  action :enable
end
