import { PROJECTS, MODIFIERS, MACROS } from './gameData.js';

export function clamp(n, lo, hi) {
  return Math.max(lo, Math.min(hi, n));
}

export function deepCopy(obj) {
  return JSON.parse(JSON.stringify(obj));
}

export function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function shuffle(arr, rng = Math.random) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function buildDeckFromCopies(items) {
  const deck = [];
  for (const it of items) {
    const copies = it.copies ?? 1;
    for (let i = 0; i < copies; i++) deck.push({ ...it, instance: `${it.id}#${i + 1}` });
  }
  return deck;
}

// Change 4: projects = number of players, minimum 3
export function getProjectCountForPlayers(nPlayers) {
  return Math.max(3, nPlayers);
}

export function getOverInvestmentPenalty(totalInvested, nPlayers, thresholdBonus = 0) {
  const t = totalInvested;

  let range300 = null;
  let min500 = null;

  if (nPlayers <= 4) {
    range300 = [1400, 1900];
    min500 = 2000;
  } else if (nPlayers === 5) {
    range300 = [1700, 2200];
    min500 = 2300;
  } else {
    range300 = [1900, 2400];
    min500 = 2500;
  }

  const r0 = range300[0] + thresholdBonus;
  const r1 = range300[1] + thresholdBonus;
  const m5 = min500 + thresholdBonus;

  if (t >= m5) return -500;
  if (t >= r0 && t <= r1) return -300;
  return 0;
}

export function lookupPayout(table, roll) {
  for (const row of table) {
    if (roll >= row.min && roll <= row.max) return row.payout;
  }
  return 0;
}

export function roll2d6(rng = Math.random) {
  const d1 = 1 + Math.floor(rng() * 6);
  const d2 = 1 + Math.floor(rng() * 6);
  return { d1, d2, total: d1 + d2 };
}

