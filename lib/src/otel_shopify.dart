// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_shopify_suppression.dart';

const _tracerName = 'dartastic_otel_libs_shopify';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Shopify Admin GraphQL query/mutation in a CLIENT span.
/// Records GraphQL semconv plus shop / api-version / cost fields.
Future<T> tracedShopifyGraphql<T>({
  required String operationName,
  required String shop,
  required Future<T> Function() invoke,
  String? apiVersion,
  int? costRequested,
  int? costActual,
  String? operationType,
}) async {
  if (shopifyInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'graphql.operation.name': operationName,
    'graphql.operation.type': operationType ?? 'query',
    'shopify.shop': shop,
  };
  if (apiVersion != null) m['shopify.api.version'] = apiVersion;
  if (costRequested != null) m['shopify.cost.requested'] = costRequested;
  if (costActual != null) m['shopify.cost.actual'] = costActual;

  final span = _tracer().startSpan(
    'shopify $operationName',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Shopify Admin REST call in a CLIENT span.
Future<T> tracedShopifyRest<T>({
  required String resource,
  required String action,
  required String shop,
  required Future<T> Function() invoke,
  String? apiVersion,
}) async {
  if (shopifyInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'shopify.resource': resource,
    'shopify.action': action,
    'shopify.operation': '$resource.$action',
    'shopify.shop': shop,
  };
  if (apiVersion != null) m['shopify.api.version'] = apiVersion;

  final span = _tracer().startSpan(
    'shopify $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
