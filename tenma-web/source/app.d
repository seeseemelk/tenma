import api.tenma;

import vibe.vibe;

int main()
{
    auto router = new URLRouter;
    router.registerRestInterface(new TenmaAPI("/dev/ttyACM0"));

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    listenHTTP(settings, router);
    return runApplication();
}