export function resolveRound(state, options = {}) {
  const s = deepCopy(state);
  const rng = options.rng || Math.random;
  const insurancePrePaid = options.insurancePrePaid === true;
  const researchPrePaid = options.researchPrePaid === true;

  const nPlayers = s.players.length;
  const macro = s.round.macro;
  const marketRoll = s.round.marketRoll;
  if (!macro || !marketRoll) throw new Error('Missing macro or market roll');

  const projects = s.round.projects;

  // Investment map
  const investmentsByProject = {};
  for (const proj of projects) investmentsByProject[proj.id] = [];

  for (const p of s.players) {
    const inv = p.round?.investments || {};
    for (const [projId, amt] of Object.entries(inv)) {
      if (!investmentsByProject[projId]) continue;
      if (amt > 0) investmentsByProject[projId].push({ playerId: p.id, amount: amt });
    }
  }

  const totalInvestedByProject = {};
  for (const proj of projects) {
    totalInvestedByProject[proj.id] = investmentsByProject[proj.id].reduce((a, x) => a + x.amount, 0);
  }

  // Change 2: macro only shifts rolls, no payout adjustments
  const adjustedRollByProject = {};
  for (const proj of projects) {
    const shift = macro.rollShiftByClass?.[proj.class] ?? 0;
    adjustedRollByProject[proj.id] = clamp(marketRoll.total + shift, 2, 12);
  }

  // Base payout per $100
  const payoutPer100 = {};
  for (const proj of projects) {
    payoutPer100[proj.id] = lookupPayout(proj.table, adjustedRollByProject[proj.id]);
  }

  // Under-minimum threshold: < $500 invested → payout $0, capital lost
  const underMinByProject = {};
  for (const proj of projects) {
    underMinByProject[proj.id] = totalInvestedByProject[proj.id] < 500;
    if (underMinByProject[proj.id]) {
      payoutPer100[proj.id] = 0;
    }
  }

  // Over-investment penalty
  const overInvestPenaltyByProject = {};
  const overInvestedByProject = {};
  for (const proj of projects) {
    const pen = getOverInvestmentPenalty(totalInvestedByProject[proj.id], nPlayers, 0);
    overInvestPenaltyByProject[proj.id] = pen;
    overInvestedByProject[proj.id] = pen !== 0;
    payoutPer100[proj.id] += pen;
  }

  // Modifier effects
  const modifierImpact = {};
  for (const proj of projects) modifierImpact[proj.id] = { delta: 0, notes: [] };

  // Change 9a: note overinvestment in notes
  for (const proj of projects) {
    if (overInvestedByProject[proj.id]) {
      modifierImpact[proj.id].notes.push(`Over-invested (penalty: ${overInvestPenaltyByProject[proj.id] >= 0 ? '+' : ''}$${overInvestPenaltyByProject[proj.id]})`);
    }
  }

  // Single modifiers
  for (const proj of projects) {
    const mod = proj.modifier;
    if (!mod || mod.type !== 'Single') continue;

    const before = payoutPer100[proj.id];
    let delta = 0;

    if (mod.id === 'structural_advantage') {
      if (before > 0) delta += 200;
    } else if (mod.id === 'demand_stability') {
      if (before < 0) delta += 200;
    } else if (mod.id === 'operational_fragility') {
      if (before < 0) delta -= 200;
    } else if (mod.id === 'scale_inefficiency') {
      if (overInvestedByProject[proj.id] && before > 0) delta -= 200;
    }

    payoutPer100[proj.id] += delta;
    modifierImpact[proj.id].delta += delta;
    if (delta !== 0) modifierImpact[proj.id].notes.push(`${mod.name}: ${delta >= 0 ? '+' : ''}$${delta}`);
  }

  // Cross modifiers
  const crossMods = projects
    .filter(p => p.modifier && p.modifier.type === 'Cross')
    .map(p => ({ projectId: p.id, proj: p, mod: p.modifier }));

  function applyCrossDelta(targetProj, delta, note) {
    payoutPer100[targetProj.id] += delta;
    modifierImpact[targetProj.id].delta += delta;
    if (delta !== 0) modifierImpact[targetProj.id].notes.push(note);
  }

  // Monopoly Amplifier
  for (const cm of crossMods.filter(x => x.mod.id === 'monopoly_amplifier')) {
    const src = cm.proj;
    const positives = projects
      .map(p => ({ id: p.id, payout: payoutPer100[p.id] }))
      .filter(x => x.payout > 0);
    if (positives.length === 0) continue;
    const maxP = Math.max(...positives.map(x => x.payout));
    const top = positives.filter(x => x.payout === maxP);
    if (top.length !== 1) continue;
    if (top[0].id !== src.id) continue;

    let removedTotal = 0;
    for (const p of projects) {
      if (p.id === src.id) continue;
      applyCrossDelta(p, -200, `Monopoly Amplifier: -$200 (due to ${src.name})`);
      removedTotal += 200;
    }
    const gain = Math.floor(removedTotal / 2);
    applyCrossDelta(src, gain, `Monopoly Amplifier: +$${gain} (captured removed payout points)`);
  }

  // Supply Chain Issues: this project -$300; successful same-class projects each +$100
  for (const cm of crossMods.filter(x => x.mod.id === 'supply_chain_issues')) {
    const src = cm.proj;
    // Always apply -$300 to this project
    applyCrossDelta(src, -300, 'Supply Chain Issues: -$300 to this project');
    // Find positive projects in the same macro group
    const successfulSameClass = projects.filter(p => p.id !== src.id && p.class === src.class && payoutPer100[p.id] > 0);
    for (const p of successfulSameClass) {
      applyCrossDelta(p, 100, `Supply Chain Issues: +$100 (successful same-class project)`);
    }
  }

  // Cost Externalization
  for (const cm of crossMods.filter(x => x.mod.id === 'cost_externalization')) {
    const src = cm.proj;
    if (payoutPer100[src.id] <= -100) {
      applyCrossDelta(src, 200, 'Cost Externalization: +$200 to source');
      for (const p of projects) {
        if (p.id === src.id) continue;
        if (p.class === src.class) {
          applyCrossDelta(p, -200, `Cost Externalization: -$200 (same class as ${src.name})`);
        }
      }
    }
  }

  // Substitute Cannibalization
  for (const cm of crossMods.filter(x => x.mod.id === 'substitute_cannibalization')) {
    const src = cm.proj;
    if (payoutPer100[src.id] <= 0) continue;
    const othersSameClassPositive = projects.filter(p => p.id !== src.id && p.class === src.class && payoutPer100[p.id] > 0);
    if (othersSameClassPositive.length === 0) continue;
    applyCrossDelta(src, -200, `Substitute Cannibalization: -$200`);
    for (const p of othersSameClassPositive) {
      applyCrossDelta(p, -200, `Substitute Cannibalization: -$200 (paired with ${src.name})`);
    }
  }

  // Breakthrough Discovery
  for (const cm of crossMods.filter(x => x.mod.id === 'breakthrough_discovery')) {
    const src = cm.proj;
    if (payoutPer100[src.id] >= 400) {
      applyCrossDelta(src, 300, 'Breakthrough Discovery: +$300');
    }
  }

  // Regulatory Backlash
  for (const cm of crossMods.filter(x => x.mod.id === 'regulatory_backlash')) {
    const src = cm.proj;
    if (payoutPer100[src.id] >= 300) {
      applyCrossDelta(src, -300, 'Regulatory Backlash: -$300');
    }
  }

  // Extraordinary modifiers
  for (const proj of projects) {
    const mod = proj.modifier;
    if (!mod || mod.type !== 'Extraordinary') continue;
    if (mod.id === 'catastrophic_non_positive_payout') {
      if (payoutPer100[proj.id] <= -300) {
        payoutPer100[proj.id] -= 300;
        modifierImpact[proj.id].delta -= 300;
        modifierImpact[proj.id].notes.push('Catastrophic Non-positive: -$300');
      }
    }
  }

  // Systemic Contagion
  let systemicTriggered = false;
  for (const proj of projects) {
    const mod = proj.modifier;
    if (!mod || mod.id !== 'systemic_contagion') continue;
    if (payoutPer100[proj.id] <= -300) systemicTriggered = true;
  }
  if (systemicTriggered) {
    for (const proj of projects) {
      payoutPer100[proj.id] -= 200;
      modifierImpact[proj.id].delta -= 200;
      modifierImpact[proj.id].notes.push('Systemic Contagion: -$200 (global)');
    }
  }

  // Change 1 & 2: NO project-specific bonuses, NO macro payout adjustments

  // Compute per-player gains/losses
  const capitalReturnByProject = {};
  for (const proj of projects) {
    capitalReturnByProject[proj.id] = underMinByProject[proj.id] ? 0 : 1;
  }

  // Change 9b: build investment breakdown per player per project for display
  const investorsByProject = {};
  for (const proj of projects) {
    investorsByProject[proj.id] = investmentsByProject[proj.id]; // [{playerId, amount}]
  }

  const playerRound = {};
  for (const p of s.players) {
    const inv = p.round?.investments || {};
    const totalInvested = Object.values(inv).reduce((a, x) => a + x, 0);
    // Change 5: if pre-paid, costs are already deducted from p.money — don't double count
    const insuranceCost = insurancePrePaid ? 0 : (p.round?.boughtInsurance ? 300 : 0);
    const researchCost = researchPrePaid ? 0 : (p.round?.researchPurchases || 0) * 100;
    // For display purposes, track what was actually paid
    const displayInsuranceCost = p.round?.boughtInsurance ? 300 : 0;
    const displayResearchCost = (p.round?.researchPurchases || 0) * 100;

    let returned = 0;
    for (const [projId, amt] of Object.entries(inv)) {
      if (!amt) continue;
      returned += amt * (capitalReturnByProject[projId] || 0);
    }

    let incremental = 0;
    for (const [projId, amt] of Object.entries(inv)) {
      if (!amt) continue;
      const per100 = payoutPer100[projId] ?? 0;
      incremental += (amt / 100) * per100;
    }

    let incrementalAfterInsurance = incremental;
    if (p.round?.boughtInsurance && incremental < 0) {
      incrementalAfterInsurance = Math.max(incremental, -totalInvested);
    }

    const startMoney = p.money;
    const endMoney = startMoney - totalInvested - researchCost - insuranceCost + returned + incrementalAfterInsurance;

    playerRound[p.id] = {
      playerId: p.id,
      playerName: p.name,
      startMoney,
      totalInvested,
      researchCost: displayResearchCost,
      insuranceCost: displayInsuranceCost,
      returnedCapital: returned,
      incrementalPayout: incremental,
      incrementalAfterInsurance,
      endMoney,
      investments: inv,
    };

    p.money = endMoney;

    if (!p.history) p.history = [];
    p.history.push({
      round: s.round.number,
      startMoney,
      endMoney,
      net: endMoney - startMoney,
    });
  }

  // Elimination
  const eliminated = [];
  s.eliminatedPlayers = s.eliminatedPlayers || [];
  s.players = s.players.filter(p => {
    if (p.money < 500) {
      eliminated.push({ playerId: p.id, name: p.name, money: p.money });
      s.eliminatedPlayers.push({
        id: p.id,
        name: p.name,
        money: p.money,
        startingMoney: p.startingMoney ?? p.history?.[0]?.startMoney ?? 1000,
        history: p.history || [],
        eliminatedAtRound: s.round.number,
      });
      return false;
    }
    return true;
  });

  // Round cleanup
  for (const p of s.players) {
    p.round = { investments: {}, researchPurchases: 0, boughtInsurance: false, researchLog: [] };
  }

  const resolution = {
    macro,
    marketRoll,
    systemicTriggered,
    perProject: projects.map(proj => ({
      projectId: proj.id,
      name: proj.name,
      class: proj.class,
      totalInvested: totalInvestedByProject[proj.id],
      underMin: underMinByProject[proj.id],
      overInvested: overInvestedByProject[proj.id],
      overInvestPenalty: overInvestPenaltyByProject[proj.id],
      modifier: proj.modifier ? { id: proj.modifier.id, name: proj.modifier.name, type: proj.modifier.type } : null,
      adjustedRoll: adjustedRollByProject[proj.id],
      payoutPer100: payoutPer100[proj.id],
      notes: modifierImpact[proj.id].notes,
      investors: investmentsByProject[proj.id], // [{playerId, amount}]
    })),
    perPlayer: playerRound,
    eliminated,
    // Map playerId -> name for lookup in resolution rendering
    playerNames: Object.fromEntries(
      [...s.players, ...(s.eliminatedPlayers || [])].map(p => [p.id, p.name])
    ),
  };

  s.round.lastResolution = resolution;

  if (s.game?.isOver) {
    s.round.phase = 'GAME_OVER';
  } else if (s.game?.maxRounds && s.round.number >= s.game.maxRounds) {
    s.game.isOver = true;
    s.game.endedAt = Date.now();
    s.game.endedReason = 'MAX_ROUNDS_REACHED';
    s.round.phase = 'GAME_OVER';
  } else {
    s.round.phase = 'REDEAL';
  }

  return { state: s, resolution };
}

