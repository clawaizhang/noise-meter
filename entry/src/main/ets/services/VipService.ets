import { iap } from '@kit.IAPKit';
import dataPreferences from '@ohos.data.preferences';
import { buffer } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export enum VipSource {
  NONE = 'none',
  SUBSCRIPTION = 'subscription',
  PERMANENT = 'permanent'
}

export interface VipStatus {
  isVip: boolean;
  source: VipSource;
  expireTime: number;
  isPermanent: boolean;
  autoRenew: boolean;
  hasLegacyVoucher: boolean;
  legacyDays: number;
}

// 订阅商品信息
export interface SubscriptionProduct {
  productId: string;
  productName: string;
  priceType: number;
  price: string;
  currency: string;
  productDesc?: string;
  subscriptionPeriod?: string;
  freeTrialPeriod?: string;
  introductoryPrice?: string;
}

// ==================== 华为IAP数据类型定义 ====================

// PurchaseData 购买数据
interface PurchaseData {
  type: number;
  jwsPurchaseOrder?: string;
  jwsSubscriptionStatus?: string;
  productId?: string;
}

// PurchaseOrderPayload 订单信息
interface PurchaseOrderPayload {
  environment?: string;
  purchaseOrderId: string;
  purchaseToken: string;
  applicationId?: string;
  productId?: string;
  productType: string;
  quantity?: number;
  purchaseTime?: number;
  finishStatus?: string;
  needFinish?: boolean;
  price?: number;
  currency?: string;
  developerPayload?: string;
  purchaseOrderRevocationReasonCode?: string;
  revocationTime?: number;
  offerTypeCode?: string;
  offerId?: string;
  countryCode?: string;
  signedTime?: number;
  subGroupGenerationId?: string;
  subscriptionId?: string;
  subGroupId?: string;
  duration?: string;
  durationTypeCode?: string;
}

// 续期信息
interface SubRenewalInfo {
  environment?: string;
  subGroupGenerationId?: string;
  nextRenewPeriodProductId?: string;
  productId?: string;
  autoRenewStatusCode?: string;
  hasInBillingRetryPeriod?: boolean;
  priceIncreaseStatusCode?: string;
  offerTypeCode?: string;
  offerId?: string;
  renewalPrice?: number;
  currency?: string;
  renewalTime?: number;
  expirationIntent?: string;
}

// 订阅状态
interface SubscriptionStatusDetail {
  subGroupGenerationId?: string;
  subscriptionId?: string;
  purchaseToken?: string;
  status?: string;
  expiresTime?: number;
  productId?: string;
  lastPurchaseOrder?: PurchaseOrderPayload;
  recentPurchaseOrderList?: PurchaseOrderPayload[];
  renewalInfo?: SubRenewalInfo;
}

// SubGroupStatusPayload 订阅组状态
interface SubGroupStatusPayload {
  environment?: string;
  applicationId?: string;
  packageName?: string;
  subGroupId?: string;
  lastSubscriptionStatus?: SubscriptionStatusDetail;
  historySubscriptionStatusList?: SubscriptionStatusDetail[];
}

// QueryPurchaseResult 购买查询结果
interface QueryPurchaseResult {
  purchaseDataList: string[];
}

// ==================== 业务接口定义 ====================

interface LegacyCheckResult {
  has: boolean;
  days: number;
}

interface SubscriptionStatus {
  hasSubscription: boolean;
  expireTime: number;
  autoRenew: boolean;
  productId?: string;
  isInTrial?: boolean;
  status?: string;
}

export interface ConvertResult {
  success: boolean;
  type: string;
  message: string;
}

interface OfferInfo {
  offerId: string;
  months: number;
}

export class VipService {
  private context: common.UIAbilityContext;
  private pref: dataPreferences.Preferences | null = null;
  private iapAvailable: boolean = true;

  constructor(context: Context) {
    this.context = context as common.UIAbilityContext;
  }

