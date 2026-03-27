2.  Setup the project
For building a helm based operator we can use an existing Helm chart. We will be using the book-store Helm chart which deploys a simple python app and mongodb instances. This app allows us to perform crud operations via. rest endpoints.

Now we will use the operator-sdk to create our Helm based bookstore-operator project.

operator-sdk new bookstore-operator --api-version=xxx.com/v1alpha1 --kind=BookStore --type=helm --helm-chart=book-store --helm-chart-repo=https://akash-gautam.github.io/helmcharts/

folder structure.

bookstore-operator/
|
|- build/ # Contains the Dockerfile to build the operator image
|- deploy/ # Contains the crd,cr and manifest files for deploying operator
|- helm-charts/ # Contains the helm chart we used while creating the project
|- watches.yaml # Specifies the resource the operator watches (maintains the state of)

In the case of Helm charts, we use the values.yaml file to pass the parameter to our Helm releases, Helm based operator converts all these configurable parameters into the spec of our custom resource. This allows us to express the values.yaml with a custom resource (CR) which, as a native Kubernetes object, enables the benefits of RBAC applied to it and an audit trail. Now when we want to update out deployed we can simply modify the CR and apply it, and the operator will ensure that the changes we made are reflected in our app.

For each object of  `BookStore` kind  the bookstore-operator will perform the following actions:

Create the bookstore app deployment if it doesn’t exists.
Create the bookstore app service if it doesn’t exists.
Create the mongodb deployment if it doesn’t exists.
Create the mongodb service if it doesn’t exists.
Ensure deployments and services match their desired configurations like the replica count, image tag, service port etc.  


3. Build the Bookstore-operator Image
The Dockerfile for building the operator image is already in our build folder we need to run the below command from the root folder of our operator project to build the image.

operator-sdk build akash125/bookstore-operator:v0.0.1

4. Run the Bookstore-operator
As we have our operator image ready we can now go ahead and run it. The deployment file (operator.yaml under deploy folder) for the operator was created as a part of our project setup we just need to set the image for this deployment to the one we built in the previous step.

After updating the image in the operator.yaml we are ready to deploy the operator.

kubectl create -f deploy/service_account.yaml
kubectl create -f deploy/role.yaml
kubectl create -f deploy/role-binding.yaml
kubectl create -f deploy/operator.yaml

Note: The role created might have more permissions then actually required for the operator so it is always a good idea to review it and trim down the permissions in production setups.

Verify that the operator pod is in running state.

kubernetes Helm 1.png
5. Deploy the Bookstore App
Now we have the bookstore-operator running in our cluster we just need to create the custom resource for deploying our bookstore app.

First, we can create bookstore cr we need to register its crd.

kubectl apply -f deploy/crds/xxx_v1alpha1_bookstore_crd.yaml

Now we can create the bookstore object.
kubectl apply -f deploy/crds/xxx_v1alpha1_bookstore_cr.yaml

Now we can see that our operator has deployed out book-store app.


Now let’s grab the external IP of the app and make some requests to store details of books.

kubernetes Helm 3.png
Let’s hit the external IP on the browser and see if it lists the books we just stored:

The bookstore operator build is available here.

Conclusion
Since its early days Kubernetes was believed to be a great tool for managing stateless application but the managing stateful applications on Kubernetes was always considered difficult. Operators are a big leap towards managing stateful applications and other complex distributed, multi (poly) cloud workloads with the same ease that we manage the stateless applications. In this blog post, we learned the basics of Kubernetes operators and build a simple helm based operator. In the next installment of this blog series, we will build an Ansible based Kubernetes operator and then in the last blog we will build a full-fledged Golang based operator for managing stateful workloads.
