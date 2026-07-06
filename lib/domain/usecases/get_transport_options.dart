import '../entities/transport_plan.dart';

class GetTransportOptions {
  Future<List<TransportPlan>> call({
    required String origin,
    required String destination,
    required String preferredMode,
  }) async {
    // Generate a set of plans based on inputs
    return [
      TransportPlan(
        modeName: 'FIFA Metro Line 2 (Direct)',
        iconType: 'train',
        durationMins: 22,
        estimatedCost: 2.50,
        crowdLevel: 'Medium',
        co2EmissionsKg: 0.15,
        co2SavedKg: 3.20,
        ecoScore: 95,
        isRecommended: preferredMode.toLowerCase() == 'metro' || preferredMode.isEmpty,
        recommendationReason: 'Fastest eco-friendly choice. Bypasses matchday road traffic and drops you directly at Stadium Gate A.',
        sustainabilityTip: 'Using public rail instead of ride-sharing cuts your greenhouse gas emissions by 95% today.',
      ),
      TransportPlan(
        modeName: 'World Cup Shuttle (Express Bus)',
        iconType: 'bus',
        durationMins: 28,
        estimatedCost: 0.0, // Free with Match ticket
        crowdLevel: 'High',
        co2EmissionsKg: 0.40,
        co2SavedKg: 2.95,
        ecoScore: 88,
        isRecommended: preferredMode.toLowerCase() == 'bus',
        recommendationReason: 'Complimentary transit with ticket. Convenient group pickup from downtown hubs.',
        sustainabilityTip: 'Shared electric bus shuttle reduces carbon footprint by pooling rides with 50 other fans.',
      ),
      TransportPlan(
        modeName: 'Ride-Share / Taxi (Drop-off Zone C)',
        iconType: 'car',
        durationMins: 40, // Traffic delay
        estimatedCost: 32.00,
        crowdLevel: 'Low',
        co2EmissionsKg: 4.80,
        co2SavedKg: 0.0,
        ecoScore: 20,
        isRecommended: preferredMode.toLowerCase() == 'taxi' || preferredMode.toLowerCase() == 'rideshare',
        recommendationReason: 'Door-to-door comfort, but subject to 15-minute congestion delay near Zone C.',
        sustainabilityTip: 'Consider carpooling or using electric taxis to offset this high-emissions trip.',
      ),
      TransportPlan(
        modeName: 'Walking Eco Path (From Park & Ride North)',
        iconType: 'walk',
        durationMins: 15,
        estimatedCost: 0.0,
        crowdLevel: 'Low',
        co2EmissionsKg: 0.0,
        co2SavedKg: 4.20,
        ecoScore: 100,
        isRecommended: preferredMode.toLowerCase() == 'walking',
        recommendationReason: 'Healthy, active transport. Zero emissions, zero wait time, and passes through the FIFA Fan Festival.',
        sustainabilityTip: 'Perfect choice for carbon neutrality! Saves 4.20kg of CO₂ and grants +10 green points.',
      ),
    ];
  }
}
