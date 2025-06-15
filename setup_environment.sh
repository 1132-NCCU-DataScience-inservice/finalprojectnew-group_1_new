#!/bin/bash
# CTCF Pipeline Environment Setup Script
# Configures environment variables and directory structure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CTCF Pipeline Environment Setup ===${NC}"

# Detect operating system
OS=$(uname -s)
echo "Detected OS: $OS"

# Base directories
if [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "CYGWIN"* ]] || [[ "$OS" == "MSYS"* ]]; then
    # Windows paths
    export CTCF_HOME="$(pwd)"
    export CTCF_DATA_DIR="$CTCF_HOME/data"
    export CTCF_OUTPUT_DIR="$CTCF_HOME/results"
    export CTCF_CONFIG_DIR="$CTCF_HOME/config"
    export CTCF_TEMP_DIR="/tmp/ctcf-$$"
    export CTCF_LOG_DIR="$CTCF_HOME/logs"
    export CTCF_SCRIPTS_DIR="$CTCF_HOME/scripts"
else
    # Unix-like paths
    export CTCF_HOME="/opt/ctcf-pipeline"
    export CTCF_DATA_DIR="$CTCF_HOME/data"
    export CTCF_OUTPUT_DIR="$CTCF_HOME/results"
    export CTCF_CONFIG_DIR="$CTCF_HOME/config"
    export CTCF_TEMP_DIR="/tmp/ctcf-$$"
    export CTCF_LOG_DIR="$CTCF_HOME/logs"
    export CTCF_SCRIPTS_DIR="$CTCF_HOME/scripts"
fi

