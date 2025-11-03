# Railway Deployment Guide

This guide walks you through deploying Sleepless Agent as a Docker container on Railway.

## Prerequisites

1. **Railway Account**: Sign up at [railway.app](https://railway.app)
2. **Slack App**: Complete the Slack app setup from the main [README.md](README.md#2-setup-slack-app)
3. **Git Repository**: Your code should be in a Git repository (GitHub, GitLab, etc.)

## Quick Deploy

### Option 1: Deploy from GitHub (Recommended)

1. **Connect Repository to Railway**
   - Go to [railway.app](https://railway.app)
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Authorize Railway to access your repository
   - Select the sleepless-agent repository

2. **Configure Environment Variables**

   Railway will automatically detect the Dockerfile. Add these environment variables in the Railway dashboard:

   **Required:**
   ```bash
   SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
   SLACK_APP_TOKEN=xapp-your-slack-app-token
   ```

   **Optional Git Configuration:**
   ```bash
   GIT_USER_NAME=Sleepless Agent
   GIT_USER_EMAIL=agent@sleepless.local
   SLEEPLESS_AGENT__GIT__USE_REMOTE_REPO=true
   SLEEPLESS_AGENT__GIT__REMOTE_REPO_URL=git@github.com:your-username/your-repo.git
   ```

   **Optional Claude Configuration:**
   ```bash
   SLEEPLESS_AGENT__CLAUDE_CODE__MODEL=claude-sonnet-4-5-20250929
   SLEEPLESS_AGENT__CLAUDE_CODE__THRESHOLD_DAY=20.0
   SLEEPLESS_AGENT__CLAUDE_CODE__THRESHOLD_NIGHT=80.0
   SLEEPLESS_AGENT__CLAUDE_CODE__NIGHT_START_HOUR=1
   SLEEPLESS_AGENT__CLAUDE_CODE__NIGHT_END_HOUR=9
   ```

3. **Add Persistent Volume**
   - In Railway dashboard, go to your service
   - Click "Variables" tab
   - Scroll to "Volumes" section
   - Click "Add Volume"
   - Mount path: `/app/workspace`
   - This ensures your task data persists across deployments

4. **Deploy**
   - Railway will automatically build and deploy
   - Monitor the build logs in the Railway dashboard
   - Once deployed, check the logs to ensure the daemon started successfully

### Option 2: Deploy via Railway CLI

1. **Install Railway CLI**
   ```bash
   npm install -g @railway/cli
   ```

2. **Login to Railway**
   ```bash
   railway login
   ```

3. **Initialize Project**
   ```bash
   cd sleepless-agent
   railway init
   ```

4. **Set Environment Variables**
   ```bash
   railway variables set SLACK_BOT_TOKEN=xoxb-your-token
   railway variables set SLACK_APP_TOKEN=xapp-your-token
   railway variables set GIT_USER_NAME="Sleepless Agent"
   railway variables set GIT_USER_EMAIL="agent@sleepless.local"
   ```

5. **Add Volume**
   ```bash
   railway volume add --mount-path /app/workspace
   ```

6. **Deploy**
   ```bash
   railway up
   ```

## Configuration

### Environment Variables

The application supports configuration via environment variables using the pattern:
- `SLACK_BOT_TOKEN` - Slack bot token (required)
- `SLACK_APP_TOKEN` - Slack app token (required)
- `SLEEPLESS_AGENT__<section>__<key>` - Override any config.yaml setting

Examples:
```bash
# Override agent workspace root
SLEEPLESS_AGENT__AGENT__WORKSPACE_ROOT=/app/workspace

# Override Claude Code model
SLEEPLESS_AGENT__CLAUDE_CODE__MODEL=claude-sonnet-4-5-20250929

# Override usage thresholds
SLEEPLESS_AGENT__CLAUDE_CODE__THRESHOLD_DAY=20.0
SLEEPLESS_AGENT__CLAUDE_CODE__THRESHOLD_NIGHT=80.0
```

### Custom Configuration File

If you want to use a custom `config.yaml`:

1. Create your custom config file
2. In Railway, add it as a volume or mount:
   - Add Volume: `/app/config`
   - Upload your `config.yaml` to the volume
   - Set environment variable: `SLEEPLESS_AGENT_CONFIG_FILE=/app/config/config.yaml`

## SSH Keys for Git Operations

If you want to use Git with SSH (recommended for private repos):

1. **Generate SSH Key** (if you don't have one)
   ```bash
   ssh-keygen -t ed25519 -C "agent@sleepless.local" -f sleepless_agent_key
   ```

2. **Add to GitHub/GitLab**
   - Copy the public key: `cat sleepless_agent_key.pub`
   - Add it to your repository's deploy keys or your user's SSH keys

3. **Add to Railway**
   - In Railway dashboard, go to your service
   - Create a new volume for SSH keys: `/root/.ssh`
   - Upload your private key as `id_ed25519`
   - Upload your public key as `id_ed25519.pub`
   - Create a `config` file with:
     ```
     Host github.com
         StrictHostKeyChecking no
         UserKnownHostsFile=/dev/null
     ```

## Monitoring

### View Logs

**Via Dashboard:**
- Go to your Railway project
- Click on your service
- Navigate to "Logs" tab

**Via CLI:**
```bash
railway logs
```

### Health Checks

The container includes a health check that verifies the database file exists:
- Health check runs every 30 seconds
- Starts after 5 seconds
- Fails after 3 consecutive failures

### Check Status

Use Slack commands to monitor the agent:
```
/check          # System status and queue
/report --list  # Available reports
/report         # Today's report
```

## Troubleshooting

### Container Keeps Restarting

1. **Check Logs:**
   ```bash
   railway logs
   ```

2. **Common Issues:**
   - Missing environment variables (SLACK_BOT_TOKEN, SLACK_APP_TOKEN)
   - Slack tokens are invalid or expired
   - Volume not properly mounted

3. **Verify Environment Variables:**
   ```bash
   railway variables
   ```

### Database/Workspace Issues

1. **Verify Volume Mount:**
   - In Railway dashboard, check if volume is mounted at `/app/workspace`
   - Check volume size and usage

2. **Reset Workspace** (if needed):
   - Delete the volume in Railway dashboard
   - Create a new volume
   - Redeploy the service

### Claude Code Not Working

1. **Verify Claude CLI Installation:**
   - The Dockerfile installs Claude Code CLI automatically
   - Check build logs to ensure installation succeeded

2. **Check Binary Path:**
   - Default path is `/usr/local/bin/claude`
   - Override with: `SLEEPLESS_AGENT__CLAUDE_CODE__BINARY_PATH=/path/to/claude`

### Git Operations Failing

1. **SSH Key Issues:**
   - Verify SSH key is properly mounted at `/root/.ssh/id_ed25519`
   - Check SSH key permissions (should be 600)
   - Ensure public key is added to GitHub/GitLab

2. **Git Configuration:**
   - Verify `GIT_USER_NAME` and `GIT_USER_EMAIL` are set
   - Check `SLEEPLESS_AGENT__GIT__REMOTE_REPO_URL` is correct

## Local Testing with Docker

Before deploying to Railway, test locally:

1. **Create `.env` file:**
   ```bash
   cp .env.example .env
   # Edit .env with your tokens
   ```

2. **Build and Run:**
   ```bash
   docker-compose up --build
   ```

3. **Check Logs:**
   ```bash
   docker-compose logs -f sleepless-agent
   ```

4. **Stop:**
   ```bash
   docker-compose down
   ```

## Scaling Considerations

### Resource Limits

Default Railway resources should be sufficient for most use cases. Monitor:
- CPU usage during task execution
- Memory usage (especially with large workspaces)
- Disk usage in workspace volume

### Cost Optimization

1. **Adjust Usage Thresholds:**
   - Lower thresholds during day hours to save credits
   - Set appropriate night hours for your timezone

2. **Monitor Task Frequency:**
   - Disable auto-generation if not needed:
     ```bash
     SLEEPLESS_AGENT__AUTO_GENERATION__ENABLED=false
     ```

3. **Regular Cleanup:**
   - Use `/trash empty` to clean up old projects
   - Monitor workspace disk usage

## Updating

### Automatic Updates (GitHub Integration)

If deployed via GitHub:
1. Push changes to your repository
2. Railway automatically rebuilds and redeploys
3. Workspace data persists across deployments

### Manual Update (CLI)

```bash
git pull
railway up
```

## Security Best Practices

1. **Secrets Management:**
   - Never commit tokens to Git
   - Use Railway's environment variable system
   - Rotate tokens regularly

2. **SSH Keys:**
   - Use deploy keys with limited permissions
   - Don't reuse personal SSH keys
   - Consider using HTTPS with tokens for Git operations

3. **Network Security:**
   - Railway provides automatic HTTPS
   - Consider restricting Slack app to specific channels

## Support

- **Railway Issues:** [Railway Discord](https://discord.gg/railway)
- **Sleepless Agent Issues:** [GitHub Issues](https://github.com/context-machine-lab/sleepless-agent/issues)
- **Slack Setup:** [Slack API Documentation](https://api.slack.com/start)

## Additional Resources

- [Railway Documentation](https://docs.railway.app/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Main README](README.md)