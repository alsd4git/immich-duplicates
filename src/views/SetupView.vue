<script setup lang="ts">
import { ref } from 'vue'
import router from '@/router'

import { useApiStore } from '@/stores/api'
import { useDataStore } from '@/stores/data'

const api = useApiStore()
const data = useDataStore()

const endpoint = ref(api.endpoint)
const baseUrlOverride = ref(api.baseUrlOverride)
const apiKey = ref(api.apiKey)
const duplicates = ref(JSON.stringify(data.duplicates))
const message = ref<string>('')
let immich_url = 'https://github.com/immich-app/immich'
if (
  window.env.DUPES_JSON_FROM_DOCKER !== '[]' &&
  !window.env.DUPES_JSON_FROM_DOCKER.startsWith('__')
) {
  duplicates.value = window.env.DUPES_JSON_FROM_DOCKER
}
if (window.env.API_KEY_FROM_DOCKER !== '' && !window.env.API_KEY_FROM_DOCKER.startsWith('__')) {
  apiKey.value = window.env.API_KEY_FROM_DOCKER
}
if (window.env.IMMICH_URL !== '' && !window.env.IMMICH_URL.startsWith('__')) {
  baseUrlOverride.value = window.env.IMMICH_URL
}
if (window.env.IMMICH_DISPLAY_URL !== '' && !window.env.IMMICH_DISPLAY_URL.startsWith('__')) {
  immich_url = window.env.IMMICH_DISPLAY_URL
}

function setUpStores() {
  api.endpoint = endpoint.value
  api.apiKey = apiKey.value
  api.baseUrlOverride = baseUrlOverride.value

  data.duplicates = JSON.parse(duplicates.value)

  if (Object.keys(data.duplicates).length) {
    router.push('/')
  } else {
    message.value = 'No data'
  }
}

function setUpLocalhostProxy() {
  endpoint.value = `${window.location.origin}/api`
}

function emptyLocal() {
  localStorage.clear()
  location.reload()
}

/**
 * Checks if the application is using a Docker environment.
 *
 * @return {boolean} Returns true if the application is using a Docker environment, false otherwise.
 */
function isUsingDockerEnv() {
  if (
    window.env.DUPES_JSON_FROM_DOCKER !== '[]' &&
    !window.env.DUPES_JSON_FROM_DOCKER.startsWith('__')
  ) {
    return true
  }
  if (window.env.API_KEY_FROM_DOCKER !== '' && !window.env.API_KEY_FROM_DOCKER.startsWith('__')) {
    return true
  }

  //actually, we don't really care for those, the important ones are the other two
  // if (window.env.IMMICH_URL !== '' && !window.env.IMMICH_URL.startsWith('__')) {
  //   return true
  // }
  // if (window.env.IMMICH_DISPLAY_URL !== '' && !window.env.IMMICH_DISPLAY_URL.startsWith('__')) {
  //   return true
  // }
  return false
}

// console.log(window.env.DUPES_JSON_FROM_DOCKER)
</script>

<template>
  <main>
    <div style="display: flex">
      <h1>Setup</h1>

      <a :href="immich_url" target="_blank" style="margin-left: auto">
        <img
          src="https://github.com/immich-app/immich/raw/main/design/immich-logo-stacked-light.svg"
          height="100"
        />
      </a>
    </div>

    <h2>Immich</h2>
    <button v-if="isUsingDockerEnv()" @click="emptyLocal">Empty Localstorage & reload</button>
    <section>
      <label for="endpoint">API Endpoint URL (including <code>/api</code>)</label>
      <input v-model="endpoint" type="text" name="endpoint" />
      <ul>
        <li>
          <code>https://immich.example.com/api</code>
          <br />
          If you configured your Immich server to support CORS.
        </li>
        <li>
          <code>http://localhost:8080/api</code>
          <br />
          If you used <code>--env IMMICH_URL=...</code> to run the duplicate browser.
          <a @click="setUpLocalhostProxy" href="#">Click here to automatically set.</a>
        </li>
      </ul>
    </section>
    <section>
      <label for="baseUrlOverride">Base URL</label>
      <input v-model="baseUrlOverride" type="text" name="baseUrlOverride" />
      <p>
        Not required if your Immich server supports CORS. Otherwise, the base address of your Immich
        server, i.e. the address shown in your browser's address bar after logging into Immich,
        without trailing
        <code>/photos</code>.<br />
        Example: <code>https://immich.example.com/</code>
      </p>
    </section>

    <section>
      <label for="endpoint">API Key</label>
      <input v-model="apiKey" type="text" name="apiKey" />
    </section>

    <h2>JSON document with duplicates</h2>
    <section>
      <label for="duplicates">The format is <code>string[][]</code></label>
      <textarea name="duplicates" v-model="duplicates"></textarea>
    </section>

    <button @click="setUpStores">OK</button>

    <p>{{ message }}</p>
  </main>
</template>

<style scoped>
h2 {
  margin-top: 2rem;
}

section {
  margin-top: 1rem;
}

label {
  display: block;
}

input,
textarea {
  width: 100%;
}

textarea {
  height: 20rem;
}
</style>
