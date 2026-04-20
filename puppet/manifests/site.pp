# ──────────────────────────────────────────────────────────────────────────────
# File: puppet/manifests/site.pp
# Purpose: Puppet manifest for GlobalMart persistent configuration management.
#
# KEY CONCEPT — Ansible vs Puppet:
#   Ansible = PROCEDURAL   → "Run these tasks in this order" (push-based)
#   Puppet  = DECLARATIVE  → "The system must ALWAYS be in this state" (pull-based)
#   Puppet agents run every 30 mins and ENFORCE this state automatically.
# ──────────────────────────────────────────────────────────────────────────────

# ── Node Classification ───────────────────────────────────────────────────────
node 'web-server-01.globalmart.com', 'web-server-02.globalmart.com' {
  include globalmart::base
  include globalmart::webserver
  include globalmart::monitoring
}

node 'db-server-01.globalmart.com' {
  include globalmart::base
  include globalmart::database
}

# Default — applies to all nodes not explicitly matched
node default {
  include globalmart::base
}


# ── Module: globalmart::base ──────────────────────────────────────────────────
class globalmart::base {

  # Enforce a global application config file — Puppet ENSURES this ALWAYS exists
  # with EXACTLY this content. If someone manually edits it, Puppet will revert it.
  file { '/etc/globalmart/app.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("END"),
      # GlobalMart Application Configuration
      # Managed by Puppet — DO NOT EDIT MANUALLY
      # Last enforced: ${facts['system_uptime']['uptime']}

      [app]
      name=GlobalMart
      environment=${facts['environment']}
      log_level=INFO
      max_connections=100

      [api]
      port=3000
      timeout_seconds=30
      rate_limit=1000

      [cache]
      ttl_seconds=300
      max_size_mb=512
      END
    notify  => Service['globalmart'],   # Restart service if config changes
  }

  # Ensure the directory exists before the file
  file { '/etc/globalmart':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    before => File['/etc/globalmart/app.conf'],
  }

  # Enforce application user exists (idempotent)
  user { 'globalmart':
    ensure     => present,
    shell      => '/bin/bash',
    home       => '/opt/globalmart',
    managehome => true,
    comment    => 'GlobalMart Service Account',
  }

  # Enforce critical packages are installed
  package { ['curl', 'wget', 'git']:
    ensure => installed,
  }

  # Enforce NTP service for time synchronization
  service { 'ntp':
    ensure => running,
    enable => true,
  }
}


# ── Module: globalmart::webserver ─────────────────────────────────────────────
class globalmart::webserver {

  # Enforce Nginx is installed
  package { 'nginx':
    ensure => '1.24.0',   # Pin to specific version — Puppet enforces this EXACT version
  }

  # Enforce Nginx config for reverse proxy to Node.js app
  file { '/etc/nginx/sites-available/globalmart':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(END),
      # Managed by Puppet
      upstream globalmart_backend {
          server 127.0.0.1:3000;
          keepalive 64;
      }

      server {
          listen 80;
          server_name globalmart.com www.globalmart.com;

          location / {
              proxy_pass http://globalmart_backend;
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection 'upgrade';
              proxy_set_header Host $host;
              proxy_cache_bypass $http_upgrade;
          }

          location /health {
              proxy_pass http://globalmart_backend/health;
              access_log off;
          }
      }
      END
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  # Enforce symlink to enable the site
  file { '/etc/nginx/sites-enabled/globalmart':
    ensure  => link,
    target  => '/etc/nginx/sites-available/globalmart',
    require => File['/etc/nginx/sites-available/globalmart'],
    notify  => Service['nginx'],
  }

  # Puppet ENSURES nginx is always running and enabled on boot
  service { 'nginx':
    ensure  => running,
    enable  => true,
    require => Package['nginx'],
  }

  # Puppet ENSURES the globalmart app service is always running
  service { 'globalmart':
    ensure => running,
    enable => true,
  }
}


# ── Module: globalmart::monitoring ───────────────────────────────────────────
class globalmart::monitoring {

  # Enforce node_exporter for Prometheus metrics
  file { '/etc/systemd/system/node_exporter.service':
    ensure  => file,
    mode    => '0644',
    content => @(END),
      [Unit]
      Description=Prometheus Node Exporter
      After=network.target

      [Service]
      User=nobody
      ExecStart=/usr/local/bin/node_exporter
      Restart=always

      [Install]
      WantedBy=multi-user.target
      END
    notify  => Service['node_exporter'],
  }

  service { 'node_exporter':
    ensure => running,
    enable => true,
  }
}


# ── Module: globalmart::database ─────────────────────────────────────────────
class globalmart::database {

  # Enforce PostgreSQL package
  package { 'postgresql':
    ensure => present,
  }

  # Enforce DB config
  file { '/etc/postgresql/15/main/postgresql.conf':
    ensure  => file,
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0644',
    content => @(END),
      # Managed by Puppet
      max_connections = 200
      shared_buffers = 256MB
      effective_cache_size = 1GB
      log_destination = 'stderr'
      logging_collector = on
      log_directory = '/var/log/postgresql'
      END
    require => Package['postgresql'],
    notify  => Service['postgresql'],
  }

  service { 'postgresql':
    ensure  => running,
    enable  => true,
    require => Package['postgresql'],
  }
}
