const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

const getConfig = () => {
  const config = synthetics.getConfiguration();
  config.setConfig({
    includeRequestHeaders: true,
    includeResponseHeaders: true,
    continueOnStepFailure: false,
    treatHttpStatusSuccessAsFailure: false
  });
};

const verifyTarget = async () => {
  getConfig();
  const targetUrl = new URL("${url}");

  const requestOptions = {
    hostname: targetUrl.hostname,
    method: 'GET',
    path: targetUrl.pathname.length ? targetUrl.pathname : '/',
    port: targetUrl.port ? Number(targetUrl.port) : (targetUrl.protocol === 'https:' ? 443 : 80),
    protocol: targetUrl.protocol,
    headers: {
      'User-Agent': 'synthetics-canary-availability-check'
    }
  };

  log.info(`Eseguo health check su $${targetUrl.toString()}`);
  const response = await synthetics.executeHttpStep('HealthCheck', requestOptions, async (res) => {
    if (res.statusCode < 200 || res.statusCode >= 400) {
      throw new Error(`Status code non valido: $${res.statusCode}`);
    }
  });

  log.info(`Health check completato con status $${response.statusCode}`);
};

exports.handler = async () => {
  return await verifyTarget();
};
