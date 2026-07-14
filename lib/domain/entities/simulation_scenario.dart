/// Different tournament operational scenarios simulated in StadiumPilot AI.
enum SimulationScenario {
  none('None (Normal Operations)'),
  heavyRain('Heavy Rain'),
  extraTime('Extra Time'),
  penaltyShootout('Penalty Shootout'),
  transportDelay('Public Transport Delay'),
  medicalEmergency('Medical Emergency'),
  vipArrival('VIP Arrival'),
  powerFailure('Power Failure'),
  crowdSurge('Crowd Surge');

  final String displayName;
  const SimulationScenario(this.displayName);
}
