<template>
  <div class="ai-chat-page">
    <div class="ai-hero">
      <div class="hero-main">
        <h2>AI 财务助手</h2>
        <p>面向企业经营的智能问答与财务分析中枢</p>
      </div>
      <div class="hero-meta">
        <span class="hero-chip">实时对话</span>
        <span class="hero-chip">报表解读</span>
        <span class="hero-chip">预算建议</span>
      </div>
    </div>

    <a-row :gutter="16" class="ai-layout">
      <a-col :span="17" class="chat-col">
        <a-card :bordered="false" class="chat-shell">
          <div class="chat-topbar">
            <div class="topbar-title">
              <RobotOutlined />
              <span>智能财务对话</span>
            </div>
            <div class="topbar-state" :class="{ 'is-streaming': streaming || loading }">
              {{ streaming || loading ? '分析中' : '就绪' }}
            </div>
          </div>

          <div class="chat-messages" ref="messagesRef">
            <div v-if="messages.length === 0" class="chat-welcome">
              <div class="welcome-icon">
                <RobotOutlined />
              </div>
              <h3>你好，我是 F-AI 财务助手</h3>
              <p>输入你的问题，我将结合财务数据给出结论、原因和建议。</p>
              <div class="quick-questions">
                <button
                  v-for="q in quickQuestions"
                  :key="q"
                  type="button"
                  class="quick-q"
                  @click="sendQuickQuestion(q)"
                >
                  <BulbOutlined />
                  <span>{{ q }}</span>
                </button>
              </div>
            </div>

            <div v-for="(msg, idx) in messages" :key="idx" class="msg-row" :class="`msg-${msg.role}`">
              <div class="msg-avatar">
                <template v-if="msg.role === 'user'">
                  <a-avatar
                    :size="36"
                    class="user-avatar"
                    :class="{ 'avatar-type-image': userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image }"
                    :style="userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image ? {} : { background: userStore.avatarConfig.bgColor }"
                  >
                    <img
                      v-if="userStore.avatarConfig.type === 'image' && userStore.avatarConfig.image"
                      :src="userStore.avatarConfig.image"
                      alt="头像"
                    />
                    <span v-else class="avatar-letter">{{ userStore.userInfo?.username?.charAt(0)?.toUpperCase() || 'U' }}</span>
                  </a-avatar>
                </template>
                <template v-else>
                  <div class="ai-avatar">
                    <RobotOutlined />
                  </div>
                </template>
              </div>

              <div class="msg-bubble">
                <div class="msg-name">{{ msg.role === 'user' ? (userStore.userInfo?.username || '用户') : 'F-AI 助手' }}</div>
                <div class="msg-content markdown-body" v-html="renderMarkdown(msg.content)"></div>
                <span v-if="streaming && idx === messages.length - 1 && msg.role === 'assistant'" class="stream-cursor"></span>
              </div>
            </div>

            <div v-if="loading" class="msg-row msg-assistant">
              <div class="msg-avatar">
                <div class="ai-avatar">
                  <RobotOutlined />
                </div>
              </div>
              <div class="msg-bubble">
                <div class="msg-name">F-AI 助手</div>
                <div class="msg-content typing">
                  <span class="dot"></span><span class="dot"></span><span class="dot"></span>
                </div>
              </div>
            </div>
          </div>

          <div class="chat-input-area">
            <a-textarea
              v-model:value="inputText"
              :auto-size="{ minRows: 1, maxRows: 4 }"
              placeholder="输入你的财务问题..."
              @pressEnter="handleEnter"
              class="chat-input"
            />
            <a-button
              type="primary"
              class="btn-primary send-btn"
              @click="sendMessage"
              :loading="loading"
              :disabled="!inputText.trim() || loading || streaming"
            >
              <SendOutlined />
            </a-button>
          </div>
        </a-card>
      </a-col>

      <a-col :span="7" class="side-col">
        <a-card :bordered="false" class="side-panel guide-panel">
          <template #title>
            <div class="side-title">
              <QuestionCircleOutlined style="color: var(--primary);" /> 使用指南
            </div>
          </template>
          <div class="guide-list">
            <div class="guide-item" v-for="(g, i) in guides" :key="g.title">
              <div class="guide-num">{{ i + 1 }}</div>
              <div class="guide-text">
                <div class="guide-title">{{ g.title }}</div>
                <div class="guide-desc">{{ g.desc }}</div>
              </div>
            </div>
          </div>
        </a-card>

        <a-card :bordered="false" class="side-panel quick-panel" style="margin-top: 20px;">
          <template #title>
            <div class="side-title">
              <ThunderboltOutlined style="color: #f59e0b;" /> 快捷操作
            </div>
          </template>
          <a-space direction="vertical" style="width: 100%;">
            <a-button block class="btn-ghost quick-op-btn" @click="sendQuickQuestion('帮我分析最近的财务状况')">
              <BarChartOutlined /> 财务分析
            </a-button>
            <a-button block class="btn-ghost quick-op-btn" @click="sendQuickQuestion('有哪些异常数据需要重点关注？')">
              <WarningOutlined /> 异常排查
            </a-button>
            <a-button block class="btn-ghost quick-op-btn" @click="sendQuickQuestion('给我下个月的预算规划建议')">
              <WalletOutlined /> 预算规划
            </a-button>
            <a-button block class="btn-ghost quick-op-btn quick-op-btn--danger" @click="clearChat">
              <DeleteOutlined /> 清空对话
            </a-button>
          </a-space>
        </a-card>
      </a-col>
    </a-row>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue'
