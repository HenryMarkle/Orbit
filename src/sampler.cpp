#include <Orbit/RlExt/sampler.h>

#include <stdexcept>
#include <cstddef>
#include <cstdint>
#include <string>

#include <raylib.h>

namespace Orbit::RlExt {

Sampler::Sampler(Image &image) : image(image) {}

void Sampler::Sample(int x, int y, Color &pixel) {
    size_t index = 0;
    
    switch (image.format) {
        case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8: {
            uint8_t *bytes = reinterpret_cast<uint8_t *>(image.data);
            index = (x + y * image.width) * 4;

            uint8_t *loc = bytes + index;

            pixel.r = loc[0];
            pixel.g = loc[1];
            pixel.b = loc[2];
            pixel.a = loc[3];
        } break;

        case PIXELFORMAT_UNCOMPRESSED_R8G8B8: {
            uint8_t *bytes = reinterpret_cast<uint8_t *>(image.data);

            index = (x + y * image.width) * 3;

            auto *first_loc = bytes + index;

            pixel.a = 255;

            pixel.r = first_loc[0];
            pixel.g = first_loc[1];
            pixel.b = first_loc[2];
        } break;

        case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: {
            uint8_t *bytes = reinterpret_cast<uint8_t *>(image.data);
            
            index = x + y * image.width;
            uint8_t byte = bytes[index];
            pixel.a = 255;
            pixel.r = pixel.g = pixel.b = byte;
        } break;
        
        case PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA: {
            uint8_t *bytes = reinterpret_cast<uint8_t *>(image.data);

            index = (x + y * image.width) * 2;
            uint8_t byte = bytes[index];
            uint8_t alpha = bytes[index + 1];
            pixel.a = alpha;
            pixel.r = pixel.g = pixel.b = byte;
        } break;

        case PIXELFORMAT_UNCOMPRESSED_R5G6B5: {
            //   R      G      B
            // 00000|000 000|00000
            uint16_t *bytes = reinterpret_cast<uint16_t *>(image.data);
            index = x + y * image.width;

            uint16_t p = bytes[index];

            pixel.a = 255;

            pixel.r = ((p >> 11) & 0x1F) * 255/31;
            pixel.g = ((p >>  6) & 0x3F) * 255/63;
            pixel.b = (p & 0x1F)         * 255/31;
        } break;

        case PIXELFORMAT_UNCOMPRESSED_R5G5B5A1: {
            //   R      G     B   A
            // 00000|000 00|00000|0
            uint16_t *bytes = reinterpret_cast<uint16_t *>(image.data);
            index = x + y * image.width;

            uint16_t p = bytes[index];

            pixel.r = ((p >> 11) & 0x1F) * 255/31;
            pixel.g = ((p >>  6) & 0x1F) * 255/31;
            pixel.b = ((p >>  1) & 0x1F) * 255/31;
            pixel.a = ((p & 0x01) != 0)  * 255;
        } break;

        case PIXELFORMAT_UNCOMPRESSED_R4G4B4A4: {
            //   R    G     B    A
            // 0000|0000| 0000|0000
            uint16_t *bytes = reinterpret_cast<uint16_t *>(image.data);
            index = x + y * image.width;

            uint16_t p = bytes[index];

            pixel.r = ((p >> 12) & 0x0F);
            pixel.g = ((p >>  8) & 0x0F);
            pixel.b = ((p >>  4) & 0x0F);
            pixel.a = (p & 0x0F);

            pixel.r = (pixel.r << 4) | pixel.r;
            pixel.g = (pixel.g << 4) | pixel.g;
            pixel.b = (pixel.b << 4) | pixel.b;
            pixel.a = (pixel.a << 4) | pixel.a;
        } break;

        case PIXELFORMAT_UNCOMPRESSED_R32: {
            float *bytes = reinterpret_cast<float *>(image.data);
            index = x + y * image.width;

            float p = bytes[index];

            pixel.a = 255;

            pixel.b = pixel.g = pixel.r = static_cast<uint8_t>(p * 255);
        } break;

        case PIXELFORMAT_UNCOMPRESSED_R32G32B32: {
            float *bytes = reinterpret_cast<float *>(image.data);
            index = (x + y * image.width) * 3;

            float *loc = bytes + index;

            pixel.a = 255;

            pixel.r = static_cast<uint8_t>(loc[0] * 255);
            pixel.g = static_cast<uint8_t>(loc[1] * 255);
            pixel.b = static_cast<uint8_t>(loc[2] * 255);
        } break;

        case PIXELFORMAT_UNCOMPRESSED_R32G32B32A32: {
            float *bytes = reinterpret_cast<float *>(image.data);
            index = (x + y * image.width) * 4;

            float *loc = bytes + index;
            
            pixel.r = static_cast<uint8_t>(loc[0] * 255);
            pixel.g = static_cast<uint8_t>(loc[1] * 255);
            pixel.b = static_cast<uint8_t>(loc[2] * 255);
            pixel.a = static_cast<uint8_t>(loc[3] * 255);
        } break;

        default: {
            throw std::runtime_error(std::string("Unsupported image format '" + std::to_string(image.format) + '\''));
        }
    }
}

};