  async init(): Promise<void> {
    // 1. 检查IAP环境可用性
    this.iapAvailable = await this.checkEnvironmentStatus();
    if (!this.iapAvailable) {
      console.warn('[VipService] IAP环境不可用，隐藏相关功能');
      return;
    }

    this.pref = await dataPreferences.getPreferences(this.context, 'vip_legacy');
    
    // 2. 查询并处理生效中的订阅权益（应用启动时）
    await this.checkCurrentEntitlements();
    
    // 3. 检查未完成订单（掉单补偿）
    await this.checkUnfinishedPurchases();
    
    // 4. 恢复非消耗型商品权益
    await this.restoreNonConsumableEntitlements();
  }

  /**
   * 【环境检查】检查IAP Kit可用性
   * queryEnvironmentStatus 返回 Promise<void>
   */
  async checkEnvironmentStatus(): Promise<boolean> {
    try {
      await iap.queryEnvironmentStatus(this.context);
      console.info('[环境检查] IAP环境可用');
      return true;
    } catch (err) {
      console.error('[环境检查] IAP环境不可用:', err);
      return false;
    }
  }

  isIapAvailable(): boolean {
    return this.iapAvailable;
  }

  /**
   * 【展示商品】查询订阅商品信息
   * queryProducts 返回 Promise<Array<Product>>
   */
  async querySubscriptionProducts(productIds: string[]): Promise<SubscriptionProduct[]> {
    if (!this.iapAvailable) {
      return [];
    }

    try {
      // queryProducts 返回 Product[]，使用 iap.Product 类型
      const result = await iap.queryProducts(this.context, {
        productType: iap.ProductType.AUTORENEWABLE,
        productIds: productIds
      });

      // 映射 Product 到 SubscriptionProduct
      return (result || []).map((p: iap.Product): SubscriptionProduct => ({
        productId: p.id,
        productName: p.name,
        priceType: p.type,
        price: p.localPrice || p.price,
        currency: p.currency,
        productDesc: p.description,
        subscriptionPeriod: p.subscriptionInfo ? `${p.subscriptionInfo.periodCount} ${p.subscriptionInfo.periodUnit}` : undefined,
        freeTrialPeriod: p.subscriptionInfo?.introductoryOffer ? 
          `${p.subscriptionInfo.introductoryOffer.periodCount} ${p.subscriptionInfo.introductoryOffer.periodUnit}` : undefined,
        introductoryPrice: p.subscriptionInfo?.introductoryOffer?.localPrice
      }));
    } catch (err) {
      console.error('[商品查询] 查询订阅商品失败:', err);
      return [];
    }
  }

  /**
   * 【对生效中的订阅发放权益】应用启动时处理
   */
  private async checkCurrentEntitlements(): Promise<void> {
    try {
      console.info('[权益发放] 检查生效中的订阅...');
      
      const result = await iap.queryPurchases(this.context, {
        productType: iap.ProductType.AUTORENEWABLE,
        queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
      }) as QueryPurchaseResult;

      const purchaseDataList: string[] = result.purchaseDataList;
      if (!purchaseDataList || purchaseDataList.length === 0) {
        console.info('[权益发放] 当前无生效中的订阅');
        return;
      }

      for (let i = 0; i < purchaseDataList.length; i++) {
        const purchaseDataObj: PurchaseData = JSON.parse(purchaseDataList[i]) as PurchaseData;
        
        if (!purchaseDataObj.jwsSubscriptionStatus) {
          continue;
        }

        const payload = this.decodeJws(purchaseDataObj.jwsSubscriptionStatus) as SubGroupStatusPayload;
        if (!payload || !payload.lastSubscriptionStatus) {
          console.error('[权益发放] JWS 解码失败或数据结构异常');
          continue;
        }

        const lastStatus = payload.lastSubscriptionStatus;
        
        // 检查订阅状态：status='1' 表示生效状态
        if (lastStatus.status !== '1') {
          console.info('[权益发放] 订阅未生效，跳过:', lastStatus.productId);
          continue;
        }

        console.info('[权益发放] 生效订阅:', lastStatus.productId, 
          '到期时间:', new Date(lastStatus.expiresTime || 0).toLocaleString());

        await this.grantSubscriptionBenefits(lastStatus);

        const lastOrder = lastStatus.lastPurchaseOrder;
        if (lastOrder && lastOrder.finishStatus !== '1') {
          console.info('[权益发放] 订单未确认发货，执行finishPurchase:', lastOrder.purchaseOrderId);
          await this.finishSubscriptionPurchase(lastOrder);
        }
      }
    } catch (err) {
      console.error('[权益发放] 检查生效订阅失败:', err);
    }
  }

