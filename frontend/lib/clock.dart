/// The app's notion of "now" follows the backend's demo clock, not the phone's, so chat
/// timestamps and the "Today" label agree with everything else on screen.
Duration _offset = Duration.zero;

void syncDemoClock(DateTime backendNow) {
  _offset = backendNow.difference(DateTime.now());
}

DateTime demoNow() => DateTime.now().add(_offset);
