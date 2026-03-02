<template>
  <div class="data-import-page">
    <div class="page-title">
      <h2>数据导入</h2>
      <p>上传 Excel/CSV 财务数据，或手动新增财务记录。</p>
    </div>

    <a-row :gutter="24">
      <a-col :span="14">
        <a-card title="文件上传" class="panel-card" style="margin-bottom: 20px;">
          <template #extra>
            <a-tag color="blue">支持 xlsx / xls / csv</a-tag>
          </template>

          <a-upload-dragger
            :before-upload="handleBeforeUpload"
            :file-list="fileList"
            :multiple="false"
            accept=".xlsx,.xls,.csv"
            @remove="handleRemove"
            class="custom-dragger"
          >
            <div class="upload-content">
              <div class="upload-icon">
                <CloudUploadOutlined />
              </div>
              <p class="upload-title">点击或拖拽文件到此区域上传</p>
              <p class="upload-hint">文件需包含 日期、类别、金额 列，支持批量导入。</p>
            </div>
          </a-upload-dragger>

          <div class="upload-actions">
            <a-button
              type="primary"
              :loading="uploading"
              :disabled="!selectedFile"
              @click="handleUpload"
              class="btn-primary"
            >
              <UploadOutlined />
              开始导入
            </a-button>
            <a-button :loading="downloadingTemplate" @click="handleDownloadTemplate" class="btn-ghost btn-template">
              <DownloadOutlined />
              下载模板
            </a-button>
          </div>

          <a-alert
            v-if="uploadResult"
            :type="uploadResult.success ? 'success' : 'error'"
            :message="uploadResult.success ? `成功导入 ${uploadResult.records_imported} 条记录` : '导入失败'"
            :description="uploadResult.errors?.length ? uploadResult.errors.join('\n') : undefined"
            show-icon
            style="margin-top: 16px; border-radius: 10px;"
          />
        </a-card>

        <a-card title="手动新增记录" class="panel-card">
          <a-form :model="manualForm" @finish="handleAddRecord" layout="vertical">
            <a-row :gutter="16">
              <a-col :span="12">
                <a-form-item label="日期" name="record_date" :rules="[{ required: true, message: '请选择日期' }]">
                  <a-date-picker v-model:value="manualForm.record_date" style="width: 100%;" placeholder="选择日期" />
                </a-form-item>
              </a-col>
              <a-col :span="12">
                <a-form-item label="类别" name="category" :rules="[{ required: true, message: '请选择类别' }]">
                  <a-select v-model:value="manualForm.category" :options="categoryOptions" placeholder="选择类别" />
                </a-form-item>
              </a-col>
            </a-row>

            <a-row :gutter="16">
              <a-col :span="12">
                <a-form-item label="子类别">
                  <a-input v-model:value="manualForm.sub_category" placeholder="如：销售收入、办公费用" />
                </a-form-item>
              </a-col>
              <a-col :span="12">
                <a-form-item label="金额" name="amount" :rules="[{ required: true, message: '请输入金额' }]">
                  <a-input-number
                    v-model:value="manualForm.amount"
                    style="width: 100%;"
                    :min="0"
                    :precision="2"
                    placeholder="0.00"
                  />
                </a-form-item>
              </a-col>
            </a-row>

            <a-form-item label="描述">
              <a-textarea v-model:value="manualForm.description" :rows="2" placeholder="可选备注说明" />
            </a-form-item>

            <a-button type="primary" html-type="submit" :loading="addingRecord" class="btn-primary">
              <PlusOutlined />
              添加记录
            </a-button>
          </a-form>
        </a-card>
      </a-col>

      <a-col :span="10">
        <a-card title="导入说明" class="panel-card" style="margin-bottom: 20px;">
          <div class="guide-section">
            <h4>必填字段</h4>
            <div class="guide-tags">
              <a-tag color="red">日期</a-tag>
              <a-tag color="red">类别</a-tag>
              <a-tag color="red">金额</a-tag>
            </div>
          </div>

          <div class="guide-section">
            <h4>可选字段</h4>
            <div class="guide-tags">
              <a-tag>子类别</a-tag>
              <a-tag>描述</a-tag>
            </div>
          </div>

          <a-divider style="margin: 16px 0;" />

          <div class="guide-section">
            <h4>类别说明</h4>
            <div class="category-list">
              <div class="category-item">
                <span class="dot dot-income"></span>
                <span><strong>收入</strong> - 销售收入、利息收入等</span>
              </div>
              <div class="category-item">
                <span class="dot dot-expense"></span>
                <span><strong>支出</strong> - 办公费用、人员工资等</span>
              </div>
              <div class="category-item">
                <span class="dot dot-asset"></span>
                <span><strong>资产</strong> - 现金、应收账款等</span>
              </div>
              <div class="category-item">
                <span class="dot dot-liability"></span>
                <span><strong>负债</strong> - 应付账款、贷款等</span>
              </div>
            </div>
          </div>
        </a-card>

        <a-card title="最近记录">
          <template #extra>
            <a-tag>{{ recentRecords.length }} 条</a-tag>
          </template>
          <a-table
            :columns="recordColumns"
            :data-source="recentRecords"
            :pagination="{ pageSize: 5, size: 'small' }"
            size="small"
          >
            <template #bodyCell="{ column, text }">
              <template v-if="column.key === 'amount'">
                <span style="font-weight: 600;">¥{{ Number(text).toLocaleString('zh-CN', { minimumFractionDigits: 2 }) }}</span>
              </template>
              <template v-if="column.key === 'category'">
                <a-tag
                  :color="text === '收入' ? 'green' : text === '支出' ? 'red' : text === '资产' ? 'blue' : 'orange'"
                  style="border-radius: 6px;"
                >
                  {{ text }}
                </a-tag>
              </template>
            </template>
          </a-table>
        </a-card>
      </a-col>
    </a-row>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { CloudUploadOutlined, UploadOutlined, PlusOutlined, DownloadOutlined } from '@ant-design/icons-vue'
