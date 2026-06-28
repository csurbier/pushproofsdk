import { registerPlugin } from '@capacitor/core';

import type { PushproofPlugin } from './definitions';

const Pushproof = registerPlugin<PushproofPlugin>('Pushproof', {
  web: () => import('./web').then((m) => new m.PushproofWeb()),
});

export * from './definitions';
export { Pushproof };
