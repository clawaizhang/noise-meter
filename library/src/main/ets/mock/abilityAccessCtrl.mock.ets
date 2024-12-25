export type Permissions = string;

export interface AtManager {
  checkAccessToken(tokenId: number, permission: string): Promise<boolean>;
}

class AtManagerImpl implements AtManager {
  checkAccessToken(tokenId: number, permission: string): Promise<boolean> {
    return Promise.resolve(true);
  }
}

class AbilityAccessCtrl {
  createAtManager(): AtManager {
    return new AtManagerImpl();
  }
}

export default new AbilityAccessCtrl(); 