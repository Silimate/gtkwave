#!/bin/bash
# Build and extract portable GTKWave + Xvfb bundle
# This creates a self-contained directory that can run on any Linux with glibc 2.17+

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/portable-build"

echo "=== Building Portable GTKWave Bundle ==="
echo "Output directory: ${OUTPUT_DIR}"
echo

# Build the Docker image using Dockerfile.portable
echo "Building Docker image (this may take a while on first run)..."
docker build --target builder -t gtkwave-portable-builder -f "${SCRIPT_DIR}/Dockerfile.portable" "${SCRIPT_DIR}"

# Clean up any existing output
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Create temporary container and extract files
echo
echo "Extracting portable bundle..."
CONTAINER_ID=$(docker create gtkwave-portable-builder)

# Copy the entire /output directory
docker cp "${CONTAINER_ID}:/output/." "${OUTPUT_DIR}/"

# Clean up container
docker rm "${CONTAINER_ID}" > /dev/null

# Create a wrapper script for easy usage
cat > "${OUTPUT_DIR}/run-gtkwave.sh" << 'WRAPPER'
#!/bin/bash
# Wrapper script to run portable GTKWave with proper environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up environment
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
export PATH="${SCRIPT_DIR}/bin:${PATH}"
export GDK_PIXBUF_MODULE_FILE="${SCRIPT_DIR}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
export GTK_THEME=Adwaita
export XDG_DATA_DIRS="${SCRIPT_DIR}/share"
export XKB_CONFIG_ROOT="${SCRIPT_DIR}/share/X11/xkb"
export FONTCONFIG_PATH="${SCRIPT_DIR}/etc/fonts"

# Force software rendering (for headless/server use)
export GDK_RENDERING=image
export GSK_RENDERER=cairo

exec "${SCRIPT_DIR}/bin/gtkwave" "$@"
WRAPPER
chmod +x "${OUTPUT_DIR}/run-gtkwave.sh"

# Create a wrapper script for Xvfb
cat > "${OUTPUT_DIR}/run-xvfb.sh" << 'WRAPPER'
#!/bin/bash
# Wrapper script to run portable Xvfb with proper environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up environment
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
export PATH="${SCRIPT_DIR}/bin:${PATH}"
export XKB_CONFIG_ROOT="${SCRIPT_DIR}/share/X11/xkb"

exec "${SCRIPT_DIR}/bin/Xvfb" "$@"
WRAPPER
chmod +x "${OUTPUT_DIR}/run-xvfb.sh"

# Create a combined script to start Xvfb and run gtkwave
cat > "${OUTPUT_DIR}/run-headless.sh" << 'WRAPPER'
#!/bin/bash
# Run GTKWave in headless mode with built-in Xvfb
# Usage: ./run-headless.sh [gtkwave args...]
# Example: ./run-headless.sh -W  (starts Tcl shell)
# Example: ./run-headless.sh file.vcd  (opens waveform file)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up environment
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
export PATH="${SCRIPT_DIR}/bin:${PATH}"
export GDK_PIXBUF_MODULE_FILE="${SCRIPT_DIR}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
export GTK_THEME=Adwaita
export XDG_DATA_DIRS="${SCRIPT_DIR}/share"
export XKB_CONFIG_ROOT="${SCRIPT_DIR}/share/X11/xkb"
export FONTCONFIG_PATH="${SCRIPT_DIR}/etc/fonts"

# Force software rendering
export GDK_RENDERING=image
export GSK_RENDERER=cairo

# Find an available display number
for DISPLAY_NUM in $(seq 99 199); do
    if [ ! -e "/tmp/.X${DISPLAY_NUM}-lock" ] && [ ! -S "/tmp/.X11-unix/X${DISPLAY_NUM}" ]; then
        break
    fi
done

export DISPLAY=":${DISPLAY_NUM}"

# Start Xvfb in background
"${SCRIPT_DIR}/bin/Xvfb" "${DISPLAY}" -screen 0 1024x768x24 2>/dev/null &
XVFB_PID=$!

# Wait for X server to start
for i in $(seq 1 10); do
    [ -S "/tmp/.X11-unix/X${DISPLAY_NUM}" ] && break
    sleep 0.5
done

# Run gtkwave
"${SCRIPT_DIR}/bin/gtkwave" "$@"
EXIT_CODE=$?

# Clean up Xvfb
kill $XVFB_PID 2>/dev/null
rm -f "/tmp/.X${DISPLAY_NUM}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM}" 2>/dev/null

exit $EXIT_CODE
WRAPPER
chmod +x "${OUTPUT_DIR}/run-headless.sh"

echo
echo "=== Build Complete ==="
echo
echo "Portable bundle extracted to: ${OUTPUT_DIR}"
echo
echo "Contents:"
echo "  bin/       - Executables (gtkwave, Xvfb, xkbcomp, tclsh, wish, etc.)"
echo "  lib/       - Shared libraries with \$ORIGIN rpaths"
echo "  share/     - Data files (icons, fonts, XKB layouts, etc.)"
echo "  etc/       - Configuration (fontconfig)"
echo
echo "Wrapper scripts:"
echo "  run-gtkwave.sh   - Run gtkwave with proper environment"
echo "  run-xvfb.sh      - Run Xvfb with proper environment"
echo "  run-headless.sh  - Start Xvfb and run gtkwave (for servers)"
echo
echo "Usage examples:"
echo "  # With existing X display:"
echo "  ./portable-build/run-gtkwave.sh file.vcd"
echo
echo "  # Headless (starts its own Xvfb):"
echo "  ./portable-build/run-headless.sh -W  # Tcl shell"
echo "  ./portable-build/run-headless.sh file.vcd"
echo
echo "Bundle size: $(du -sh "${OUTPUT_DIR}" | cut -f1)"
