# How to Add an SSH Key and Configure GitHub Secrets for Deployment to Production Servers

### Introduction

If you're developing a project on GitHub and need to deploy your code automatically to production servers using GitHub Actions, you can use SSH to connect to the server remotely. In this guide, we'll cover how to add an SSH key to your GitHub repository, how to use GitHub Secrets in Actions, and how to set up your server with necessary configurations.

### Requirements

1. **GitHub Account**: You should have a GitHub repository for your project.
2. **Remote Server (e.g., VPS or other server)**: You should have SSH access to the server.
3. **Permission to use GitHub Actions**: This guide assumes you're using GitHub Actions for automating deployment.

---

## 1. Creating a New SSH Key (on Your Local Machine)

### 1.1 Create an SSH Key using `ssh-keygen`

Open the terminal on your local machine and run the following command to create a new SSH key using the `ed25519` algorithm (this is more secure than the older RSA keys).

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### 1.2 Store the Key

When prompted, you can press `Enter` to accept the default location for saving the key (typically in the `~/.ssh/id_ed25519` file).

```
Enter file in which to save the key (/home/your-user/.ssh/id_ed25519):
```

### 1.3 Set a Passphrase

You'll be prompted to set a passphrase for additional protection. You can leave it blank or enter a passphrase if you prefer.

---

## 2. Adding the SSH Key to GitHub

### 2.1 Copy the Public Key

Open the public key file that was generated (usually located at `/home/your-user/.ssh/id_ed25519.pub` or the default location depending on your system).

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire contents of the file.

### 2.2 Add the Key to GitHub Settings

1. Go to your repository on GitHub.
2. From the top menu, select **Settings**.
3. In the sidebar, select **Deploy Keys** under the **Security** section.
4. Click the **Add deploy key** button.
5. In the **Title** field, provide a descriptive name for the key, such as "SSH Key for Production Server".
6. In the **Key** field, paste the public key you copied earlier.
7. Make sure to check the **Allow write access** box if you need to push changes to the repository via SSH.
8. Click **Add key**.

---

## 3. Adding Secrets to GitHub Settings

### 3.1 Add Secrets for Server Connection

To use SSH in GitHub Actions, you need to add some secret variables to your GitHub repository settings.

1. Go to your repository on GitHub.
2. Click on **Settings**.
3. In the sidebar, select **Secrets and variables** > **Actions**.
4. Click on **New repository secret**.

### 3.2 Add the Following Secrets

- **SSH_HOST**: The IP address of the server.
- **SSH_USERNAME**: The username for SSH login on the server.
- **SSH_PASSWORD**: The password for the username (if required).
- **SSH_PATH**: The root directory path on the server where your project will be deployed.
- **SSH_PORT**: The SSH port to use (usually `22`).

For example:

| Key             | Value                        |
|-----------------|------------------------------|
| `SSH_HOST`      | `192.168.1.1`                |
| `SSH_USERNAME`  | `new-Site-User`              |
| `SSH_PASSWORD`  | `***3EyhUl****`              |
| `SSH_PATH`      | `/home/newUser/htdocs/project.com` |
| `SSH_PORT`      | `22`                          |

---

## 4. Server Configuration

### 4.1 Granting Proper Permissions

Before you can deploy files to the server, make sure you have set the correct permissions for your project folder and enabled appropriate access.

#### Example Commands:

1. **Change Permissions for the Deployment Script**:
   Ensure that the `deploy.sh` script is executable:

   ```bash
   chmod -R 775 deploy.sh
   ```

2. **Change Ownership of the `.git` Folder**:
   Ensure the `.git` folder is owned by the correct user:

   ```bash
   sudo chown -R your_user:your_group .git/
   ```

---

## 5. Summary

- You created a new SSH key using `ssh-keygen`.
- You added the SSH key to GitHub as a deploy key.
- You added the necessary secrets (such as `SSH_HOST` and `SSH_USERNAME`) to GitHub settings.
- You ensured the server was properly configured to receive the files and update the repository.

---

### Additional Tips

- **Security**: Ensure that your private key is not leaked. Use GitHub Secrets to securely store it.
- **Documentation**: Make sure to document your setup for easier troubleshooting and future updates.
- **Test Locally**: Before adding commands to GitHub Actions, test them locally on the server via SSH to ensure everything works as expected.

---
