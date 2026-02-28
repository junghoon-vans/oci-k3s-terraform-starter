# Cloud-init Templates

- `k3s-server.yaml.tftpl`: k3s server bootstrap for `k3s-node-1`.
- `k3s-agent.yaml.tftpl`: k3s agent bootstrap for `k3s-node-2/3/4`.

Both templates install and join Tailscale with tagged auth keys.

- server template uses `tag:k3s-server`
- agent template uses `tag:k3s-agent`
