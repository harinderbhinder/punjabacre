module.exports = {
  apps: [
    {
      name: 'classified-api',
      script: './src/index.js',
      instances: 'max',        // use all CPU cores
      exec_mode: 'cluster',    // PM2 cluster mode
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'development',
      },
      env_production: {
        NODE_ENV: 'production',
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      // Graceful shutdown — wait for requests to finish
      kill_timeout: 5000,
      listen_timeout: 10000,
    },
  ],
};
