import 'package:dio/dio.dart';
import 'package:emitrace/src/core/emitrace_controller.dart';

/// Dio interceptor that records request/response/error breadcrumbs.
class EmitraceDioInterceptor extends Interceptor {
  final EmitraceController _controller = EmitraceController();

  final Map<int, DateTime> _requestStartTime = {};

  int _requestId(RequestOptions options) => identityHashCode(options);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = _requestId(options);
    //record request start time
    _requestStartTime[requestId] = DateTime.now();

    //Log request
    _controller.log(
      '→ ${options.method} ${options.path}',
      data: {
        'headers': options.headers.toString(),
        'body': options.data?.toString() ?? 'empty',
      },
    );

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final requestId = _requestId(response.requestOptions);
    final startTime = _requestStartTime.remove(requestId);
    final responseTimeMs = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : 0;

    _controller.network(
      method: response.requestOptions.method,
      url: response.requestOptions.path,
      statusCode: response.statusCode ?? 0,
      responseTime: responseTimeMs,
      data: {
        'requestHeaders': response.requestOptions.headers,
        'requestBody': response.requestOptions.data,
        'query': response.requestOptions.queryParameters,
        'responseBody': response.data,
        'statusMessage': response.statusMessage,
      },
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = _requestId(err.requestOptions);
    final startTime = _requestStartTime.remove(requestId);
    final responseTimeMs = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : 0;
    final statusCode = err.response?.statusCode ?? 0;

    _controller.network(
      method: err.requestOptions.method,
      url: err.requestOptions.path,
      statusCode: statusCode,
      responseTime: responseTimeMs,
      data: {
        'isError': true,
        'message': err.message,
        'requestHeaders': err.requestOptions.headers,
        'requestBody': err.requestOptions.data,
        'query': err.requestOptions.queryParameters,
        'responseBody': err.response?.data,
        'statusMessage': err.response?.statusMessage,
      },
    );

    _controller.error(
      '❌ ${err.requestOptions.method} '
      '${err.requestOptions.path} failed',
      exception: {
        'message': err.message,
        'requestHeaders': err.requestOptions.headers,
        'requestBody': err.requestOptions.data,
        'query': err.requestOptions.queryParameters,
        'responseBody': err.response?.data,
        'statusCode': err.response?.statusCode,
      },
    );

    handler.next(err);
  }
}
