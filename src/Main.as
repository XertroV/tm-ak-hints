void Main(){
    @currentState = RaceState();
    startnew(MainCoro);//.WithRunContext(Meta::RunContext::AfterScripts);
    yield();
    g_initialized = true;
}

/// Watch for when we are racing and update the player's state; reset on various conditions

void MainCoro() {
    while (true) {
        yield();
        auto app = GetApp();
        // only null when exiting (if that, even)
        if (app is null || app.GameScene is null) return;
        auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
        if (cp is null || cp.ArenaInterface is null) continue;
        if (cp.GameTerminals.Length == 0) continue;
        auto gt = cp.GameTerminals[0];
        auto player = cast<CSmPlayer>(gt.ControlledPlayer);
        if (player is null) continue;
        if (app.Network.PlaygroundClientScriptAPI is null) continue;
        g_pgNow = app.Network.PlaygroundClientScriptAPI.GameTime;

        if (g_LastSeq != int(gt.UISequence_Current)) {
            g_LastSeq = int(gt.UISequence_Current);
            // if we change UI sequences, replace race state
            @currentState = RaceState();
        }

        // don't check other stuff if we're not playing
        if (g_LastSeq != int(SGamePlaygroundUIConfig::EUISequence::Playing)) continue;

        if (g_StartTime != player.StartTime) {
            // we restarted or something
            g_StartTime = player.StartTime;
            @currentState = RaceState();
        }

        if (g_LRLI != player.CurrentLaunchedRespawnLandmarkIndex) {
            g_LRLI = player.CurrentLaunchedRespawnLandmarkIndex;
            g_SRLI = player.CurrentStoppedRespawnLandmarkIndex;
            currentState.OnCpTaken(player);
        }

        g_SI = player.SpawnIndex;
        if (g_RR != player.Score.NbRespawnsRequested) {
            g_RR = player.Score.NbRespawnsRequested;
            // one second delay on respawn
            g_RespawnRegainControl = g_pgNow + 995;
            startnew(OnRespawnCoro);
        }
        g_RR = player.Score.NbRespawnsRequested;
        g_LastUpdate = Time::Now;
        currentState.CheckAkPressed(player.StartTime <= g_pgNow);
        // only check for override if we're not in a respawning state
        if (g_RespawnRegainControl < g_pgNow) {
            CSceneVehicleVis@ vis = VehicleState::GetVis(app.GameScene, player);
            if (vis !is null) {
                currentState.CheckAgainstVisSteering(vis.AsyncState.InputSteer);
            }
        }
    }
}


/// A coro to monitor the player for respawn behavior (flying or standing)


void OnRespawnCoro() {
    auto app = GetApp();
    if (app.GameScene is null) return;
    auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
    if (cp is null || cp.ArenaInterface is null) return;
    if (cp.GameTerminals.Length == 0) return;
    auto player = cast<CSmPlayer>(cp.GameTerminals[0].ControlledPlayer);
    CSceneVehicleVis@ vis1 = VehicleState::GetVis(app.GameScene, player);
    if (vis1 is null) return;
    vec3 lastPos = vis1.AsyncState.Position;
    @player = null;
    yield();
    uint count = 0, count_standing = 0, count_flying = 0;
    while (count < 8) {
        if (app is null || app.GameScene is null || app.CurrentPlayground is null) return;
        auto playerTmp = cast<CSmPlayer>(cp.GameTerminals[0].ControlledPlayer);
        if (playerTmp is null) return;
        auto vis = VehicleState::GetVis(app.GameScene, playerTmp);
        if (vis is null) return;
        if ((vis1.AsyncState.Position - lastPos).LengthSquared() < 0.0001) {
            count_standing++;
        } else {
            count_flying++;
        }
        lastPos = vis1.AsyncState.Position;
        count++;
        yield();
    }
    if (count_flying >= count_standing) {
        currentState.OnRespawn();
    } else {
        currentState.OnStandingRespawn();
    }
}

/// Main rendering logic

#if DEV
bool showDebugWindow = true;
#else
bool showDebugWindow = false;
#endif

void Render() {
    if (!g_initialized) return;
    bool shouldShowAK = GetApp().CurrentPlayground !is null && currentState !is null && currentState.currentAk != AK::AK5;
    if (S_Preview || shouldShowAK) {
        auto pos = vec2(Draw::GetWidth(), Draw::GetHeight()) * vec2(S_ScreenPosX, S_ScreenPosY);
        nvgCircleScreenPos(pos, GetAkBgColor(currentState.currentAk), S_SizeRadius);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::FontSize(S_SizeRadius * 1.4);
        DrawTextWithStroke(pos + vec2(0, S_SizeRadius * 0.12), tostring(currentState.currentAk).SubStr(2), S_TextColor, 2, S_StrokeColor);
    }

    if (!showDebugWindow) return;

    if (UI::Begin("debug ak window", showDebugWindow, UI::WindowFlags::AlwaysAutoResize)) {
        UI::Text("g_LastUpdate: " + g_LastUpdate);
        UI::Text("g_LastSeq: " + g_LastSeq);
        UI::Text("g_LRLI: " + g_LRLI);
        // UI::Text("g_SRLI: " + g_SRLI);
        UI::Text("spawn ix: " + g_SI);
        UI::Text("resapwns: " + g_RR);
        UI::Text("currentAk: " + tostring(currentState.currentAk));
        UI::Text("lastFlags: " + Text::Format("0x%04x", currentState.lastFlags));
    }
    UI::End();
}

