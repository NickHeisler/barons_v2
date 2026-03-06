<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>The Barons (Local Host)</title>
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 0; background: #0b0f14; color: #e8eef6; }
    a { color: #9ad1ff; }
    .wrap { max-width: 1100px; margin: 0 auto; padding: 16px; }
    .card { background: #121a24; border: 1px solid #243244; border-radius: 12px; padding: 12px; margin: 12px 0; }
    .row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    @media (max-width: 900px){ .row { grid-template-columns: 1fr; } }
    input, select, button, textarea { background: #0b0f14; color: #e8eef6; border: 1px solid #2a3a50; border-radius: 10px; padding: 10px; font-size: 14px; }
    button { cursor: pointer; }
    button.primary { border-color: #4fa8ff; }
    button.danger { border-color: #ff6b6b; }
    .muted { color: #a6b3c3; }
    .tiny { font-size: 12px; }
    .pill { display: inline-block; padding: 3px 8px; border: 1px solid #2a3a50; border-radius: 999px; font-size: 12px; color: #cfe3ff; }
    .grid3 { display:grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
    @media (max-width: 900px){ .grid3 { grid-template-columns: 1fr; } }
    table { width: 100%; border-collapse: collapse; }
    th, td { border-bottom: 1px solid #243244; padding: 8px; text-align: left; font-size: 13px; }
    .mono { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
    .success { color: #9dffb3; }
    .warn { color: #ffd38a; }
    .bad { color: #ff9aa2; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1 style="margin: 8px 0 0">The Barons</h1>
    <div class="muted" style="margin: 4px 0 14px">Local-host game app (functionality first). Investments are <b>$100 increments</b>. Dice can be rolled in-app.</div>

    <div id="landing" class="card">
      <div class="row">
        <div>
          <h3>Create a Room (Admin)</h3>
          <div class="muted tiny">You will be the host/dealer. Share the Room Code with players.</div>
          <div style="display:flex; gap:8px; margin-top:10px; flex-wrap: wrap;">
            <input id="adminName" placeholder="Admin name" value="Admin" />
            <input id="seed" placeholder="Optional seed (number)" class="mono" style="width: 220px" />
            <button id="createRoom" class="primary">Create</button>
          </div>
          <div id="createdInfo" class="muted tiny" style="margin-top:10px"></div>
        </div>
        <div>
          <h3>Join a Room</h3>
          <div class="muted tiny">Players join with Room Code. Admin can also join with Admin Secret.</div>
          <div style="display:flex; gap:8px; margin-top:10px; flex-wrap: wrap;">
            <input id="roomCode" placeholder="Room code" class="mono" />
            <input id="playerName" placeholder="Your name" />
            <input id="adminSecret" placeholder="Admin secret (admin only)" class="mono" style="width: 260px" />
            <button id="joinRoom" class="primary">Join</button>
          </div>
          <div id="joinError" class="bad tiny" style="margin-top:10px"></div>
        </div>
      </div>
    </div>

    <div id="app" style="display:none">
      <div class="card">
        <div style="display:flex; justify-content: space-between; gap: 12px; flex-wrap: wrap; align-items: center;">
          <div>
            <div class="muted tiny">Room</div>
            <div class="mono" style="font-size: 18px"><span id="roomId"></span> <span id="rolePill" class="pill"></span></div>
          </div>
          <div>
            <div class="muted tiny">Phase</div>
            <div style="font-size: 18px"><span id="phase"></span> <span class="pill">Round <span id="roundNum"></span></span></div>
          </div>
          <div>
            <div class="muted tiny">Macro</div>
            <div id="macroName" style="font-size: 18px">—</div>
          </div>
        </div>
      </div>

      <div id="scoreboard" class="card"></div>
      <div id="macroDetails" class="card"></div>

      <div class="row">
        <div class="card">
          <h3>Players</h3>
          <div id="players"></div>
        </div>

        <div class="card">
          <h3>Projects (this round)</h3>
          <div class="muted tiny">Modifiers are hidden until resolution (or your private research).</div>
          <div id="projects"></div>
        </div>
      </div>

      <div class="row">
        <div class="card" id="playerPanel" style="display:none">
          <h3>Player Actions</h3>
          <div class="muted tiny">Your research log and investments are private.</div>

          <div id="playerMoney" class="mono" style="margin:10px 0; font-size: 16px"></div>

          <div class="card" style="background:#0e1520">
            <div style="display:flex; justify-content: space-between; align-items: center; gap: 10px; flex-wrap: wrap;">
              <div>
                <div><b>Research</b> <span class="pill">$100</span></div>
                <div class="muted tiny">Each purchase lets you privately reveal 2 face-down project modifiers.</div>
              </div>
              <button id="buyResearch" class="primary">Buy research</button>
            </div>
            <div id="researchPicker" style="display:none; margin-top:10px"></div>
            <div id="researchResults" class="tiny" style="margin-top:10px"></div>
          </div>

          <div class="card" style="background:#0e1520">
            <div style="display:flex; justify-content: space-between; align-items: center; gap: 10px; flex-wrap: wrap;">
              <div>
                <div><b>Insurance</b> <span class="pill">$300</span></div>
                <div class="muted tiny">Optional. Loss floor applied at round-level.</div>
              </div>
              <label class="tiny" style="display:flex; gap:8px; align-items:center;">
                <input type="checkbox" id="insuranceToggle" /> Buy insurance
              </label>
            </div>
            <div class="muted tiny" id="insuranceStatus" style="margin-top:6px"></div>
          </div>

          <div class="card" style="background:#0e1520">
            <div style="display:flex; justify-content: space-between; align-items: center; gap: 10px; flex-wrap: wrap;">
              <div>
                <div><b>Invest</b> <span class="pill">$100 increments</span></div>
                <div class="muted tiny">Enter allocations (private) then submit.</div>
              </div>
              <button id="submitInvest" class="primary">Submit investments</button>
            </div>
            <div id="investForm" style="margin-top:10px"></div>
            <div id="investError" class="bad tiny" style="margin-top:8px"></div>
          </div>
        </div>

        <div class="card" id="adminPanel" style="display:none">
          <h3>Admin Controls</h3>
          <div class="muted tiny">You can advance phases, roll dice, and resolve the round.</div>

          <div class="grid3" style="margin-top:10px">
            <button id="startRound" class="primary">Start / Redeal Round</button>
            <button id="setPhaseResearch">Phase: Research</button>
            <button id="setPhaseInsurance">Phase: Insurance</button>
            <button id="setPhaseInvest">Phase: Invest</button>
            <button id="rollMarket" class="primary">Roll 2d6 (in-app)</button>
            <button id="resolveRound" class="danger">Resolve Round</button>
            <button id="endGame" class="danger">End Game</button>
          </div>

          <div class="card" style="background:#0e1520; margin-top:12px">
            <div style="display:flex; gap:10px; align-items:center; flex-wrap: wrap;">
              <div><b>Market Roll</b></div>
              <div class="mono" id="marketRoll">—</div>
              <div class="muted tiny">(Optional) Enter physical dice:</div>
              <input id="d1" placeholder="d1" style="width:70px" class="mono" />
              <input id="d2" placeholder="d2" style="width:70px" class="mono" />
              <button id="setMarket" class="primary">Set</button>
            </div>
          </div>

          <div class="card" style="background:#0e1520; margin-top:12px">
            <div style="display:flex; gap:10px; align-items:center; flex-wrap: wrap;">
              <button id="saveGame">Save JSON</button>
              <button id="loadGame">Load JSON</button>
              <input type="file" id="loadFile" accept="application/json" style="display:none" />
              <div class="muted tiny">Save/load keeps everything, including decks.</div>
            </div>
          </div>

          <div id="adminError" class="bad tiny" style="margin-top:10px"></div>
        </div>
      </div>

      <div class="card">
        <div id="payoutCalculator"><div class="muted tiny">No projects dealt yet.</div></div>
      </div>

      <div class="card">
        <h3>Round Resolution</h3>
        <div id="resolution" class="tiny muted">No resolution yet.</div>
      </div>

      <div class="card">
        <h3>Event Log</h3>
        <div id="log" class="tiny mono"></div>
      </div>
    </div>

      <div class="card" id="cheatSheet"></div>
    </div>
  </div>

  <script src="https://cdn.socket.io/4.7.5/socket.io.min.js"></script>
  <script src="app.js"></script>
</body>
</html>