import dayjs from 'dayjs'
import { financialApi } from '@/api/financial'
import { categoryOptions } from '@/utils/format'
import type { UploadFile } from 'ant-design-vue'

const selectedFile = ref<File | null>(null)
const fileList = ref<UploadFile[]>([])
const uploading = ref(false)
const addingRecord = ref(false)
const downloadingTemplate = ref(false)
const uploadResult = ref<any>(null)
const recentRecords = ref<any[]>([])

const manualForm = reactive({
  record_date: null as any,
  category: undefined as string | undefined,
  sub_category: '',
  amount: null as number | null,
  description: '',
})

const recordColumns = [
  { title: '日期', dataIndex: 'record_date', key: 'record_date', width: 110 },
  { title: '类别', dataIndex: 'category', key: 'category', width: 80 },
  { title: '金额', dataIndex: 'amount', key: 'amount', width: 130 },
  { title: '描述', dataIndex: 'description', key: 'description', ellipsis: true },
]

function handleBeforeUpload(file: File) {
  fileList.value = [file as any]
  selectedFile.value = file
  uploadResult.value = null
  return false
}

function handleRemove() {
  fileList.value = []
  selectedFile.value = null
}

async function handleDownloadTemplate() {
  downloadingTemplate.value = true
  try {
    await financialApi.downloadTemplate()
    message.success('模板下载成功')
  } catch {
    message.error('模板下载失败')
  } finally {
    downloadingTemplate.value = false
  }
}

async function handleUpload() {
  if (!selectedFile.value) return
  uploading.value = true
  try {
    const res = await financialApi.uploadFile(selectedFile.value)
    uploadResult.value = res
    if (res.success) {
      message.success(`成功导入 ${res.records_imported} 条记录`)
      loadRecords()
    }
  } catch {
    message.error('上传失败')
  } finally {
    uploading.value = false
  }
}

async function handleAddRecord() {
  if (!manualForm.record_date || !manualForm.category || manualForm.amount === null) return
  addingRecord.value = true
  try {
    await financialApi.addRecord({
      record_date: dayjs(manualForm.record_date).format('YYYY-MM-DD'),
      category: manualForm.category,
      sub_category: manualForm.sub_category || null,
      amount: manualForm.amount,
      description: manualForm.description || null,
    })
    message.success('记录添加成功')
    manualForm.record_date = null
    manualForm.category = undefined
    manualForm.sub_category = ''
    manualForm.amount = null
    manualForm.description = ''
    loadRecords()
  } catch {
    message.error('添加失败')
  } finally {
    addingRecord.value = false
  }
}

async function loadRecords() {
  try {
    const res = await financialApi.getRecords({ limit: 10 })
    recentRecords.value = res.items
  } catch {
    // ignore
  }
}

onMounted(loadRecords)
</script>

<style scoped lang="less">
.data-import-page {
  .page-title {
    margin-bottom: 16px;

    h2 {
      margin: 0;
    }

    p {
      margin: 4px 0 0;
      color: var(--text-muted);
    }
  }
}

.panel-card {
  border-radius: 14px !important;
  border: 1px solid #dbe6f4 !important;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.05) !important;
}

.custom-dragger {
  :deep(.ant-upload-drag) {
    border: 2px dashed var(--border) !important;
    border-radius: 12px !important;
    background: #fafbfc !important;
    transition: all 0.2s;

    &:hover {
      border-color: var(--primary) !important;
      background: var(--primary-bg) !important;
    }
  }
}

.upload-content {
  padding: 24px 0;
}

.upload-icon {
  font-size: 42px;
  color: var(--primary-light);
  margin-bottom: 12px;
}

.upload-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 4px;
}

.upload-hint {
  font-size: 13px;
  color: var(--text-muted);
}

.upload-actions {
  display: flex;
  gap: 12px;
  margin-top: 20px;
}

.guide-section {
  margin-bottom: 16px;

  h4 {
    font-size: 13px;
    font-weight: 700;
    color: var(--text-secondary);
    margin-bottom: 8px;
    text-transform: uppercase;
    letter-spacing: 0.4px;
  }
}

.guide-tags {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.category-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.category-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: var(--text-secondary);

  .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .dot-income { background: var(--success); }
  .dot-expense { background: var(--danger); }
  .dot-asset { background: var(--primary); }
  .dot-liability { background: var(--warning); }
}

.btn-template {
  height: 40px !important;
  font-weight: 500 !important;

  &:hover {
    transform: translateY(-1px);
    box-shadow: 0 2px 8px rgba(13, 148, 136, 0.15) !important;
  }
}

</style>
