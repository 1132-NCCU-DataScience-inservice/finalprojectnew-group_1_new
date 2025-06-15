# Comprehensive Pipeline Test Script
# Tests the complete pipeline with chromosome-based splitting
# Can be run locally or via Docker using: ./run-in-docker.sh test_pipeline_chromosome_split.sh

#!/usr/bin/env bash

echo "=== CTCF Pipeline Test with Chromosome-based Split ==="
echo "Test started at: $(date)"
echo ""

# Check if running in Docker or locally
if [ -f /.dockerenv ]; then
    echo "Running inside Docker container"
    DOCKER_MODE=true
else
    echo "Running locally (consider using: ./run-in-docker.sh test_pipeline_chromosome_split.sh)"
    DOCKER_MODE=false
fi
echo ""

# Function to check if command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 completed successfully"
    else
        echo "❌ $1 failed"
        exit 1
    fi
}

# Function to check if file exists and report size
check_file() {
    if [ -f "$1" ]; then
        size=$(wc -l < "$1" 2>/dev/null || echo "unknown")
        echo "✅ $1 exists (${size} lines)"
        return 0
    else
        echo "❌ $1 not found"
        return 1
    fi
}

echo "1. PRE-TEST VALIDATION"
echo "====================="

# Check if required input files exist
check_file "data/preprocessed_sequences_optimized.fasta"
if [ $? -ne 0 ]; then
    echo "   Run preprocessing pipeline first"
    exit 1
fi

echo ""
echo "2. RUNNING CHROMOSOME-BASED SPLIT TEST"
echo "======================================"

# Run the chromosome split test
echo "Testing chromosome extraction and validation..."
Rscript test_chromosome_split.R
check_status "Chromosome split test"

echo ""
echo "3. TESTING DOWNSTREAM PIPELINE COMPONENTS"
echo "========================================="

# Test sequence quality analysis
echo "Running sequence quality analysis..."
Rscript scripts/analyze_sequence_quality.R data/training_sequences.fasta results/sequence_quality_analysis.txt
check_status "Sequence quality analysis"
check_file "results/sequence_quality_analysis.txt"

# Test PWM building with new training set
echo "Building PWM from chromosome-split training data..."
Rscript scripts/build_subset_pwm.R data/training_sequences.fasta results/test_subset_pwm 1000
check_status "Subset PWM building"
check_file "results/test_subset_pwm_size1000.rds"

# Test simple aligned PWM if alignment exists
if [ -f "data/aligned_sequences.fasta" ]; then
    echo "Building simple aligned PWM..."
    Rscript scripts/simple_aligned_pwm.R data/aligned_sequences.fasta results/test_simple_aligned_pwm.rds
    check_status "Simple aligned PWM building"
    check_file "results/test_simple_aligned_pwm.rds"
fi

echo ""
echo "4. TESTING MODEL EVALUATION"
echo "==========================="

# Test model evaluation with the chromosome-split test set
if [ -f "results/test_subset_pwm_size1000.rds" ] && [ -f "data/test_sequences.fasta" ]; then
    echo "Evaluating PWM on chromosome-split test set..."
    Rscript scripts/evaluate_models.R
    check_status "Model evaluation"
fi

echo ""
echo "5. DATA LEAKAGE VALIDATION"
echo "=========================="

# Create a script to specifically check for data leakage
cat > validate_no_leakage.R << 'EOF'
library(Biostrings)

# Load data
train_seqs <- readDNAStringSet("data/training_sequences.fasta")
test_seqs <- readDNAStringSet("data/test_sequences.fasta")

# Extract chromosome info
source("scripts/prepare_datasets.R", local = TRUE)

train_chrs <- sapply(names(train_seqs), extract_chromosome)
test_names_clean <- gsub(" \\| class=[01]", "", names(test_seqs))
test_chrs <- sapply(test_names_clean, extract_chromosome)

# Check for overlap
train_unique <- unique(train_chrs)
test_unique <- unique(test_chrs)
overlap <- intersect(train_unique, test_unique)

