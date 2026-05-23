import 'package:dart_mappable/dart_mappable.dart';

part 'config_bundle.mapper.dart';

@MappableClass()
class ConfigBundleOutbound with ConfigBundleOutboundMappable {
  final String tag;
  final String type;
  final String server;
  final int? serverPort;
  final String? uuid;
  final String? password;
  final Map<String, dynamic>? tls;
  final Map<String, dynamic>? transport;

  const ConfigBundleOutbound({
    required this.tag,
    required this.type,
    required this.server,
    this.serverPort,
    this.uuid,
    this.password,
    this.tls,
    this.transport,
  });

  static const fromMap = ConfigBundleOutboundMapper.fromMap;
}

@MappableClass()
class DnsTunnelEntry with DnsTunnelEntryMappable {
  final String serverName;
  final String country;
  final String dnsDomain;
  final String encryptionKey;
  final List<String> resolvers;

  const DnsTunnelEntry({
    required this.serverName,
    required this.country,
    required this.dnsDomain,
    required this.encryptionKey,
    required this.resolvers,
  });

  static const fromMap = DnsTunnelEntryMapper.fromMap;
}

@MappableClass()
class ConfigBundle with ConfigBundleMappable {
  final List<ConfigBundleOutbound> outbounds;
  final List<DnsTunnelEntry> dnsTunnel;
  final String? recommendedOutbound;
  final int generatedAt;

  const ConfigBundle({
    required this.outbounds,
    required this.dnsTunnel,
    this.recommendedOutbound,
    required this.generatedAt,
  });

  static const fromMap = ConfigBundleMapper.fromMap;
}
