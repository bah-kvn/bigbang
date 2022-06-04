kubectl delete pv $(kubectl get pv | grep vault | cut -d' ' -f1 )
