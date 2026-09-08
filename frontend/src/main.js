// index.htmlから最初に実行される入口。共通CSSを読み、#appへVueの画面を取り付ける。
import { createApp } from 'vue'
import 'bootstrap/dist/css/bootstrap.min.css'
import './shared/styles/style.css'
import App from './App.vue'
createApp(App).mount('#app')
