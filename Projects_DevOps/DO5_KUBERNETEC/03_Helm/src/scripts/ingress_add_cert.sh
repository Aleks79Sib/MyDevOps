
KUBECONFIG=~/.kube/helm2.yaml kubectl apply \
  -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.3/deploy/static/provider/baremetal/deploy.yaml 

  KUBECONFIG=~/.kube/helm2.yaml kubectl apply \
  -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.4/cert-manager.yaml

  KUBECONFIG=~/.kube/helm2.yaml kubectl apply \
  -f manifests/cert-manager-selfsigned.yaml \
  -f manifests/root-ca.yaml \
  -f manifests/ca-issuer.yaml \
  -f manifests/wildcard-certificate.yaml

  KUBECONFIG=~/.kube/helm2.yaml kubectl get ingress -n hotel
NAME              CLASS   HOSTS           ADDRESS         PORTS     AGE
gateway-ingress   nginx   app.k8s.local   10.181.19.105   80, 443   23m

KUBECONFIG=~/.kube/helm2.yaml kubectl get pods -n ingress-nginx
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-66fb98f85f-qwz5h   1/1     Running   0          2m57s

KUBECONFIG=~/.kube/helm2.yaml kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.43.245.155   <none>        80:31916/TCP,443:30619/TCP   5m14s
ingress-nginx-controller-admission   ClusterIP   10.43.45.103    <none>        443/TCP                      5m14s
