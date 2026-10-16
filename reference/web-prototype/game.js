// Scoville - Playable Day-1 Prototype Engine
(function() {
  'use strict';

  // --- Sound Effects Synthesis (Web Audio API) ---
  class SoundFX {
    constructor() {
      this.ctx = null;
      this.enabled = true;
    }

    init() {
      if (!this.ctx) {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (AudioCtx) this.ctx = new AudioCtx();
      }
      if (this.ctx && this.ctx.state === 'suspended') {
        this.ctx.resume();
      }
    }

    toggle() {
      this.enabled = !this.enabled;
      return this.enabled;
    }

    playHarvest(isCrit = false) {
      if (!this.enabled || !this.ctx) return;
      this.init();
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = isCrit ? 'triangle' : 'sine';
      const baseFreq = isCrit ? 600 : 380;
      osc.frequency.setValueAtTime(baseFreq, this.ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(baseFreq * 1.8, this.ctx.currentTime + 0.08);

      gain.gain.setValueAtTime(0.2, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.09);

      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start();
      osc.stop(this.ctx.currentTime + 0.1);
    }

    playBottle() {
      if (!this.enabled || !this.ctx) return;
      this.init();
      // Resonant cork / glass pop
      const now = this.ctx.currentTime;
      const osc1 = this.ctx.createOscillator();
      const osc2 = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(220, now);
      osc1.frequency.exponentialRampToValueAtTime(880, now + 0.05);

      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(1320, now + 0.02);
      osc2.frequency.exponentialRampToValueAtTime(1760, now + 0.12);

      gain.gain.setValueAtTime(0.35, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.18);

      osc1.connect(gain);
      osc2.connect(gain);
      gain.connect(this.ctx.destination);

      osc1.start(now);
      osc2.start(now + 0.02);
      osc1.stop(now + 0.15);
      osc2.stop(now + 0.18);
    }

    playCash() {
      if (!this.enabled || !this.ctx) return;
      this.init();
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(987.77, now); // B5
      osc.frequency.setValueAtTime(1318.51, now + 0.08); // E6

      gain.gain.setValueAtTime(0.25, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.22);

      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.24);
    }

    playFrenzyTrigger() {
      if (!this.enabled || !this.ctx) return;
      this.init();
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(200, now);
      osc.frequency.exponentialRampToValueAtTime(900, now + 0.4);

      gain.gain.setValueAtTime(0.3, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.45);

      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.48);
    }
  }

  const sfx = new SoundFX();

  // --- Game State Model ---
  const defaultState = {
    cash: 0.0,
    peppers: {
      bell: 0,
      jalapeno: 0,
    },
    bottles: {
      table: 0,
      smoky: 0,
    },
    heat: 0.0,
    frenzyTimer: 0.0,
    upgrades: {
      capper: 0,
      picker: 0,
      shears: 0,
      jalapeno: 0,
    },
    stats: {
      totalPeppers: 0,
      totalBottles: 0,
      totalRevenue: 0.0,
      totalFrenzies: 0,
    },
    unlocked: {
      bottling: false,
      upgrades: false,
      jalapeno: false,
    }
  };

  let state = JSON.parse(JSON.stringify(defaultState));

  // Load from LocalStorage
  function loadGame() {
    try {
      const saved = localStorage.getItem('scoville_save_v1');
      if (saved) {
        const parsed = JSON.parse(saved);
        state = Object.assign(JSON.parse(JSON.stringify(defaultState)), parsed);
      }
    } catch (e) {
      console.warn('Could not load save, using defaults', e);
    }
  }

  function saveGame() {
    try {
      localStorage.setItem('scoville_save_v1', JSON.stringify(state));
    } catch (e) {
      // ignore
    }
  }

  function resetGame() {
    if (confirm('Reset your farm and kitchen progress?')) {
      state = JSON.parse(JSON.stringify(defaultState));
      saveGame();
      updateUI();
    }
  }

  // --- Costs & Formats ---
  function getCapperCost() {
    return 10.0 * Math.pow(1.4, state.upgrades.capper);
  }
  function getPickerCost() {
    return 25.0 * Math.pow(1.4, state.upgrades.picker);
  }
  function getShearsCost() {
    return 15.0 * Math.pow(1.5, state.upgrades.shears);
  }
  function getJalapenoCost() {
    return 100.0;
  }

  function fmtMoney(amount) {
    if (amount >= 1e9) return '$' + (amount / 1e9).toFixed(2) + 'B';
    if (amount >= 1e6) return '$' + (amount / 1e6).toFixed(2) + 'M';
    if (amount >= 1e3) return '$' + (amount / 1e3).toFixed(2) + 'k';
    return '$' + amount.toFixed(2);
  }

  function fmtInt(num) {
    if (num >= 1e9) return (num / 1e9).toFixed(2) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(2) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(1) + 'k';
    return Math.floor(num).toLocaleString();
  }

  // --- Actions ---
  function handleTap(event) {
    sfx.init();

    const isFrenzy = state.frenzyTimer > 0;
    const baseTap = 1 + state.upgrades.shears;
    const mult = isFrenzy ? 5.0 : 1.0;
    const isCrit = Math.random() < 0.08;
    const critMult = isCrit ? 3.0 : 1.0;

    const yieldAmount = Math.round(baseTap * mult * critMult);

    // Harvest Bell Peppers (and chance of Jalapeño if unlocked)
    state.peppers.bell += yieldAmount;
    state.stats.totalPeppers += yieldAmount;

    if (state.unlocked.jalapeno) {
      const jalYield = Math.random() < 0.35 ? 1 : 0;
      if (jalYield > 0) {
        state.peppers.jalapeno += jalYield;
        state.stats.totalPeppers += jalYield;
      }
    }

    // Heat building
    if (!isFrenzy) {
      state.heat = Math.min(100.0, state.heat + 5.5);
      if (state.heat >= 100.0) {
        triggerFlashBoil();
      }
    }

    sfx.playHarvest(isCrit || isFrenzy);
    spawnParticle(event, `+${yieldAmount} 🫑`, isCrit, isFrenzy);
    checkProgressiveDisclosure();
    updateUI();
  }

  function triggerFlashBoil() {
    state.frenzyTimer = 10.0;
    state.heat = 100.0;
    state.stats.totalFrenzies++;
    sfx.playFrenzyTrigger();
  }

  function sellRawPeppers() {
    if (state.peppers.bell <= 0) return;
    const revenue = state.peppers.bell * 0.05;
    state.cash += revenue;
    state.stats.totalRevenue += revenue;
    state.peppers.bell = 0;
    sfx.playCash();
    updateUI();
  }

  function sellRawJalapenos() {
    if (state.peppers.jalapeno <= 0) return;
    const revenue = state.peppers.jalapeno * 0.35;
    state.cash += revenue;
    state.stats.totalRevenue += revenue;
    state.peppers.jalapeno = 0;
    sfx.playCash();
    updateUI();
  }

  function bottleTableSauce() {
    if (state.peppers.bell < 20) return;
    state.peppers.bell -= 20;
    state.bottles.table += 1;
    state.stats.totalBottles += 1;

    // Immediately sells to diner for $2.50
    const sale = 2.50;
    state.cash += sale;
    state.stats.totalRevenue += sale;

    sfx.playBottle();
    sfx.playCash();

    if (!state.unlocked.upgrades) {
      state.unlocked.upgrades = true;
    }
    updateUI();
  }

  function bottleSmokySauce() {
    if (state.peppers.jalapeno < 15) return;
    state.peppers.jalapeno -= 15;
    state.bottles.smoky += 1;
    state.stats.totalBottles += 1;

    const sale = 15.00;
    state.cash += sale;
    state.stats.totalRevenue += sale;

    sfx.playBottle();
    sfx.playCash();
    updateUI();
  }

  function buyUpgrade(key) {
    if (key === 'capper') {
      const cost = getCapperCost();
      if (state.cash >= cost) {
        state.cash -= cost;
        state.upgrades.capper++;
        sfx.playCash();
      }
    } else if (key === 'picker') {
      const cost = getPickerCost();
      if (state.cash >= cost) {
        state.cash -= cost;
        state.upgrades.picker++;
        sfx.playCash();
      }
    } else if (key === 'shears') {
      const cost = getShearsCost();
      if (state.cash >= cost) {
        state.cash -= cost;
        state.upgrades.shears++;
        sfx.playCash();
      }
    } else if (key === 'jalapeno') {
      const cost = getJalapenoCost();
      if (state.cash >= cost && !state.unlocked.jalapeno) {
        state.cash -= cost;
        state.upgrades.jalapeno = 1;
        state.unlocked.jalapeno = true;
        sfx.playCash();
      }
    }
    updateUI();
  }

  // --- Progressive Disclosure ---
  function checkProgressiveDisclosure() {
    // 20 peppers reveals the kitchen bottling station!
    if (state.stats.totalPeppers >= 20 && !state.unlocked.bottling) {
      state.unlocked.bottling = true;
      const card = document.getElementById('bottling-card');
      card.classList.remove('hidden');
      card.style.animation = 'flashPill 0.8s ease-out';
    }

    if (state.unlocked.upgrades) {
      document.getElementById('upgrades-card').classList.remove('hidden');
    }

    if (state.unlocked.jalapeno) {
      document.getElementById('jalapeno-stock-pill').classList.remove('hidden');
      document.getElementById('recipe-smoky-sauce').classList.remove('hidden');
      document.getElementById('upgrade-jalapeno-row').classList.add('hidden');
      document.getElementById('brand-tier-label').textContent = 'Backyard Jalapeño Batch #2';
    }
  }

  // --- Visual Floating Particles ---
  function spawnParticle(event, text, isCrit, isFrenzy) {
    const container = document.getElementById('particle-container');
    const pt = document.createElement('div');
    pt.className = 'float-particle' + (isCrit ? ' crit' : '') + (isFrenzy ? ' frenzy-pt' : '');
    pt.textContent = text;

    const rect = container.getBoundingClientRect();
    let x = rect.width / 2;
    let y = rect.height / 2;

    if (event && event.clientX) {
      x = event.clientX - rect.left;
      y = event.clientY - rect.top;
    }

    // Random jitter
    x += (Math.random() - 0.5) * 40;
    y += (Math.random() - 0.5) * 20;

    pt.style.left = `${x}px`;
    pt.style.top = `${y}px`;

    container.appendChild(pt);
    setTimeout(() => {
      if (pt.parentNode) pt.parentNode.removeChild(pt);
    }, 800);
  }

  // --- UI Update Loop ---
  function updateUI() {
    // Currencies
    document.getElementById('cash-display').textContent = (state.cash).toFixed(2);
    document.getElementById('bell-count').textContent = fmtInt(state.peppers.bell);
    document.getElementById('jalapeno-count').textContent = fmtInt(state.peppers.jalapeno);

    // Loose Sell Buttons
    const looseVal = (state.peppers.bell * 0.05);
    document.getElementById('sell-raw-val').textContent = fmtMoney(looseVal);
    document.getElementById('sell-raw-btn').disabled = state.peppers.bell <= 0;

    const looseJalVal = (state.peppers.jalapeno * 0.35);
    document.getElementById('sell-jalapeno-val').textContent = fmtMoney(looseJalVal);
    document.getElementById('sell-jalapeno-btn').disabled = state.peppers.jalapeno <= 0;

    // Bottling Buttons
    document.getElementById('bottle-table-btn').disabled = state.peppers.bell < 20;
    document.getElementById('bottle-smoky-btn').disabled = state.peppers.jalapeno < 15;
    document.getElementById('total-bottles-crafted').textContent = fmtInt(state.stats.totalBottles);

    // Heat & Frenzy UI
    const isFrenzy = state.frenzyTimer > 0;
    const heatFill = document.getElementById('heat-fill');
    const heatMult = document.getElementById('heat-mult-label');
    const tapBtn = document.getElementById('tap-button');
    const flameOverlay = document.getElementById('flame-overlay');
    const flashPill = document.getElementById('flash-boil-pill');

    if (isFrenzy) {
      heatFill.style.width = '100%';
      heatMult.textContent = '5.0× BOIL';
      heatMult.style.color = 'var(--crimson-main)';
      tapBtn.classList.add('frenzy');
      flameOverlay.classList.remove('hidden');
      flashPill.classList.remove('hidden');
      document.getElementById('button-title').textContent = 'FLASH BOIL!';
      document.getElementById('button-subtext').textContent = `+${(1 + state.upgrades.shears) * 5} Peppers (Frenzy)`;
    } else {
      heatFill.style.width = `${state.heat}%`;
      const currentMult = 1.0 + (state.heat / 100.0) * 0.8;
      heatMult.textContent = `${currentMult.toFixed(1)}×`;
      heatMult.style.color = 'var(--orange-main)';
      tapBtn.classList.remove('frenzy');
      flameOverlay.classList.add('hidden');
      flashPill.classList.add('hidden');
      document.getElementById('button-title').textContent = 'PICK PEPPER';
      document.getElementById('button-subtext').textContent = `+${1 + state.upgrades.shears} Bell Pepper`;
    }

    // Upgrades
    document.getElementById('capper-lvl').textContent = `Lv ${state.upgrades.capper}`;
    document.getElementById('capper-cost').textContent = getCapperCost().toFixed(2);
    document.getElementById('buy-capper-btn').disabled = state.cash < getCapperCost();

    document.getElementById('picker-lvl').textContent = `Lv ${state.upgrades.picker}`;
    document.getElementById('picker-cost').textContent = getPickerCost().toFixed(2);
    document.getElementById('buy-picker-btn').disabled = state.cash < getPickerCost();

    document.getElementById('shears-lvl').textContent = `Lv ${state.upgrades.shears}`;
    document.getElementById('shears-cost').textContent = getShearsCost().toFixed(2);
    document.getElementById('buy-shears-btn').disabled = state.cash < getShearsCost();

    document.getElementById('buy-jalapeno-btn').disabled = state.cash < getJalapenoCost();

    // Stats
    document.getElementById('stat-peppers').textContent = fmtInt(state.stats.totalPeppers);
    document.getElementById('stat-bottles').textContent = fmtInt(state.stats.totalBottles);
    document.getElementById('stat-revenue').textContent = fmtMoney(state.stats.totalRevenue);
    document.getElementById('stat-frenzies').textContent = fmtInt(state.stats.totalFrenzies);

    // Cards disclosure
    if (state.unlocked.bottling) {
      document.getElementById('bottling-card').classList.remove('hidden');
    }
    if (state.unlocked.upgrades) {
      document.getElementById('upgrades-card').classList.remove('hidden');
    }
    if (state.unlocked.jalapeno) {
      document.getElementById('jalapeno-stock-pill').classList.remove('hidden');
      document.getElementById('recipe-smoky-sauce').classList.remove('hidden');
      document.getElementById('upgrade-jalapeno-row').classList.add('hidden');
    }
  }

  // --- Main Tick Loop (10 ticks / sec) ---
  let autoCapperAccumulator = 0;
  setInterval(() => {
    // 1. Heat decay
    if (state.frenzyTimer > 0) {
      state.frenzyTimer -= 0.1;
      if (state.frenzyTimer <= 0) {
        state.frenzyTimer = 0;
        state.heat = 0;
      }
    } else {
      if (state.heat > 0) {
        state.heat = Math.max(0, state.heat - 1.2);
      }
    }

    // 2. Passive Field Pickers
    if (state.upgrades.picker > 0) {
      const passiveRate = state.upgrades.picker * 2 * 0.1; // 2 per second per lvl
      state.peppers.bell += passiveRate;
      state.stats.totalPeppers += passiveRate;
      checkProgressiveDisclosure();
    }

    // 3. Automated Hand Capper
    if (state.upgrades.capper > 0) {
      const intervalSec = Math.max(0.8, 4.0 / (1 + state.upgrades.capper * 0.35));
      autoCapperAccumulator += 0.1;
      if (autoCapperAccumulator >= intervalSec) {
        autoCapperAccumulator = 0;
        if (state.peppers.bell >= 20) {
          bottleTableSauce();
        }
      }
    }

    updateUI();
  }, 100);

  // Auto-save every 3 seconds
  setInterval(saveGame, 3000);

  // --- Event Listeners Setup ---
  window.addEventListener('DOMContentLoaded', () => {
    loadGame();
    checkProgressiveDisclosure();
    updateUI();

    document.getElementById('tap-button').addEventListener('click', handleTap);
    document.getElementById('sell-raw-btn').addEventListener('click', sellRawPeppers);
    document.getElementById('sell-jalapeno-btn').addEventListener('click', sellRawJalapenos);
    document.getElementById('bottle-table-btn').addEventListener('click', bottleTableSauce);
    document.getElementById('bottle-smoky-btn').addEventListener('click', bottleSmokySauce);

    document.getElementById('buy-capper-btn').addEventListener('click', () => buyUpgrade('capper'));
    document.getElementById('buy-picker-btn').addEventListener('click', () => buyUpgrade('picker'));
    document.getElementById('buy-shears-btn').addEventListener('click', () => buyUpgrade('shears'));
    document.getElementById('buy-jalapeno-btn').addEventListener('click', () => buyUpgrade('jalapeno'));

    document.getElementById('reset-game-btn').addEventListener('click', resetGame);

    const soundBtn = document.getElementById('sound-toggle');
    soundBtn.addEventListener('click', () => {
      sfx.init();
      const on = sfx.toggle();
      soundBtn.textContent = on ? '🔊' : '🔇';
    });
  });
})();
