# Typst 简历 Marketplace

一个 Claude Code 插件，从自由格式的 Markdown 简历生成精美 PDF。在浏览器中用你的真实简历数据预览 5 套模板，点击选择后一键编译。

## 工作流程

```
Markdown 简历 → AI 解析 → 5 套模板预览 → 浏览器选择 → PDF + .typ + JSON
```

### 四阶段流程

1. **解析** — AI 读取你的 Markdown 简历，提取结构化 JSON（无需特殊格式）
2. **预览** — 用你的真实数据编译 5 套模板的 SVG 预览
3. **选择** — 打开本地浏览器页面，点击选择模板
4. **编译** — 输出三件套：PDF、Typst 源码、JSON 数据

## 模板

| 模板 | 风格 |
|------|------|
| 经典 (Classic) | 单栏布局，居中头部，分隔线分区 |
| 现代 (Modern) | 深色侧栏 + 蓝色强调色，技能进度条 |
| 极简 (Minimal) | 大量留白，字重灰度建立层次 |
| 双栏 (Two-Column) | 左栏联系方式和技能，右栏主要经历 |
| 学术 (Academic) | 衬线字体，smallcaps 标题，学术风格 |

## 安装

```bash
/plugin marketplace add Aryous/typst-resume-marketplace
/plugin install typst-resume@typst-resume-marketplace
```

### 前置依赖

- [Typst](https://typst.app/) >= 0.14（`brew install typst`）
- Python 3（macOS 自带）

## 使用

```
/typst-resume
```

也可以自然语言触发：

> "帮我把 resume.md 排版成好看的 PDF"

当你提到简历制作、简历排版、typst 简历、resume PDF 等关键词时，Skill 会自动触发。

## 输出

所有产出物位于工作目录下的 `tpr-output/final/`：

```
tpr-output/final/
├── resume-modern-20260402-154530.pdf    # 最终 PDF
├── resume-modern-20260402-154530.typ    # Typst 源码（可手动编辑）
└── resume-modern-20260402-154530.json   # 结构化数据（可换模板重新生成）
```

文件命名格式：`resume-{模板}-{yyyymmdd}-{HHmmss}.{ext}`

## 添加模板

1. 在 `plugins/typst-resume/skills/typst-resume/assets/templates/` 下创建 `.typ` 文件
2. 导入共用转换器：`#import "lib/markdown.typ": render-md`
3. 通过 `json(bytes(sys.inputs.at("resume-data")))` 读取数据
4. 遵循 `references/resume-schema.md` 中的 JSON 数据契约

## 许可证

MIT
