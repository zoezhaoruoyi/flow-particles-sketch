# ✨ Flow Particles Sketch — 流动粒子画板

用手指在屏幕上画图形，松手后笔迹会变成流动的发光粒子，开启麦克风后粒子会跟着声音的节奏扭动。

## 在线体验

👉 **[点击体验 Demo](https://zoezhaoruoyi.github.io/flow-particles-sketch)**

## 效果说明

1. **手绘** — 手指触屏画线，笔头粗、笔尾细（类似无边记画笔）
2. **粒子化** — 松手后笔迹变成白色发光粒子，沿原来的轨迹轻柔飘动
3. **声音互动** — 开启麦克风后，说话或放音乐，粒子会像水波一样扩散扭曲，声音越大扭曲越强

## 项目结构

```
├── Web 版（React + Vite）
│   ├── App.tsx                 — 主界面 + 麦克风开关
│   ├── components/FlowCanvas   — 核心：触摸 + 粒子 + 渲染
│   ├── hooks/useAudioAnalyzer  — 声音采集
│   └── types.ts                — 数据类型
│
├── SwiftUI 版（iOS 15+）
│   ├── FlowParticlesApp        — App 入口
│   ├── FlowParticlesView       — 主界面 + Canvas 渲染
│   ├── ParticleGenerator       — 粒子生成
│   ├── AudioAnalyzer           — 声音采集
│   └── Models                  — 数据类型 + 常量
│
└── 技术文档
    └── 完整的公式和参数说明（见飞书文档）
```

## 本地运行（Web 版）

```bash
npm install
npm run dev
```

打开 http://localhost:3000 即可使用。

## Xcode 运行（SwiftUI 版）

1. 新建 iOS App 项目（SwiftUI）
2. 把 `swiftui/` 下的 5 个 `.swift` 文件拖入项目
3. 在 Info.plist 添加麦克风权限说明
4. 运行到 iPhone 或 iPad

## 核心参数

| 参数 | 值 | 作用 |
|------|-----|------|
| 粒子密度 | 每像素 25 个 | 画 200px 的线产生 5000 个粒子 |
| 波动速度 | 0.08 | 粒子自然飘动的速度 |
| 水波振幅 | 40px | 声音最大时的扭曲幅度 |
| 呼吸频率 | 3Hz | 粒子明暗闪烁的频率 |

## 三层粒子

- **Core（30%）** — 紧贴曲线的明亮小点
- **Dust（50%）** — 中等扩散的弥漫颗粒
- **Nebula（20%）** — 外围大范围的淡光雾

## 许可

MIT
