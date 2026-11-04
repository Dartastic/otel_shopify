// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_shopify/otel_shopify.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_shopify-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('GraphQL query records graphql.* + shopify.* attrs', () async {
    await tracedShopifyGraphql<String>(
      operationName: 'GetOrders',
      shop: 'my-shop.myshopify.com',
      apiVersion: '2024-10',
      costRequested: 10,
      costActual: 8,
      invoke: () async => 'orders',
    );
    final a = attrsOf(spans.findSpanByName('shopify GetOrders')!);
    expect(a['graphql.operation.name'], 'GetOrders');
    expect(a['graphql.operation.type'], 'query');
    expect(a['shopify.shop'], 'my-shop.myshopify.com');
    expect(a['shopify.api.version'], '2024-10');
    expect(a['shopify.cost.requested'], 10);
    expect(a['shopify.cost.actual'], 8);
  });

  test('REST orders.create records CLIENT span', () async {
    await tracedShopifyRest<String>(
      resource: 'orders',
      action: 'create',
      shop: 'my-shop.myshopify.com',
      apiVersion: '2024-10',
      invoke: () async => 'o-1',
    );
    final a = attrsOf(spans.findSpanByName('shopify orders.create')!);
    expect(a['shopify.resource'], 'orders');
    expect(a['shopify.action'], 'create');
    expect(a['shopify.operation'], 'orders.create');
    expect(a['shopify.shop'], 'my-shop.myshopify.com');
    expect(a['shopify.api.version'], '2024-10');
  });

  test('suppression skips spans', () async {
    await runWithoutShopifyInstrumentationAsync(() async {
      await tracedShopifyRest<String>(
        resource: 'orders',
        action: 'create',
        shop: 's',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('shopify '), isEmpty);
  });
}
