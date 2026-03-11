# Startup Optimization for ARM/Pi Hosts

## Environment Variables
Add to ~/.bashrc for faster CLI startup:

export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
mkdir -p /var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
