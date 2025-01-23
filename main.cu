// clang-format off
#include <glad/glad.h>
#include <GLFW/glfw3.h>
// clang-format on

#include <iomanip>
#include <iostream>
#include <thread>
#include <vector>

class Shader {
public:
    Shader() : ID(0) {}

    // constructor generates the shader on the fly
    // ------------------------------------------------------------------------
    void build() {
        std::string vertex_code_str = "#version 330 core\n"
                                      "layout (location = 0) in vec3 aPos;\n"
                                      "layout (location = 1) in vec3 aColor;\n"
                                      "layout (location = 2) in vec2 aTexCoord;\n"
                                      "\n"
                                      "out vec3 ourColor;\n"
                                      "out vec2 TexCoord;\n"
                                      "\n"
                                      "void main()\n"
                                      "{\n"
                                      "    gl_Position = vec4(aPos, 1.0);\n"
                                      "    ourColor = aColor;\n"
                                      "    TexCoord = vec2(aTexCoord.x, aTexCoord.y);\n"
                                      "}\n";

        std::string fragment_code_str = "#version 330 core\n"
                                        "out vec4 FragColor;\n"
                                        "\n"
                                        "in vec3 ourColor;\n"
                                        "in vec2 TexCoord;\n"
                                        "\n"
                                        "// texture sampler\n"
                                        "uniform sampler2D texture1;\n"
                                        "\n"
                                        "void main()\n"
                                        "{\n"
                                        "    FragColor = texture(texture1, TexCoord);\n"
                                        "}\n";

        const char *vShaderCode = vertex_code_str.c_str();
        const char *fShaderCode = fragment_code_str.c_str();
        // 2. compile shaders
        unsigned int vertex, fragment;
        // vertex shader
        vertex = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertex, 1, &vShaderCode, NULL);
        glCompileShader(vertex);
        checkCompileErrors(vertex, "VERTEX");
        // fragment Shader
        fragment = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragment, 1, &fShaderCode, NULL);
        glCompileShader(fragment);
        checkCompileErrors(fragment, "FRAGMENT");
        // shader Program
        ID = glCreateProgram();
        glAttachShader(ID, vertex);
        glAttachShader(ID, fragment);
        glLinkProgram(ID);
        checkCompileErrors(ID, "PROGRAM");
        // delete the shaders as they're linked into our program now and no longer necessary
        glDeleteShader(vertex);
        glDeleteShader(fragment);
    }

    // activate the shader
    // ------------------------------------------------------------------------
    void use() { glUseProgram(ID); }

private:
    unsigned int ID;

    // utility function for checking shader compilation/linking errors.
    // ------------------------------------------------------------------------
    void checkCompileErrors(unsigned int shader, std::string type) {
        int success;
        char infoLog[1024];
        if (type != "PROGRAM") {
            glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
            if (!success) {
                glGetShaderInfoLog(shader, 1024, NULL, infoLog);
                std::cout << "ERROR::SHADER_COMPILATION_ERROR of type: " << type << "\n"
                          << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;
            }
        }
        else {
            glGetProgramiv(shader, GL_LINK_STATUS, &success);
            if (!success) {
                glGetProgramInfoLog(shader, 1024, NULL, infoLog);
                std::cout << "ERROR::PROGRAM_LINKING_ERROR of type: " << type << "\n"
                          << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;
            }
        }
    }
};


class GLHelper {
    uint VBO = 0;
    uint VAO = 0;
    uint EBO = 0;
    GLFWwindow *window = nullptr;

    Shader shader;
    unsigned int texture = 0;

    bool initialized = false;

    int resolution_x = 0;
    int resolution_y = 0;

public:
    uint8_t *gpu_frame_buffer = nullptr;
    // std::vector<uint8_t> frame_buffer;

    ~GLHelper() {
        if (initialized) {
            this->release();
        }
    }

