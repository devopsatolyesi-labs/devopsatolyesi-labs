// ==============================================================================
// DevOps Atölyesi — Order API Microservice
// Demonstrates Real-World HTTP Requests, Error Handling & Structured Logging
// ==============================================================================
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const logger = require('./logger');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// ------------------------------------------------------------------------------
// Request Context & Structured Audit Logging Middleware
// ------------------------------------------------------------------------------
app.use((req, res, next) => {
  const startTime = Date.now();
  const requestId = req.headers['x-request-id'] || uuidv4();
  req.id = requestId;

  res.on('finish', () => {
    const durationMs = Date.now() - startTime;
    const logLevel = res.statusCode >= 500 ? 'error' : res.statusCode >= 400 ? 'warn' : 'info';

    const logPayload = {
      message: `${req.method} ${req.originalUrl} -> ${res.statusCode} (${durationMs}ms)`,
      http_method: req.method,
      request_path: req.originalUrl,
      status: res.statusCode,
      duration_ms: durationMs,
      client_ip: req.ip || req.headers['x-forwarded-for'] || '127.0.0.1',
      user_agent: req.get('user-agent') || 'unknown',
      request_id: requestId
    };

    logger.log(logLevel, logPayload.message, logPayload);

    // Also send via TCP to Logstash for dual-path ingest demonstration
    logger.sendTcp({
      level: logLevel.toUpperCase(),
      ...logPayload
    });
  });

  next();
});

// ------------------------------------------------------------------------------
// API Routes
// ------------------------------------------------------------------------------
app.get('/health', (req, res) => {
  res.json({
    status: 'UP',
    service: 'order-api',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/orders', (req, res) => {
  logger.info('Fetching order history', {
    action: 'list_orders',
    request_id: req.id,
    user_id: 'usr_8492'
  });

  res.json([
    { order_id: 'ord_1001', total: 149.99, status: 'COMPLETED' },
    { order_id: 'ord_1002', total: 49.50, status: 'PROCESSING' }
  ]);
});

app.post('/api/orders', (req, res) => {
  const orderId = `ord_${Math.floor(1000 + Math.random() * 9000)}`;
  const traceId = `trc_${uuidv4().substring(0, 8)}`;
  const { customer, items, total_amount, payment_method } = req.body || {};

  logger.info('Order checkout initiated', {
    order_id: orderId,
    trace_id: traceId,
    request_id: req.id,
    customer: customer || 'guest',
    items_count: Array.isArray(items) ? items.length : 1,
    total_amount: total_amount || 99.00,
    payment_method: payment_method || 'CREDIT_CARD'
  });

  // Simulate payment processing
  if (req.body && req.body.fail_payment) {
    logger.error('Payment gateway rejection: Insufficient funds or gateway timeout', {
      order_id: orderId,
      trace_id: traceId,
      error_code: 'PAYMENT_GATEWAY_TIMEOUT',
      gateway: 'Stripe_Mock',
      status: 502
    });

    return res.status(502).json({
      error: 'Payment processing failed',
      order_id: orderId,
      trace_id: traceId
    });
  }

  logger.info('Order placed and confirmation sent', {
    order_id: orderId,
    trace_id: traceId,
    status: 201
  });

  res.status(201).json({
    success: true,
    order_id: orderId,
    trace_id: traceId,
    status: 'CREATED'
  });
});

app.get('/api/simulate-error', (req, res) => {
  const errorTrace = `err_${uuidv4().substring(0, 8)}`;
  const error = new Error('Database connection pool exhausted');
  error.code = 'ECONNRESET';

  logger.error('Critical database timeout in order inventory subsystem', {
    trace_id: errorTrace,
    error_name: error.name,
    error_message: error.message,
    error_stack: error.stack,
    subsystem: 'inventory-db',
    status: 500
  });

  res.status(500).json({
    error: 'Internal Server Error',
    trace_id: errorTrace,
    message: 'Database connection failed'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  logger.info(`Order API service running on port ${PORT}`, {
    port: PORT,
    environment: process.env.NODE_ENV || 'production'
  });
});
