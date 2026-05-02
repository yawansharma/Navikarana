import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static final Client client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('69ecea2600127cefd5b2'); // replace this

  static final Databases databases = Databases(client);
}