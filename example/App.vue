<template>
  <router-view v-slot="{ Component }">
    <v-fade-transition appear>
      <component :is="Component" />
    </v-fade-transition>
  </router-view>
</template>

<script setup lang="ts">
  const user = useUserStore()
  const router = useRouter()
  const route = useRoute()
  const theme = useTheme()
  const { locale } = useI18n()
  const auth = useAuthStore()
</script>

<style lang="sass">
a:not(:hover)
  text-decoration: none

p
  margin-bottom: 1rem
  line-height: 1.8

  a, a:visited
    color: rgb(var(--v-theme-primary))

h1
  + p
    font-size: 1.25rem
    font-weight: 300

ul:not([class]),
ol:not([class])
  padding-left: 20px

ul:not([class]):not(li > ul)
  margin-bottom: 16px

// Theme transition
.app-copy
  position: fixed !important
  z-index: -1 !important
  pointer-events: none !important
  contain: size style !important
  overflow: clip !important

.app-transition
  --clip-size: 0
  --clip-pos: 0 0
  clip-path: circle(var(--clip-size) at var(--clip-pos))
  transition: clip-path .35s ease-out
</style>

<style lang='sass' scoped>
.pwa-loader
  position: fixed
  top: 0
  left: 0
  right: 0
  z-index: 1010
</style>

<style lang=sass scoped>
.pwa-loader
  position: fixed
  top: 0
  left: 0
  right: 0
  z-index: 1010
</style>