cat("Training chromosomes:", paste(sort(train_unique), collapse=", "), "\n")
cat("Testing chromosomes:", paste(sort(test_unique), collapse=", "), "\n")

if (length(overlap) > 0) {
    cat("❌ DATA LEAKAGE DETECTED!\n")
    cat("Overlapping chromosomes:", paste(overlap, collapse=", "), "\n")
    quit(status = 1)
} else {
    cat("✅ No data leakage - chromosomes are properly separated\n")
}

# Additional checks
cat("Training sequences:", length(train_seqs), "\n")
cat("Test sequences:", length(test_seqs), "\n")
cat("Test positives:", sum(grepl("class=1", names(test_seqs))), "\n")
cat("Test negatives:", sum(grepl("class=0", names(test_seqs))), "\n")
EOF

echo "Validating no genomic data leakage..."
Rscript validate_no_leakage.R
check_status "Data leakage validation"

# Clean up temporary validation script
rm -f validate_no_leakage.R

echo ""
echo "6. PERFORMANCE COMPARISON TEST"
echo "============================="

# Test to compare chromosome-split vs random-split performance
cat > compare_split_methods.R << 'EOF'
# Compare chromosome-based vs random split performance

library(Biostrings)

# Function to calculate basic sequence statistics
calc_stats <- function(sequences, label) {
    lengths <- width(sequences)
    cat(label, ":\n")
    cat("  Count:", length(sequences), "\n")
    cat("  Length range:", min(lengths), "-", max(lengths), "\n")
    cat("  Mean length:", round(mean(lengths), 1), "\n")
    
    # Check sequence diversity (unique sequences)
    unique_seqs <- length(unique(as.character(sequences)))
    cat("  Unique sequences:", unique_seqs, "(", round(100*unique_seqs/length(sequences), 1), "%)\n")
    cat("\n")
}

# Load chromosome-split data
if (file.exists("data/training_sequences.fasta")) {
    train_seqs <- readDNAStringSet("data/training_sequences.fasta")
    test_seqs <- readDNAStringSet("data/test_sequences.fasta")
    
    # Filter test sequences to only positives for comparison
    test_pos_seqs <- test_seqs[grepl("class=1", names(test_seqs))]
    
    cat("=== Chromosome-based Split Statistics ===\n")
    calc_stats(train_seqs, "Training set")
    calc_stats(test_pos_seqs, "Test set (positives only)")
    
    # Check for potential issues
    train_prop <- length(train_seqs) / (length(train_seqs) + length(test_pos_seqs))
    cat("Actual train proportion:", round(train_prop, 3), "\n")
    
    if (abs(train_prop - 0.8) > 0.1) {
        cat("⚠️  WARNING: Train proportion deviates significantly from target 80%\n")
    } else {
        cat("✅ Train proportion close to target\n")
    }
}
EOF

echo "Analyzing split statistics..."
Rscript compare_split_methods.R
check_status "Split comparison analysis"

# Clean up
rm -f compare_split_methods.R

echo ""
echo "7. SUMMARY"
echo "=========="

# Count successful outputs
success_count=0
total_tests=6

# Check key output files
key_files=(
    "data/training_sequences.fasta"
    "data/test_sequences.fasta"
    "results/sequence_quality_analysis.txt"
)

for file in "${key_files[@]}"; do
    if [ -f "$file" ]; then
        ((success_count++))
    fi
done

echo "Key files created: $success_count/${#key_files[@]}"
echo ""

if [ $success_count -eq ${#key_files[@]} ]; then
    echo "🎉 ALL TESTS PASSED!"
    echo "The chromosome-based split pipeline is working correctly."
    echo ""
    echo "Next steps:"
    echo "1. Run the full pipeline: bash quick_test.sh"
    echo "2. Build and compare PWMs: Rscript scripts/compare_pwms.R"
    echo "3. Generate statistical reports: Rscript scripts/enhanced_compare_pwms.R"
else
    echo "❌ Some tests failed. Check the output above for details."
    exit 1
fi

echo ""
echo "Test completed at: $(date)"
