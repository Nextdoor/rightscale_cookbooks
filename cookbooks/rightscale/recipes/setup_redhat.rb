#
# Cookbook Name:: rightscale
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.

rightscale_marker

username = node[:rightscale][:redhat][:username]
password = node[:rightscale][:redhat][:password]

if username.to_s.empty? || password.to_s.empty?
  message = "  Skipping system registration with Red Hat:"
  message << " In order to run the registration process both"
  message << " 'rightscale/redhat/username' and"
  message << " 'rightscale/redhat/password' inputs should be set."
  log message

else
  log "  Registering the system using 'subscription-manager'."

  # Install subscription-manager if not already installed
  package "subscription-manager"

  # 'subscription-manager' is a client program that registers a system
  # with a subscription management service.
  #
  #   --auto-attach : Automatically attaches the best-matched, compatible
  #                   subscriptions to the system.
  #
  #   --force : Regenerates the identity certificate for the system using
  #             username/password authentication.
  #
  # On stop/start the system gets a different IP, and registration to
  # Red Hat records all this info. Without re-registration the information
  # would be out of sync.

  execute "subscription-manager register" do
    command "subscription-manager register" +
      " --username=#{username}" +
      " --password=#{password}" +
      " --auto-attach" +
      " --force"
    user "root"
    group "root"
  end

  # 'product-id' and 'subscription-manager' yum plug-ins provide support
  # for the certificate-based Content Delivery Network.
  # We need to make sure they are enabled.

  cookbook_file "/etc/yum/pluginconf.d/product-id.conf" do
    owner "root"
    group "root"
    mode 0644
    source "product-id.conf"
  end

  cookbook_file "/etc/yum/pluginconf.d/subscription-manager.conf" do
    owner "root"
    group "root"
    mode 0644
    source "subscription-manager.conf"
  end

end
