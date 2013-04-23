#
# Cookbook Name:: lb_elb
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.

action :install do
  log "  Install does not apply to ELB"
end


action :attach do

  require "right_cloud_api"
  require "cloud/aws/elb/manager"

  log "  Attaching #{node[:ec2][:instance_id]} to " +
    "#{new_resource.service_lb_name}"

  # Creates an interface handle to ELB.
  elb = RightScale::CloudApi::AWS::ELB::Manager::new(
    new_resource.service_account_id,
    new_resource.service_account_secret,
    "https://elasticloadbalancing." +
    node[:ec2][:placement][:availability_zone].gsub(/[a-z]+$/, '') +
    ".amazonaws.com"
    )

  # Verify that the ELB exists.
  existing_elbs = elb.DescribeLoadBalancers["DescribeLoadBalancersResponse"]\
    ["DescribeLoadBalancersResult"]\
    ["LoadBalancerDescriptions"]\
    ["member"]

  if selected_elb = existing_elbs.detect { |f|
    f["LoadBalancerName"] == new_resource.service_lb_name }
    log "  ELB #{new_resource.service_lb_name} exists"
  else
    raise "ERROR: ELB named #{new_resource.service_lb_name} does not exist"
  end

  # Checks if this instance's zone is part of the lb. If not, add it.
  if selected_elb["AvailabilityZones"]["member"].
    include?(node[:ec2][:placement][:availability_zone])
    log "...instance part of ELB zone"
  else
    log "...activating zone #{node[:ec2][:placement][:availability_zone]}"
    elb.EnableAvailabilityZonesForLoadBalancer({
      "LoadBalancerName" => new_resource.service_lb_name,
      "AvailabilityZones.member" => node[:ec2][:placement][:availability_zone]})
  end

  # Opens the backend_port.
  # See cookbooks/sys_firewall/providers/default.rb for the "update" action.
  sys_firewall "Open backend_port to allow ELB to connect" do
    port new_resource.backend_port
    enable true
    ip_addr "any"
    action :update
  end

  # Connects the server to ELB.
  log ".. registering with ELB"
  elb.RegisterInstancesWithLoadBalancer({
    "LoadBalancerName" => new_resource.service_lb_name,
    "Instances.member" => node[:ec2][:instance_id]})
end

action :attach_request do

  log "  Attach request for #{node[:ec2][:instance_id]}"

  # Calls the "attach" action
  lb "Attaching to ELB" do
    provider "lb_elb"
    backend_port new_resource.backend_port
    service_lb_name new_resource.service_lb_name
    service_account_id new_resource.service_account_id
    service_account_secret new_resource.service_account_secret
    action :attach
  end

end


action :detach do

  log "  Detaching #{node[:ec2][:instance_id]}"

  require "right_aws"

  # Creates an interface handle to ELB.
  elb = RightAws::ElbInterface.new(
    new_resource.service_account_id, new_resource.service_account_secret,
    {:endpoint_url => "https://elasticloadbalancing." + node[:ec2][:placement][:availability_zone].gsub(/[a-z]+$/, '') + ".amazonaws.com"}
  )

  # Disconnects the server from ELB.
  log ".. detaching from ELB"
  elb.deregister_instances_with_load_balancer(new_resource.service_lb_name, node[:ec2][:instance_id])

  # Closes the backend_port.
  # See cookbooks/sys_firewall/providers/default.rb for the "update" action.
  sys_firewall "Close backend_port allowing ELB to connect" do
    port new_resource.backend_port
    enable false
    ip_addr "any"
    action :update
  end

end


action :detach_request do

  log "  Detach request for #{node[:ec2][:instance_id]}"

  # Calls the "detach" action
  lb "Detaching from ELB" do
    provider "lb_elb"
    backend_port new_resource.backend_port
    service_lb_name new_resource.service_lb_name
    service_account_id new_resource.service_account_id
    service_account_secret new_resource.service_account_secret
    action :detach
  end

end


action :setup_monitoring do
  log "  Setup monitoring does not apply to ELB"
end


action :restart do
  log "  Restart does not apply to ELB"
end
