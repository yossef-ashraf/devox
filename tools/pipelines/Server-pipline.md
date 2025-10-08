To set up a **CI/CD Pipeline** using GitHub Actions (`.github/workflows/ci.yaml` file) and a `deploy.sh` file to run deployments on the server, you can follow these steps:

### 1. Set up the project on your local machine
#### a) Make sure that the following files are present in your project:
- `.github/workflows/ci.yaml` - the configuration file for GitHub Actions.
- `scripts/deploy.sh` - the deployment script that will run on the server.

### 2. Create a CI (GitHub Actions) file
1. **Create a GitHub Actions folder**:
In your main project folder, create the following folder:
```bash
mkdir -p .github/workflows
```

2. **Create a CI file in GitHub Actions**:
Inside the folder you created, create a `ci.yaml` file:
```bash
touch .github/workflows/ci.yaml
```

3. **Configure a CI file**:
Open the `ci.yaml` file and add the following settings:
```yaml
name: CI/CD Pipeline

on:
  pull_request:
    branches:
      - master
  push:
    branches:
      - master

jobs:
  deploy:
    name: Deploy WordPress
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USERNAME }}
          port: ${{ secrets.SSH_PORT }}
          password: ${{ secrets.SSH_PASSWORD }}
          script: cd ${{ secrets.SSH_PATH }} && ./.scripts/deploy.sh
```bash
mkdir scripts
```

2. **Add the `deploy.sh` script**:
Inside the `scripts` folder, create a `deploy.sh` file:
```bash
touch scripts/deploy.sh
```

3. **Configure the `deploy.sh` script**:
Add the content of the deployment script, making sure to update the commands to suit your server environment:
```bash
set -e

echo "Deployment started ..."

cd /Path

# git reset --hard
git pull origin master

echo "Deployment completed!"
```

4. **Grant Execution Permissions to `deploy.sh`**:
To be able to run the `deploy.sh` script from GitHub Actions, you must grant it Execution Permissions:
```bash
chmod +x scripts/deploy.sh
```

### 4. Setting Up SSH Keys for Deployment
1. Generate an SSH key on your local machine:
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

2. **Add the Public Key** to your server:
Copy the public key (`~/.ssh/id_rsa.pub`) to the server:
```bash
ssh-copy-id user@your_server_ip
```

3. **Add the Private Key to GitHub Secrets**:
- Go to GitHub Repository > Settings > Secrets and Variables > Actions.
- Add `SSH_PRIVATE_KEY` as a Secret, and put in it the contents of your private key (`~/.ssh/id_rsa`).

### 5. Testing and Running
1. Push your changes to the `main` branch in GitHub:
```bash
git add .
git commit -m "Add CI/CD pipeline"
git push origin main
```

2. Make sure the pipeline is running through the GitHub Actions page in your repository. GitHub Actions will automatically trigger CI/CD every time you push or open a new merge request to the `main` branch.

### Summary
- **`.github/workflows/ci.yaml`** runs your tests and builds the project, then executes `deploy.sh` to deploy to the server.
- **`scripts/deploy.sh`** is the script that executes the deployment commands on the server via SSH.