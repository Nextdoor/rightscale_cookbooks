name             "lb_elb"
maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          "Copyright RightScale, Inc. All rights reserved."
description      "RightScale load balancer cookbook for AWS Elastic Load" +
                 " Balancer (ELB). This cookbook provides recipes for attaching" +
                 " and detaching application servers to and from an existing" +
                 " AWS Elastic Load Balancer (ELB)."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "13.5.1"

supports "centos"
supports "redhat"
supports "ubuntu"

depends "rightscale"
depends "lb"