import { message } from 'ant-design-vue'
import {
  RobotOutlined,
  BulbOutlined,
  SendOutlined,
  QuestionCircleOutlined,
  ThunderboltOutlined,
  BarChartOutlined,
  WarningOutlined,
  WalletOutlined,
  DeleteOutlined,
} from '@ant-design/icons-vue'
import { useUserStore } from '@/stores/user'
import { aiApi } from '@/api/financial'
import MarkdownIt from 'markdown-it'

const md = new MarkdownIt({
  html: false,
  linkify: true,
  typographer: true,
  breaks: true,
})

const userStore = useUserStore()
const inputText = ref('')
const loading = ref(false)
const streaming = ref(false)
const messagesRef = ref<HTMLElement | null>(null)

interface ChatMessage {
  role: 'user' | 'assistant'
  content: string
}

const messages = ref<ChatMessage[]>([])

const quickQuestions = [
  '本月的收入和支出情况如何？',
  '最近有哪些财务异常需要关注？',
  '帮我分析一下利润变化趋势',
  '给我下个月的预算建议',
]

const guides = [
  { title: '财务查询', desc: '查询收入、支出、利润等核心指标' },
  { title: '趋势分析', desc: '了解财务数据的变化趋势' },
  { title: '异常解读', desc: '分析异常波动的原因与对策' },
  { title: '预算建议', desc: '获取 AI 生成的预算规划方案' },
]

function renderMarkdown(text: string): string {
  return md.render(normalizeAiContent(text))
}

function normalizeAiContent(text: string): string {
  let normalized = convertPlainTableBlocks(text)
  normalized = convertCodeLikeBlocks(normalized)
  normalized = sanitizeTechnicalCode(normalized)
  return normalized
}

