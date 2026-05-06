import mqttClient from '../../core/mqtt/mqtt';
import { logger } from '../../core/logger';

export async function publishFactoryReset(deviceId: string, requestId?: string) {
  const topic = `home/${deviceId}/cmd`;
  const payload = JSON.stringify({ cmd: 'factory_reset', requestId: requestId || '' });
  logger.info(`Publicando factory_reset a ${topic}`);
  mqttClient.publish(topic, payload);
}
