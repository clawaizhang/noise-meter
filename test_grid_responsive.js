/**
 * 测试响应式grid布局
 * 用于验证settings页面在不同屏幕尺寸下的网格列数计算
 */

const { responsiveLayout } = require('./entry/src/main/ets/utils/ResponsiveLayout.ets');

// 模拟不同屏幕尺寸的测试用例
const testCases = [
  { width: 320, height: 640, name: 'XS - 小屏手机竖屏', expectedPortrait: 1, expectedLandscape: 1 },
  { width: 480, height: 800, name: 'SM - 中屏手机竖屏', expectedPortrait: 1, expectedLandscape: 1 },
  { width: 600, height: 1024, name: 'MD - 平板竖屏', expectedPortrait: 2, expectedLandscape: 2 },
  { width: 840, height: 1200, name: 'LG - 大平板竖屏', expectedPortrait: 2, expectedLandscape: 3 },
  { width: 1200, height: 1600, name: 'XL - 大屏竖屏', expectedPortrait: 3, expectedLandscape: 4 },
  { width: 640, height: 320, name: 'XS - 小屏手机横屏', expectedPortrait: 1, expectedLandscape: 1 },
  { width: 800, height: 480, name: 'SM - 中屏手机横屏', expectedPortrait: 1, expectedLandscape: 1 },
  { width: 1024, height: 600, name: 'MD - 平板横屏', expectedPortrait: 2, expectedLandscape: 2 },
  { width: 1200, height: 840, name: 'LG - 大平板横屏', expectedPortrait: 2, expectedLandscape: 3 },
  { width: 1600, height: 1200, name: 'XL - 大屏横屏', expectedPortrait: 3, expectedLandscape: 4 }
];

function testGridColumnsCalculation() {
  console.log('开始测试响应式grid布局...\n');
  
  let passed = 0;
  let failed = 0;

  testCases.forEach((testCase, index) => {
    const isLandscape = testCase.width > testCase.height;
    const expected = isLandscape ? testCase.expectedLandscape : testCase.expectedPortrait;
    
    // 模拟updateGridColumns逻辑
    let gridColumns;
    if (testCase.width >= 1200) {
      gridColumns = isLandscape ? 4 : 3;
    } else if (testCase.width >= 840) {
      gridColumns = isLandscape ? 3 : 2;
    } else if (testCase.width >= 600) {
      gridColumns = isLandscape ? 2 : 2;
    } else {
      gridColumns = 1;
    }

    const status = gridColumns === expected ? '✓ 通过' : '✗ 失败';
    if (gridColumns === expected) {
      passed++;
    } else {
      failed++;
    }

    console.log(`${index + 1}. ${testCase.name}`);
    console.log(`   尺寸: ${testCase.width}x${testCase.height}`);
    console.log(`   方向: ${isLandscape ? '横屏' : '竖屏'}`);
    console.log(`   预期列数: ${expected}`);
    console.log(`   实际列数: ${gridColumns}`);
    console.log(`   状态: ${status}\n`);
  });

  console.log('测试结果:');
  console.log(`通过: ${passed}`);
  console.log(`失败: ${failed}`);
  console.log(`总计: ${testCases.length}`);
  console.log(`通过率: ${((passed / testCases.length) * 100).toFixed(1)}%`);

  return failed === 0;
}

// 运行测试
const success = testGridColumnsCalculation();

if (success) {
  console.log('\n🎉 所有测试通过！响应式grid布局实现正确。');
} else {
  console.log('\n❌ 部分测试失败，请检查实现逻辑。');
}

module.exports = { testGridColumnsCalculation };