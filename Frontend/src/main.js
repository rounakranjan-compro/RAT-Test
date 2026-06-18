import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import './plugins/axios.js'
import './style.css'
import App from './App.vue'

console.log('main.js loaded, router:', router) // ← add this

const pinia = createPinia()
const app = createApp(App)

app.use(pinia)
app.use(router)
app.mount('#app')