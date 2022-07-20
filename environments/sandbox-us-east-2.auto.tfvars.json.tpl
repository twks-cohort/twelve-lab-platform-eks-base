{
    "aws_region": "us-east-2",
    "aws_assume_role": "DPSPlatformEksBaseRole",
    "aws_account_id": "{{ op://empc-lab/aws-dps-2/aws-account-id }}",

    "cluster_name": "sandbox-us-east-2",
    "cluster_version": "1.22",
    "cluster_enabled_log_types": ["api", "audit", "authenticator", "controllerManager", "scheduler"],
    "cluster_log_retention": "30",
    "vpc_cni_version": "v1.11.2-eksbuild.1",
    "coredns_version": "v1.8.7-eksbuild.1",
    "kube_proxy_version": "v1.22.11-eksbuild.2",
    "aws_ebs_csi_version": "v1.8.0-eksbuild.0",
    "alert_channel": "sandbox",

    "default_node_group_name": "group-a",
    "default_node_group_ami_type": "AL2_x86_64",
    "default_node_group_platform": "linux",
    "default_node_group_min_size": "3",
    "default_node_group_max_size": "5",
    "default_node_group_desired_size": "3",
    "default_node_group_disk_size": "50",
    "default_node_group_capacity_type": "SPOT",
    "default_node_group_instance_types": ["t2.2xlarge","t3.2xlarge","t3a.2xlarge","m5n.2xlarge","m5.2xlarge","m4.2xlarge"]
}
