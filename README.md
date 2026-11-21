# 🚀 End-to-End CI/CD and GitOps on Amazon EKS

### GitHub Actions + AWS OIDC + Docker + Amazon ECR + Kubernetes + Argo CD

An end-to-end DevOps project demonstrating how to build, publish, and deploy a containerized Python application to Amazon EKS using GitHub Actions, AWS IAM OIDC federation, Amazon ECR, and Argo CD.

The goal is to automate application delivery without storing long-lived AWS access keys in GitHub.

## 🏗️ Architecture

```text
Developer (Mac)
      |
      | git push
      v
GitHub Repository
      |
      v
GitHub Actions
      |
      | Authenticate using AWS OIDC
      v
AWS IAM Role
      |
      v
Docker Build
      |
      | Push container image
      v
Amazon ECR
      |
      | Image reference updated in Git
      v
Kubernetes Manifests (GitHub)
      |
      | GitOps synchronization
      v
Argo CD
      |
      | Kubernetes API
      v
Amazon EKS Cluster
      |
      v
Self-Managed EC2 Worker Nodes
      |
      v
Hello World Application
```

**Important:** The GitOps deployment portion requires the GitHub Actions workflow to update the Kubernetes image reference and Argo CD to synchronize the manifests. These steps must be configured and verified independently of the ECR image push.

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| GitHub | Source code and GitOps repository |
| GitHub Actions | CI/CD automation |
| AWS IAM OIDC | Keyless AWS authentication |
| Docker | Application containerization |
| Amazon ECR | Private Docker image registry |
| Amazon EKS | Managed Kubernetes control plane |
| Amazon EC2 | Self-managed Kubernetes worker nodes |
| Kubernetes | Container orchestration |
| Argo CD | GitOps continuous delivery |
| Python | Hello World HTTP application |

## 📁 Repository Structure

```text
eks-hello-world/
├── app/
│   └── main.py
├── .github/
│   └── workflows/
│       └── build-and-push.yml
├── kubernetes/
│   ├── deployment.yaml
│   └── service.yaml
├── argocd/
│   └── application.yaml
├── Dockerfile
├── .dockerignore
├── .gitignore
├── requirements.txt
└── README.md
```

## 1. Python Hello World Application

The application uses Python's built-in HTTP server.

It listens on port `8080` and returns:

```text
Hello World from Amazon EKS!
```

Application source:

`app/main.py`

The application requires no external Python dependencies.

## 2. Docker Containerization

The Dockerfile uses:

- Python 3.12 Alpine as the base image
- A non-root application user
- Container port `8080`
- A Python command to start the HTTP server

Build locally:

```bash
docker build -t eks-hello-world:local .
```

Run locally:

```bash
docker run --rm -p 8080:8080 eks-hello-world:local
```

Test:

```bash
curl http://localhost:8080
```

Expected response:

```text
Hello World from Amazon EKS!
```

## 3. AWS Infrastructure Configuration

| Resource | Configuration |
|---|---|
| AWS Region | `eu-north-1` |
| AWS Account | `788353521849` |
| EKS Cluster | `test-cluster` |
| Worker Nodes | Self-managed EC2 instances |
| Container Registry | Amazon ECR |
| ECR Repository | `eks-hello-world` |
| IAM Role | `GitHubActionsECRRole` |

### Amazon ECR Repository

Repository URI:

```text
788353521849.dkr.ecr.eu-north-1.amazonaws.com/eks-hello-world
```

The ECR repository must exist before GitHub Actions can push an image.

## 4. Secure AWS Authentication with GitHub OIDC

GitHub Actions authenticates to AWS using OpenID Connect (OIDC).

This avoids storing permanent AWS access keys as GitHub secrets.

### Authentication Flow

```text
GitHub Actions
      |
      | Request OIDC token
      v
GitHub OIDC Provider
      |
      | Present token
      v
AWS Security Token Service (STS)
      |
      | Validate IAM trust policy
      v
Temporary AWS Credentials
      |
      v
Amazon ECR
```

### IAM Configuration

