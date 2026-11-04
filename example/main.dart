// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_shopify/otel_shopify.dart';

/// Traces Shopify Admin calls with OpenTelemetry.
///
/// `otel_shopify` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Shopify Admin call in
/// [tracedShopifyGraphql]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'shopify-example');

  // Wraps a Shopify Admin GraphQL query/mutation in a CLIENT span.
  final shopifyGraphqlId = await tracedShopifyGraphql<String>(
    operationName: 'example',
    shop: 'example',
    apiVersion: '1',
    costRequested: 1,
    costActual: 1,
    operationType: 'standard',
    invoke: () async {
      // Make the Shopify Admin call here, then report what it returned.
      return 'shopify_8f3a2c';
    },
  );
  OTelLog.info('tracedShopifyGraphql returned $shopifyGraphqlId');

  // Wraps a Shopify Admin REST call in a CLIENT span.
  final shopifyRestId = await tracedShopifyRest<String>(
    resource: 'Order',
    action: 'example',
    shop: 'example',
    apiVersion: '1',
    invoke: () async {
      // Make the Shopify Admin call here, then report what it returned.
      return 'shopify_8f3a2c';
    },
  );
  OTelLog.info('tracedShopifyRest returned $shopifyRestId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutShopifyInstrumentationAsync.
  await runWithoutShopifyInstrumentationAsync(
    () => tracedShopifyGraphql<String>(
      operationName: 'example',
      shop: 'example',
      apiVersion: '1',
      costRequested: 1,
      costActual: 1,
      operationType: 'standard',
      invoke: () async {
        return 'shopify_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
