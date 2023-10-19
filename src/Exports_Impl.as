namespace AkHints {
    // 0 for not initialized or error
    int GetAKNumber() {
        if (currentState is null) return 0;
        return currentState.currentAk == AK::AK1 ? 1
            : currentState.currentAk == AK::AK2 ? 2
            : currentState.currentAk == AK::AK3 ? 3
            : currentState.currentAk == AK::AK4 ? 4
            : 5;
    }
    // steering limit
    float GetAKLimit() {
        if (currentState is null) return 1.;
        return currentState.GetCurrAkLimit();
    }
}