  /**
   * 【发放订阅权益】
   */
  private async grantSubscriptionBenefits(lastStatus: SubscriptionStatusDetail): Promise<void> {
    await this.pref?.put('subscription_product_id', lastStatus.productId || '');
    await this.pref?.put('subscription_expire_time', lastStatus.expiresTime || 0);
    await this.pref?.put('subscription_status', lastStatus.status || '');
    await this.pref?.put('has_active_subscription', true);
    await this.pref?.flush();

    console.info('[权益发放] 已发放订阅权益:', lastStatus.productId);
  }

  /**
   * 【确认发货】完成订阅购买流程
   */
  private async finishSubscriptionPurchase(purchaseOrder: PurchaseOrderPayload): Promise<boolean> {
    try {
      const finishParam: iap.FinishPurchaseParameter = {
        productType: Number(purchaseOrder.productType) || iap.ProductType.AUTORENEWABLE,
        purchaseToken: purchaseOrder.purchaseToken,
        purchaseOrderId: purchaseOrder.purchaseOrderId
      };
      
      await iap.finishPurchase(this.context, finishParam);
      
      console.info('[确认发货] 订阅订单已确认发货:', purchaseOrder.purchaseOrderId);
      return true;
    } catch (err) {
      console.error('[确认发货] 订阅订单确认发货失败:', err);
      return false;
    }
  }

  /**
   * 【掉单补偿】检查未完成订单
   */
  private async checkUnfinishedPurchases(): Promise<void> {
    try {
      console.info('[掉单补偿] 检查未完成订单...');
      
      await this.queryAndProcessUnfinished(iap.ProductType.AUTORENEWABLE);
      await this.queryAndProcessUnfinished(iap.ProductType.NONCONSUMABLE);
      
    } catch (err) {
      console.error('[掉单补偿] 检查未完成订单失败:', err);
    }
  }

  /**
   * 查询并处理未完成订单
   */
  private async queryAndProcessUnfinished(productType: iap.ProductType): Promise<void> {
    try {
      const result = await iap.queryPurchases(this.context, {
        productType: productType,
        queryType: iap.PurchaseQueryType.UNFINISHED
      }) as QueryPurchaseResult;

      const purchaseDataList: string[] = result.purchaseDataList;
      if (!purchaseDataList || purchaseDataList.length === 0) {
        return;
      }

      console.info(`[掉单补偿] 发现 ${purchaseDataList.length} 个未完成订单`);

      for (let i = 0; i < purchaseDataList.length; i++) {
        const purchaseDataObj: PurchaseData = JSON.parse(purchaseDataList[i]) as PurchaseData;
        
        if (productType === iap.ProductType.AUTORENEWABLE) {
          if (!purchaseDataObj.jwsSubscriptionStatus) continue;
          
          const payload = this.decodeJws(purchaseDataObj.jwsSubscriptionStatus) as SubGroupStatusPayload;
          if (!payload?.lastSubscriptionStatus) continue;

          const lastStatus = payload.lastSubscriptionStatus;
          
          if (lastStatus.status === '1') {
            await this.grantSubscriptionBenefits(lastStatus);
            
            const lastOrder = lastStatus.lastPurchaseOrder;
            if (lastOrder && lastOrder.finishStatus !== '1') {
              await this.finishSubscriptionPurchase(lastOrder);
            }
          }
        } else {
          if (!purchaseDataObj.jwsPurchaseOrder) continue;
          
          const purchaseOrder = this.decodeJws(purchaseDataObj.jwsPurchaseOrder) as PurchaseOrderPayload;
          if (!purchaseOrder) continue;

          if (purchaseOrder.purchaseOrderRevocationReasonCode) {
            console.info('[掉单补偿] 订单已撤销，跳过:', purchaseOrder.purchaseOrderId);
            continue;
          }

          if (purchaseOrder.finishStatus === '1') {
            console.info('[掉单补偿] 订单已发货，跳过:', purchaseOrder.purchaseOrderId);
            continue;
          }

          await this.deliverNonConsumable(purchaseOrder);
        }
      }
    } catch (err) {
      console.error('[掉单补偿] 处理失败:', err);
    }
  }

