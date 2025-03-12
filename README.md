# Audacy Kubernetes Cluster Documentation

This repository contains the configuration files for the Audacy GKE on-prem Kubernetes cluster. The cluster is designed to host multiple radio broadcasting applications and services from Telos Alliance along with WideOrbit virtual machines.

## Cluster Configuration

The cluster is based on Google Kubernetes Engine (GKE) on-prem (Anthos Bare Metal) version 1.30.100-gke.96. 

### Cluster Specifications

- **Cluster Name**: audacy-user-cluster
- **Namespace**: cluster-audacy-user-cluster
- **Project ID**: audacy-dc-dev
- **Location**: us-east4
- **Pod CIDR**: 192.168.0.0/16
- **Service CIDR**: 10.96.0.0/20

### Control Plane Configuration

- **Control Plane Node**: 172.21.237.32
- **Control Plane VIP**: 172.21.237.37
- **Ingress VIP**: 172.21.237.48
- **Load Balancer Address Pool**: 172.21.237.48/28

### Node Configuration

The cluster consists of the following nodes:
- Control plane node: 172.21.237.32
- Worker node in node pool: 172.21.237.33

### Security Features

- Root-less containers enabled
- Seccomp enabled
- Container runtime: containerd
- Maximum 110 pods per node

### Storage Configuration

The cluster uses the following storage options:
- **Local Disk Storage**: `/mnt/localpv-disk` with storage class `local-disks`
- **Local Shared Storage**: `/mnt/localpv-share` with storage class `local-shared`
- **NFS Storage**: External NFS server at 172.21.237.31 with storage class `k8sfs`

## Network Configuration

### Network Interfaces

The cluster uses multiple network interfaces:

1. **Pod Network (L3)**
   - Internal Kubernetes network for pod communications
   - CIDR: 192.168.0.0/16
   - Services CIDR: 10.96.0.0/20

2. **LiveWire Network (L2)**
   - VLAN ID: 410
   - Interface: eno2
   - Gateway: 192.168.41.1
   - DNS: 8.8.8.8, 8.8.4.4
   - Used for broadcast-specific traffic

3. **Heartbeat Network (L2)**
   - VLAN ID: 300
   - Interface: eno3
   - Uses external DHCP

### Network Interface Assignments

The following dedicated network interfaces are configured:
- **Altus Interface**: 192.168.41.25/24
- **Zephyr Interface**: 192.168.41.26/24
- **PDM Interface**: 192.168.41.27/24
- **Forza Interface**: 192.168.41.28/24

## Applications

The cluster hosts several applications from Telos Alliance:

### Containers

1. **Altus**
   - Image: quay.io/telosalliance/altus
   - Resources: 400m CPU, 8Gi memory
   - Interfaces: pod-network and LiveWire network

2. **Zephyr Connect**
   - Image: quay.io/telosalliance/zephyr-connect
   - Resources: 400m CPU, 8Gi memory
   - Interfaces: pod-network and LiveWire network

3. **PDMX**
   - Image: quay.io/telosalliance/pdmx
   - Resources: 400m CPU, 8Gi memory
   - Interfaces: pod-network and LiveWire network

4. **Forza FM**
   - Image: quay.io/telosalliance/forza-fm
   - Resources: 400m CPU, 8Gi memory
   - Interfaces: pod-network and LiveWire network

### Virtual Machines

The cluster also runs several Windows and Linux VMs, managed by VM Operator:

#### Windows VMs:
1. **WideOrbit Radio Systems (5 VMs)**
   - windows-vm-1 (RS-1): 192.168.41.8/24
   - windows-vm-2 (Content Server): 192.168.41.9/24
   - windows-vm-3 (RS-2): 192.168.41.10/24
   - windows-vm-4: 192.168.41.11/24
   - windows-vm-5 (X2): 192.168.41.12/24
   - All VMs: 8 vCPUs, 32Gi memory

#### Linux VMs:
1. **Pathfinder**
   - Ubuntu 20.04 Server
   - 2 vCPUs, 8Gi memory
   - IP: 172.16.0.7/24

