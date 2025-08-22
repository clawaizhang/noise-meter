// 测试布局模式计算
const DesignConstants = {
  METRIC_ITEM: { WIDTH: 100 },
  SPACING_MD: 12
};

function updateLayoutMode(width) {
  // 计算6个MetricItem所需的最小宽度（包括间距）
  const minWidthForLargeLayout = DesignConstants.METRIC_ITEM.WIDTH * 6 + DesignConstants.SPACING_MD * 5;
  
  let layoutMode;
  if (width >= minWidthForLargeLayout) {
    layoutMode = 'large';
  } else if (width >= DesignConstants.METRIC_ITEM.WIDTH * 3 + DesignConstants.SPACING_MD * 2) {
    layoutMode = 'medium';
  } else if (width >= DesignConstants.METRIC_ITEM.WIDTH * 2 + DesignConstants.SPACING_MD) {
    layoutMode = 'small';
  } else {
    layoutMode = 'xsmall';
  }
  
  console.log(`屏幕宽度: ${width}px, 布局模式: ${layoutMode}, 大屏最小宽度: ${minWidthForLargeLayout}px`);
  return layoutMode;
}

// 测试不同屏幕宽度
const testWidths = [400, 600, 800, 1000, 1200, 1400, 1600];

console.log('=== 布局模式测试 ===');
testWidths.forEach(width => {
  updateLayoutMode(width);
});

console.log('\n=== 详细计算 ===');
const minLarge = DesignConstants.METRIC_ITEM.WIDTH * 6 + DesignConstants.SPACING_MD * 5;
const minMedium = DesignConstants.METRIC_ITEM.WIDTH * 3 + DesignConstants.SPACING_MD * 2;
const minSmall = DesignConstants.METRIC_ITEM.WIDTH * 2 + DesignConstants.SPACING_MD;

console.log(`大屏模式最小宽度: ${minLarge}px (6个卡片 + 5个间距)`);
console.log(`中屏模式最小宽度: ${minMedium}px (3个卡片 + 2个间距)`);
console.log(`小屏模式最小宽度: ${minSmall}px (2个卡片 + 1个间距)`);