  /**
   * 【权益恢复】恢复非消耗型商品权益
   */
  private async restoreNonConsumableEntitlements(): Promise<void> {
    try {
      console.info('[权益恢复] 恢复非消耗型商品权益...');
      
      const result = await iap.queryPurchases(this.context, {
        productType: iap.ProductType.NONCONSUMABLE,
        queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
      }) as QueryPurchaseResult;

      const purchaseDataList: string[] = result.purchaseDataList;
      if (!purchaseDataList || purchaseDataList.length === 0) {
        console.info('[权益恢复] 没有非消耗型商品权益需要恢复');
        return;
      }

      for (let i = 0; i < purchaseDataList.length; i++) {
        const purchaseDataObj: PurchaseData = JSON.parse(purchaseDataList[i]) as PurchaseData;
        
        if (!purchaseDataObj.jwsPurchaseOrder) continue;

        const purchaseOrder = this.decodeJws(purchaseDataObj.jwsPurchaseOrder) as PurchaseOrderPayload;
        if (!purchaseOrder) continue;

        console.info('[权益恢复] 恢复权益:', purchaseOrder.purchaseOrderId);
        
        if (purchaseOrder.finishStatus !== '1') {
          await this.deliverNonConsumable(purchaseOrder);
        }
        
        await this.recordNonConsumableEntitlement(purchaseOrder);
      }
    } catch (err) {
      console.error('[权益恢复] 恢复失败:', err);
    }
  }

  /**
   * 发放非消耗型商品权益
   */
  private async deliverNonConsumable(purchaseOrder: PurchaseOrderPayload): Promise<boolean> {
    try {
      console.info('[权益发放] 发放非消耗型权益:', purchaseOrder.purchaseOrderId);
      
      const finishParam: iap.FinishPurchaseParameter = {
        productType: Number(purchaseOrder.productType) || iap.ProductType.NONCONSUMABLE,
        purchaseToken: purchaseOrder.purchaseToken,
        purchaseOrderId: purchaseOrder.purchaseOrderId
      };
      
      await iap.finishPurchase(this.context, finishParam);
      
      console.info('[权益发放] 非消耗型权益发放成功');
      return true;
    } catch (err) {
      console.error('[权益发放] 非消耗型权益发放失败:', err);
      return false;
    }
  }

  /**
   * 记录非消耗型商品权益到本地
   */
  private async recordNonConsumableEntitlement(purchaseOrder: PurchaseOrderPayload): Promise<void> {
    await this.pref?.put('has_permanent_vip', true);
    await this.pref?.put('permanent_vip_order_id', purchaseOrder.purchaseOrderId);
    await this.pref?.flush();
  }

  /**
   * 【购买失败处理】
   */
  async handlePurchaseError(err: BusinessError): Promise<void> {
    if (err.code === iap.IAPErrorCode.PRODUCT_OWNED || 
        err.code === iap.IAPErrorCode.SYSTEM_ERROR) {
      console.info('[购买失败处理] 检测到错误码:', err.code, '，检查补发货...');
      await this.checkUnfinishedPurchases();
    }
  }

