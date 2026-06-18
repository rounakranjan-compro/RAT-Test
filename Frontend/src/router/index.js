import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/auth/callback',
      component: () => import('@/views/AuthCallback.vue'),
    },
    {
      path: '/:pathMatch(.*)*',
      component: { template: '<div></div>' } // App.vue handles everything else
    }
  ]
})

export default router