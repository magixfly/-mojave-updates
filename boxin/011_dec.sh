logcat -d -t 3000 | grep -i -E "c2\.(qti|android|exynos|mtk)|OMX\.|MediaCodec.*(create|Created)|CCodec.*allocate" | tail -12
dumpsys media.resource_manager 2>/dev/null | grep -i -E "codec|name" | head -12
