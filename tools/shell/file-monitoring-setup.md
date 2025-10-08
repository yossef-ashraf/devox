# File System Monitoring with inotify-tools

Guide for setting up real-time file system monitoring using inotify-tools on Linux.

---

## Installation

```bash
sudo apt update
sudo apt install inotify-tools -y
```

## Setup Monitoring Directory

```bash
mkdir -p /root/watch_test
touch /root/watch_test/inotify.log
```

## Create Monitoring Script

Save this script as `/root/watch.sh`:

```bash
#!/bin/bash

# Configuration
WATCH_PATH="/home/cloudhosta-intellevo-back/htdocs/intellevo-back.cloudhosta.com"
LOG_FILE="/root/watch_test/inotify.log"

# Start monitoring
inotifywait -m -r -e modify,create,delete "$WATCH_PATH" \
    --format '%T | %w%f | %e' \
    --timefmt '%Y-%m-%d %H:%M:%S' |
while read line; do
    echo "$line" >> "$LOG_FILE"
done
```

## Make Script Executable and Run

```bash
# Make executable
chmod +x /root/watch.sh

# Run in background
nohup /root/watch.sh > /dev/null 2>&1 &
```

---

## Script Explanation

### Parameters:
- **`-m`**: Monitor continuously (don't exit after first event)
- **`-r`**: Recursive monitoring of subdirectories
- **`-e modify,create,delete`**: Monitor these specific events
- **`--format`**: Custom output format
- **`--timefmt`**: Timestamp format

### Events Monitored:
- **modify**: File content changes
- **create**: New files/directories created
- **delete**: Files/directories deleted

### Log Format:
```
2024-01-15 14:30:25 | /path/to/file.txt | MODIFY
2024-01-15 14:30:26 | /path/to/newfile.txt | CREATE
2024-01-15 14:30:27 | /path/to/oldfile.txt | DELETE
```

---

## Advanced Usage

### Monitor Specific File Types

```bash
# Monitor only PHP files
inotifywait -m -r -e modify --include '.*\.php$' /var/www/html/

# Monitor multiple file types
inotifywait -m -r -e modify --include '.*\.(php|js|css)$' /var/www/html/
```

### Custom Actions on File Changes

```bash
#!/bin/bash
WATCH_PATH="/var/www/html"

inotifywait -m -r -e modify,create,delete "$WATCH_PATH" |
while read path action file; do
    echo "File $file in $path was $action at $(date)"
    
    # Custom actions based on event type
    case $action in
        MODIFY)
            echo "File modified: $path$file"
            # Add your custom action here
            ;;
        CREATE)
            echo "File created: $path$file"
            # Add your custom action here
            ;;
        DELETE)
            echo "File deleted: $path$file"
            # Add your custom action here
            ;;
    esac
done
```

---

## Management Commands

### Check if monitoring is running:
```bash
ps aux | grep inotifywait
```

### Stop monitoring:
```bash
pkill -f inotifywait
```

### View real-time logs:
```bash
tail -f /root/watch_test/inotify.log
```

### Create systemd service for automatic startup:

Create `/etc/systemd/system/file-monitor.service`:

```ini
[Unit]
Description=File System Monitor
After=network.target

[Service]
Type=simple
User=root
ExecStart=/root/watch.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable file-monitor
sudo systemctl start file-monitor
```

---

## Use Cases

1. **Security Monitoring**: Track unauthorized file changes
2. **Development**: Auto-reload applications on file changes
3. **Backup Triggers**: Initiate backups when files are modified
4. **Log Analysis**: Monitor log file changes in real-time
5. **Content Management**: Track website file modifications

---

## Troubleshooting

### Common Issues:
- **Permission denied**: Ensure script has proper permissions
- **Path not found**: Verify the watch path exists
- **High CPU usage**: Limit monitoring to specific file types
- **Log file growing too large**: Implement log rotation

### Performance Tips:
- Use specific event types instead of monitoring all events
- Exclude temporary files and directories
- Implement log rotation to prevent disk space issues