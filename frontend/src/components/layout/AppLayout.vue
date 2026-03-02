<template>
  <a-layout class="app-root">
    <AppSider />
    <a-layout class="app-main">
      <AppHeader />
      <a-layout-content class="main-content">
        <transition name="slide-up" mode="out-in">
          <router-view />
        </transition>
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useUserStore } from '@/stores/user'
import AppHeader from './AppHeader.vue'
import AppSider from './AppSider.vue'

const userStore = useUserStore()

onMounted(() => {
  if (userStore.token && !userStore.userInfo) {
    userStore.fetchUserInfo()
  }
})
</script>

<style scoped lang="less">
.app-root {
  height: 100vh;
  overflow: hidden;
}

.app-main {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.main-content {
  margin: 0;
  padding: 28px 32px;
  background: var(--bg-page);
  flex: 1;
  overflow-y: auto;
}
</style>