# Auto-detect system resources
detect_system_resources() {
    echo -e "${YELLOW}Detecting system resources...${NC}"
    
    # CPU cores
    if command -v nproc &> /dev/null; then
        CPU_CORES=$(nproc)
    elif command -v sysctl &> /dev/null; then
        CPU_CORES=$(sysctl -n hw.ncpu)
    else
        CPU_CORES=4
    fi
    
    # Memory (in GB)
    if command -v free &> /dev/null; then
        TOTAL_MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
        AVAILABLE_MEMORY_GB=$(echo "$TOTAL_MEMORY_GB * 0.8" | bc 2>/dev/null || echo "8")
    elif command -v vm_stat &> /dev/null; then
        # macOS
        TOTAL_MEMORY_GB=$(echo "$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//' ) * 4096 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "8")
        AVAILABLE_MEMORY_GB=$(echo "$TOTAL_MEMORY_GB * 0.8" | bc 2>/dev/null || echo "8")
    else
        TOTAL_MEMORY_GB=8
        AVAILABLE_MEMORY_GB=6
    fi
    
    echo "CPU cores: $CPU_CORES"
    echo "Total memory: ${TOTAL_MEMORY_GB}GB"
    echo "Available memory: ${AVAILABLE_MEMORY_GB}GB"
}

# Processing settings
detect_system_resources

export CTCF_THREADS=$CPU_CORES
export CTCF_MEMORY="${AVAILABLE_MEMORY_GB}G"
export CTCF_BATCH_SIZE=1000
export CTCF_QUALITY_THRESHOLD=0.8

# Pipeline behavior settings
export CTCF_ALIGNMENT_METHOD="integrated"
export CTCF_MIN_IC=8.0
export CTCF_DEBUG_MODE="false"
export CTCF_VERBOSE="false"

# Docker settings
export CTCF_DOCKER_IMAGE="ctcf-pipeline:latest"
export CTCF_DOCKER_MEMORY="${AVAILABLE_MEMORY_GB}g"
export CTCF_DOCKER_CPUS="$CPU_CORES"

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
create_directories() {
    local dirs=(
        "$CTCF_DATA_DIR"
        "$CTCF_OUTPUT_DIR"
        "$CTCF_CONFIG_DIR"
        "$CTCF_TEMP_DIR"
        "$CTCF_LOG_DIR"
        "$CTCF_SCRIPTS_DIR"
        "$CTCF_DATA_DIR/reference_genome"
        "$CTCF_OUTPUT_DIR/pwms"
        "$CTCF_OUTPUT_DIR/reports"
        "$CTCF_OUTPUT_DIR/plots"
        "$CTCF_OUTPUT_DIR/validation"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "Created: $dir"
        else
            echo "Exists: $dir"
        fi
    done
}

create_directories

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
if [[ "$OS" != "MINGW"* ]] && [[ "$OS" != "CYGWIN"* ]] && [[ "$OS" != "MSYS"* ]]; then
    chmod 755 "$CTCF_TEMP_DIR" 2>/dev/null || true
    chmod 755 "$CTCF_LOG_DIR" 2>/dev/null || true
    chmod 755 "$CTCF_OUTPUT_DIR" 2>/dev/null || true
fi

# Create environment file
echo -e "${YELLOW}Creating environment file...${NC}"
cat > "$CTCF_HOME/.ctcf_env" << EOF
# CTCF Pipeline Environment Variables
# Source this file to load the environment: source .ctcf_env

# Base directories
export CTCF_HOME="$CTCF_HOME"
export CTCF_DATA_DIR="$CTCF_DATA_DIR"
export CTCF_OUTPUT_DIR="$CTCF_OUTPUT_DIR"
export CTCF_CONFIG_DIR="$CTCF_CONFIG_DIR"
export CTCF_TEMP_DIR="$CTCF_TEMP_DIR"
export CTCF_LOG_DIR="$CTCF_LOG_DIR"
export CTCF_SCRIPTS_DIR="$CTCF_SCRIPTS_DIR"

# Processing settings
export CTCF_THREADS=$CTCF_THREADS
export CTCF_MEMORY="$CTCF_MEMORY"
export CTCF_BATCH_SIZE=$CTCF_BATCH_SIZE
export CTCF_QUALITY_THRESHOLD=$CTCF_QUALITY_THRESHOLD

# Pipeline behavior
export CTCF_ALIGNMENT_METHOD="$CTCF_ALIGNMENT_METHOD"
export CTCF_MIN_IC=$CTCF_MIN_IC
export CTCF_DEBUG_MODE="$CTCF_DEBUG_MODE"
export CTCF_VERBOSE="$CTCF_VERBOSE"

# Docker settings
export CTCF_DOCKER_IMAGE="$CTCF_DOCKER_IMAGE"
export CTCF_DOCKER_MEMORY="$CTCF_DOCKER_MEMORY"
export CTCF_DOCKER_CPUS="$CTCF_DOCKER_CPUS"

# Add scripts to PATH
export PATH="\$CTCF_SCRIPTS_DIR:\$PATH"

echo "CTCF Pipeline environment loaded"
EOF

# Check for required tools
echo -e "${YELLOW}Checking for required tools...${NC}"
check_requirements() {
    local missing_tools=()
    
    # Check for R
    if ! command -v R &> /dev/null; then
        missing_tools+=("R")
    fi
    
    # Check for Docker (optional)
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Warning: Docker not found (optional)${NC}"
    fi
    
    # Check for basic tools
    local tools=("awk" "sed" "grep" "sort" "uniq")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install the missing tools before running the pipeline."
        return 1
    else
        echo -e "${GREEN}All required tools are available${NC}"
        return 0
    fi
}

check_requirements

# Create quick test script
echo -e "${YELLOW}Creating quick test script...${NC}"
cat > "$CTCF_HOME/test_environment.sh" << 'EOF'
#!/bin/bash
# Quick environment test

source .ctcf_env

echo "=== CTCF Pipeline Environment Test ==="
echo "CTCF_HOME: $CTCF_HOME"
echo "CTCF_DATA_DIR: $CTCF_DATA_DIR"
echo "CTCF_OUTPUT_DIR: $CTCF_OUTPUT_DIR"
echo "CTCF_THREADS: $CTCF_THREADS"
echo "CTCF_MEMORY: $CTCF_MEMORY"

echo ""
echo "Directory structure:"
find "$CTCF_HOME" -type d -name "ctcf-*" -o -name "data" -o -name "results" -o -name "config" -o -name "logs" 2>/dev/null | sort

echo ""
echo "Environment test completed successfully!"
EOF

chmod +x "$CTCF_HOME/test_environment.sh"

# Summary
echo -e "${GREEN}=== Environment Setup Complete ===${NC}"
echo ""
echo "Environment configuration:"
echo "  Home: $CTCF_HOME"
echo "  Data: $CTCF_DATA_DIR"
echo "  Output: $CTCF_OUTPUT_DIR"
echo "  Config: $CTCF_CONFIG_DIR"
echo "  Logs: $CTCF_LOG_DIR"
echo "  Threads: $CTCF_THREADS"
echo "  Memory: $CTCF_MEMORY"
echo ""
echo "To load the environment in future sessions:"
echo "  source $CTCF_HOME/.ctcf_env"
echo ""
echo "To test the environment:"
echo "  ./test_environment.sh"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