2. **Phones VX**
   - Ubuntu 20.04 Server
   - 2 vCPUs, 8Gi memory
   - IP: 172.16.0.8/24

## Storage and Persistence

The cluster uses an NFS server for persistent storage. PersistentVolumeClaims are created for virtual machine disks. The NFS server is located at 172.21.237.31.

## Authentication and RBAC

The cluster admin role is granted to:
- aaron.wolfrom@audacy.com
- mike.wiseley@cdw.com
- spencer.cuffe@cdw.com

A service account `vm-administrator` is available for VM management.

## Utilities

### Kubeconfig Generation

A script `kubeconfig-gen.sh` is available to generate kubeconfig files for service accounts.

## Network Policies

A permissive network policy is applied that allows all traffic to and from all pods in the default namespace.

## Deployment Instructions

1. Create the user cluster:
   ```bash
   kubectl apply -f cluster-platform/audacy-user-cluster.yaml
   ```

2. Configure network interfaces:
   ```bash
   kubectl apply -f cluster-platform/livewire-network.yaml
   kubectl apply -f cluster-platform/heartbeat-network.yaml
   kubectl apply -f telos-applications/telos-nic.yaml
   ```

3. Configure storage:
   ```bash
   kubectl apply -f cluster-platform/k8sfs-sc.yaml
   ```

4. Create persistent volumes and claims:
   ```bash
   kubectl apply -f k8sfs-restore/pv-1.yaml
   kubectl apply -f k8sfs-restore/pvc-1.yaml
   kubectl apply -f k8sfs-restore/gdisk.yaml
   ```

5. Deploy virtual machines:
   ```bash
   kubectl apply -f k8sfs-restore/vm-check.yaml
   kubectl apply -f telos-applications/linux-vms.yaml
   ```

6. Deploy Telos applications:
   ```bash
   kubectl apply -f telos-applications/quay-secret.yaml
   kubectl apply -f telos-applications/altus-deployment.yaml
   kubectl apply -f telos-applications/altus-service.yaml
   kubectl apply -f telos-applications/zephyr-deployment.yaml
   kubectl apply -f telos-applications/zephyr-service.yaml
   kubectl apply -f telos-applications/pdm-deployment.yaml
   kubectl apply -f telos-applications/pdm-service.yaml
   kubectl apply -f telos-applications/forza-deployment.yaml
   kubectl apply -f telos-applications/forza-service.yaml
   ```

7. Apply network policies:
   ```bash
   kubectl apply -f k8sfs-restore/network-policy.yaml
   ```

8. Apply VM services:
   ```bash
   kubectl apply -f wideorbit-vms/wors-service-1.yaml
   kubectl apply -f wideorbit-vms/wocs-service.yaml
   kubectl apply -f wideorbit-vms/wors-service-2.yaml
   kubectl apply -f wideorbit-vms/x2-service.yaml
   kubectl apply -f wideorbit-vms/pathfinder-service.yaml
   kubectl apply -f wideorbit-vms/phones-service.yaml
   ```

## Troubleshooting

### Common Issues

1. **Network Connectivity**
   - Ensure VLAN IDs are correctly configured on the physical network switches
   - Verify that multicast is enabled for LiveWire traffic

2. **VM Storage**
   - Check that the NFS server is accessible from the Kubernetes nodes
   - Verify that the NFS paths exist and have correct permissions

3. **Pod Networking**
   - Use `kubectl describe pod <pod-name>` to check for network interface errors
   - Verify that the correct network annotations are applied

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Check VM status
kubectl get virtualmachines
kubectl get virtualmachinedisks

# Check network interfaces
kubectl get network
kubectl get networkinterface

# Generate kubeconfig for service account
./cluster-platform/kubeconfig-gen.sh
```

## Support

For technical support, please contact:
- aaron.wolfrom@audacy.com
- mike.wiseley@cdw.com
- spencer.cuffe@cdw.com
