#include "gl_helper.h"

int main() {
    GLHelper gl_helper;

    /*
     * good: (500, 400), (520, 400)
     * bad:  (510, 400), (513, 400)
     *
     */

    int width = 510;
    int height = 400;

    gl_helper.init("initializing", width, height);

    auto title = "resolution: " + std::to_string(width) + "x" + std::to_string(height);
    gl_helper.draw_frame(title);

    getchar();

    return 0;
}
