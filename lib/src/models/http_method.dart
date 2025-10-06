enum RequestMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH');

  const RequestMethod(this.value);
  final String value;
}
