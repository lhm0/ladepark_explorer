import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

/// Privacy disclosure and deliberately user-initiated local diagnostics for
/// FR-PRIV-001. No telemetry or crash-reporting SDK is involved.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({required this.automaticDatasetChecks, super.key});

  final bool automaticDatasetChecks;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.privacyAndDiagnostics)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _PrivacyCard(
            icon: Icons.shield_outlined,
            title: strings.noTelemetry,
            body: strings.noTelemetryExplanation,
          ),
          _PrivacyCard(
            icon: Icons.phone_iphone_outlined,
            title: strings.localData,
            body: strings.localDataExplanation,
          ),
          _PrivacyCard(
            icon: Icons.cloud_outlined,
            title: strings.externalServices,
            body: strings.externalServicesExplanation,
          ),
          const SizedBox(height: 8),
          Text(
            strings.localDiagnostics,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            _diagnosticSummary(strings),
            key: const ValueKey('diagnostic-summary'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('copy-diagnostics'),
            onPressed: () => _copyDiagnostics(context, strings),
            icon: const Icon(Icons.copy_outlined),
            label: Text(strings.copyDiagnostics),
          ),
          const SizedBox(height: 8),
          Text(
            strings.diagnosticsPrivacyExplanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _diagnosticSummary(AppLocalizations strings) => [
    strings.telemetryStatus,
    strings.crashReportingStatus,
    strings.adTrackingStatus,
    automaticDatasetChecks
        ? strings.datasetChecksEnabled
        : strings.datasetChecksDisabled,
  ].join('\n');

  Future<void> _copyDiagnostics(
    BuildContext context,
    AppLocalizations strings,
  ) async {
    await Clipboard.setData(ClipboardData(text: _diagnosticSummary(strings)));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.diagnosticsCopied)));
    }
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