function convertPlainTableBlocks(text: string): string {
  const lines = text.split('\n')
  const result: string[] = []
  let i = 0
  let inFence = false

  const amountRowPattern = /^(.+?)\s+([¥￥]?\d[\d,]*(?:\.\d+)?)\s+(.+?)\s+(.+)$/
  const amountLikePattern = /[¥￥]?\d[\d,]*(?:\.\d+)?/

  const isTableLikeLine = (line: string) => {
    const t = line.trim()
    if (!t) return false
    if (/^[-*]\s+/.test(t) || /^\d+\./.test(t)) return false
    if (amountRowPattern.test(t)) return true
    if (/[ \t]{2,}/.test(line)) return true
    if (/\s+/.test(t) && /[A-Za-z]/.test(t) && amountLikePattern.test(t)) return true
    return false
  }

  const splitCols = (line: string) => {
    const t = line.trim()
    const amountMatch = t.match(amountRowPattern)
    if (amountMatch) return [amountMatch[1], amountMatch[2], amountMatch[3], amountMatch[4]]
    if (/\t+|\s{2,}/.test(line)) return t.split(/\t+|\s{2,}/).map((x) => x.trim()).filter(Boolean)
    return t.split(/\s+/).map((x) => x.trim()).filter(Boolean)
  }

  while (i < lines.length) {
    const line = lines[i]
    if (line.trim().startsWith('```')) {
      inFence = !inFence
      result.push(line)
      i += 1
      continue
    }

    if (!inFence && isTableLikeLine(line)) {
      let j = i
      const block: string[] = []
      while (j < lines.length && isTableLikeLine(lines[j])) {
        block.push(lines[j])
        j += 1
      }

      if (block.length >= 3) {
        const header = splitCols(block[0])
        const rows = block.slice(1).map(splitCols)
        const valid = header.length >= 2 && rows.every((r) => r.length >= Math.max(2, header.length - 1))
        if (valid) {
          const fixedRows = rows.map((r) => {
            const copy = [...r]
            while (copy.length < header.length) copy.push('')
            return copy.slice(0, header.length)
          })
          result.push(`| ${header.join(' | ')} |`)
          result.push(`| ${header.map(() => '---').join(' | ')} |`)
          fixedRows.forEach((r) => result.push(`| ${r.join(' | ')} |`))
          i = j
          continue
        }
      }
    }

    result.push(line)
    i += 1
  }

  return result.join('\n')
}

