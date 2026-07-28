output "nodes" {
  description = "Public and private IP addresses for all nodes"
  value = {
    for name, node in hcloud_server.node : name => {
      public_ip  = node.ipv4_address
      private_ip = local.nodes[name].private_ip
      role       = local.nodes[name].role
    }
  }
}

output "control_plane_public_ip" {
  value = hcloud_server.node["sre-cp-01"].ipv4_address
}
