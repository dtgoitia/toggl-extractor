extension AddQueryParamsToUri on Uri {
  /// Replace `Uri` query parameters with the provided `queryParams`.
  Uri setQueryParams(Map<String, String> queryParams) {
    final updated = Uri(
      scheme: this.scheme,
      host: this.host,
      port: this.port,
      path: this.path,
      queryParameters: queryParams.length > 0 ? queryParams : null,
      fragment: this.hasFragment ? this.fragment : null,
    );

    return updated;
  }
}
