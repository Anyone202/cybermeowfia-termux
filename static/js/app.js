/* CyberMeowfia · 前端工具函数 + 全局事件
   - 通用 fetch 封装(自动携带 cookie)
   - toast 通知
   - 复制到剪贴板
   - 标签页导航
*/
(function() {
  'use strict';

  // ----------------- 通用 API 调用
  window.api = async function(url, opts) {
    opts = opts || {};
    opts.credentials = opts.credentials || 'same-origin';
    opts.headers = Object.assign({'Content-Type': 'application/json'}, opts.headers || {});
    if (opts.body && typeof opts.body !== 'string' && !(opts.body instanceof FormData)) {
      opts.body = JSON.stringify(opts.body);
    }
    let r;
    try {
      r = await fetch(url, opts);
    } catch (e) {
      toast('网络错误: ' + e.message, 'err');
      throw e;
    }
    let j;
    try { j = await r.json(); } catch (e) { j = {ok: false, error: '解析失败'}; }
    if (!j.ok) toast(j.error || ('HTTP ' + r.status), 'err');
    return j;
  };

  // ----------------- Toast 通知
  window.toast = function(msg, kind) {
    const box = document.getElementById('toast');
    if (!box) { console.log('[toast]', msg); return; }
    const t = document.createElement('div');
    t.className = 't' + (kind ? ' ' + kind : '');
    t.textContent = msg;
    box.appendChild(t);
    setTimeout(() => {
      t.style.opacity = '0';
      t.style.transform = 'translateX(20px)';
      t.style.transition = 'all 0.25s ease';
      setTimeout(() => t.remove(), 250);
    }, 3000);
  };

  // ----------------- 复制到剪贴板
  window.copyText = function(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.select();
    el.setSelectionRange(0, 99999);
    try {
      document.execCommand('copy');
      toast('已复制', 'ok');
    } catch (e) {
      // 兼容新版 API
      navigator.clipboard.writeText(el.value).then(
        () => toast('已复制', 'ok'),
        () => toast('复制失败', 'err'));
    }
  };

  // ----------------- HTML 转义
  window.escapeHtml = function(s) {
    return (s == null ? '' : String(s)).replace(/[&<>"']/g, c => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    })[c]);
  };

  // ----------------- 顶栏锚点 -> 跳到对应 section
  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.menu a[data-tab]').forEach(a => {
      a.addEventListener('click', e => {
        const tab = a.dataset.tab;
        const target = document.getElementById(tab);
        if (target) {
          e.preventDefault();
          target.scrollIntoView({behavior: 'smooth'});
        }
      });
    });
  });
})();