  async hasLegacyVoucher(): Promise<LegacyCheckResult> {
    const converted = (await this.pref?.get('legacy_converted', false)) as boolean;
    if (converted) {
      return { has: false, days: 0 };
    }

    const expireTime = (await this.pref?.get('local_expire_time', 0)) as number;
    if (expireTime <= 0) {
      return { has: false, days: 0 };
    }

    const now = Date.now();
    if (expireTime <= now) {
      await this.markLegacyConverted();
      return { has: false, days: 0 };
    }

    const days = Math.ceil((expireTime - now) / (24 * 60 * 60 * 1000));
    return { has: days > 0, days };
  }

  private async markLegacyConverted(): Promise<void> {
    await this.pref?.put('legacy_converted', true);
    await this.pref?.put('legacy_converted_at', Date.now());
    await this.pref?.flush();
  }

  /**
   * 【查询订阅状态】
   */
  async querySubscriptionStatus(): Promise<SubscriptionStatus> {
    try {
      const result = await iap.queryPurchases(this.context, {
        productType: iap.ProductType.AUTORENEWABLE,
        queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
      }) as QueryPurchaseResult;

      if (!result.purchaseDataList || result.purchaseDataList.length === 0) {
        return { hasSubscription: false, expireTime: 0, autoRenew: false };
      }

      const purchaseDataObj: PurchaseData = JSON.parse(result.purchaseDataList[0]) as PurchaseData;
      const payload = this.decodeJws(purchaseDataObj.jwsSubscriptionStatus || '') as SubGroupStatusPayload;
      
      if (!payload?.lastSubscriptionStatus) {
        return { hasSubscription: false, expireTime: 0, autoRenew: false };
      }

      const lastStatus = payload.lastSubscriptionStatus;
      const now = Date.now();
      const expiresTime = lastStatus.expiresTime || 0;
      const isActive = lastStatus.status === '1' && expiresTime > now;
      
      return {
        hasSubscription: isActive,
        expireTime: expiresTime,
        autoRenew: lastStatus.renewalInfo?.autoRenewStatusCode === '1',
        productId: lastStatus.productId,
        status: lastStatus.status,
        isInTrial: this.isInTrialPeriod(lastStatus)
      };
    } catch (err) {
      console.error('[订阅状态] 查询失败:', err);
      return { hasSubscription: false, expireTime: 0, autoRenew: false };
    }
  }

  /**
   * 判断是否处于试用期
   */
  private isInTrialPeriod(lastStatus: SubscriptionStatusDetail): boolean {
    return false;
  }

  /**
   * 检查是否可以购买指定商品
   */
  async canPurchaseProduct(productId: string): Promise<boolean> {
    const subStatus = await this.querySubscriptionStatus();
    
    if (subStatus.hasSubscription && 
        subStatus.autoRenew && 
        subStatus.productId === productId) {
      console.info('[购买检查] 已有生效中的自动续期订阅:', productId);
      return false;
    }
    
    return true;
  }

  async hasActiveSubscription(): Promise<boolean> {
    const status = await this.querySubscriptionStatus();
    return status.hasSubscription;
  }

  async checkPermanentStatus(): Promise<boolean> {
    try {
      const result = await iap.queryPurchases(this.context, {
        productType: iap.ProductType.NONCONSUMABLE,
        queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
      }) as QueryPurchaseResult;
      
      if (result.purchaseDataList) {
        for (let i = 0; i < result.purchaseDataList.length; i++) {
          const purchaseDataObj: PurchaseData = JSON.parse(result.purchaseDataList[i]) as PurchaseData;
          if (purchaseDataObj.productId === 'vip_permanent') {
            return true;
          }
        }
      }
      return false;
    } catch (err) {
      return false;
    }
  }

