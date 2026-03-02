<template>
  <a-upload-dragger
    :before-upload="handleBeforeUpload"
    :file-list="fileList"
    :multiple="false"
    accept=".xlsx,.xls,.csv"
    @remove="handleRemove"
  >
    <p class="ant-upload-drag-icon">
      <InboxOutlined />
    </p>
    <p class="ant-upload-text">点击或拖拽文件到此区域上传</p>
    <p class="ant-upload-hint">支持 Excel(.xlsx/.xls) 和 CSV 文件</p>
  </a-upload-dragger>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { InboxOutlined } from '@ant-design/icons-vue'
import type { UploadFile } from 'ant-design-vue'

const emit = defineEmits<{
  (e: 'file-selected', file: File): void
}>()

const fileList = ref<UploadFile[]>([])

function handleBeforeUpload(file: File) {
  fileList.value = [file as any]
  emit('file-selected', file)
  return false
}

function handleRemove() {
  fileList.value = []
}
</script>
