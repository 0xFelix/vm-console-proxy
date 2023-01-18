#!/bin/bash
set -e

source $(dirname "$0")/versions.sh

NAMESPACE=${1:-kubevirt}

oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
EOF

# Deploying kuebvirt
oc apply -n $NAMESPACE -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"

# Using KubeVirt CR from version v0.35.0
oc apply -n $NAMESPACE -f - <<EOF
apiVersion: kubevirt.io/v1alpha3
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  certificateRotateStrategy: {}
  configuration:
    selinuxLauncherType: "virt_launcher.process"
    developerConfiguration:
      featureGates:
        - DataVolumes
        - CPUManager
        - LiveMigration
        # - ExperimentalIgnitionSupport
        # - Sidecar
        # - Snapshot
  customizeComponents: {}
  imagePullPolicy: IfNotPresent
EOF

echo "Waiting for Kubevirt to be ready..."
oc wait --for=condition=Available --timeout=600s -n $NAMESPACE kv/kubevirt