OIDC Provider:

```text
token.actions.githubusercontent.com
```

IAM Role:

```text
arn:aws:iam::788353521849:role/GitHubActionsECRRole
```

### Immutable OIDC Subject

This repository uses GitHub's immutable OIDC subject format.

The repository's subject prefix is:

```text
repo:arushi-gupta1111@37296206/eks-hello-world@1465639955
```

For a workflow running on the `main` branch, the expected subject is:

```text
repo:arushi-gupta1111@37296206/eks-hello-world@1465639955:ref:refs/heads/main
```

The IAM trust policy must match the actual OIDC subject.

This restricts AWS role assumption to the authorized repository and branch.

### Required ECR Permissions

The IAM role requires the following actions:

```text
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:BatchGetImage
ecr:InitiateLayerUpload
ecr:UploadLayerPart
ecr:CompleteLayerUpload
ecr:PutImage
```

Repository-specific actions should be restricted to:

```text
arn:aws:ecr:eu-north-1:788353521849:repository/eks-hello-world
```

`ecr:GetAuthorizationToken` requires `Resource: "*"`.

## 5. GitHub Actions CI Pipeline

Workflow file:

`.github/workflows/build-and-push.yml`

The intended workflow performs the following operations:

1. Checkout application source code.
2. Request a GitHub OIDC token.
3. Assume the AWS IAM role.
4. Authenticate with Amazon ECR.
5. Build the Docker image.
6. Tag the image using the Git commit SHA.
7. Push the image to ECR.
8. Update the Kubernetes Deployment image reference in Git, if the GitOps update step is configured.

### GitHub Actions Permissions

```yaml
permissions:
  id-token: write
  contents: write
```

`id-token: write` allows the workflow to request an OIDC token.

`contents: write` allows the workflow to push manifest changes back to GitHub when required.

### Image Tagging

An example image reference is:

```text
788353521849.dkr.ecr.eu-north-1.amazonaws.com/eks-hello-world:<COMMIT_SHA>
```

Using commit-based image tags improves traceability and makes deployments easier to audit.

## 6. Amazon EKS Deployment

The application is intended to run on an Amazon EKS cluster with self-managed EC2 worker nodes.

Cluster:

```text
test-cluster
```

Region:

```text
eu-north-1
```

### Kubernetes Deployment

File:

`kubernetes/deployment.yaml`

The Deployment defines:

- Application container image
- Desired replica count
- Container port `8080`
- Readiness probe
- CPU and memory resource requests and limits
- Container security settings

### Kubernetes Service

File:

`kubernetes/service.yaml`

The Service provides a stable network endpoint for the application Pods.

A `ClusterIP` Service exposes the application internally within the Kubernetes cluster.

## 7. Argo CD GitOps Deployment

Argo CD continuously compares the desired Kubernetes configuration stored in Git with the live cluster state.

### GitOps Flow

```text
GitHub Actions
      |
      | Push image to ECR
      v
Update deployment.yaml
      |
      | Commit updated image reference
      v
GitHub Repository
      |
      | Argo CD detects changes
      v
Argo CD Application
      |
      | Synchronize desired state
      v
Amazon EKS
```

Argo CD Application manifest:

`argocd/application.yaml`

The Application should point to:

```text
Repository:
https://github.com/arushi-gupta1111/eks-hello-world.git

Path:
kubernetes

Target revision:
main

Destination:
https://kubernetes.default.svc

Namespace:
hello-world
```

The destination URL `https://kubernetes.default.svc` refers to the Kubernetes API of the cluster where Argo CD is running.

### Apply the Argo CD Application

After installing Argo CD and configuring the Application manifest:

```bash
kubectl apply -f argocd/application.yaml -n argocd
```

Verify:

```bash
kubectl get applications -n argocd
```

For automated deployment, configure Argo CD with automatic synchronization and self-healing as appropriate.

## 8. Verify the Kubernetes Deployment

Check nodes:

```bash
kubectl get nodes
```

Check application Pods:

```bash
kubectl get pods -n hello-world
```

Check Deployment:

