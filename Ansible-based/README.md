Building an Ansible Based Operator
1. Let’s first install the operator sdk
go get -d github.com/operator-framework/operator-sdk
cd $GOPATH/src/github.com/operator-framework/operator-sdk
git checkout master make dep make install

Now we will have the operator-sdk binary in the $GOPATH/bin folder.

2.  Setup the project
Operator-sdk new bookstore-operator --api-version=blog.xx.com/v1alpha1 --kind=BookStore --type=ansible

In the above command we have set the operator type as ansible as we want an ansible based operator. It creates a folder structure as shown below

bookstore-operator/

| |- build/ # Contains the Dockerfile to build the operator image.

| |- deploy/ # Contains the crd, cr and manifest files for deploying operator.

| |- roles/ # Contains the helm chart we used while creating the project.

| |- molecule/ # molecule is used for testing the ansible roles.

| |- watches.yaml # Specifies the resource the operator watches (maintains the state of).

Inside the roles folder, it creates an Ansible role name `bookstore`. This role is bootstrapped with all the directories and files which are part of the standard ansible roles.

Now let’s take a look at the watches.yaml file:

Here we can see that it looks just like the operator is going to watch the events related to the objects of BookStore kind and execute the ansible role bookstore.  Drawing parallels from our helm based operator we can see that the behavior in both the cases are similar the only difference being that in case of Helm based operator the operator used to execute the helm chart specified in response to the events related to the object it was watching and here we are executing an ansible role.

In case of ansible based operators, we can get the operator to execute an Ansible playbook as well rather than an ansible role.

3.  Building the bookstore Ansible role        
Now we need to modify the bookstore Ansible roles created for us by the operator-framework.

First we will update the custom resource (CR) file ( blog_v1alpha1_bookstore_cr.yaml) available at deploy/crd/ location. In this CR we can configure all the values which we want to pass to the bookstore Ansible role. By default the CR contains only the size field, we will update it to include other field which we need in our role.  To keep things simple, we will just include some basic variables like image name, tag etc. in our spec.

The Ansible operator passes the key values pairs listed in the spec of the cr as variables to Ansible.  The operator changes the name of the variables to snake_case before running Ansible so when we use the variables in our role we will refer the values in snake case.

Next, we need to create the tasks the bookstore roles will execute. Now we will update the tasks to define our deployment. By default an Ansible role executes the tasks defined at `/tasks/main.yml`. For defining our deployment we will leverage k8s module of Ansible. We will create a kubernetes deployment and service for our app as well as mongodb.

In the above file we can see that we have used the pullPolicy field defined in our cr spec as ‘pull_policy’ in our tasks. Here we have used inline definition to create our k8s objects as our app is quite simple. For large applications creating objects using separate definition files would be a better approach.

4 . Build the bookstore-operator image
The Dockerfile for building the operator image is already in our build folder we need to run the below command from the root folder of our operator project to build the image.

'operator-sdk build akash125/bookstore-operator:ansible'

You can use your own docker repository instead of ‘akash125/bookstore-operator’

5. Run the bookstore-operator
As we have our operator image ready we can now go ahead and run it. The deployment file (operator.yaml under deploy folder) for the operator was created as a part of our project setup we just need to set the image for this deployment to the one we built in the previous step.

After updating the image in the operator.yaml we are ready to deploy the operator.

kubectl create -f deploy/service_account.yaml
kubectl create -f deploy/role.yaml
kubectl create -f deploy/role_binding.yaml
kubectl create -f deploy/operator.yaml

Note: The role created might have more permissions then actually required for the operator so it is always a good idea to review it and trim down the permissions in production setups.

Verify that the operator pod is in running state.
kubectl get pods

Kubernetes Operator 2.png
Here two containers have been started as part of the operator deployment. One is the operator and the other one is ansible. The ansible pod exists only to make the logs available to stdout in ansible format.

6. Deploy the bookstore app
Now we have the bookstore-operator running in our cluster we just need to create the custom resource for deploying our bookstore app.

First, we can create bookstore cr we need to register its crd

‘kubectl delete -f deploy/crds/blog_v1alpha1_bookstore_crd.yaml’

Now we can create the bookstore object

‘kubectl delete -f deploy/crds/blog_v1alpha1_bookstore_cr.yaml’

Now we can see that our operator has deployed out book-store app:

kubectl get pods 
kubectl get svc

Now let’s grab the external IP of the app and make some requests to store details of books.

curl -X POST -d '{"name":"Macbeth", "author":"William Shakespear","price":230}' http://34.x.x.x/books && echo {"id": "989fhso8f9ro","name":"Macbeth","author":"William Shakespear","price":230}

Kubernetes Operator 4.png
Let’s hit the external IP on the browser and see if it lists the books we just stored:

Kubernetes Operator 5.png
We can see that our ‘book-store’ app is up and running.

The operator build is available here.

Conclusion
In this blog post, we learned how we can create an Ansible based operator using the operator framework. Ansible based operators are a great way to combine the power of Ansible and Kubernetes as it allows us to deploy our applications using Ansible role and playbooks and we can pass parameters to them (control them) using custom K8s resources. If Ansible is being heavily used across your organization and you are migrating to Kubernetes then Ansible based operators are an ideal choice for managing deployments. In the next blog, we will learn about Golang based operators.