/// Global vars to track player state

bool g_initialized;
uint g_LastUpdate;
uint g_pgNow;
uint g_LRLI;
uint g_SRLI;
uint g_RR;
uint g_SI;
int g_StartTime;
int g_LastSeq;
int g_RespawnRegainControl;

/// Track AK state

enum AK { AK1 = 0x40, AK2 = 0x80, AK3 = 0x100, AK4 = 0x200, AK5 = 0x400 }

class RaceState {
    AK lastCpAk = AK::AK5;
    AK currentAk = AK::AK5;
    // track key presses to find new ones
    uint lastFlags;

    void CheckAkPressed(bool raceStarted) {
        trace('>> reading AK pressed');
        auto pressed = ReadAKPressed();
        if (pressed == lastFlags) return;
        if (AK::AK1 & pressed != AK::AK1 & lastFlags) OnPressAK(AK::AK1);
        else if (AK::AK2 & pressed != AK::AK2 & lastFlags) OnPressAK(AK::AK2);
        else if (AK::AK3 & pressed != AK::AK3 & lastFlags) OnPressAK(AK::AK3);
        else if (AK::AK4 & pressed != AK::AK4 & lastFlags) OnPressAK(AK::AK4);
        else if (AK::AK5 & pressed != AK::AK5 & lastFlags) OnPressAK(AK::AK5);
        if (!raceStarted) currentAk = AK::AK5;
        lastFlags = pressed;
        trace('DONE reading AK pressed');
    }

    void OnPressAK(AK ak) {
        // we released the key
        if (ak & lastFlags > 0) return;
        // otherwise it must be that we pressed it
        currentAk = currentAk == ak ? AK::AK5 : ak;
    }

    void OnCpTaken(CSmPlayer@ player) {
        lastCpAk = currentAk;
    }

    void OnRespawn() {
        currentAk = lastCpAk;
    }

    void OnStandingRespawn() {
        currentAk = AK::AK5;
    }

    void CheckAgainstVisSteering(float InputSteer) {
        InputSteer = Math::Abs(InputSteer);
        // with controller you can steer less than the current AK
        if (InputSteer > GetCurrAkLimit()) {
            // then we can't be in the right AK
            currentAk = InferAkFromInput(InputSteer);
        }
    }

    float GetCurrAkLimit() {
        if (currentAk == AK::AK1) return 0.2;
        if (currentAk == AK::AK2) return 0.4;
        if (currentAk == AK::AK3) return 0.6;
        if (currentAk == AK::AK4) return 0.8;
        return 1.0;
    }

    AK InferAkFromInput(float input) {
        if (input <= 0.2001) return AK::AK1;
        if (input <= 0.4001) return AK::AK2;
        if (input <= 0.6001) return AK::AK3;
        if (input <= 0.8001) return AK::AK4;
        return AK::AK5;
    }
}


/// AK read via Dev::


// ~~Null if not racing~~
RaceState@ currentState;

const uint16 OFFSET_ARENA_INTERFACE_AK_PRESSED = 0x10b0;

// Flags: 0x40 -> ak1, 0x80 -> ak2, 0x100 -> ak3, 0x200 -> ak4, 0x400 -> ak5
uint16 ReadAKPressed() {
	auto cp = cast<CSmArenaClient>(GetApp().CurrentPlayground);
	if (cp is null || cp.ArenaInterface is null) return 0; // throw('Check that CurrentPlayground and ArenaInterface are not null before calling.');
	return Dev::GetOffsetUint16(cp.ArenaInterface, OFFSET_ARENA_INTERFACE_AK_PRESSED);
}


/// NVG


void nvgCircleScreenPos(vec2 xy, vec4 col = vec4(1, .5, 0, 1), float radius = 25.) {
    nvg::Reset();
    nvg::BeginPath();
    nvg::FillColor(col);
    nvg::Circle(xy, radius);
    nvg::Fill();
    nvg::ClosePath();
}

const double TAU = 6.28318530717958647692;

// this does not seem to be expensive
const float nTextStrokeCopies = 32;

void DrawTextWithStroke(const vec2 &in pos, const string &in text, vec4 textColor, float strokeWidth, vec4 strokeColor = vec4(0, 0, 0, 1)) {
    nvg::FillColor(strokeColor);
    for (float i = 0; i < nTextStrokeCopies; i++) {
        float angle = TAU * float(i) / nTextStrokeCopies;
        vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * strokeWidth;
        nvg::Text(pos + offs, text);
    }
    nvg::FillColor(textColor);
    nvg::Text(pos, text);
}