function convertCodeLikeBlocks(text: string): string {
  const lines = text.split('\n')
  const result: string[] = []
  let i = 0
  let inFence = false

  const codeLine = (line: string) => {
    const t = line.trim()
    if (!t) return false
    if (/^(\||[-*]|\d+\.)/.test(t)) return false
    if (/(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|GROUP BY|ORDER BY|JOIN|CREATE|ALTER|DROP)\b/i.test(t)) return true
    if (/^["'{\[]/.test(t) || /^["']?\w+["']?\s*:\s*/.test(t)) return true
    if (/^<[^>]+>/.test(t) || /^<\/[^>]+>/.test(t)) return true
    if (/[{}[\];=<>]/.test(t) && /[A-Za-z_]/.test(t)) return true
    return false
  }

  const buildBusinessPlanBlock = (block: string[]) => {
    const cleaned = block.map((x) => x.trim()).filter(Boolean)
    const cue = cleaned.find(
      (line) =>
        /[\u4e00-\u9fa5]{4,}/.test(line) &&
        !/(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|JOIN|CREATE|ALTER|DROP|\{|\}|\[|\]|;|=>)/i.test(line)
    )
    const title = cue?.replace(/^[-*#>\d.\s]+/, '').slice(0, 30) || '围绕该问题建立数据跟踪与复盘机制'
    return [
      '> **业务执行方案（已隐藏技术代码）**',
      `> ${title}`,
      '> 1) 明确统计口径、时间范围与责任人',
      '> 2) 聚焦关键指标，设置预警阈值与触发条件',
      '> 3) 按周复盘偏差，沉淀可执行改进动作',
    ]
  }

  while (i < lines.length) {
    const line = lines[i]
    if (line.trim().startsWith('```')) {
      inFence = !inFence
      result.push(line)
      i += 1
      continue
    }

    if (!inFence && codeLine(line)) {
      let j = i
      const block: string[] = []
      while (j < lines.length && lines[j].trim() && codeLine(lines[j])) {
        block.push(lines[j])
        j += 1
      }

      if (block.length >= 3) {
        result.push(...buildBusinessPlanBlock(block))
        i = j
        continue
      }
    }

    result.push(line)
    i += 1
  }

  return result.join('\n')
}

function sanitizeTechnicalCode(text: string): string {
  return text.replace(/```[\w-]*\n([\s\S]*?)```/g, (_, content: string) => {
    const lines = content.split('\n').map((x) => x.trim()).filter(Boolean)
    const cue = lines.find(
      (line) =>
        /[\u4e00-\u9fa5]{4,}/.test(line) &&
        !/(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|JOIN|CREATE|ALTER|DROP|\{|\}|\[|\]|;|=>)/i.test(line)
    )
    const title = cue?.replace(/^[-*#>\d.\s]+/, '').slice(0, 30) || '围绕目标问题执行数据分析与经营改进'
    return [
      '> **业务执行方案（已隐藏技术代码）**',
      `> ${title}`,
      '> 1) 先核对数据口径与时间区间',
      '> 2) 再输出关键指标、变化原因与风险提示',
      '> 3) 最后给出分阶段执行动作与复盘节点',
    ].join('\n')
  })
}

function scrollToBottom() {
  nextTick(() => {
    if (messagesRef.value) {
      messagesRef.value.scrollTop = messagesRef.value.scrollHeight
    }
  })
}

function handleEnter(e: KeyboardEvent) {
  if (e.shiftKey) return
  e.preventDefault()
  sendMessage()
}

async function sendMessage() {
  const text = inputText.value.trim()
  if (!text || loading.value) return

  messages.value.push({ role: 'user', content: text })
  inputText.value = ''
  loading.value = true
  streaming.value = false
  scrollToBottom()

  const history = messages.value.slice(0, -1).map((m) => ({ role: m.role, content: m.content }))

  try {
    const response = await aiApi.chatStream(text, history)

    if (!response.ok) {
      const errData = await response.json().catch(() => null)
      throw new Error(errData?.detail || `HTTP ${response.status}`)
    }

    const reader = response.body!.getReader()
    const decoder = new TextDecoder('utf-8')
    let buffer = ''

    messages.value.push({ role: 'assistant', content: '' })
    const assistantIdx = messages.value.length - 1
    loading.value = false
    streaming.value = true
    scrollToBottom()

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split('\n')
      buffer = lines.pop() || ''

      for (const line of lines) {
        const trimmed = line.trim()
        if (!trimmed || !trimmed.startsWith('data: ')) continue
        const payload = trimmed.slice(6)
        if (payload === '[DONE]') continue

        try {
          const json = JSON.parse(payload)
          if (json.error) {
            messages.value[assistantIdx].content += `\n\n错误：${json.error}`
            break
          }
          if (json.content) {
            messages.value[assistantIdx].content += json.content
            scrollToBottom()
          }
        } catch {
          // ignore malformed chunk
        }
      }
    }
  } catch (err: any) {
    const detail = err?.message || 'AI 服务暂时不可用，请检查 LLM API 配置'
    if (
      messages.value.length &&
      messages.value[messages.value.length - 1].role === 'assistant' &&
      messages.value[messages.value.length - 1].content === ''
    ) {
      messages.value[messages.value.length - 1].content = `抱歉，出现了错误：${detail}`
    } else {
      messages.value.push({ role: 'assistant', content: `抱歉，出现了错误：${detail}` })
    }
    message.error('AI 回复失败')
  } finally {
    loading.value = false
    streaming.value = false
    scrollToBottom()
  }
}

function sendQuickQuestion(q: string) {
  inputText.value = q
  sendMessage()
}

function clearChat() {
  messages.value = []
}
</script>

<style scoped lang="less">
.ai-chat-page {
  .ai-hero {
    display: flex;
    align-items: flex-end;
    justify-content: space-between;
    margin-bottom: 10px;
    padding: 2px 2px 0;
  }

  .hero-main h2 {
    margin: 0;
    font-size: 22px;
    line-height: 1.1;
    font-weight: 800;
    color: #0f172a;
    letter-spacing: 0.01em;
  }

  .hero-main p {
    margin: 4px 0 0;
    font-size: 13px;
    color: #64748b;
  }

  .hero-meta {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: flex-end;
  }

  .hero-chip {
    font-size: 12px;
    color: #0f766e;
    background: #e9fbf7;
    border: 1px solid #c8f5ea;
    border-radius: 999px;
    padding: 4px 10px;
    font-weight: 600;
  }
}

.chat-shell {
  border: 1px solid #dfe8f3 !important;
  border-radius: 16px !important;
  overflow: hidden;
  box-shadow: 0 12px 24px rgba(15, 23, 42, 0.06) !important;

  :deep(.ant-card-body) {
    padding: 0;
    display: flex;
    flex-direction: column;
    height: calc(100vh - 170px);
    min-height: 460px;
  }
}

.chat-topbar {
  height: 46px;
  padding: 0 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #e7eef7;
  background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%);
}

.topbar-title {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #1e293b;
  font-weight: 700;
}

.topbar-state {
  font-size: 12px;
  padding: 2px 10px;
  border-radius: 999px;
  color: #0f766e;
  background: #e7faf5;
  border: 1px solid #c6efe3;
  font-weight: 600;

  &.is-streaming {
    color: #0369a1;
    background: #ecf8ff;
    border-color: #cfeeff;
  }
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 14px 16px;
  background: #fbfdff;
}

.chat-welcome {
  text-align: center;
  padding: 20px 10px 12px;

  .welcome-icon {
    width: 52px;
    height: 52px;
    margin: 0 auto 10px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    font-size: 22px;
    background: linear-gradient(135deg, #0d9488, #2dd4bf);
    box-shadow: 0 5px 12px rgba(13, 148, 136, 0.22);
  }

  h3 {
    margin: 0;
    font-size: 16px;
    font-weight: 800;
    color: #0f172a;
  }

  p {
    margin: 6px auto 12px;
    max-width: 620px;
    font-size: 13px;
    line-height: 1.6;
    color: #64748b;
  }
}

.quick-questions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  justify-content: center;
}

.quick-q {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: 1px solid #d7e2ef;
  background: #fff;
  border-radius: 999px;
  padding: 6px 11px;
  color: #334155;
  cursor: pointer;
  font-size: 13px;
  transition: all 0.2s ease;

  &:hover {
    border-color: #0d9488;
    color: #0d9488;
    background: #f0fdf9;
    transform: translateY(-1px);
  }
}

.msg-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 18px;

  &.msg-user {
    flex-direction: row-reverse;

    .msg-bubble {
      background: linear-gradient(135deg, rgba(13, 148, 136, 0.86) 0%, rgba(15, 118, 110, 0.88) 100%);
      color: #fff;
      border-radius: 18px 18px 8px 18px;
      box-shadow: 0 10px 22px rgba(13, 148, 136, 0.24);
      border: 1px solid rgba(255, 255, 255, 0.26);
      backdrop-filter: blur(3px);

      &::after {
        content: '';
        position: absolute;
        right: -5px;
        top: 16px;
        width: 11px;
        height: 11px;
        background: rgba(15, 118, 110, 0.92);
        border-radius: 3px;
        transform: rotate(45deg);
      }
    }

    .msg-name {
      color: rgba(255, 255, 255, 0.78);
      text-align: right;
    }

    .msg-content {
      color: #fff;

      :deep(code) {
        background: rgba(255, 255, 255, 0.2);
        color: #fff;
      }
    }
  }

  &.msg-assistant .msg-bubble {
    border: 1px solid #d3e1ef;
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.94) 0%, rgba(241, 248, 255, 0.88) 100%);
    border-radius: 18px 18px 18px 8px;
    box-shadow: 0 10px 22px rgba(15, 23, 42, 0.07);
    backdrop-filter: blur(3px);

      &::before {
        content: '';
        position: absolute;
        left: -5px;
        top: 16px;
        width: 11px;
        height: 11px;
        background: #f7fbff;
        border-left: 1px solid #d3e1ef;
        border-top: 1px solid #d3e1ef;
        border-radius: 3px;
        transform: rotate(-45deg);
      }
    }
}

