class Device {
  const Device({
    required this.id,
    required this.name,
    required this.online,
    required this.status,
    required this.address,
  });
  final String id, name, address;
  final bool online;
  final int status;
}
