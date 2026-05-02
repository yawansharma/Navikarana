import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '69ecea2600127cefd5b2';

  static final Client client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId);

  static final Databases databases = Databases(client);
  static final Storage storage = Storage(client);
  static final Realtime realtime = Realtime(client);
}
