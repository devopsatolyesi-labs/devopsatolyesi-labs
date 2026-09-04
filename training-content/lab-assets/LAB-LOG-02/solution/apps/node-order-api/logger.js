// ==============================================================================
// DevOps Atölyesi — Winston Structured Logger for ELK Stack
// ==============================================================================
const winston = require('winston');
const os = require('os');
const net = require('net');

const SERVICE_NAME = process.env.SERVICE_NAME || 'order-api';
const ENVIRONMENT = process.env.NODE_ENV || 'production';
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

// Custom JSON Formatter adding ELK-standard metadata
const elkFormat = winston.format((info) => {
  info['@timestamp'] = new Date().toISOString();
  info.service = SERVICE_NAME;
  info.environment = ENVIRONMENT;
  info.host = os.hostname();
  info.level = info.level.toUpperCase();
  return info;
});

const transports = [
  // 1. Standard Output JSON for Docker & Filebeat scraping
  new winston.transports.Console({
    format: winston.format.combine(
      elkFormat(),
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json()
    )
  })
];

const logger = winston.createLogger({
  level: LOG_LEVEL,
  defaultMeta: {
    service: SERVICE_NAME,
    environment: ENVIRONMENT
  },
  transports
});

// Helper function to send log payload over TCP directly to Logstash (port 5000)
logger.sendTcp = function (payload) {
  const host = process.env.LOGSTASH_TCP_HOST;
  const port = parseInt(process.env.LOGSTASH_TCP_PORT || '5000', 10);

  if (!host) return;

  const client = new net.Socket();
  client.connect(port, host, () => {
    const data = JSON.stringify({
      '@timestamp': new Date().toISOString(),
      service: SERVICE_NAME,
      environment: ENVIRONMENT,
      host: os.hostname(),
      ...payload
    }) + '\n';
    client.write(data);
    client.end();
  });

  client.on('error', (err) => {
    // Non-blocking fallback to standard console
    logger.warn('Logstash TCP send failed: ' + err.message);
  });
};

module.exports = logger;
