(() => {
  'use strict';

  const resourceName = (window.GetParentResourceName && window.GetParentResourceName()) || 'ab_admin';

  const state = {
    open: false,
    players: [],
    bans: [],
    logs: [],
    config: { title: 'AB ADMIN', subtitle: 'Moderation Terminal', discord: '', bans: [], command: 'ban' },
    openDrawerId: null,
  };

  const el = (id) => document.getElementById(id);

  const dom = {
    app: el('app'),
    closeBtn: el('closeBtn'),
    uiTitle: el('uiTitle'),
    uiSubtitle: el('uiSubtitle'),
    caseTag: el('caseTag'),
    clock: el('clock'),
    navItems: document.querySelectorAll('.nav-item'),
    tabs: document.querySelectorAll('.tab'),
    playersList: el('playersList'),
    playersEmpty: el('playersEmpty'),
    playerSearch: el('playerSearch'),
    refreshPlayers: el('refreshPlayers'),
    bansList: el('bansList'),
    bansEmpty: el('bansEmpty'),
    banSearch: el('banSearch'),
    refreshBans: el('refreshBans'),
    logsList: el('logsList'),
    logsEmpty: el('logsEmpty'),
    refreshLogs: el('refreshLogs'),
    dashRecentLogs: el('dashRecentLogs'),
    statOnline: el('statOnline'),
    statBans: el('statBans'),
    statPerma: el('statPerma'),
    statLogs: el('statLogs'),
    toastHost: el('toastHost'),
  };

  //-------------------------------------------------------
  // NUI bridge
  //-------------------------------------------------------

  async function fetchNui(eventName, data = {}) {
    try {
      const resp = await fetch(`https://${resourceName}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
      });
      return await resp.json().catch(() => ({}));
    } catch (e) {
      // Allows local browser preview/testing without a game client
      return {};
    }
  }

  //-------------------------------------------------------
  // Utility
  //-------------------------------------------------------

  function initials(name) {
    if (!name) return '??';
    return name.trim().split(/\s+/).slice(0, 2).map(p => p[0]).join('').toUpperCase();
  }

  function escapeHtml(str) {
    const d = document.createElement('div');
    d.textContent = str ?? '';
    return d.innerHTML;
  }

  function showToast(message, type = 'primary') {
    const t = document.createElement('div');
    t.className = `toast ${type}`;
    t.textContent = message;
    dom.toastHost.appendChild(t);
    setTimeout(() => {
      t.style.transition = 'opacity 0.25s ease';
      t.style.opacity = '0';
      setTimeout(() => t.remove(), 260);
    }, 3200);
  }

  function updateClock() {
    const now = new Date();
    dom.clock.textContent = now.toLocaleTimeString('en-GB', { hour12: false });
  }
  setInterval(updateClock, 1000);
  updateClock();

  function setCaseTag() {
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    const rand = String(Math.floor(Math.random() * 900) + 100);
    dom.caseTag.textContent = `CASE #${y}${m}${d}-${rand}`;
  }

  //-------------------------------------------------------
  // Open / close
  //-------------------------------------------------------

  function openPanel(config, players) {
    state.open = true;
    state.config = { ...state.config, ...(config || {}) };
    state.players = players || [];

    dom.uiTitle.textContent = state.config.title || 'AB ADMIN';
    dom.uiSubtitle.textContent = state.config.subtitle || 'Moderation Terminal';
    setCaseTag();

    dom.app.classList.add('visible');
    renderPlayers();
    renderStats();
    fetchNui('requestBans');
    fetchNui('requestLogs');
  }

  function closePanel(sendCallback = true) {
    state.open = false;
    state.openDrawerId = null;
    dom.app.classList.remove('visible');
    if (sendCallback) fetchNui('close');
  }

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && state.open) closePanel();
  });

  dom.closeBtn.addEventListener('click', () => closePanel());

  //-------------------------------------------------------
  // Tabs
  //-------------------------------------------------------

  function switchTab(name) {
    dom.navItems.forEach(n => n.classList.toggle('active', n.dataset.tab === name));
    dom.tabs.forEach(t => t.classList.toggle('active', t.id === `tab-${name}`));
  }

  dom.navItems.forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
  });

  document.querySelectorAll('[data-tab-jump]').forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tabJump));
  });

  //-------------------------------------------------------
  // Stats
  //-------------------------------------------------------

  function renderStats() {
    dom.statOnline.textContent = state.players.length;
    dom.statBans.textContent = state.bans.length;
    dom.statPerma.textContent = state.bans.filter(b => b.permanent).length;
    dom.statLogs.textContent = state.logs.length;

    dom.dashRecentLogs.innerHTML = '';
    const recent = state.logs.slice(0, 6);
    if (recent.length === 0) {
      dom.dashRecentLogs.innerHTML = `<div class="empty-state" style="padding:16px 0;">No actions logged yet.</div>`;
    } else {
      recent.forEach(l => dom.dashRecentLogs.appendChild(buildLogRow(l)));
    }
  }

  //-------------------------------------------------------
  // Players tab
  //-------------------------------------------------------

  function genderIconPath(gender) {
    // 1 = female, otherwise male-stroke
    return gender === 1
      ? '<circle cx="12" cy="9" r="5"/><path d="M12 14v7M9 18h6"/>'
      : '<circle cx="10" cy="10" r="5"/><path d="M14 6l6-1M20 5v5M20 5l-6 6"/>';
  }

  function buildPlayerCard(p) {
    const card = document.createElement('div');
    card.className = 'record-card';
    card.dataset.id = p.id;

    const jobBadge = p.job ? `<span class="badge job">${escapeHtml(p.job)}</span>` : '';
    const dutyBadge = p.onDuty ? `<span class="badge duty">On Duty</span>` : '';

    card.innerHTML = `
      <div class="record-head">
        <span class="status-dot"></span>
        <div style="flex:1; min-width:0;">
          <div class="record-name">${escapeHtml(p.name)}</div>
          <div class="record-meta">${escapeHtml(p.citizenid || '')} · ${p.ping ?? 0}ms</div>
        </div>
        <span class="record-license">${escapeHtml(p.license || '')}</span>
        ${jobBadge}
        ${dutyBadge}
        <span class="record-id-tag">ID ${p.id}</span>
        <svg class="chevron" viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg>
      </div>
      <div class="drawer">
        <div class="drawer-inner">
          <div class="action-row">
            <div class="action-tab active" data-action="ban">Ban</div>
            <div class="action-tab" data-action="message">Message</div>
            <div class="action-tab" data-action="notify">Notify</div>
            <div class="action-tab" data-action="teleport">Teleport</div>
          </div>

          <div class="action-panel active" data-panel="ban">
            <div>
              <div class="field-label">Reason</div>
              <input class="field-input" data-field="reason" placeholder="Spam, Hack, Cheating…" />
            </div>
            <div>
              <div class="field-label">Duration</div>
              <select class="field-select" data-field="duration">
                ${state.config.bans.map(b => `<option value="${b.value}">${escapeHtml(b.label)}</option>`).join('')}
              </select>
            </div>
            <button class="submit-btn danger" data-submit="ban">Ban Player</button>
          </div>

          <div class="action-panel" data-panel="message">
            <div>
              <div class="field-label">txAdmin Message</div>
              <input class="field-input" data-field="message" placeholder="Write a direct message…" />
            </div>
            <button class="submit-btn" data-submit="message">Send Message</button>
          </div>

          <div class="action-panel" data-panel="notify">
            <div class="field-row">
              <div>
                <div class="field-label">Message</div>
                <input class="field-input" data-field="notifyMessage" placeholder="Notification text…" />
              </div>
              <div>
                <div class="field-label">Type</div>
                <select class="field-select" data-field="notifyType">
                  <option value="primary">Primary</option>
                  <option value="error">Error</option>
                </select>
              </div>
            </div>
            <button class="submit-btn warn" data-submit="notify">Send Notification</button>
          </div>

          <div class="action-panel" data-panel="teleport">
            <p style="margin:0; font-size:12.5px; color:var(--text-dim);">
              Teleports you directly to this player's current location.
            </p>
            <button class="submit-btn" data-submit="teleport">Teleport To Player</button>
          </div>
        </div>
      </div>
    `;

    // drawer toggle
    card.querySelector('.record-head').addEventListener('click', () => {
      const isOpen = card.classList.contains('open');
      dom.playersList.querySelectorAll('.record-card.open').forEach(c => c.classList.remove('open'));
      if (!isOpen) card.classList.add('open');
      state.openDrawerId = isOpen ? null : p.id;
    });

    // action sub-tabs
    card.querySelectorAll('.action-tab').forEach(tabBtn => {
      tabBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        card.querySelectorAll('.action-tab').forEach(t => t.classList.remove('active'));
        card.querySelectorAll('.action-panel').forEach(pnl => pnl.classList.remove('active'));
        tabBtn.classList.add('active');
        card.querySelector(`.action-panel[data-panel="${tabBtn.dataset.action}"]`).classList.add('active');
      });
    });

    // submit handlers
    const banBtn = card.querySelector('[data-submit="ban"]');
    banBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const reason = card.querySelector('[data-field="reason"]').value.trim();
      const duration = card.querySelector('[data-field="duration"]').value;
      if (!reason) { showToast('Please enter a ban reason', 'error'); return; }
      fetchNui('banPlayer', { id: p.id, reason, duration });
      showToast(`Ban submitted for ${p.name}`, 'success');
      card.classList.remove('open');
    });

    const msgBtn = card.querySelector('[data-submit="message"]');
    msgBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const input = card.querySelector('[data-field="message"]');
      const message = input.value.trim();
      if (!message) { showToast('Please enter a message', 'error'); return; }
      fetchNui('sendMessage', { id: p.id, message });
      showToast(`Message sent to ${p.name}`, 'success');
      input.value = '';
    });

    const notifyBtn = card.querySelector('[data-submit="notify"]');
    notifyBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      const message = card.querySelector('[data-field="notifyMessage"]').value.trim();
      const ntype = card.querySelector('[data-field="notifyType"]').value;
      if (!message) { showToast('Please enter a message', 'error'); return; }
      fetchNui('sendNotify', { id: p.id, message, ntype });
      showToast(`Notification sent to ${p.name}`, 'success');
    });

    const tpBtn = card.querySelector('[data-submit="teleport"]');
    tpBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (!p.coords) { showToast('No coordinates available for this player', 'error'); return; }
      fetchNui('teleportToPlayer', { coords: p.coords, name: p.name });
      closePanel();
    });

    if (state.openDrawerId === p.id) card.classList.add('open');

    return card;
  }

  function renderPlayers() {
    const query = (dom.playerSearch.value || '').toLowerCase().trim();
    const filtered = state.players.filter(p => {
      if (!query) return true;
      return (
        p.name.toLowerCase().includes(query) ||
        String(p.id).includes(query) ||
        (p.license || '').toLowerCase().includes(query)
      );
    });

    dom.playersList.innerHTML = '';
    dom.playersEmpty.hidden = filtered.length !== 0;
    filtered.forEach(p => dom.playersList.appendChild(buildPlayerCard(p)));
    renderStats();
  }

  dom.playerSearch.addEventListener('input', renderPlayers);
  dom.refreshPlayers.addEventListener('click', () => fetchNui('refreshPlayers'));

  //-------------------------------------------------------
  // Bans tab
  //-------------------------------------------------------

  function buildBanCard(b) {
    const card = document.createElement('div');
    card.className = 'record-card danger';

    const statusBadge = b.permanent
      ? `<span class="badge perm">Permanent</span>`
      : `<span class="badge temp">${escapeHtml(b.remaining)}</span>`;

    card.innerHTML = `
      <div class="record-head">
        <span class="status-dot off"></span>
        <div style="flex:1; min-width:0;">
          <div class="record-name">${escapeHtml(b.reason)}</div>
          <div class="record-meta">Banned by ${escapeHtml(b.admin)} · ${escapeHtml(b.banDate)}</div>
        </div>
        <span class="record-license">${escapeHtml(b.license)}</span>
        ${statusBadge}
        <svg class="chevron" viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg>
      </div>
      <div class="drawer">
        <div class="drawer-inner">
          <p style="margin:0 0 12px; font-size:12.5px; color:var(--text-dim);">
            Expires: <b style="color:var(--text)">${escapeHtml(b.expireDate)}</b>
          </p>
          <button class="submit-btn" data-submit="unban">Lift Ban</button>
        </div>
      </div>
    `;

    card.querySelector('.record-head').addEventListener('click', () => {
      const isOpen = card.classList.contains('open');
      dom.bansList.querySelectorAll('.record-card.open').forEach(c => c.classList.remove('open'));
      if (!isOpen) card.classList.add('open');
    });

    card.querySelector('[data-submit="unban"]').addEventListener('click', (e) => {
      e.stopPropagation();
      fetchNui('unbanPlayer', { license: b.license });
      showToast('Lifting ban…', 'primary');
    });

    return card;
  }

  function renderBans() {
    const query = (dom.banSearch.value || '').toLowerCase().trim();
    const filtered = state.bans.filter(b => {
      if (!query) return true;
      return (b.license || '').toLowerCase().includes(query) || (b.reason || '').toLowerCase().includes(query);
    });

    dom.bansList.innerHTML = '';
    dom.bansEmpty.hidden = filtered.length !== 0;
    filtered.forEach(b => dom.bansList.appendChild(buildBanCard(b)));
    renderStats();
  }

  dom.banSearch.addEventListener('input', renderBans);
  dom.refreshBans.addEventListener('click', () => fetchNui('requestBans'));

  //-------------------------------------------------------
  // Logs tab
  //-------------------------------------------------------

  function timeAgo(unixSeconds) {
    const diff = Math.floor(Date.now() / 1000) - unixSeconds;
    if (diff < 60) return `${diff}s ago`;
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
  }

  function buildLogRow(l) {
    const row = document.createElement('div');
    row.className = 'log-row';
    row.innerHTML = `
      <span class="log-dot ${escapeHtml(l.action)}"></span>
      <span class="log-text"><b>${escapeHtml(l.admin)}</b> ${escapeHtml(l.action.toLowerCase())}${l.target ? ' · ' + escapeHtml(l.target) : ''}${l.detail ? ' — ' + escapeHtml(l.detail) : ''}</span>
      <span class="log-time">${timeAgo(l.date)}</span>
    `;
    return row;
  }

  function renderLogs() {
    dom.logsList.innerHTML = '';
    dom.logsEmpty.hidden = state.logs.length !== 0;
    state.logs.forEach(l => dom.logsList.appendChild(buildLogRow(l)));
    renderStats();
  }

  dom.refreshLogs.addEventListener('click', () => fetchNui('requestLogs'));

  //-------------------------------------------------------
  // Message bridge from client.lua
  //-------------------------------------------------------

  window.addEventListener('message', (event) => {
    const data = event.data || {};
    switch (data.action) {
      case 'open':
        openPanel(data.config, data.players);
        break;
      case 'close':
        closePanel(false);
        break;
      case 'setPlayers':
        state.players = data.players || [];
        renderPlayers();
        break;
      case 'setBans':
        state.bans = data.bans || [];
        renderBans();
        break;
      case 'setLogs':
        state.logs = data.logs || [];
        renderLogs();
        break;
    }
  });
})();
