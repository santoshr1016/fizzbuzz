### Step 1. Building the Fizzbuzz Web Application exposing end points. 
```python
The Flask app is exposing the 2 end points
GET request http://localhost:5001/
GET request http://localhost:5001/api/fizzbuzz
POST request http://localhost:5001/api/fizzbuzz
body as "{"number": 100 }"

Please check the curl commands
curl http://localhost:5001/
curl -d '{"number":100}' -H "Content-Type: application/json" -X POST http://localhost:5001/api/fizzbuzz
curl -d '{"number":0}' -H "Content-Type: application/json" -X POST http://localhost:5001/api/fizzbuzz

```
### Step 2. Dockerize the Flask application
```python
To deploy the application to in k8s, we first need to containerize if it:
We create a Dockerfile manifest file with the project build and run configurations.
```

### Step 3. Building and pushing Docker image to dockerhub repo.
cd PROJECT_DIR
```python
docker login
docker build -t santoshr1016/fizzbuzz:v0.0.3 .
docker run --rm --name fizzbuzz -it -p 5001:8000 -d santoshr1016/fizzbuzz:v0.0.3
docker push  santoshr1016/fizzbuzz:v0.0.3
```
#### Verify using the curl commands
```python
curl http://localhost:5001/
curl -d '{"number":100}' -H "Content-Type: application/json" -X POST http://localhost:5001/api/fizzbuzz
curl -d '{"number":0}' -H "Content-Type: application/json" -X POST http://localhost:5001/api/fizzbuzz

```

### Creating the K8S deployment
```python
Find the kube-deployment.yaml manifest file
```
### Starting a local Kubernetes cluster using Docker Desktop and deploying the app
```python
kubectl apply -f kube-deployment.yaml
  
kubectl get deploy
➜  simple_fizz_buzz k get deploy                                                     
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
fizzbuzz   3/3     3            3           28m


kubectl get pods
➜  simple_fizz_buzz k get pods  
NAME                       READY   STATUS    RESTARTS   AGE
fizzbuzz-fdbf987b7-6xx2j   1/1     Running   0          29m
fizzbuzz-fdbf987b7-d75kv   1/1     Running   0          29m
fizzbuzz-fdbf987b7-zwrj6   1/1     Running   0          29m

kubectl port-forward fizzbuzz-fdbf987b7-6xx2j 8080:8000

➜  simple_fizz_buzz kubectl port-forward fizzbuzz-fdbf987b7-6xx2j 8080:8000
Forwarding from 127.0.0.1:8080 -> 8000
Forwarding from [::1]:8080 -> 8000


➜  ~ curl localhost:8080/
"<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n    <meta charset=\"UTF-8\">\n    <title>This is FizzBuzz microservice homepage</title>\n</head>\n<body>\n    <h1> Just a test message </h1>\n    <p> Fizzbuzz is fun </p>\n</body>\n</html>"
➜  ~ curl localhost:8080/api/fizzbuzz
{"message": "This is Fizz Buzz api"}
➜  ~ curl -d '{"number":100}' -H "Content-Type: application/json" -X POST http://localhost:8080/api/fizzbuzz
{"message": "Fizzbuzz computed", "result": "[1, 2, 'Fizz', 4, 'Buzz', 'Fizz', 7, 8, 'Fizz', 'Buzz', 11, 'Fizz', 13, 14, 'FizzBuzz', 16, 17, 'Fizz', 19, 'Buzz', 'Fizz', 22, 23, 'Fizz', 'Buzz', 26, 'Fizz', 28, 29, 'FizzBuzz', 31, 32, 'Fizz', 34, 'Buzz', 'Fizz', 37, 38, 'Fizz', 'Buzz', 41, 'Fizz', 43, 44, 'FizzBuzz', 46, 47, 'Fizz', 49, 'Buzz', 'Fizz', 52, 53, 'Fizz', 'Buzz', 56, 'Fizz', 58, 59, 'FizzBuzz', 61, 62, 'Fizz', 64, 'Buzz', 'Fizz', 67, 68, 'Fizz', 'Buzz', 71, 'Fizz', 73, 74, 'FizzBuzz', 76, 77, 'Fizz', 79, 'Buzz', 'Fizz', 82, 83, 'Fizz', 'Buzz', 86, 'Fizz', 88, 89, 'FizzBuzz', 91, 92, 'Fizz', 94, 'Buzz', 'Fizz', 97, 98, 'Fizz', 'Buzz']"}


```

