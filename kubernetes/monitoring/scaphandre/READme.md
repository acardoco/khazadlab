# Instalacion Scaphandre

Fuente: https://hubblo-org.github.io/scaphandre-documentation/tutorials/kubernetes.html

```bash
git clone https://github.com/hubblo-org/scaphandre

cd scaphandre
```

## Pasos realizados en cada nodo Ubuntu

1. **Instalación de Scaphandre en k3s**  
   ```bash
   helm install scaphandre helm/scaphandre \
     --namespace scaphandre --create-namespace \
     --set serviceMonitor.enabled=true \
     --set serviceMonitor.namespace=monitoring \
     --set serviceMonitor.interval=30s
    ```

2. **Setup en hosting**
Hay que instalar una libreria, que depende de la version del kernel que tengas (si es menor de 5, hay que usar otra a estos pasos):
    ```bash
    uname -r
    # → 6.11.0-26-generic

    sudo apt update
    sudo apt install linux-modules-extra-$(uname -r)

    sudo modprobe intel_rapl_common

    lsmod | grep rapl
    # rapl
    # intel_rapl_msr
    # processor_thermal_rapl
    # intel_rapl_common

    kubectl rollout restart daemonset/scaphandre -n scaphandre
    ```

3. **Otras configuraciones**

    Labelear si no lo detecta el prometheus:
    ```
    kubectl label servicemonitor scaphandre-service-monitoring \
    -n monitoring release=prometheus
    ```
    Añadir en kubernetes/monitoring/scaphandre/scaphandre/helm/scaphandre/templates/daemonset.yaml ```hostPID: true```, ```mountPropagation: HostToContainer``` y
    ```yaml 
    securityContext:
        privileged: true
        runAsUser: 0
        runAsGroup: 0
    ```
    En el servicemonitor añadir esto, para poder filtrar por nombre de nodos:
    ```yaml 
    ...
    endpoints:
    - port: metrics
      path: /metrics
      interval: 30s
      relabelings:
        - sourceLabels: [ __meta_kubernetes_pod_node_name ]
          action: replace
          targetLabel: node
    ```