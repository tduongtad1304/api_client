enum HTTPMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH');

  const HTTPMethod(this.value);
  final String value;
}
