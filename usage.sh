#!/bin/bash
#
#################################################################
# Clean all the failed pod in order to get and accurate quota   #
# Display of current resources usage, request and limits        #
# Generate manifest for namespaces with hard limits             #
#################################################################

 set -e

NAMESPACES=$(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name)
declare -a RESOURCES=("requests.cpu" "limits.cpu" "requests.memory" "limits.memory")
declare -a EXCLUDED=("default" "e2e-tests" "flux" "ingress-nginx" "k2w" "kibana" "kubernetes-dashboard" "katalog" "kong" "kube-node-lease" "kube-public" "kube-system" "logging" "monitoring" "newrelic" "nginx" "products" "sonobuoy" "sre-metrics-collector" "whoami")
header="NAMESPACE|pod.qty|used.cpu|requests.cpu|limits.cpu|used.mem|requests.mem|limits.mem"
tmpfile=$(mktemp)

function newquota() {
  if [ $2 == 1 ]; then
  factor=300
  elif [ $2 == 2 ]; then
  factor=200
  else
  factor=150
  fi
  echo $(($1*$factor/100))
}

function createmanifest() {
  if [ $3 != 0 ] || [ $5 != 0 ]; then
  echo 'apiVersion: v1
kind: ResourceQuota
metadata:
  name: mem-cpu-quota-'$1'
  namespace: '$1'
spec:
  hard:
    requests.cpu: '$2'm
    limits.cpu: '$3'm
    requests.memory: '$4'Mi
    limits.memory: '$5'Mi' > /home/{{ ansible_user }}/resource-quota/k8s-namespaces-quota/$1-mem-cpu-quota.yaml
  fi
}

function cleannamespaces() {
  for namespace in ${EXCLUDED[@]}; do
  NAMESPACES=( "${NAMESPACES[@]/$namespace}" )
  done
}

function usage() {
    kubectl get pods --all-namespaces --field-selector 'status.phase==Failed' -o json | kubectl delete -f -
    cleannamespaces
    echo $header > $tmpfile
    for ns in $NAMESPACES; do
      podqty=$(kubectl -n $ns get pods -o=name --no-headers --field-selector 'status.phase==Running' | awk '{ print } END { print NR }' | tail -1)
      for resourcetype in "${RESOURCES[@]}"; do
        sum=0
        for i in 0 1 2 3 4 5; do
          PODS=$(kubectl -n $ns get pods -o json | jq -r '.items[] | .spec.containers['$i'].resources.'$resourcetype'')
          num=0
          for pod in $PODS; do
            if [[ $resourcetype == *".cpu" ]];
            then
              if [[ $pod == *"m"* ]];
              then
                num=$(echo $pod | sed 's/[^0-9]*//g')
              else
                num=$(echo $pod | awk '{print $1*1000}')
              fi
            fi

            if [[ $resourcetype == *".memory" ]];
            then
              if [[ $pod == *"Gi"* ]];
              then
                num=$(echo $pod | sed 's/[^0-9]*//g' | awk '{print $1*1024}')
              else
                num=$(echo $pod | sed 's/[^0-9]*//g')
              fi
            fi

            if [[ $num == "" ]];
            then
              num=0
            fi

            sum=$(($sum + $num))
          done

          if [[ $resourcetype == "limits.memory" ]];
          then
              lm=$sum
          fi
          if [[ $resourcetype == "limits.cpu" ]];
          then
              lc=$sum
          fi
          if [[ $resourcetype == "requests.memory" ]];
          then
              rm=$sum
          fi
          if [[ $resourcetype == "requests.cpu" ]];
          then
              rc=$sum
          fi
        done
      done
      uc=$(kubectl -n $ns top pods --no-headers | awk 'BEGIN { total=0 } { total+=$2 } END { print total}' || echo 0)
      um=$(kubectl -n $ns top pods --no-headers | awk 'BEGIN { total=0 } { total+=$3 } END { print total}' || echo 0)
      echo "$ns|$podqty|$uc|$rc|$lc|$um|$rm|$lm" >> $tmpfile

      rc=$(newquota $rc $podqty)
      lc=$(newquota $lc $podqty)
      rm=$(newquota $rm $podqty)
      lm=$(newquota $lm $podqty)

      createmanifest $ns $rc $lc $rm $lm

    done

    cat $tmpfile | column -t -s "|"
    rm -f $tmpfile
}

usage $NAMESPACES