  async getVipStatus(): Promise<VipStatus> {
    const isPermanent = await this.checkPermanentStatus();
    if (isPermanent) {
      return {
        isVip: true,
        source: VipSource.PERMANENT,
        isPermanent: true,
        autoRenew: false,
        expireTime: 0,
        hasLegacyVoucher: false,
        legacyDays: 0
      };
    }

    const subStatus = await this.querySubscriptionStatus();
    if (subStatus.hasSubscription) {
      return {
        isVip: true,
        source: VipSource.SUBSCRIPTION,
        expireTime: subStatus.expireTime,
        autoRenew: subStatus.autoRenew,
        isPermanent: false,
        hasLegacyVoucher: false,
        legacyDays: 0
      };
    }

    const legacy = await this.hasLegacyVoucher();

    return {
      isVip: false,
      source: VipSource.NONE,
      isPermanent: false,
      autoRenew: false,
      expireTime: 0,
      hasLegacyVoucher: legacy.has,
      legacyDays: legacy.days
    };
  }

  async convertLegacyVoucher(): Promise<ConvertResult> {
    const legacy = await this.hasLegacyVoucher();
    if (!legacy.has) {
      return { success: false, type: '', message: '没有可转换的本地会员' };
    }

    if (legacy.days > 1095) {
      return this.convertToPermanent();
    } else {
      return this.convertToSubscription(legacy.days);
    }
  }

  private async convertToPermanent(): Promise<ConvertResult> {
    try {
      const result = await iap.createPurchase(this.context, {
        productId: 'vip_permanent',
        productType: iap.ProductType.NONCONSUMABLE,
        developerPayload: JSON.stringify({
          type: 'legacy_convert',
          timestamp: Date.now()
        })
      });

      return await this.handlePurchaseResult(result, iap.ProductType.NONCONSUMABLE, 'permanent');
    } catch (err) {
      console.error('转换永久会员失败:', err);
      await this.handlePurchaseError(err as BusinessError);
      return { success: false, type: '', message: '转换失败，请重试' };
    }
  }

  private async convertToSubscription(days: number): Promise<ConvertResult> {
    try {
      const result = await iap.createPurchase(this.context, {
        productId: 'vip_monthly',
        productType: iap.ProductType.AUTORENEWABLE,
        developerPayload: JSON.stringify({
          type: 'legacy_convert',
          originalDays: days,
          timestamp: Date.now()
        })
      });

      return await this.handlePurchaseResult(result, iap.ProductType.AUTORENEWABLE, 'subscription');
    } catch (err) {
      console.error('转换订阅失败:', err);
      await this.handlePurchaseError(err as BusinessError);
      return { success: false, type: '', message: '转换失败，请重试' };
    }
  }

  /**
   * 【处理购买结果】
   */
  private async handlePurchaseResult(
    result: iap.CreatePurchaseResult, 
    productType: iap.ProductType,
    type: string
  ): Promise<ConvertResult> {
    const purchaseDataObj: PurchaseData = JSON.parse(result.purchaseData) as PurchaseData;
    
    if (productType === iap.ProductType.AUTORENEWABLE) {
      const jwsString = purchaseDataObj.jwsSubscriptionStatus;
      if (!jwsString) {
        return { success: false, type: '', message: '订阅数据异常' };
      }

      const payload = this.decodeJws(jwsString) as SubGroupStatusPayload;
      if (!payload?.lastSubscriptionStatus) {
        return { success: false, type: '', message: '订阅验证失败' };
      }

      const lastStatus = payload.lastSubscriptionStatus;
      
      if (lastStatus.status !== '1') {
        return { success: false, type: '', message: '订阅未生效' };
      }

      await this.grantSubscriptionBenefits(lastStatus);

      const lastOrder = lastStatus.lastPurchaseOrder;
      if (lastOrder && lastOrder.finishStatus !== '1') {
        await this.finishSubscriptionPurchase(lastOrder);
      }

      await this.markLegacyConverted();
      return {
        success: true,
        type: 'subscription',
        message: '已成功转为订阅会员'
      };
    } else {
      const jwsString = purchaseDataObj.jwsPurchaseOrder;
      if (!jwsString) {
        return { success: false, type: '', message: '购买数据异常' };
      }

      const purchaseOrder = this.decodeJws(jwsString) as PurchaseOrderPayload;
      if (!purchaseOrder) {
        return { success: false, type: '', message: '订单验证失败' };
      }

      if (purchaseOrder.purchaseOrderRevocationReasonCode) {
        return { success: false, type: '', message: '订单已撤销' };
      }

      const delivered = await this.deliverNonConsumable(purchaseOrder);
      
      if (delivered) {
        await this.markLegacyConverted();
        return {
          success: true,
          type: 'permanent',
          message: '已成功转为永久会员'
        };
      } else {
        return { success: false, type: '', message: '权益发放失败' };
      }
    }
  }