.msg-avatar {
  flex-shrink: 0;
}

.user-avatar {
  font-size: 15px !important;
  font-weight: 700;

  &.avatar-type-image {
    background: transparent !important;

    :deep(img) {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  }
}

.ai-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: linear-gradient(135deg, #0d9488, #2dd4bf);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
}

.msg-bubble {
  position: relative;
  max-width: 82%;
  padding: 12px 14px;
}

.msg-name {
  font-size: 11px;
  color: #7f8ea3;
  margin-bottom: 7px;
  font-weight: 600;
  letter-spacing: 0.02em;
}

.msg-content {
  font-size: 14px;
  line-height: 1.78;
  color: #0f172a;
  word-break: break-word;
  text-wrap: pretty;

  :deep(p) {
    margin: 4px 0;
  }

  :deep(ul),
  :deep(ol) {
    margin: 6px 0;
    padding-left: 22px;
  }

  :deep(li) {
    margin-bottom: 3px;
  }

  :deep(pre) {
    background: linear-gradient(180deg, #071226 0%, #0b1d3a 100%);
    color: #dbeafe;
    border-radius: 12px;
    border: 1px solid #1b3b72;
    padding: 14px;
    overflow-x: auto;
    margin: 10px 0;
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08);
  }

  :deep(pre code) {
    color: #dbeafe;
    background: transparent;
    padding: 0;
    font-size: 13px;
    line-height: 1.7;
    font-family: 'JetBrains Mono', 'Consolas', 'Courier New', monospace;
  }

  :deep(code) {
    background: #edf3fb;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 13px;
    color: #1e3a8a;
  }

  :deep(table) {
    width: 100%;
    border-collapse: collapse;
    margin: 10px 0;
    border: 1px solid #d9e5f3;
    border-radius: 8px;
    overflow: hidden;
    background: #fff;
  }

  :deep(th),
  :deep(td) {
    border: 1px solid #d9e5f3;
    padding: 8px 10px;
    text-align: left;
    font-size: 13px;
    line-height: 1.5;
  }

  :deep(th) {
    background: #f2f7fd;
    color: #334155;
    font-weight: 700;
  }

  :deep(tr:nth-child(even) td) {
    background: #fafcff;
  }

  :deep(blockquote) {
    margin: 8px 0;
    padding: 10px 12px;
    border-left: 3px solid #14b8a6;
    border-radius: 8px;
    background: linear-gradient(180deg, #f0fdfa 0%, #ecfeff 100%);
    color: #134e4a;
  }
}

.stream-cursor {
  display: inline-block;
  width: 2px;
  height: 14px;
  margin-left: 2px;
  background: #0d9488;
  animation: blink 0.8s step-end infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}

.typing {
  display: flex;
  gap: 6px;

  .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #0d9488;
    opacity: 0.35;
    animation: typing-bounce 1.1s ease-in-out infinite;

    &:nth-child(2) { animation-delay: 0.2s; }
    &:nth-child(3) { animation-delay: 0.4s; }
  }
}

@keyframes typing-bounce {
  0%, 60%, 100% { transform: translateY(0); opacity: 0.35; }
  30% { transform: translateY(-5px); opacity: 1; }
}

.chat-input-area {
  display: flex;
  gap: 10px;
  padding: 10px 12px;
  border-top: 1px solid #e6edf6;
  background: #f7fafc;
}

.chat-input {
  flex: 1;
  border-radius: 10px !important;
  font-size: 14px;
}

.send-btn {
  min-height: 36px;
  padding: 0 14px !important;
  border-radius: 8px !important;
}

.side-panel {
  border: 1px solid #dfe8f3 !important;
  border-radius: 16px !important;
  box-shadow: 0 10px 20px rgba(15, 23, 42, 0.05) !important;

  :deep(.ant-card-head) {
    border-bottom: 1px solid #e6edf6;
    background: #fbfdff;
    min-height: 46px;
    padding: 0 12px;
  }

  :deep(.ant-card-body) {
    padding: 12px;
  }
}

.side-title {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-weight: 700;
}

.guide-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.guide-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.guide-num {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  background: #e7f9f4;
  color: #0d9488;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}

.guide-text {
  flex: 1;
}

.guide-title {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.guide-desc {
  margin-top: 3px;
  font-size: 12px;
  color: #64748b;
}

.quick-op-btn {
  height: 36px !important;
  border-radius: 10px !important;
  font-weight: 600 !important;
}

.quick-op-btn--danger:hover {
  border-color: #ef4444 !important;
  color: #dc2626 !important;
  background: #fff5f5 !important;
}

@media (max-width: 1200px) {
  .ai-chat-page .ai-hero {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  :deep(.chat-col),
  :deep(.side-col) {
    flex: 0 0 100%;
    max-width: 100%;
  }

  .chat-shell :deep(.ant-card-body) {
    height: auto;
    min-height: 420px;
  }
}
</style>
