enum RequestMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH');

  const RequestMethod(this.value);
  final String value;

  factory RequestMethod.fromString(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return RequestMethod.get;
      case 'POST':
        return RequestMethod.post;
      case 'PUT':
        return RequestMethod.put;
      case 'DELETE':
        return RequestMethod.delete;
      case 'PATCH':
        return RequestMethod.patch;
      default:
        throw ArgumentError('Invalid HTTP method: $method');
    }
  }
}