export function newGameState({ roomId, adminSecret, seed = null, nPlayers = 2 } = {}) {
  const rng = seed == null ? Math.random : mulberry32(seed);
  const projectDeck = shuffle(PROJECTS.map(p => ({ ...p })), rng);
  const modifierDeck = shuffle(buildDeckFromCopies(MODIFIERS), rng);
  const macroDeck = shuffle(MACROS.map(m => ({ ...m })), rng);

  return {
    roomId,
    adminSecret,
    createdAt: Date.now(),
    seed,
    decks: { projectDeck, modifierDeck, macroDeck },
    players: [],
    round: {
      number: 0,
      phase: 'LOBBY',
      macro: null,
      marketRoll: null,
      projects: [],
      lastResolution: null,
    },
    game: {
      maxRounds: 5, // Change 3: 5 rounds
      isOver: false,
      endedAt: null,
      endedReason: null,
    },
    eliminatedPlayers: [],
    log: [],
  };
}

export function startNextRound(state, { rng = Math.random } = {}) {
  const s = deepCopy(state);
  if (s.game?.isOver) throw new Error('Game is over');
  if (s.game?.maxRounds && s.round.number >= s.game.maxRounds) {
    throw new Error('Max rounds reached. End the game.');
  }

  const nPlayers = s.players.length;
  if (nPlayers < 2) throw new Error('Need at least 2 players');

  s.round.number += 1;
  s.round.phase = 'RESEARCH';
  s.round.lastResolution = null;
  s.round.marketRoll = null;

  // Deal macro
  if (s.decks.macroDeck.length === 0) {
    s.decks.macroDeck = shuffle(MACROS.map(m => ({ ...m })), rng);
  }
  s.round.macro = s.decks.macroDeck.pop();

  // Change 4: projects = number of players (min 3)
  const projectCount = getProjectCountForPlayers(nPlayers);
  while (s.decks.projectDeck.length < projectCount) {
    s.decks.projectDeck = shuffle(PROJECTS.map(p => ({ ...p })), rng);
  }
  const projects = [];
  for (let i = 0; i < projectCount; i++) {
    const proj = s.decks.projectDeck.pop();
    if (s.decks.modifierDeck.length === 0) {
      s.decks.modifierDeck = shuffle(buildDeckFromCopies(MODIFIERS), rng);
    }
    const mod = s.decks.modifierDeck.pop();
    projects.push({ ...proj, modifier: mod });
  }

  s.round.projects = projects;

  for (const p of s.players) {
    p.round = { investments: {}, researchPurchases: 0, boughtInsurance: false, researchLog: [] };
  }

  s.log.push({ t: Date.now(), type: 'ROUND_START', msg: `Round ${s.round.number} started: ${s.round.macro.name}` });
  return s;
}