  /**
   * JWS 解码
   */
  private decodeJws(jwsString: string): object | null {
    try {
      const parts = jwsString.split('.');
      if (parts.length !== 3) return null;
      
      let base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      while (base64.length % 4) base64 += '=';
      
      const decoded = buffer.from(base64, 'base64').toString('utf-8');
      return JSON.parse(decoded);
    } catch (e) {
      console.error('JWS 解码失败:', e);
      return null;
    }
  }

  private selectOfferByDays(days: number): OfferInfo {
    if (days <= 89) return { offerId: 'offer_legacy_3m', months: 3 };
    if (days <= 179) return { offerId: 'offer_legacy_6m', months: 6 };
    if (days <= 364) return { offerId: 'offer_legacy_1y', months: 12 };
    if (days <= 729) return { offerId: 'offer_legacy_2y', months: 24 };
    return { offerId: 'offer_legacy_3y', months: 36 };
  }

  async startFreeTrial(): Promise<boolean> {
    if (!await this.canPurchaseProduct('vip_monthly')) {
      console.warn('[免费试用] 已存在生效中的订阅');
      return false;
    }

    try {
      const result = await iap.createPurchase(this.context, {
        productId: 'vip_monthly',
        productType: iap.ProductType.AUTORENEWABLE,
        developerPayload: JSON.stringify({ offerId: 'offer_trial_7d' })
      });

      return await this.processPurchaseResult(result, iap.ProductType.AUTORENEWABLE);
    } catch (err) {
      console.error('试用失败:', err);
      await this.handlePurchaseError(err as BusinessError);
      return false;
    }
  }

  async purchaseSubscription(productId: string): Promise<boolean> {
    if (!await this.canPurchaseProduct(productId)) {
      console.warn('[购买订阅] 已存在生效中的相同订阅');
      return false;
    }

    try {
      const result = await iap.createPurchase(this.context, {
        productId: productId,
        productType: iap.ProductType.AUTORENEWABLE
      });

      return await this.processPurchaseResult(result, iap.ProductType.AUTORENEWABLE);
    } catch (err) {
      console.error('购买失败:', err);
      await this.handlePurchaseError(err as BusinessError);
      return false;
    }
  }

  /**
   * 处理购买结果（简化版）
   */
  private async processPurchaseResult(
    result: iap.CreatePurchaseResult, 
    productType: iap.ProductType
  ): Promise<boolean> {
    const purchaseDataObj: PurchaseData = JSON.parse(result.purchaseData) as PurchaseData;
    
    if (productType === iap.ProductType.AUTORENEWABLE) {
      const jwsString = purchaseDataObj.jwsSubscriptionStatus;
      if (!jwsString) return false;

      const payload = this.decodeJws(jwsString) as SubGroupStatusPayload;
      if (!payload?.lastSubscriptionStatus) return false;

      const lastStatus = payload.lastSubscriptionStatus;
      if (lastStatus.status !== '1') return false;

      await this.grantSubscriptionBenefits(lastStatus);

      const lastOrder = lastStatus.lastPurchaseOrder;
      if (lastOrder && lastOrder.finishStatus !== '1') {
        await this.finishSubscriptionPurchase(lastOrder);
      }
      return true;
    } else {
      const jwsString = purchaseDataObj.jwsPurchaseOrder;
      if (!jwsString) return false;

      const purchaseOrder = this.decodeJws(jwsString) as PurchaseOrderPayload;
      if (!purchaseOrder) return false;

      return await this.deliverNonConsumable(purchaseOrder);
    }
  }
}
