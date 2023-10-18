[Setting hidden]
float S_ScreenPosX = 0.55;
[Setting hidden]
float S_ScreenPosY = 0.75;
[Setting hidden]
float S_SizeRadius = 35.;
[Setting hidden]
bool S_Preview = false;
[Setting hidden]
bool S_UseSameColor = false;
[Setting hidden]
vec4 S_Col_AK1 = vec4(.2, .5, 1, 1);
[Setting hidden]
vec4 S_Col_AK2 = vec4(.2, 1, 1, 1);
[Setting hidden]
vec4 S_Col_AK3 = vec4(.5, 1, .5, 1);
[Setting hidden]
vec4 S_Col_AK4 = vec4(1, .5, 0, 1);
[Setting hidden]
vec4 S_Col_AK5 = vec4(1, .1, .7, 1);
[Setting hidden]
vec4 S_TextColor = vec4(1);
[Setting hidden]
vec4 S_StrokeColor = vec4(0, 0, 0, 1);

[SettingsTab name="General" icon="KeyboardO"]
void Settings_RenderGeneral() {
    if (!g_initialized) return;

    UI::PushItemWidth(UI::GetWindowContentRegionWidth() * .5);

    S_ScreenPosX = Math::Clamp(UI::InputFloat("Position (X, Relative)", S_ScreenPosX, 0.0f), 0.0, 1.0);
    S_ScreenPosY = Math::Clamp(UI::InputFloat("Position (Y, Relative)", S_ScreenPosY, 0.0f), 0.0, 1.0);
    S_SizeRadius = Math::Clamp(UI::InputFloat("Size (Radius)", S_SizeRadius, 1.0f), 1.0, 200.0);
    S_Preview = UI::Checkbox("Show Preview", S_Preview);

    UI::Separator();

    S_TextColor = UI::InputColor4("Text Color", S_TextColor);
    S_StrokeColor = UI::InputColor4("Stroke Color", S_StrokeColor);
    S_UseSameColor = UI::Checkbox("Use same color for all AK indicators", S_UseSameColor);
    if (S_UseSameColor) {
        S_Col_AK4 = UI::InputColor4("Indicator Bg Color", S_Col_AK4);
    } else {
        S_Col_AK1 = UI::InputColor4("AK1 Bg Color", S_Col_AK1);
        S_Col_AK2 = UI::InputColor4("AK2 Bg Color", S_Col_AK2);
        S_Col_AK3 = UI::InputColor4("AK3 Bg Color", S_Col_AK3);
        S_Col_AK4 = UI::InputColor4("AK4 Bg Color", S_Col_AK4);
        S_Col_AK5 = UI::InputColor4("AK5 Bg Color", S_Col_AK5);
    }

    UI::PopItemWidth();
}


[SettingsTab name='Debug' icon="Cogs"]
void Settings_RenderDebug() {
    UI::AlignTextToFramePadding();
    UI::Text("Debug Utils:");

    showDebugWindow = UI::Checkbox("Show debug window", showDebugWindow);

//#if DEV
    if (UI::Button("Set AK1")) currentState.currentAk = AK::AK1;
    if (UI::Button("Set AK2")) currentState.currentAk = AK::AK2;
    if (UI::Button("Set AK3")) currentState.currentAk = AK::AK3;
    if (UI::Button("Set AK4")) currentState.currentAk = AK::AK4;
    if (UI::Button("Set AK5")) currentState.currentAk = AK::AK5;
// #endif
}


vec4 GetAkBgColor(AK ak) {
    if (S_UseSameColor) return S_Col_AK4;
    if (ak == AK::AK1) return S_Col_AK1;
    if (ak == AK::AK2) return S_Col_AK2;
    if (ak == AK::AK3) return S_Col_AK3;
    if (ak == AK::AK4) return S_Col_AK4;
    if (ak == AK::AK5) return S_Col_AK5;
    return S_Col_AK4;
}
