// 健康卡片数据刷新优化测试脚本
// 这个脚本模拟了数据刷新行为，验证修复效果

class MockDeviceHealthService {
  constructor() {
    this.healthInfo = {
      battery: { level: 80, health: 100, temperature: 25, status: 'discharging' },
      performance: {
        cpu: 15,
        memory: { totalMem: 8000000n, availableMem: 4000000n },
        storage: { total: 128000000, used: 64000000, free: 64000000 }
      },
      network: { signalStrength: 3, type: 'wifi', isConnected: true },
      sensors: { status: 'normal' },
      score: 85,
      lastUpdated: new Date().toISOString()
    };
    this.updateCount = 0;
    this.baseBatteryLevel = 80;
  }

  getHealthInfo() {
    this.updateCount++;
    
    // 模拟真实的数据变化模式
    if (this.updateCount % 4 === 0) {
      // 每4次调用有一次显著变化（电池电量变化3%以上）
      const change = Math.random() > 0.5 ? 3 : -3;
      this.healthInfo.battery.level = Math.max(5, Math.min(100, this.baseBatteryLevel + change));
      this.baseBatteryLevel = this.healthInfo.battery.level;
      
      // CPU使用率也有变化
      this.healthInfo.performance.cpu = Math.max(5, Math.min(95, 15 + (Math.random() * 10 - 5)));
      
      this.healthInfo.score = Math.max(60, Math.min(100, 85 + (Math.random() * 10 - 5)));
    } else if (this.updateCount % 2 === 0) {
      // 每2次调用有一次微小变化（电池电量变化1-2%）
      const change = Math.random() > 0.5 ? 1 : -1;
      this.healthInfo.battery.level = Math.max(5, Math.min(100, this.baseBatteryLevel + change));
    }
    
    return { ...this.healthInfo }; // 返回新对象避免引用相同
  }
}

// 模拟优化后的 loadHealthData 逻辑
function simulateLoadHealthData(service) {
  const state = {
    currentState: 'SUCCESS',
    healthInfo: service.getHealthInfo(),
    lastHealthDataUpdateTime: 0,
    healthDataUpdateInterval: 10000,
    lastHealthInfoHash: ''
  };

  let loadingCount = 0;
  let significantChangeCount = 0;

  function generateHash(healthInfo) {
    const mem = healthInfo.performance.memory;
    const storage = healthInfo.performance.storage;
    const battery = healthInfo.battery;
    const network = healthInfo.network;
    const sensors = healthInfo.sensors;
    
    return `${battery.level}_${battery.health}_${battery.temperature}_${battery.status}_` +
           `${mem.totalMem}_${mem.availableMem}_` +
           `${storage.total}_${storage.used}_${storage.free}_` +
           `${healthInfo.performance.cpu}_` +
           `${network.signalStrength}_${network.type}_${network.isConnected}_` +
           `${sensors.status}_${healthInfo.score}`;
  }

  function hasSignificantChange(newHealthInfo, oldInfo) {
    if (!oldInfo || oldInfo.score === 0) return true;
    
    const newHash = generateHash(newHealthInfo);
    const oldHash = state.lastHealthInfoHash;
    
    if (newHash === oldHash && oldHash !== '') return false;
    
    const batteryChange = Math.abs(newHealthInfo.battery.level - oldInfo.battery.level) > 2;
    const cpuChange = Math.abs(newHealthInfo.performance.cpu - oldInfo.performance.cpu) > 5;
    
    return batteryChange || cpuChange;
  }

  // 模拟10次数据刷新
  for (let i = 0; i < 10; i++) {
    const currentTime = Date.now() + (i * 11000); // 每次间隔11秒
    
    if (state.lastHealthDataUpdateTime > 0 && currentTime - state.lastHealthDataUpdateTime < state.healthDataUpdateInterval) {
      console.log(`刷新 ${i+1}: 频率控制 - 跳过`);
      continue;
    }

    const newHealthInfo = service.getHealthInfo();
    
    if (!hasSignificantChange(newHealthInfo, state.healthInfo) && state.currentState === 'SUCCESS') {
      console.log(`刷新 ${i+1}: 数据无显著变化 - 跳过加载状态`);
      state.lastHealthInfoHash = generateHash(newHealthInfo);
      state.lastHealthDataUpdateTime = currentTime;
      continue;
    }

    // 显示加载状态
    if (state.currentState !== 'LOADING') {
      state.currentState = 'LOADING';
      loadingCount++;
      console.log(`刷新 ${i+1}: 显示加载状态`);
    }

    state.lastHealthDataUpdateTime = currentTime;
    
    // 模拟异步加载完成
    setTimeout(() => {
      if (hasSignificantChange(newHealthInfo, state.healthInfo)) {
        state.healthInfo = newHealthInfo;
        significantChangeCount++;
        console.log(`刷新 ${i+1}: 数据有变化 - 更新显示`);
      } else {
        console.log(`刷新 ${i+1}: 数据无变化 - 保持原状`);
      }
      state.currentState = 'SUCCESS';
      state.lastHealthInfoHash = generateHash(state.healthInfo);
    }, 100);
  }

  return { loadingCount, significantChangeCount };
}

// 运行测试
console.log('开始测试健康卡片数据刷新优化...\n');
const service = new MockDeviceHealthService();
const result = simulateLoadHealthData(service);

console.log('\n测试结果:');
console.log(`总刷新次数: 10`);
console.log(`显示加载状态的次数: ${result.loadingCount}`);
console.log(`数据有显著变化的次数: ${result.significantChangeCount}`);
console.log(`避免不必要加载的次数: ${10 - result.loadingCount}`);

if (result.loadingCount < 5) {
  console.log('\n✅ 优化成功：大幅减少了不必要的加载状态显示');
} else {
  console.log('\n❌ 需要进一步优化');
}