#include <fcgiapp.h>

int main() {
    FCGX_Request req;
    FCGX_Init();
    FCGX_InitRequest(&req, 0, 0);

    while (FCGX_Accept_r(&req) >= 0) {
        FCGX_FPrintF(req.out, "Content-Type: text/html\n\n");
        FCGX_FPrintF(req.out, "<html><body><h1>Hello, World!</h1></body></html>");
        FCGX_Finish_r(&req);
    }

    return 0;
}         