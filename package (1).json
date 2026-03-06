/* global io */

const socket = io();

let ROLE = null;
let ROOM = null;
let ADMIN_SECRET = null;
let PLAYER_ID = null;
let STATE = null;

// Research cache (client-side only)
let CURRENT_ROUND = null;
let REVEALED = {};
let REVEAL_ORDER = [];

// Change 8: preserve invest form values across state updates
let INVEST_FORM_VALUES = {};

const $ = (id) => document.getElementById(id);

function money(n) {
  const sign = n < 0 ? '-' : '';
  const abs = Math.abs(Math.round(n));
  return sign + '$' + abs.toLocaleString('en-US');
}

function signedMoney(n) {
  const v = Math.round(n);
  const s = v >= 0 ? '+' : '-';
  return s + '$' + Math.abs(v).toLocaleString('en-US');
}

function htmlEscape(s) {
  return String(s).replace(/[&<>\"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

// ── CHEAT SHEET DATA ──────────────────────────────────────────────────────────

const CHEAT_MACROS = [
  { name: 'Innovation Boom',       shifts: { Growth: +2, Defensive: -1 } },
  { name: 'Commodity Spike',       shifts: { Normal: -2, Growth: +1 } },
  { name: 'Public Safety Mandate', shifts: { Defensive: +2, Growth: -2 } },
  { name: 'Geopolitical Standoff', shifts: { Defensive: +1, Military: -2 } },
  { name: 'Consumer Expansion',    shifts: { Normal: +2, Military: -1 } },
  { name: 'Regulatory Clampdown',  shifts: { Normal: +1, Defensive: -2 } },
  { name: 'War Mobilization',      shifts: { Military: +2, Normal: -2 } },
  { name: 'Credit Crisis',         shifts: { Defensive: +1, Normal: -2, Growth: -2, Military: -2 } },
];

const CHEAT_PROJECTS = [
  { name: 'Municipal Utilities Network',  cls: 'Defensive', table: [{r:'2–4',p:-100},{r:'5–7',p:0},{r:'8–9',p:100},{r:'10–11',p:200},{r:'12',p:300}] },
  { name: 'Food Processing Consortium',   cls: 'Defensive', table: [{r:'2–3',p:-200},{r:'4–6',p:0},{r:'7–8',p:100},{r:'9–10',p:200},{r:'11–12',p:400}] },
  { name: 'Government Bond Syndicate',    cls: 'Defensive', table: [{r:'2–5',p:100},{r:'6–9',p:200},{r:'10–12',p:200}] },
  { name: 'National Railroad Expansion',  cls: 'Normal',    table: [{r:'2–3',p:-300},{r:'4–6',p:-100},{r:'7–8',p:100},{r:'9–10',p:300},{r:'11–12',p:500}] },
  { name: 'Commercial Banking Expansion', cls: 'Normal',    table: [{r:'2–3',p:-300},{r:'4–5',p:-100},{r:'6–8',p:300},{r:'9–10',p:200},{r:'11–12',p:0}] },
  { name: 'Distillery',                   cls: 'Normal',    table: [{r:'2–3',p:400},{r:'4–5',p:300},{r:'6–7',p:200},{r:'8–9',p:100},{r:'10–11',p:0},{r:'12',p:-100}] },
  { name: 'Steel Foundry Modernization',  cls: 'Growth',    table: [{r:'2–3',p:-400},{r:'4–6',p:-200},{r:'7–8',p:100},{r:'9–10',p:400},{r:'11–12',p:700}] },
  { name: 'Electrical Grid Innovation',   cls: 'Growth',    table: [{r:'2–4',p:-500},{r:'5–7',p:0},{r:'8–9',p:200},{r:'10–12',p:600}] },
  { name: 'Transcontinental Shipping',    cls: 'Growth',    table: [{r:'2–4',p:-300},{r:'5–6',p:-100},{r:'7–8',p:200},{r:'9–10',p:400},{r:'11–12',p:600}] },
  { name: 'Arms Manufacturing Contract',  cls: 'Military',  table: [{r:'2–3',p:300},{r:'4–6',p:200},{r:'7–8',p:100},{r:'9–10',p:-100},{r:'11–12',p:-200}] },
  { name: 'Naval Shipyard Expansion',     cls: 'Military',  table: [{r:'2–4',p:-300},{r:'5–6',p:-100},{r:'7–8',p:100},{r:'9–10',p:300},{r:'11–12',p:500}] },
  { name: 'Advanced Weapons R&D',         cls: 'Military',  table: [{r:'2–4',p:-600},{r:'5–7',p:-200},{r:'8–9',p:0},{r:'10–11',p:500},{r:'12',p:1000}] },
];

const CHEAT_MODIFIERS = [
  { name: 'Structural Advantage',      type: 'Single',       text: "If payout is positive → +$200." },
  { name: 'Demand Stability',          type: 'Single',       text: "If payout is negative → improve by +$200." },
  { name: 'Operational Fragility',     type: 'Single',       text: "If payout is negative → worsen by -$200." },
  { name: 'Scale Inefficiency',        type: 'Single',       text: "If over-invested → reduce any positive payout by -$200." },
  { name: 'Monopoly Amplifier',        type: 'Cross',        text: "Highest positive payout: all others –$200; this gains half of total removed (ties: no effect)." },
  { name: 'Supply Chain Issues',       type: 'Cross',        text: "This project gets -$300. Successful projects in the same macro group each get +$100." },
  { name: 'Cost Externalization',      type: 'Cross',        text: "If –$100 or worse: this +$200; same class projects –$200." },
  { name: 'Substitute Cannibalization',type: 'Cross',        text: "If positive and another same-class project is also positive: both –$200." },
  { name: 'Breakthrough Discovery',    type: 'Cross (×1)',   text: "If payout ≥ +$400 → +$300." },
  { name: 'Regulatory Backlash',       type: 'Cross (×1)',   text: "If payout ≥ +$300 → –$300." },
  { name: 'Catastrophic Non-positive', type: 'Extraordinary',text: "If payout ≤ –$300 → –$300 more." },
  { name: 'Systemic Contagion',        type: 'Extraordinary',text: "If payout ≤ –$300 → ALL projects –$200." },
];

const CLASS_COLORS = { Defensive: '#4fa8ff', Normal: '#ffd38a', Growth: '#9dffb3', Military: '#ff9aa2' };
const TYPE_COLORS  = { Single: '#cfe3ff', Cross: '#ffd38a', 'Cross (×1)': '#ffd38a', Extraordinary: '#ff9aa2' };

function renderCheatSheet() {
  const el = $('cheatSheet');
  if (!el || el.dataset.loaded === '1') return;
  el.dataset.loaded = '1';

  const macroRows = CHEAT_MACROS.map(m => {
    const shifts = Object.entries(m.shifts).map(([cls, v]) => {
      const sign = v > 0 ? '+' : '';
      const color = CLASS_COLORS[cls] || '#e8eef6';
      return `<span style="color:${color}">${cls} ${sign}${v}</span>`;
    }).join(', ');
    return `<tr><td><b>${htmlEscape(m.name)}</b></td><td class="tiny">${shifts}</td></tr>`;
  }).join('');

  const classSections = ['Defensive','Normal','Growth','Military'].map(cls => {
    const projs = CHEAT_PROJECTS.filter(p => p.cls === cls);
    const color = CLASS_COLORS[cls];
    const cards = projs.map(p => {
      const rollCells = p.table.map(row => {
        const cls2 = row.p > 0 ? 'success' : row.p < 0 ? 'bad' : 'warn';
        return `<td class="mono tiny ${cls2}" style="text-align:center">${row.p > 0 ? '+' : ''}$${row.p}<br/><span class="muted" style="font-size:10px">${row.r}</span></td>`;
      }).join('');
      return `<div style="margin-bottom:8px">
        <div style="font-size:12px"><b>${htmlEscape(p.name)}</b></div>
        <table style="width:auto"><tbody><tr>${rollCells}</tr></tbody></table>
      </div>`;
    }).join('');
    return `<div style="margin-bottom:12px">
      <div style="color:${color}; font-weight:bold; font-size:13px; margin-bottom:6px; border-bottom:1px solid ${color}33; padding-bottom:3px">${cls}</div>
      ${cards}
    </div>`;
  }).join('');

  const modRows = CHEAT_MODIFIERS.map(m => {
    const color = TYPE_COLORS[m.type] || '#e8eef6';
    return `<tr>
      <td style="white-space:nowrap"><b>${htmlEscape(m.name)}</b></td>
      <td><span class="pill" style="color:${color}">${htmlEscape(m.type)}</span></td>
      <td class="tiny">${htmlEscape(m.text)}</td>
    </tr>`;
  }).join('');

  el.innerHTML = `
    <details>
      <summary style="cursor:pointer"><b>Cheat Sheet</b> — Macros, Projects &amp; Modifiers (click to expand)</summary>
      <div style="margin-top:12px">
        <div style="font-size:14px; font-weight:bold; margin-bottom:6px">Macro Regimes (roll shifts only)</div>
        <div style="overflow:auto; margin-bottom:16px">
          <table>
            <thead><tr><th>Macro</th><th>Roll Shifts</th></tr></thead>
            <tbody>${macroRows}</tbody>
          </table>
        </div>
        <div style="font-size:14px; font-weight:bold; margin-bottom:8px">Projects — Roll Tables (payout per $100 invested)</div>
        <div style="columns: 2; column-gap: 16px; margin-bottom:16px">${classSections}</div>
        <div style="font-size:14px; font-weight:bold; margin-bottom:6px">Modifiers</div>
        <div style="overflow:auto">
          <table>
            <thead><tr><th>Modifier</th><th>Type</th><th>Effect</th></tr></thead>
            <tbody>${modRows}</tbody>
          </table>
        </div>
      </div>
    </details>
  `;
}

function showApp() {
  renderCheatSheet();
  $('landing').style.display = 'none';
  $('app').style.display = 'block';
  $('roomId').textContent = ROOM;
  $('rolePill').textContent = ROLE === 'admin' ? 'ADMIN' : 'PLAYER';
  $('rolePill').className = 'pill';
  $('adminPanel').style.display = ROLE === 'admin' ? 'block' : 'none';
  $('playerPanel').style.display = ROLE === 'player' ? 'block' : 'none';
}

// ── RECONNECT ─────────────────────────────────────────────────────────────────

socket.on('connect', () => {
  if (!ROOM || !ROLE) return;
  socket.emit('rejoin_room', { roomId: ROOM, playerId: PLAYER_ID || undefined, adminSecret: ADMIN_SECRET || undefined }, (resp) => {
    if (!resp?.ok) console.warn('Rejoin failed:', resp?.error);
  });
});

// ── SCOREBOARD ────────────────────────────────────────────────────────────────

function renderScoreboard() {
  const el = $('scoreboard');
  if (!el) return;

  const maxRounds = STATE?.game?.maxRounds || 5;
  const players = [].concat(STATE?.players || []).concat(STATE?.eliminatedPlayers || []);

  if (players.length === 0) {
    el.innerHTML = '<h3>Scoreboard</h3><div class="muted tiny">No players yet.</div>';
    return;
  }

  players.sort((a, b) => {
    const aElim = !!a.eliminatedAtRound;
    const bElim = !!b.eliminatedAtRound;
    if (aElim !== bElim) return aElim ? 1 : -1;
    return (b.money || 0) - (a.money || 0);
  });

  const hdrRounds = Array.from({ length: maxRounds }, (_, i) => `<th class="mono">R${i + 1}</th>`).join('');
  const rows = players.map(p => {
    const hist = p.history || [];
    const byRound = new Map(hist.map(h => [h.round, h.net]));
    const roundCells = Array.from({ length: maxRounds }, (_, i) => {
      const r = i + 1;
      const net = byRound.get(r);
      if (net == null) return '<td class="mono muted">—</td>';
      const cls = net >= 0 ? 'success' : 'bad';
      return `<td class="mono ${cls}">${signedMoney(net)}</td>`;
    }).join('');

    const totalMoney = p.money ?? 0;
    const starting = p.startingMoney ?? totalMoney;
    const totalNet = totalMoney - starting;
    const name = htmlEscape(p.name || 'Player');
    const elimTag = p.eliminatedAtRound ? ` <span class="pill">ELIM R${p.eliminatedAtRound}</span>` : '';
    return `<tr>
      <td><b>${name}</b>${elimTag}</td>
      ${roundCells}
      <td class="mono"><b>${money(totalMoney)}</b><div class="tiny ${totalNet >= 0 ? 'success' : 'bad'}">${signedMoney(totalNet)}</div></td>
    </tr>`;
  }).join('');

  const over = STATE?.game?.isOver;
  el.innerHTML = `
    <div style="display:flex; justify-content: space-between; align-items:center; gap: 10px; flex-wrap: wrap;">
      <h3 style="margin:0">Scoreboard</h3>
      <div class="muted tiny">${over ? '<span class="pill">FINAL</span>' : 'Updates after each Resolve Round.'}</div>
    </div>
    <div style="overflow:auto; margin-top: 8px;">
      <table>
        <thead><tr><th>Player</th>${hdrRounds}<th class="mono">Total ($)</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
    </div>
  `;
}

// ── MACRO DETAILS ─────────────────────────────────────────────────────────────

function renderMacroDetails() {
  const el = $('macroDetails');
  if (!el) return;

  const macro = STATE?.round?.macro;
  if (!macro) {
    el.innerHTML = '<h3>Macro Regime</h3><div class="muted tiny">No macro dealt yet.</div>';
    return;
  }

  const shifts = macro.rollShiftByClass || {};
  const shiftLines = Object.entries(shifts).map(([cls, v]) => {
    const sign = v >= 0 ? '+' : '';
    const css = v >= 0 ? 'success' : 'bad';
    return `<li><span class="pill mono">${htmlEscape(cls)}</span> roll shift: <span class="mono ${css}">${sign}${v}</span></li>`;
  }).join('');

  el.innerHTML = `
    <h3 style="margin:0 0 6px">Macro: <b>${htmlEscape(macro.name)}</b></h3>
    <div class="tiny">
      <ul style="margin: 0 0 10px 18px; padding:0">
        ${shiftLines || '<li class="muted">No roll shifts.</li>'}
      </ul>
      <div class="muted tiny">Macro only affects the roll, not payouts directly.</div>
    </div>
  `;
}

// ── MAIN RENDER ───────────────────────────────────────────────────────────────

function render() {
  if (!STATE) return;

  if (ROLE === 'player' && STATE?.round?.number != null) {
    if (CURRENT_ROUND === null) {
      CURRENT_ROUND = STATE.round.number;
    } else if (CURRENT_ROUND !== STATE.round.number) {
      CURRENT_ROUND = STATE.round.number;
      REVEALED = {};
      REVEAL_ORDER = [];
      INVEST_FORM_VALUES = {}; // reset on new round
    }
  }

  $('phase').textContent = STATE.round.phase || '—';
  $('roundNum').textContent = String(STATE.round.number || 0);
  $('macroName').textContent = STATE.round.macro ? STATE.round.macro.name : '—';

  renderScoreboard();
  renderMacroDetails();
  renderCheatSheet();
  renderPayoutCalculator();

  const gameOver = !!STATE.game?.isOver;

  // Players list
  const players = STATE.players || [];
  $('players').innerHTML = players.map(p => {
    const submitted = !!p.round?.investmentsSubmitted;
    const insurance = !!p.round?.boughtInsurance;
    const rp = p.round?.researchPurchases || 0;
    const statusBits = [];
    if (submitted) statusBits.push('<span class="pill">invest submitted</span>');
    if (insurance) statusBits.push('<span class="pill">insured</span>');
    if (rp > 0) statusBits.push(`<span class="pill">research ×${rp}</span>`);
    return `
      <div class="card" style="background:#0e1520; margin: 8px 0">
        <div style="display:flex; justify-content: space-between; gap: 10px; flex-wrap: wrap; align-items: center;">
          <div>
            <div><b>${htmlEscape(p.name)}</b></div>
            <div class="mono">${money(p.money)}</div>
          </div>
          <div style="display:flex; gap:6px; flex-wrap: wrap;">${statusBits.join('')}</div>
        </div>
      </div>
    `;
  }).join('') || '<div class="muted">No players yet.</div>';

  // Projects
  const projects = STATE.round.projects || [];
  $('projects').innerHTML = projects.map(p => {
    let shownModifier = p.modifier;
    if (ROLE === 'player' && shownModifier && shownModifier.type === 'Hidden') {
      const byId = REVEALED['id:' + p.id];
      const byName = REVEALED['name:' + p.name];
      if (byId || byName) shownModifier = (byId || byName).modifier;
    }

    const mod = shownModifier
      ? `${htmlEscape(shownModifier.name)} <span class="muted">(${htmlEscape(shownModifier.type)})</span>`
      : '—';

    const cheatProj = CHEAT_PROJECTS.find(c => p.name.startsWith(c.name.slice(0, 12)));
    const rollTable = cheatProj ? `
      <div style="display:flex; gap:4px; flex-wrap:wrap; margin-top:6px">
        ${cheatProj.table.map(row => {
          const cls = row.p > 0 ? 'success' : row.p < 0 ? 'bad' : 'warn';
          return `<div style="text-align:center; background:#0b0f14; border-radius:6px; padding:3px 6px; min-width:36px">
            <div class="mono tiny ${cls}">${row.p > 0 ? '+' : ''}$${row.p}</div>
            <div class="muted" style="font-size:10px">${row.r}</div>
          </div>`;
        }).join('')}
      </div>` : '';

    const clsColor = CLASS_COLORS[p.class] || '#e8eef6';

    return `
      <div class="card" style="background:#0e1520; margin: 8px 0">
        <div style="display:flex; justify-content: space-between; gap: 10px; flex-wrap: wrap;">
          <div style="flex:1">
            <div><b>${htmlEscape(p.name)}</b> <span class="pill" style="color:${clsColor}">${htmlEscape(p.class)}</span></div>
            ${rollTable}
          </div>
          <div class="tiny" style="text-align:right; white-space:nowrap">
            <div class="muted">Modifier</div>
            <div>${mod}</div>
          </div>
        </div>
      </div>
    `;
  }).join('') || '<div class="muted">No projects dealt yet.</div>';

  // Player panel
  if (ROLE === 'player') {
    const me = STATE.players.find(p => p.id === PLAYER_ID);
    if (me) {
      // Change 5: show real-time money
      $('playerMoney').textContent = `Your money: ${money(me.money)}`;

      const wants = !!me.round?.boughtInsurance;
      $('insuranceToggle').checked = wants;
      $('insuranceStatus').textContent = wants
        ? 'Insurance active — $300 already deducted.'
        : 'No insurance (toggle to buy for $300).';

      // Change 8: don't re-render invest form if player already submitted — preserve values
      const submitted = !!me.round?.investmentsSubmitted;
      if (!submitted) {
        renderInvestForm(projects, INVEST_FORM_VALUES);
      }
    }

    renderResearchPicker(projects);

    const phase = STATE.round.phase;
    $('buyResearch').disabled = (phase !== 'RESEARCH') || gameOver;
    $('insuranceToggle').disabled = (phase !== 'INSURANCE') || gameOver;
    $('submitInvest').disabled = (phase !== 'INVEST') || gameOver;

    $('researchResults').innerHTML = REVEAL_ORDER.map(key => {
      const r = REVEALED[key];
      if (!r) return '';
      return `
        <div class="card" style="background:#0b0f14; margin:6px 0">
          <div><b>${htmlEscape(r.projectName)}</b></div>
          <div class="muted tiny">Modifier: <span class="pill">${htmlEscape(r.modifier.type)}</span> <b>${htmlEscape(r.modifier.name)}</b></div>
          <div class="tiny">${htmlEscape(r.modifier.text || '')}</div>
        </div>
      `;
    }).join('');
  }

  // Admin panel
  if (ROLE === 'admin') {
    const r = STATE.round.marketRoll;
    $('marketRoll').textContent = r ? `${r.d1}+${r.d2}=${r.total}` : '—';
  }

  // Resolution
  if (STATE.round.lastResolution) {
    $('resolution').classList.remove('muted');
    $('resolution').innerHTML = renderResolution(STATE.round.lastResolution);
  } else {
    $('resolution').classList.add('muted');
    $('resolution').textContent = 'No resolution yet.';
  }

  // Event log
  const log = (STATE.log || []).slice(-40).reverse();
  $('log').innerHTML = log.map(e => `${new Date(e.t).toLocaleTimeString()}  ${htmlEscape(e.type)}  ${htmlEscape(e.msg)}`).join('<br/>') || '<span class="muted">No events yet.</span>';

  // Freeze controls when game over
  const freezeIds = ['startRound','setPhaseResearch','setPhaseInsurance','setPhaseInvest','rollMarket','setMarket','resolveRound','buyResearch','doResearch','cancelResearch','insuranceToggle','submitInvest','endGame'];
  for (const id of freezeIds) {
    const btn = $(id);
    if (btn) btn.disabled = gameOver;
  }
}

// ── RESOLUTION RENDERER ───────────────────────────────────────────────────────

function renderResolution(res) {
  const perProject = res.perProject || [];
  const perPlayer = res.perPlayer || {};
  const allPlayers = Object.values(perPlayer);
  // Build playerId -> name map from all sources
  const playerNames = res.playerNames || {};
  for (const pp of allPlayers) {
    if (pp.playerId && pp.playerName) playerNames[pp.playerId] = pp.playerName;
  }

  // Change 9c: project table now includes "Investors" column showing who invested what
  const projRows = perProject.map(p => {
    const cls = p.payoutPer100 > 0 ? 'success' : (p.payoutPer100 === 0 ? 'warn' : 'bad');
    const mod = p.modifier ? `${htmlEscape(p.modifier.name)}` : '—';
    const notes = (p.notes || []).map(n => `• ${htmlEscape(n)}`).join('<br/>');

    // Change 9b: list all investors
    const investors = (p.investors || []);
    const investorLines = investors.length > 0
      ? investors.map(inv => {
          const name = htmlEscape(playerNames[inv.playerId] || inv.playerId);
          return `<div>${name}: <span class="mono">${money(inv.amount)}</span></div>`;
        }).join('')
      : '<div class="muted">None</div>';

    return `
      <tr>
        <td><b>${htmlEscape(p.name)}</b><div class="muted tiny">${htmlEscape(p.class)}</div></td>
        <td class="mono">${money(p.totalInvested)}</td>
        <td class="tiny">${investorLines}</td>
        <td class="mono">${p.adjustedRoll}</td>
        <td>${mod}</td>
        <td class="mono ${cls}">${p.payoutPer100 > 0 ? '+' : ''}${money(p.payoutPer100)}</td>
        <td class="tiny">${p.underMin ? '<span class="pill">UNDER $500 → $0, capital lost</span><br/>' : ''}${notes}</td>
      </tr>
    `;
  }).join('');

  // Change 9c: player money table now has Name as first column
  const playerRows = allPlayers.map(p => {
    const cls = p.endMoney >= 500 ? 'success' : 'bad';
    const name = htmlEscape(p.playerName || playerNames[p.playerId] || p.playerId || '?');
    return `
      <tr>
        <td><b>${name}</b></td>
        <td class="mono">${money(p.startMoney)}</td>
        <td class="mono">${money(-p.totalInvested)}</td>
        <td class="mono">${money(-p.researchCost)}</td>
        <td class="mono">${money(-p.insuranceCost)}</td>
        <td class="mono">${money(p.returnedCapital)}</td>
        <td class="mono">${money(p.incrementalAfterInsurance)}</td>
        <td class="mono ${cls}"><b>${money(p.endMoney)}</b></td>
      </tr>
    `;
  }).join('');

  const eliminated = (res.eliminated || []).map(x => `<div class="bad">Eliminated: ${htmlEscape(x.name)} (${money(x.money)})</div>`).join('');

  return `
    <div class="tiny" style="margin-bottom:8px">
      Market roll: <span class="mono">${res.marketRoll.d1}+${res.marketRoll.d2}=${res.marketRoll.total}</span>
      • Macro: <b>${htmlEscape(res.macro.name)}</b>
      ${res.systemicTriggered ? ' • <span class="bad">Systemic Contagion triggered</span>' : ''}
    </div>
    <div class="card" style="background:#0e1520">
      <b>Projects</b>
      <div style="overflow:auto">
        <table>
          <thead>
            <tr>
              <th>Project</th>
              <th>Total Invested</th>
              <th>Investors</th>
              <th>Adj Roll</th>
              <th>Modifier</th>
              <th>Payout / $100</th>
              <th>Notes</th>
            </tr>
          </thead>
          <tbody>${projRows}</tbody>
        </table>
      </div>
    </div>
    <div class="card" style="background:#0e1520">
      <b>Player Results</b>
      <div class="muted tiny">Research and insurance costs are deducted in real time (shown here for reference).</div>
      <div style="overflow:auto">
        <table>
          <thead>
            <tr>
              <th>Player</th>
              <th>Start</th>
              <th>−Invested</th>
              <th>−Research</th>
              <th>−Insurance</th>
              <th>+Capital Returned</th>
              <th>+Incremental Payout</th>
              <th>End</th>
            </tr>
          </thead>
          <tbody>${playerRows}</tbody>
        </table>
      </div>
      ${eliminated}
    </div>
  `;
}

// ── INVEST FORM ───────────────────────────────────────────────────────────────

function renderInvestForm(projects, current) {
  const phase = STATE.round.phase;
  const disabled = phase !== 'INVEST';

  const lines = projects.map(p => {
    const val = Number(current?.[p.id] || 0);
    return `
      <div style="display:flex; justify-content: space-between; gap: 10px; align-items: center; margin: 6px 0;">
        <div style="min-width: 220px"><b>${htmlEscape(p.name)}</b> <span class="pill">${htmlEscape(p.class)}</span></div>
        <div style="display:flex; gap:6px; align-items:center;">
          <button data-dec="${p.id}" ${disabled ? 'disabled' : ''}>-$100</button>
          <input data-amt="${p.id}" class="mono" style="width:120px" value="${val}" ${disabled ? 'disabled' : ''} />
          <button data-inc="${p.id}" ${disabled ? 'disabled' : ''}>+$100</button>
        </div>
      </div>
    `;
  }).join('');

  $('investForm').innerHTML = lines;

  // Change 8: update the in-memory values when user changes them
  $('investForm').querySelectorAll('input[data-amt]').forEach(inp => {
    inp.oninput = () => {
      INVEST_FORM_VALUES[inp.getAttribute('data-amt')] = Number(inp.value || 0);
    };
  });
  $('investForm').querySelectorAll('button[data-inc]').forEach(btn => {
    btn.onclick = () => {
      const id = btn.getAttribute('data-inc');
      const inp = $('investForm').querySelector(`input[data-amt="${id}"]`);
      const newVal = Number(inp.value || 0) + 100;
      inp.value = String(newVal);
      INVEST_FORM_VALUES[id] = newVal;
    };
  });
  $('investForm').querySelectorAll('button[data-dec]').forEach(btn => {
    btn.onclick = () => {
      const id = btn.getAttribute('data-dec');
      const inp = $('investForm').querySelector(`input[data-amt="${id}"]`);
      const newVal = Math.max(0, Number(inp.value || 0) - 100);
      inp.value = String(newVal);
      INVEST_FORM_VALUES[id] = newVal;
    };
  });
}

function readInvestForm(projects) {
  const inv = {};
  for (const p of projects) {
    const v = INVEST_FORM_VALUES[p.id] || 0;
    if (v) inv[p.id] = v;
  }
  return inv;
}

// ── PAYOUT CALCULATOR ─────────────────────────────────────────────────────────
// Shows baseline payout per $100 for each active project across rolls 2–12,
// applying the current macro's roll shift. Ignores modifiers and penalties.

function renderPayoutCalculator() {
  const el = $('payoutCalculator');
  if (!el) return;

  const projects = STATE?.round?.projects || [];
  const macro = STATE?.round?.macro;

  if (projects.length === 0) {
    el.innerHTML = '<div class="muted tiny">No projects dealt yet.</div>';
    return;
  }

  // For each project look up its full table from CHEAT_PROJECTS
  const resolved = projects.map(p => {
    const cheat = CHEAT_PROJECTS.find(c => p.name.startsWith(c.name.slice(0, 12)));
    const shift = macro?.rollShiftByClass?.[p.class] ?? 0;
    return { proj: p, cheat, shift };
  });

  // Header row: project names
  const thCols = resolved.map(({ proj }) => {
    const color = CLASS_COLORS[proj.class] || '#e8eef6';
    return `<th style="text-align:center; min-width:80px; font-size:11px">
      <div style="color:${color}">${htmlEscape(proj.name.split(' ').slice(0,2).join(' '))}</div>
      <div class="muted" style="font-size:10px; font-weight:normal">${htmlEscape(proj.class)}</div>
    </th>`;
  }).join('');

  // Build rows for raw rolls 2–12
  const rows = [];
  for (let roll = 2; roll <= 12; roll++) {
    const cells = resolved.map(({ proj, cheat, shift }) => {
      if (!cheat) return '<td class="mono muted" style="text-align:center">?</td>';

      // Apply macro roll shift, clamped 2–12
      const adjRoll = Math.max(2, Math.min(12, roll + shift));

      // Lookup payout from proj's actual table (most accurate)
      let payout = null;
      for (const row of proj.table) {
        if (adjRoll >= row.min && adjRoll <= row.max) { payout = row.payout; break; }
      }
      if (payout === null) {
        // fallback to cheat table
        for (const row of cheat.table) {
          const [lo, hi] = row.r.includes('–') ? row.r.split('–').map(Number) : [Number(row.r), Number(row.r)];
          if (adjRoll >= lo && adjRoll <= hi) { payout = row.p; break; }
        }
      }
      if (payout === null) return '<td class="mono muted" style="text-align:center">—</td>';

      const cls = payout > 0 ? 'success' : payout < 0 ? 'bad' : 'warn';
      const shiftNote = shift !== 0 ? `<div style="font-size:9px; color:#6a7f99">${roll}→${adjRoll}</div>` : '';
      return `<td class="mono ${cls}" style="text-align:center; padding:4px 6px">
        ${payout > 0 ? '+' : ''}$${payout}
        ${shiftNote}
      </td>`;
    }).join('');

    // Highlight the current market roll row if known
    const marketRoll = STATE?.round?.marketRoll?.total;
    const isCurrentRoll = (roll === marketRoll);
    const rowStyle = isCurrentRoll
      ? 'background:#1e2d1e; outline:1px solid #9dffb3;'
      : (roll % 2 === 0 ? 'background:#0e1520' : '');

    rows.push(`<tr style="${rowStyle}">
      <td class="mono" style="text-align:center; color:#6a7f99; padding:4px 8px; font-size:12px">${roll}</td>
      ${cells}
    </tr>`);
  }

  const macroShiftNote = macro
    ? Object.entries(macro.rollShiftByClass || {})
        .map(([cls, v]) => `<span style="color:${CLASS_COLORS[cls]}">${cls} ${v > 0 ? '+' : ''}${v}</span>`)
        .join(' · ')
    : '';

  el.innerHTML = `
    <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; margin-bottom:8px">
      <b>Payout Calculator</b>
      <div class="muted tiny">${macroShiftNote ? `Macro shifts applied: ${macroShiftNote}` : 'No macro yet — showing raw rolls.'} &nbsp;Ignores modifiers &amp; penalties.</div>
    </div>
    <div style="overflow-x:auto">
      <table style="border-collapse:collapse; width:100%">
        <thead>
          <tr>
            <th style="text-align:center; color:#6a7f99; font-size:11px; min-width:36px">Roll</th>
            ${thCols}
          </tr>
        </thead>
        <tbody>${rows.join('')}</tbody>
      </table>
    </div>
    ${STATE?.round?.marketRoll ? `<div class="muted tiny" style="margin-top:6px">Current roll highlighted: <span class="mono success">${STATE.round.marketRoll.total}</span></div>` : ''}
  `;
}

// ── RESEARCH PICKER ───────────────────────────────────────────────────────────

function renderResearchPicker(projects) {
  if (STATE.round.phase !== 'RESEARCH') {
    $('researchPicker').style.display = 'none';
  }
}

// Change 6: research picks 1 project only
function openResearchPicker(projects) {
  $('researchPicker').style.display = 'block';
  const opts = projects.map(p => `<option value="${p.id}">${htmlEscape(p.name)} (${htmlEscape(p.class)})</option>`).join('');
  $('researchPicker').innerHTML = `
    <div class="muted tiny">Pick 1 project to peek at its modifier ($100):</div>
    <div style="display:flex; gap: 8px; flex-wrap: wrap; margin-top: 8px">
      <select id="r1">${opts}</select>
      <button id="doResearch" class="primary">Reveal</button>
      <button id="cancelResearch">Cancel</button>
    </div>
  `;

  $('cancelResearch').onclick = () => { $('researchPicker').style.display = 'none'; };

  $('doResearch').onclick = () => {
    const r1 = $('r1').value;
    // Change 6: send single project id
    socket.emit('player_buy_research', { projectIds: [r1] }, (resp) => {
      if (!resp?.ok) { alert(resp?.error || 'Error'); return; }

      const revealed = resp.revealed || [];
      for (const r of revealed) {
        const idKey = 'id:' + r.projectId;
        const nameKey = 'name:' + r.projectName;
        if (!REVEALED[idKey]) {
          REVEALED[idKey] = { projectName: r.projectName, modifier: r.modifier };
          REVEAL_ORDER.push(idKey);
        }
        if (!REVEALED[nameKey]) {
          REVEALED[nameKey] = { projectName: r.projectName, modifier: r.modifier };
        }
      }

      $('researchPicker').style.display = 'none';
      render();
    });
  };
}

// ── LANDING ───────────────────────────────────────────────────────────────────

$('createRoom').onclick = () => {
  const adminName = $('adminName').value || 'Admin';
  const seedRaw = $('seed').value.trim();
  const seed = seedRaw ? Number(seedRaw) : undefined;
  socket.emit('create_room', { adminName, seed: Number.isFinite(seed) ? seed : undefined }, ({ roomId, adminSecret }) => {
    $('createdInfo').innerHTML = `Room: <span class="mono">${roomId}</span><br/>Admin Secret: <span class="mono">${adminSecret}</span><br/><span class="muted">(Keep secret private.)</span>`;
    ROOM = roomId;
    ROLE = 'admin';
    ADMIN_SECRET = adminSecret;
    showApp();
  });
};

$('joinRoom').onclick = () => {
  $('joinError').textContent = '';
  const roomId = $('roomCode').value.trim();
  const name = $('playerName').value.trim();
  const adminSecret = $('adminSecret').value.trim();
  socket.emit('join_room', { roomId, name, adminSecret: adminSecret || undefined }, (resp) => {
    if (!resp?.ok) { $('joinError').textContent = resp?.error || 'Could not join.'; return; }
    ROOM = roomId.toUpperCase();
    ROLE = resp.role;
    PLAYER_ID = resp.playerId || null;
    if (resp.role === 'admin') ADMIN_SECRET = adminSecret;
    showApp();
  });
};

// ── ADMIN HANDLERS ────────────────────────────────────────────────────────────

$('startRound').onclick = () => {
  $('adminError').textContent = '';
  socket.emit('admin_start_round', {}, (resp) => {
    if (!resp?.ok) $('adminError').textContent = resp?.error || 'Error';
  });
};
$('setPhaseResearch').onclick = () => socket.emit('admin_set_phase', { phase: 'RESEARCH' });
$('setPhaseInsurance').onclick = () => socket.emit('admin_set_phase', { phase: 'INSURANCE' });
$('setPhaseInvest').onclick = () => socket.emit('admin_set_phase', { phase: 'INVEST' });
$('rollMarket').onclick = () => {
  $('adminError').textContent = '';
  socket.emit('admin_roll_market', {}, (resp) => {
    if (!resp?.ok) $('adminError').textContent = resp?.error || 'Error';
  });
};
$('setMarket').onclick = () => {
  const d1 = $('d1').value.trim();
  const d2 = $('d2').value.trim();
  socket.emit('admin_set_market_roll', { d1, d2 }, (resp) => {
    if (!resp?.ok) $('adminError').textContent = resp?.error || 'Error';
  });
};
$('resolveRound').onclick = () => {
  $('adminError').textContent = '';
  socket.emit('admin_resolve_round', {}, (resp) => {
    if (!resp?.ok) $('adminError').textContent = resp?.error || 'Error';
  });
};
$('endGame').onclick = () => {
  $('adminError').textContent = '';
  if (!confirm('End the game now?')) return;
  socket.emit('admin_end_game', {}, (resp) => {
    if (!resp?.ok) $('adminError').textContent = resp?.error || 'Error';
  });
};
$('saveGame').onclick = () => {
  socket.emit('admin_save', {}, (resp) => {
    if (!resp?.ok) return;
    const blob = new Blob([JSON.stringify(resp.state, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `the_barons_${ROOM}_round${STATE?.round?.number || 0}.json`;
    a.click();
    URL.revokeObjectURL(url);
  });
};
$('loadGame').onclick = () => $('loadFile').click();
$('loadFile').onchange = async (e) => {
  const file = e.target.files?.[0];
  if (!file) return;
  const text = await file.text();
  const state = JSON.parse(text);
  socket.emit('admin_load', { state }, (resp) => {
    if (!resp?.ok) $('adminError').textContent = resp?.error || 'Load failed';
  });
  $('loadFile').value = '';
};

// ── PLAYER HANDLERS ───────────────────────────────────────────────────────────

$('buyResearch').onclick = () => {
  const projects = STATE?.round?.projects || [];
  openResearchPicker(projects);
};

$('insuranceToggle').onchange = () => {
  $('investError').textContent = '';
  socket.emit('player_buy_insurance', { buy: $('insuranceToggle').checked }, (resp) => {
    if (!resp?.ok) {
      // Revert checkbox if failed
      $('insuranceToggle').checked = !$('insuranceToggle').checked;
      $('investError').textContent = resp?.error || 'Error';
    }
  });
};

$('submitInvest').onclick = () => {
  $('investError').textContent = '';
  const projects = STATE?.round?.projects || [];
  const inv = readInvestForm(projects);
  socket.emit('player_submit_investments', { investments: inv }, (resp) => {
    if (!resp?.ok) {
      $('investError').textContent = resp?.error || 'Error';
      return;
    }
    $('investError').innerHTML = '<span class="success">Submitted! Waiting for other players...</span>';
  });
};

// ── SOCKET STATE UPDATES ──────────────────────────────────────────────────────

socket.on('state', (state) => {
  STATE = state;
  render();
});
