/// Brauzerdan tashqari muhit (test, VM) uchun variant — xotirada saqlaydi.
int? _value;

int? readLastActivity() => _value;

void writeLastActivity(int epochMs) => _value = epochMs;

void clearLastActivity() => _value = null;