### Creating a Kubernetes Service
The port-forward command is good for testing the pods directly. But in production, you would want to expose the pod using services.
The level of access the service provides to the set of pods depends on the service type which can be:

    ClusterIP: Internal only.
    NodePort: Gives each node an external IP that’s accessible from outside the cluster and also opens a Port. A kube-proxy 
              component that runs on each node of the Kubernetes cluster listens for incoming traffic on the port and forwards 
              them to the selected pods in a round-robin fashion.
    LoadBalancer: Adds a load balancer from the cloud provider which forwards traffic from the service to the nodes within it.

```python
Find the kube-service-fizzbuzz.yaml manifest file

Run kubectl apply -f kube-service-fizzbuzz.yaml

➜  simple_fizz_buzz k get pods                                             
NAME                       READY   STATUS    RESTARTS   AGE
fizzbuzz-fdbf987b7-6xx2j   1/1     Running   0          40m
fizzbuzz-fdbf987b7-d75kv   1/1     Running   0          40m
fizzbuzz-fdbf987b7-zwrj6   1/1     Running   0          40m
➜  simple_fizz_buzz k apply -f kube-service-fizzbuzz.yaml 
service/fizzbuzz-service created
➜  simple_fizz_buzz k get svc                               
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
fizzbuzz-service   NodePort    10.107.188.226   <none>        8001:30186/TCP   6s
kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP          67m
➜  simple_fizz_buzz curl  192.168.99.1:30186/ 
"<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n    <meta charset=\"UTF-8\">\n    <title>This is FizzBuzz microservice homepage</title>\n</head>\n<body>\n    <h1> Just a test message </h1>\n    <p> Fizzbuzz is fun </p>\n</body>\n</html>"
➜  simple_fizz_buzz curl  192.168.99.1:30186/api/fizzbuzz
{"message": "This is Fizz Buzz api"}
➜  simple_fizz_buzz curl  -d '{"number":100}' -H "Content-Type: application/json" -X POST 192.168.99.1:30186/api/fizzbuzz
{"message": "Fizzbuzz computed", "result": "[1, 2, 'Fizz', 4, 'Buzz', 'Fizz', 7, 8, 'Fizz', 'Buzz', 11, 'Fizz', 13, 14, 'FizzBuzz', 16, 17, 'Fizz', 19, 'Buzz', 'Fizz', 22, 23, 'Fizz', 'Buzz', 26, 'Fizz', 28, 29, 'FizzBuzz', 31, 32, 'Fizz', 34, 'Buzz', 'Fizz', 37, 38, 'Fizz', 'Buzz', 41, 'Fizz', 43, 44, 'FizzBuzz', 46, 47, 'Fizz', 49, 'Buzz', 'Fizz', 52, 53, 'Fizz', 'Buzz', 56, 'Fizz', 58, 59, 'FizzBuzz', 61, 62, 'Fizz', 64, 'Buzz', 'Fizz', 67, 68, 'Fizz', 'Buzz', 71, 'Fizz', 73, 74, 'FizzBuzz', 76, 77, 'Fizz', 79, 'Buzz', 'Fizz', 82, 83, 'Fizz', 'Buzz', 86, 'Fizz', 88, 89, 'FizzBuzz', 91, 92, 'Fizz', 94, 'Buzz', 'Fizz', 97, 98, 'Fizz', 'Buzz']"}
➜  simple_fizz_buzz 
```

### Scaling the deployment
```python
kubectl scale --replicas=4 deployment/fizzbuzz
```

### Deleteting Service and deployment
```python
 ➜  simple_fizz_buzz k delete deploy fizzbuzz
deployment.extensions "fizzbuzz" deleted

simple_fizz_buzz k get svc               
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
fizzbuzz-service   NodePort    10.107.188.226   <none>        8001:30186/TCP   7m51s
kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP          75m
➜  simple_fizz_buzz k delete svc fizzbuzz-service       
service "fizzbuzz-service" deleted
➜  simple_fizz_buzz 


```