```bash
kubectl get deployment -n hello-world
```

Check Services:

```bash
kubectl get svc -n hello-world
```

Inspect Pod logs:

```bash
kubectl logs -n hello-world deployment/hello-world
```

### Test the Application

If the Kubernetes Service is named `hello-world` and exposes port `80`:

```bash
kubectl port-forward \
  svc/hello-world 8080:80 \
  -n hello-world
```

Open another terminal:

```bash
curl http://localhost:8080
```

Expected output:

```text
Hello World from Amazon EKS!
```

## 9. Troubleshooting and Lessons Learned

### Git Push Rejected — Non-Fast-Forward

**Problem:**

```text
Updates were rejected because the remote contains work
that you do not have locally.
```

**Cause:** Local and remote branches have diverged.

**Resolution:** Synchronize commits using `git pull --rebase origin main`, resolve any conflicts, and push after the rebase completes.

Avoid force-pushing shared branches.

### Dockerfile Cannot Be Empty

**Problem:**

```text
failed to solve: the Dockerfile cannot be empty
```

**Cause:** The Dockerfile was initially created as an empty placeholder or an older commit was used.

**Resolution:** Add Docker instructions, commit the changes, push them, and verify that the workflow builds the intended commit.

### AWS OIDC Authentication Failure

**Problem:**

```text
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

**Cause:** The IAM role's trust policy did not match the repository's OIDC subject.

**Resolution:** Verify the OIDC subject and update the IAM trust relationship with the correct repository and branch restrictions.

### Amazon ECR Repository Not Found

**Problem:**

```text
The repository with name 'eks-hello-world'
does not exist in the registry.
```

**Cause:** The ECR repository had not been created in the expected AWS account and region.

**Resolution:** Create the private ECR repository before pushing images.

### ECR Manifest Request Returns 403

**Problem:**

```text
403 Forbidden
HEAD /v2/eks-hello-world/manifests/sha256:...
```

**Possible cause:** Missing ECR image-read permissions, repository-policy restrictions, or other authorization issues.

**Resolution:** Verify `ecr:BatchGetImage`, the IAM role's effective permissions, repository policies, and any explicit denies.

### Kubernetes Pods Remain Pending

**Possible causes:**

- Insufficient EC2 worker node resources
- Node scheduling restrictions
- Unavailable worker nodes
- Unbound persistent volumes

Investigate using:

```bash
kubectl describe pod <POD_NAME> -n hello-world
```

### ImagePullBackOff

**Possible causes:**

- Incorrect ECR image URI or tag
- Missing image in ECR
- Insufficient ECR permissions on the worker node IAM role
- Network connectivity issues

Inspect:

```bash
kubectl describe pod <POD_NAME> -n hello-world
```

## 10. Key DevOps Concepts Demonstrated

- CI/CD pipeline automation
- Keyless AWS authentication using OIDC
- IAM least-privilege access control
- Docker image building and publishing
- Container registry management
- Kubernetes Deployments and Services
- Self-managed EC2 worker nodes in Amazon EKS
- GitOps-based continuous delivery
- Declarative infrastructure and application configuration
- Troubleshooting Git, Docker, AWS IAM, ECR, and Kubernetes

## 11. Project Verification Checklist

- [x] GitHub repository created
- [x] GitHub OIDC configuration inspected
- [x] AWS IAM role configured for GitHub Actions
- [x] Docker build reached the ECR push stage
- [x] ECR repository created
- [ ] Confirm successful Docker image push to ECR
- [ ] Confirm GitHub Actions updates the Kubernetes image reference
- [ ] Confirm Argo CD Application is synchronized and healthy
- [ ] Confirm application Pods are running
- [ ] Verify Hello World response through the Kubernetes Service

## 🔗 Repository

[GitHub — eks-hello-world](https://github.com/arushi-gupta1111/eks-hello-world)

---

**Project objective:** Demonstrate a secure, automated application delivery workflow from source code to Kubernetes using GitHub Actions, AWS OIDC, Amazon ECR, Amazon EKS, and Argo CD.