    void init(const std::string &title, int width, int height) {
        initialized = true;

        resolution_x = width;
        resolution_y = height;

        const uint num_pixels = width * height;

        /*
        frame_buffer = std::vector<uint8_t>(num_pixels * 3);
        for (uint idx = 0; idx < num_pixels; ++idx) {
            frame_buffer[idx * 3 + 0] = 0;
            frame_buffer[idx * 3 + 1] = 0;
            frame_buffer[idx * 3 + 2] = 0;
        }
        */


        const auto size = sizeof(uint8_t) * 3 * num_pixels;
        cudaMallocManaged(&gpu_frame_buffer, size);
        for (uint idx = 0; idx < num_pixels; ++idx) {
            gpu_frame_buffer[idx * 3 + 0] = 0;
            gpu_frame_buffer[idx * 3 + 1] = 0;
            gpu_frame_buffer[idx * 3 + 2] = 0;
        }


        glfwInit();
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);
        // thus disable window resizing

        create_window(width, height, title);
        glfwMakeContextCurrent(window);

        /*
        // center the window
        glfwSetWindowPos(window, (monitor_resolution.x - window_dimension.x) / 2,
                         (monitor_resolution.y - window_dimension.y) / 2);
        */

        // glad: load all OpenGL function pointers
        // ---------------------------------------
        if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
            std::cout << "ERROR: failed to initialize GLAD\n";
            exit(1);
        }

        build_triangles();
    }

    void release() {
        // optional: de-allocate all resources once they've outlived their purpose:
        // ------------------------------------------------------------------------
        glDeleteVertexArrays(1, &VAO);
        glDeleteBuffers(1, &VBO);
        glDeleteBuffers(1, &EBO);

        glfwTerminate();
    }

    void create_window(uint width, uint height, const std::string &window_initial_name) {
        window = glfwCreateWindow(width, height, window_initial_name.c_str(), NULL, NULL);
        if (window == NULL) {
            std::cout << "ERROR: failed to create GLFW window" << std::endl;
            glfwTerminate();
            exit(1);
        }
    }

    /*
    static std::string assemble_title(const float progress_percentage) {
        std::stringstream stream;
        stream << std::fixed << std::setprecision(1) << (progress_percentage * 100.0);
        return stream.str() + "%";
    }
    */

    void draw_frame(const std::string &title) {
        /*
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, resolution_x, resolution_y, 0, GL_RGB, GL_UNSIGNED_BYTE,
                     this->frame_buffer.data());
        */

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, resolution_x, resolution_y, 0, GL_RGB, GL_UNSIGNED_BYTE,
                     this->gpu_frame_buffer);

        glGenerateMipmap(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, texture);

        shader.use();
        glBindVertexArray(VAO);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
        glfwSwapBuffers(window);

        glfwSetWindowTitle(window, title.c_str());
        glfwPollEvents();
    }

    void build_triangles() {
        shader.build();

        // set up vertex data (and buffer(s)) and configure vertex attributes
        // ------------------------------------------------------------------
        const float vertices[] = {
                // positions          // colors           // texture coords
                1.0f,  1.0f,  0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f, // top right
                1.0f,  -1.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, // bottom right
                -1.0f, -1.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.0f, 1.0f, // bottom left
                -1.0f, 1.0f,  0.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f // top left
        };

        const unsigned int indices[] = {
                0, 1, 3, // first triangle
                1, 2, 3 // second triangle
        };

        glGenVertexArrays(1, &VAO);
        glGenBuffers(1, &VBO);
        glGenBuffers(1, &EBO);

        glBindVertexArray(VAO);

        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

        // position attribute
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void *)0);
        glEnableVertexAttribArray(0);
        // color attribute
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void *)(3 * sizeof(float)));
        glEnableVertexAttribArray(1);
        // texture coord attribute
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void *)(6 * sizeof(float)));
        glEnableVertexAttribArray(2);

        // load and create a texture
        // -------------------------
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D,
                      texture); // all upcoming GL_TEXTURE_2D operations now have effect on this
        // texture object
        // set the texture wrapping parameters
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
                        GL_REPEAT); // set texture wrapping to GL_REPEAT (default wrapping method)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        // set texture filtering parameters
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
};


int main() {
    GLHelper gl_helper;

    /*
     * bug: (755, 1200)
     * weird result: (750, 1200)
     */

    int width = 755;
    int height = 1200;

    gl_helper.init("initializing", width, height);

    auto title = "resolution: " + std::to_string(width) + "x" + std::to_string(height);
    gl_helper.draw_frame(title);

    getchar();

    return 0;
}
