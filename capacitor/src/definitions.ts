export interface PushproofConfig {
  /** Endpoint d'ingestion du SaaS, ex: https://api.pushproof.dev/v1/receipts */
  ingestUrl: string;
  /** Clé d'ingestion publique de l'app (safe à embarquer ; scope = ingestion only). */
  ingestKey: string;
  /** App Group iOS partagé entre l'app et la NSE, ex: group.<BUNDLE_ID>. */
  appGroup?: string;
}

export interface DeliveryReceipt {
  notifId: string;
  /** optionnel : identifiant opaque du client, lu dans le payload (feature Pro). */
  userId?: string;
  /** optionnel : libellé de campagne, lu dans le payload, pour attribuer le livré. */
  campaign?: string;
  platform: 'ios' | 'android';
  /** ISO8601 */
  receivedAt: string;
  delivered: boolean;
}

export interface PushproofPlugin {
  /** Enregistre l'endpoint et la clé. À appeler au démarrage de l'app. */
  configure(config: PushproofConfig): Promise<void>;

  /**
   * Capture manuelle d'une livraison — à appeler depuis votre listener de
   * réception **quand l'app est au premier plan** (la NSE iOS peut être
   * court-circuitée en foreground). Idempotent côté serveur : si la NSE a aussi
   * capté, le doublon est dédupliqué sur `(notif_id, device)`.
   *
   * Inutile sur Android (onMessageReceived s'exécute déjà en foreground), mais
   * sans effet néfaste si appelé.
   *
   * `campaign` (optionnel) : relayez `notif.data?.campaign` pour attribuer le
   * livré à une campagne (rapproché de l'envoi déclaré via /v1/sent).
   */
  recordDelivery(receipt: { notifId: string; userId?: string; campaign?: string }): Promise<{ accepted: boolean }>;

  /** Accusés mis en file par la NSE (lus via App Group) et pas encore confirmés. */
  getPendingReceipts(): Promise<{ receipts: DeliveryReceipt[] }>;
}
