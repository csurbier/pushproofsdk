import { WebPlugin } from '@capacitor/core';

import type { DeliveryReceipt, PushproofConfig, PushproofPlugin } from './definitions';

/**
 * Stub web : Pushproof capte la livraison au niveau de l'OS mobile (NSE iOS /
 * service Android), inexistant sur le web. Les méthodes sont des no-op qui
 * préviennent en console, pour ne pas casser un build web (PWA, dev navigateur).
 */
export class PushproofWeb extends WebPlugin implements PushproofPlugin {
  async configure(_config: PushproofConfig): Promise<void> {
    this.warn();
  }

  async recordDelivery(_receipt: { notifId: string; userId?: string; campaign?: string }): Promise<{ accepted: boolean }> {
    this.warn();
    return { accepted: false };
  }

  async getPendingReceipts(): Promise<{ receipts: DeliveryReceipt[] }> {
    return { receipts: [] };
  }

  private warn(): void {
    console.warn('[Pushproof] non supporté sur le web : la capture de livraison est native (iOS/Android).');
  }
}
