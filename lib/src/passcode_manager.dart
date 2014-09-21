part of web_play;

/**
 * Easily generate and verify controller passcodes.
 */
class PasscodeManager {
  String _passcode;
  
  /**
   * A human-readable representation of the current passcode or `null`.
   */
  String get passcodeString => _passcode;
  
  /**
   * Create a new passcode manager with no current passcode.
   */
  PasscodeManager();
  
  /**
   * Generate a new passcode for this manager.
   */
  void generate() {
    String chars = '0123456789';
    _passcode = '';
    Random r = new Random();
    for (int i = 0; i < 4; ++i) {
      _passcode += chars[r.nextInt(chars.length)];
    }
  }
  
  /**
   * Clear the passcode for this manager.
   */
  void clear() {
    _passcode = null;
  }
  
  /**
   * Check the passcode against an array of code units.
   */
  bool check(List<int> raw) {
    if (_passcode == null) return false;
    List<int> units = _passcode.codeUnits;
    if (units.length != raw.length) return false;
    for (int i = 0; i < units.length; ++i) {
      if (units[i] != raw[i]) {
        return false;
      }
    }
    return true;
  }
}
