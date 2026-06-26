# Local Jenkins + GitHub webhook (cost: $0)

## 1. Start Jenkins
```bash
cd jenkins
docker compose up -d --build
# get the first-login password:
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
Open http://localhost:8080, install **suggested plugins**, and create an admin user.
Make sure these plugins are present: **Pipeline**, **Git**, **GitHub**, **Credentials Binding**.

## 2. Add AWS credentials
**Manage Jenkins → Credentials → System → Global → Add Credentials**
- Kind: **Username with password**
- Username: your `AWS_ACCESS_KEY_ID`
- Password: your `AWS_SECRET_ACCESS_KEY`
- ID: **`aws-credentials`**  ← must match the ID used in the `Jenkinsfile`

The IAM user needs: ECR push/pull, EKS describe, and access to the cluster
(add the user/role to the cluster's `aws-auth` / EKS access entries).

## 3. Create the pipeline job
- **New Item → Pipeline** (e.g. `task-manager`).
- **Build Triggers** → check **GitHub hook trigger for GITScm polling**.
- **Pipeline → Definition: Pipeline script from SCM** → Git → your fork URL →
  Script Path: `Jenkinsfile`.

## 4. Expose Jenkins to GitHub with ngrok
```bash
ngrok http 8080
```
Copy the `https://<id>.ngrok-free.app` URL.

## 5. Add the GitHub webhook
In your fork: **Settings → Webhooks → Add webhook**
- Payload URL: `https://<id>.ngrok-free.app/github-webhook/`  (trailing slash matters)
- Content type: `application/json`
- Events: **Just the push event**

Now every `git push` triggers the pipeline: build versioned images → push to ECR →
roll out to EKS. The deploy stage only succeeds while the EKS cluster is up, so run the
demo push during your EKS window.

> Bonus alternative (not used here): run Jenkins on an EC2 instance instead of local+ngrok.
> That gives a stable public URL and avoids ngrok, at the cost of an EC2 instance.
