# API Reference

> **📋 Technical Specifications and Formats**  
> Complete technical reference for data formats, function interfaces, configuration schemas, and integration specifications in the CTCF PWM Testing Pipeline.

## 🎯 API Overview

The CTCF PWM Testing Pipeline provides multiple interfaces for integration and customization:
- **R Function APIs** - Direct R function calls for programmatic access
- **Command-Line Interface** - Shell script integration
- **Configuration APIs** - YAML/JSON configuration schemas
- **Data Format APIs** - Input/output file format specifications
- **Extension APIs** - Plugin and extension development interfaces

## 🔧 R Function APIs

### Core Pipeline Functions

#### `build_pwm_robust()`

**Function Signature:**
```r
build_pwm_robust(
  sequences,                    # character vector or DNAStringSet
  config = list(),             # configuration list
  output_file = NULL,          # output file path (optional)
  format = "meme",             # output format
  verbose = FALSE              # verbose output
)
```

**Parameters:**
```r
# sequences: Input sequences
#   Type: character vector, DNAStringSet, or file path
#   Format: FASTA format if file path provided
#   Requirements: Aligned sequences, minimum 10 sequences
#   Example: c("ATCGATCG", "ATCGATCG", "ATCGATCG")

# config: Configuration parameters
#   Type: named list
#   Default: Uses default pipeline configuration
#   Structure: See Configuration Schema section

# output_file: Output file path
#   Type: character string or NULL
#   Default: NULL (returns result without writing)
#   Formats: Determined by file extension or format parameter

# format: Output format specification
#   Type: character string
#   Options: "meme", "jaspar", "transfac", "json", "custom"
#   Default: "meme"

# verbose: Enable verbose output
#   Type: logical
#   Default: FALSE
#   Effect: Prints detailed processing information
```

**Return Value:**
```r
# Returns a list with structure:
list(
  pwm = matrix,                 # 4 x L probability matrix (A,C,G,T rows)
  frequency_matrix = matrix,    # 4 x L frequency count matrix
  information_content = numeric, # L-length vector of IC values
  total_ic = numeric,           # Total information content (sum)
  conserved_positions = integer, # Positions with IC > threshold
  quality_metrics = list,       # Comprehensive quality assessment
  metadata = list               # Processing metadata
)
```

**Example Usage:**
```r
# Basic usage
sequences <- c("ATCGATCGCCGCG", "ATCGATCGCCGCG", "ATCGATCGCCGCG")
result <- build_pwm_robust(sequences)

# Advanced usage with configuration
config <- list(
  pseudocount = 0.05,
  min_ic_threshold = 10.0,
  quality_checks = TRUE
)
result <- build_pwm_robust(
  sequences = "data/aligned_sequences.fa",
  config = config,
  output_file = "results/ctcf_pwm.meme",
  format = "meme",
  verbose = TRUE
)
```

#### `validate_pwm_quality()`

**Function Signature:**
```r
validate_pwm_quality(
  pwm,                         # PWM object or file path
  sequences = NULL,            # original sequences (optional)
  validation_tests = "all",    # validation tests to run
  output_file = NULL,          # output report file
  config = list()              # validation configuration
)
```

**Return Value:**
```r
list(
  overall_quality = character,     # "EXCELLENT", "GOOD", "ACCEPTABLE", "POOR"
  quality_score = numeric,         # Overall quality score (0-1)
  validation_results = list(
    information_content = list(
      total_ic = numeric,
      conserved_positions = integer,
      ic_threshold_pass = logical
    ),
    statistical_tests = list(
      significance_test = list(p_value = numeric, significant = logical),
      null_model_comparison = list(effect_size = numeric, p_value = numeric)
    ),
    biological_validation = list(
      ctcf_pattern_similarity = numeric,
      zinc_finger_correspondence = numeric,
      biological_relevance = logical
    )
  ),
  recommendations = character,     # Improvement recommendations
  certification = list            # Quality certification details
)
```

#### `align_sequences()`

**Function Signature:**
```r
align_sequences(
  sequences,                   # input sequences
  method = "integrated",       # alignment method
  config = list(),            # method-specific configuration
  output_file = NULL          # output aligned sequences file
)
```

**Alignment Methods:**
```r
# Available methods:
# "center"     - Center-based alignment
# "consensus"  - Consensus-driven alignment  
# "integrated" - Hybrid approach (recommended)
# "iterative"  - Iterative refinement alignment
# Custom methods can be registered via extensions
```

### Utility Functions

#### `calculate_information_content()`

**Function Signature:**
```r
calculate_information_content(
  pwm,                        # probability matrix (4 x L)
  background = c(0.25, 0.25, 0.25, 0.25),  # background frequencies
  pseudocount = 0.001         # pseudocount for log calculations
)
```

**Mathematical Implementation:**
```r
# Information content formula:
# IC(i) = Σ p(b,i) * log2(p(b,i) / q(b))
# where:
#   p(b,i) = probability of base b at position i
#   q(b) = background probability of base b
#   b ∈ {A, C, G, T}
```

#### `assess_alignment_quality()`

**Function Signature:**
```r
assess_alignment_quality(
  original_sequences,         # sequences before alignment
  aligned_sequences,          # sequences after alignment
  metrics = "all"            # quality metrics to calculate
)
```

**Quality Metrics:**
```r
# Available metrics:
# "ic_improvement"     - Information content improvement ratio
# "pattern_clarity"    - Motif pattern clarity enhancement
# "conservation_gain"  - Conservation pattern improvement
# "alignment_stability" - Consistency across multiple runs
# "convergence_rate"   - Alignment algorithm convergence
```

## 📝 Configuration Schema

### Main Configuration Structure

**YAML Schema:**
```yaml
# Complete configuration schema
pipeline_config:
  
  # Data processing configuration
  data:
    input:
      format: "fasta"                    # Input format
      validation: true                   # Enable input validation
      min_sequences: 10                  # Minimum required sequences
      max_sequences: 100000              # Maximum sequences to process
    
    preprocessing:
      min_length: 50                     # Minimum sequence length
      max_length: 500                    # Maximum sequence length
      quality_threshold: 0.8             # Quality score threshold
      remove_duplicates: true            # Remove duplicate sequences
      filter_repetitive: true            # Filter repetitive elements
      normalize_length: false            # Normalize sequence lengths
    
    validation:
      method: "chromosome_split"         # Validation method
      test_ratio: 0.2                   # Test set ratio
      random_seed: 42                   # Random seed for reproducibility
  
  # Algorithm configuration
  algorithms:
    alignment:
      method: "integrated"               # Default alignment method
      parameters:
        center_window: 50                # Center alignment window
        consensus_threshold: 0.8         # Consensus threshold
        max_iterations: 10               # Maximum iterations
        convergence_threshold: 0.01      # Convergence criterion
    
    pwm_construction:
      pseudocount: 0.1                   # Pseudocount value
      background_frequencies:            # Background nucleotide frequencies
        A: 0.25
        C: 0.25
        G: 0.25
        T: 0.25
      normalization: "probability"       # Normalization method
  
  # Quality assessment configuration
  quality:
    thresholds:
      min_total_ic: 8.0                 # Minimum total information content
      min_conserved_positions: 3         # Minimum conserved positions
      conservation_threshold: 1.0        # IC threshold for conservation
    
    tests:
      information_content: true          # Enable IC analysis
      statistical_significance: true     # Enable statistical tests
      biological_validation: true       # Enable biological validation
      cross_validation: true            # Enable cross-validation
    
    grading:
      excellent_threshold: 16.0          # Excellent quality threshold
      good_threshold: 12.0               # Good quality threshold
      acceptable_threshold: 8.0          # Minimum acceptable threshold
  
  # Output configuration
  output:
    formats: ["meme", "jaspar"]          # Output formats to generate
    include_metadata: true               # Include processing metadata
    generate_reports: true              # Generate quality reports
    create_visualizations: true         # Create visualization plots
    
    file_naming:
      use_timestamp: true                # Include timestamp in filenames
      use_method_suffix: true            # Include method name in filename
      use_quality_suffix: false          # Include quality grade in filename
  
  # Performance configuration
  performance:
    parallel_processing: true           # Enable parallel processing
    num_threads: 4                     # Number of CPU threads
    memory_limit: "8G"                 # Memory usage limit
    temp_directory: "/tmp/ctcf"        # Temporary file directory
    
  # Logging configuration
  logging:
    level: "INFO"                      # Log level
    file: "pipeline.log"               # Log file path
    console_output: true               # Enable console logging
    verbose_alignment: false           # Verbose alignment logging
```

### Function-Specific Configuration

**Alignment Configuration:**
```yaml
alignment_config:
  method: "integrated"
  parameters:
    # Center-based alignment
    center:
      window_size: 50
      position_weight: 1.0
      
    # Consensus-based alignment  
    consensus:
      threshold: 0.8
      iteration_limit: 20
      convergence_criterion: 0.01
      
    # Integrated alignment
    integrated:
      weight_center: 0.4
      weight_consensus: 0.6
      refinement_cycles: 3
      
    # Iterative alignment
    iterative:
      max_iterations: 50
      improvement_threshold: 0.05
      early_stopping: true
```

**Quality Assessment Configuration:**
```yaml
quality_config:
  metrics:
    information_content:
      calculate: true
      threshold: 8.0
      per_position_threshold: 1.0
      
    conservation_analysis:
      calculate: true
      conservation_threshold: 1.0
      pattern_matching: true
      
    statistical_validation:
      significance_level: 0.01
      null_model_iterations: 1000
      bootstrap_samples: 500
      
    biological_validation:
      ctcf_pattern_check: true
      zinc_finger_analysis: true
      evolutionary_conservation: false
      
  reporting:
    generate_plots: true
    include_statistics: true
    detailed_breakdown: true
    confidence_intervals: true
```

## 📊 Data Format Specifications

### Input Formats

#### FASTA Format

**Standard FASTA:**
```
>sequence_1_chr1:1000000-1000200
ATCGATCGATCGCCGCGAATGGTGGCAGATCGATCGATC
>sequence_2_chr2:2000000-2000200  
GCTAGCTAGCGCCGCGAATGGTGGCAGGCTAGCTAGCTAG
>sequence_3_chr3:3000000-3000200
TTAATTAATGCCGCGAATGGTGGCATTAATTAATTAATT
```

**Extended FASTA with Metadata:**
```
>sequence_1_chr1:1000000-1000200|score=850|pvalue=1e-10|strand=+
ATCGATCGATCGCCGCGAATGGTGGCAGATCGATCGATC
>sequence_2_chr2:2000000-2000200|score=920|pvalue=1e-12|strand=+
GCTAGCTAGCGCCGCGAATGGTGGCAGGCTAGCTAGCTAG
```

**Validation Rules:**
- Sequence names must be unique
- Sequences must contain only valid nucleotides (A, C, G, T, N)
- Minimum sequence length: 10 bp (configurable)
- Maximum sequence length: 1000 bp (configurable)
- Ambiguous nucleotides (N) allowed but limited (<20% of sequence)

#### BED Format

**Standard BED (for coordinate input):**
```
chr1    1000000    1000200    peak_1    850    +
chr2    2000000    2000200    peak_2    920    +
chr3    3000000    3000200    peak_3    780    +
```

**Extended BED with Additional Columns:**
```
chr1    1000000    1000200    peak_1    850    +    1e-10    summitOffset=100
chr2    2000000    2000200    peak_2    920    +    1e-12    summitOffset=95
chr3    3000000    3000200    peak_3    780    +    1e-9     summitOffset=105
```

### Output Formats

#### RD Format (R Data Serialization)

**Overview:**
The RD format (.rds files) is the native R Data Serialization format used throughout the CTCF PWM Testing Pipeline for storing complex R objects with complete metadata preservation. This binary format efficiently stores PWM results, statistical analyses, and processing metadata in a compact, version-controlled manner.

**Key Features:**
- **Complete Object Preservation**: Maintains all R object attributes, metadata, and structure
- **Compact Binary Storage**: Efficient compression for large datasets
- **Version Compatibility**: Cross-platform and R version compatible
- **Fast I/O Operations**: Optimized for quick reading and writing
- **Metadata Retention**: Preserves processing timestamps, parameters, and provenance

**Core RD Object Structure:**

**PWM Result Object (.rds):**
```r
# Complete PWM result structure
pwm_result <- list(
  # Core PWM data
  pwm = matrix(                        # 4 x L probability matrix
    c(0.050, 0.850, 0.075, 0.025,    # Position 1: A, C, G, T
      0.040, 0.860, 0.070, 0.030,    # Position 2: A, C, G, T
      0.030, 0.080, 0.870, 0.020),   # Position 3: A, C, G, T
    nrow = 4, byrow = FALSE,
    dimnames = list(c("A", "C", "G", "T"), NULL)
  ),
  
  # Frequency count matrix
  frequency_matrix = matrix(
    c(50, 850, 75, 25,              # Raw counts per position
      40, 860, 70, 30,
      30, 80, 870, 20),
    nrow = 4, byrow = FALSE,
    dimnames = list(c("A", "C", "G", "T"), NULL)
  ),
  
  # Information content analysis
  information_content = c(1.85, 1.76, 1.91),  # Per-position IC values
  total_info = 19.592,                         # Total information content (bits)
  average_info = 1.306,                        # Average IC per position
  conserved_positions = c(1, 2, 3, 8, 9, 11, 12, 13, 14, 15),  # High-IC positions
  
  # Quality assessment metrics
  quality_metrics = list(
    grade = "EXCELLENT",                       # Overall quality grade
    score = 0.95,                             # Normalized quality score
    information_content_pass = TRUE,           # IC threshold check
    conservation_pass = TRUE,                  # Conservation check
    statistical_significance = list(
      p_value = 1.2e-15,                      # Significance vs null models
      significant = TRUE,                      # Boolean significance flag
      effect_size = 12.4                      # Cohen's d or similar
    ),
    biological_validation = list(
      ctcf_pattern_similarity = 0.92,         # Similarity to known CTCF motif
      zinc_finger_correspondence = 0.85,       # ZF domain mapping score
      pattern_match = TRUE                     # Boolean pattern validation
    )
  ),
  
  # Processing metadata
  creation_time = as.POSIXct("2024-01-15 10:30:15 UTC"),
  input_file = "data/ctcf_peaks_chr1.fa",
  method = "integrated_alignment",
  num_sequences = 1000,
  pseudocount = 0.1,
  background_frequencies = c(A=0.25, C=0.25, G=0.25, T=0.25),
  
  # Cross-validation results (if performed)
  cross_validation = list(
    folds = 5,
    mean_performance = 19.08,
    std_deviation = 0.64,
    coefficient_of_variation = 0.034,
    fold_results = c(18.2, 19.5, 19.8, 18.9, 19.0)
  ),
  
  # Algorithm-specific parameters
  algorithm_parameters = list(
    alignment_method = "integrated",
    center_window = 50,
    consensus_threshold = 0.8,
    max_iterations = 10,
    convergence_threshold = 0.01
  )
)

# Save PWM result
saveRDS(pwm_result, "results/ctcf_pwm.rds")
```

**Statistical Analysis Object (.rds):**
```r
# Statistical significance results structure
statistical_results <- list(
  # Null model comparison
  null_comparison = list(
    observed_ic = 19.592,                    # Real PWM information content
    null_distribution = c(2.1, 3.4, 2.8, ...), # Null model IC values (n=1000)
    null_mean = 2.473,                       # Mean of null distribution
    null_sd = 0.642,                         # Standard deviation of null
    z_score = 26.68,                         # Standardized score
    p_value = 1.2e-15,                       # Two-tailed p-value
    significant = TRUE                        # Boolean significance flag
  ),
  
  # Bootstrap confidence intervals
  bootstrap_results = list(
    n_replicates = 1000,
    bootstrap_ics = c(18.9, 19.1, 20.2, ...), # Bootstrap IC values
    confidence_intervals = list(
      ci_95 = c(18.2, 21.0),                  # 95% confidence interval
      ci_99 = c(17.8, 21.4)                   # 99% confidence interval
    )
  ),
  
  # Effect size analysis
  effect_size = list(
    cohens_d = 12.4,                         # Cohen's d effect size
    interpretation = "Very Large",            # Effect size interpretation
    confidence_interval = c(11.8, 13.0)      # CI for effect size
  ),
  
  # Multiple testing correction
  multiple_testing = list(
    method = "bonferroni",                   # Correction method
    corrected_p_value = 1.2e-14,            # Adjusted p-value
    family_wise_error_rate = 0.05           # Target FWER
  )
)

# Save statistical results
saveRDS(statistical_results, "results/statistical_analysis.rds")
```

**Reading and Writing RD Format:**

**Basic I/O Operations:**
```r
# Save R object to RD format
saveRDS(object, file = "path/to/file.rds", compress = TRUE)

# Load R object from RD format  
object <- readRDS("path/to/file.rds")

# Save with explicit compression
saveRDS(pwm_result, "results/pwm.rds", compress = "gzip")

# Batch save multiple objects
results_list <- list(pwm1 = pwm1, pwm2 = pwm2, stats = stats)
saveRDS(results_list, "results/batch_results.rds")
```

**Error Handling and Validation:**
```r
# Safe RD format operations with error handling
safe_save_rds <- function(object, file_path) {
  tryCatch({
    saveRDS(object, file_path, compress = TRUE)
    cat("✅ Successfully saved:", file_path, "\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ Error saving", file_path, ":", e$message, "\n")
    return(FALSE)
  })
}

safe_load_rds <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  tryCatch({
    object <- readRDS(file_path)
    cat("✅ Successfully loaded:", file_path, "\n")
    return(object)
  }, error = function(e) {
    cat("❌ Error loading", file_path, ":", e$message, "\n")
    return(NULL)
  })
}

# Validate PWM object structure
validate_pwm_rds <- function(pwm_object) {
  required_fields <- c("pwm", "total_info", "creation_time")
  missing_fields <- setdiff(required_fields, names(pwm_object))
  
  if (length(missing_fields) > 0) {
    stop("Missing required fields: ", paste(missing_fields, collapse = ", "))
  }
  
  if (!is.matrix(pwm_object$pwm) || nrow(pwm_object$pwm) != 4) {
    stop("PWM matrix must be 4 x L matrix (A, C, G, T rows)")
  }
  
  return(TRUE)
}
```

**Integration with Other Formats:**

**RD to MEME Conversion:**
```r
# Convert RD format to MEME format
convert_rds_to_meme <- function(rds_file, output_file) {
  pwm_data <- readRDS(rds_file)
  
  meme_content <- c(
    "MEME version 4",
    "",
    "ALPHABET= ACGT",
    "",
    "strands: + -",
    "",
    "Background letter frequencies (from uniform background):",
    "A 0.25000 C 0.25000 G 0.25000 T 0.25000",
    "",
    "MOTIF CTCF_PWM",
    paste0("letter-probability matrix: alength= 4 w= ", ncol(pwm_data$pwm), 
           " nsites= ", pwm_data$num_sequences, " E= 0")
  )
  
  # Add probability matrix
  for (j in 1:ncol(pwm_data$pwm)) {
    row_values <- sprintf("%.6f", pwm_data$pwm[, j])
    meme_content <- c(meme_content, paste(row_values, collapse = " "))
  }
  
  writeLines(meme_content, output_file)
}
```

**RD to JSON Conversion:**
```r
# Convert RD format to JSON
convert_rds_to_json <- function(rds_file, output_file) {
  pwm_data <- readRDS(rds_file)
  
  json_data <- list(
    motif = list(
      name = "CTCF_PWM",
      created = as.character(pwm_data$creation_time)
    ),
    pwm = list(
      probability_matrix = as.list(as.data.frame(pwm_data$pwm)),
      consensus_sequence = generate_consensus(pwm_data$pwm),
      length = ncol(pwm_data$pwm)
    ),
    information_content = list(
      per_position = pwm_data$information_content,
      total = pwm_data$total_info
    ),
    quality_metrics = pwm_data$quality_metrics,
    processing_metadata = list(
      input_sequences = pwm_data$num_sequences,
      method = pwm_data$method,
      processing_time = as.character(pwm_data$creation_time)
    )
  )
  
  jsonlite::write_json(json_data, output_file, pretty = TRUE)
}
```

**Use Cases and Applications:**

1. **Intermediate Results Storage**: Save processing results between pipeline steps
2. **Result Archiving**: Long-term storage of PWM analyses with complete metadata
3. **Batch Processing**: Efficient storage and retrieval for large-scale analyses
4. **Cross-Analysis Integration**: Share results between different analysis workflows
5. **Version Control**: Track analysis evolution with timestamped objects
6. **Reproducibility**: Preserve exact analysis state for reproducible research

**Performance Characteristics:**

- **File Size**: ~10-50KB for typical PWM results (with compression)
- **I/O Speed**: ~0.1-1ms for typical PWM objects
- **Compression**: 60-80% size reduction with gzip compression
- **Memory Usage**: Minimal overhead for R native objects
- **Cross-Platform**: Compatible across Windows, Linux, macOS

**Best Practices:**

1. **Always Use Compression**: `saveRDS(object, file, compress = "gzip")`
2. **Include Metadata**: Timestamp, method, parameters for reproducibility
3. **Validate Structure**: Check object integrity after loading
4. **Error Handling**: Use tryCatch for robust file operations
5. **Naming Convention**: Use descriptive filenames with method and timestamp
6. **Documentation**: Include processing metadata within objects

#### MEME Format (TBD)

**Complete MEME Format Specification:**
```
MEME version 4

ALPHABET= ACGT

strands: + -

Background letter frequencies (from uniform background):
A 0.25000 C 0.25000 G 0.25000 T 0.25000

MOTIF CTCF_PWM
letter-probability matrix: alength= 4 w= 15 nsites= 1000 E= 0
 0.050000  0.850000  0.075000  0.025000
 0.040000  0.860000  0.070000  0.030000
 0.030000  0.080000  0.870000  0.020000
 0.045000  0.855000  0.075000  0.025000
 0.100000  0.100000  0.700000  0.100000
 0.200000  0.300000  0.300000  0.200000
 0.250000  0.250000  0.250000  0.250000
 0.050000  0.100000  0.800000  0.050000
 0.030000  0.070000  0.870000  0.030000
 0.180000  0.320000  0.320000  0.180000
 0.060000  0.140000  0.740000  0.060000
 0.050000  0.100000  0.800000  0.050000
 0.040000  0.860000  0.070000  0.030000
 0.900000  0.033000  0.033000  0.033000
 0.100000  0.100000  0.700000  0.100000
```

#### JASPAR Format (TBD)

**JASPAR Matrix Format:**
```
>CTCF_PWM
A  [   50   40   30   45  100  200  250   50   30  180   60   50   40  900  100 ]
C  [  850  860   80  855  100  300  250  100   70  320  140  100  860   33  100 ]
G  [   75   70  870   75  700  300  250  800  870  320  740  800   70   33  700 ]
T  [   25   30   20   25  100  200  250   50   30  180   60   50   30   33  100 ]
```

#### JSON Format (TBD)

**Complete JSON Output Schema:**
```json
{
  "motif": {
    "name": "CTCF_PWM",
    "id": "motif_001",
    "version": "1.0",
    "created": "2024-01-15T10:30:15Z"
  },
  "pwm": {
    "probability_matrix": [
      [0.050, 0.040, 0.030, 0.045],
      [0.850, 0.860, 0.080, 0.855],
      [0.075, 0.070, 0.870, 0.075],
      [0.025, 0.030, 0.020, 0.025]
    ],
    "frequency_matrix": [
      [50, 40, 30, 45],
      [850, 860, 80, 855],
      [75, 70, 870, 75],
      [25, 30, 20, 25]
    ],
    "consensus_sequence": "CCGCGNGGNGGCAG",
    "length": 15,
    "alphabet": ["A", "C", "G", "T"]
  },
  "information_content": {
    "per_position": [1.8, 1.6, 1.9, 1.7, 0.8, 0.4, 0.9, 1.5, 1.4, 0.6, 1.2, 1.3, 1.8, 1.6, 1.4],
    "total": 19.592,
    "conserved_positions": [1, 2, 3, 4, 8, 9, 11, 12, 13, 14, 15],
    "conservation_threshold": 1.0
  },
  "quality_metrics": {
    "grade": "EXCELLENT",
    "score": 0.95,
    "information_content_pass": true,
    "conservation_pass": true,
    "statistical_significance": {
      "p_value": 1.2e-15,
      "significant": true
    },
    "biological_validation": {
      "ctcf_pattern_similarity": 0.92,
      "zinc_finger_correspondence": 0.85,
      "pattern_match": true
    }
  },
  "processing_metadata": {
    "input_sequences": 1000,
    "alignment_method": "integrated",
    "processing_time": "35.2 seconds",
    "software_version": "2.0.0",
    "parameters": {
      "pseudocount": 0.1,
      "background_frequencies": [0.25, 0.25, 0.25, 0.25],
      "quality_threshold": 8.0
    }
  },
  "validation_results": {
    "cross_validation": {
      "folds": 5,
      "mean_performance": 19.08,
      "std_deviation": 0.64,
      "coefficient_of_variation": 0.034
    },
    "statistical_tests": {
      "null_model_comparison": {
        "p_value": 1.2e-15,
        "effect_size": 12.4
      },
      "bootstrap_confidence": {
        "lower_95": 18.2,
        "upper_95": 21.0
      }
    }  }
}
```

## 🔌 Command-Line Interface

### Main Pipeline Scripts

#### `build_pwm_robust.R`

**Full Command-Line Interface:**
```bash
Rscript scripts/build_pwm_robust.R \
  --sequences PATH              # Input sequences file (required)
  --output PATH                 # Output PWM file (required) 
  --config PATH                 # Configuration file (optional)
  --format FORMAT               # Output format: meme|jaspar|transfac|json
  --pseudocount FLOAT           # Pseudocount value (default: 0.1)
  --background A,C,G,T          # Background frequencies (default: 0.25,0.25,0.25,0.25)
  --min-ic FLOAT                # Minimum information content threshold
  --min-conserved INT           # Minimum conserved positions
  --threads INT                 # Number of threads (default: 4)
  --memory SIZE                 # Memory limit (e.g., 8G)
  --temp-dir PATH               # Temporary directory
  --verbose                     # Verbose output
  --debug                       # Debug mode
  --quiet                       # Suppress non-error output
  --force                       # Force overwrite existing files
  --dry-run                     # Show what would be done
  --help                        # Show help message
```

**Exit Codes:**
```bash
# Exit code meanings:
0   # Success
1   # General error
2   # Invalid arguments
3   # Input file not found
4   # Output file cannot be created
5   # Insufficient memory
6   # Quality threshold not met
7   # Configuration error
8   # Processing timeout
```

### Batch Processing Scripts (TBD)

#### `batch_process_pwms.sh`

**Batch Processing Interface:**
```bash
#!/bin/bash
# Batch process multiple PWM datasets

./scripts/batch_process_pwms.sh \
  --input-dir DIR               # Directory containing input files
  --output-dir DIR              # Output directory
  --config FILE                 # Configuration file
  --pattern GLOB                # File pattern (e.g., "*.fa")
  --parallel JOBS               # Number of parallel jobs
  --resume                      # Resume interrupted processing
  --dry-run                     # Show processing plan
```

## 🔗 Integration APIs (Future)

### R Package Integration

**Load as R Package:**
```r
# Install and load CTCF pipeline as R package
devtools::install_local("path/to/ctcf-predictor")
library(ctcfpredictor)

# Use package functions
result <- ctcfpredictor::build_pwm_robust(sequences)
quality <- ctcfpredictor::validate_pwm_quality(result$pwm)
```

### Python Integration

**R-Python Bridge:**
```python
# Use rpy2 to call R functions from Python
import rpy2.robjects as ro
from rpy2.robjects import pandas2ri
pandas2ri.activate()

# Load R script
ro.r.source('scripts/build_pwm_robust.R')

# Call R function from Python
sequences = ["ATCGATCG", "ATCGATCG", "ATCGATCG"]
result = ro.r['build_pwm_robust'](sequences)
```

### REST API Interface

**HTTP API Endpoints:**
```
POST /api/v1/pwm/build
  Content-Type: multipart/form-data
  Parameters:
    sequences: file upload (FASTA format)
    config: JSON configuration (optional)
    format: output format (optional)
  Response: JSON with PWM results

GET /api/v1/pwm/{job_id}/status
  Response: JSON with job status

GET /api/v1/pwm/{job_id}/results
  Response: PWM results in requested format

POST /api/v1/pwm/validate
  Content-Type: application/json
  Body: PWM data for validation
  Response: Validation results

GET /api/v1/formats
  Response: List of supported input/output formats

GET /api/v1/health
  Response: API health status
```

## 🎯 Extension APIs

### Plugin Interface

**Plugin Development Interface:**
```r
# Plugin interface specification
create_plugin <- function(plugin_name) {
  list(
    # Plugin metadata
    info = list(
      name = plugin_name,
      version = "1.0.0",
      description = "Plugin description",
      author = "Author name",
      dependencies = character(0),
      pipeline_version_min = "2.0.0"
    ),
    
    # Plugin initialization
    initialize = function(config = list()) {
      # Plugin initialization code
    },
    
    # Main plugin function
    execute = function(input_data, config = list()) {
      # Plugin processing logic
      # Must return standardized output format
    },
    
    # Plugin cleanup
    cleanup = function() {
      # Cleanup resources
    },
    
    # Plugin configuration schema
    config_schema = list(
      type = "object",
      properties = list(
        # Configuration property definitions
      )
    )
  )
}
```

### Custom Method Registration

**Method Registration API:**
```r
# Register custom alignment method
register_alignment_method <- function(method_name, method_function) {
  # Validate method function interface
  validate_alignment_method(method_function)
  
  # Register in global method registry
  ALIGNMENT_METHODS[[method_name]] <- method_function
  
  # Update method documentation
  update_method_documentation(method_name, method_function)
}

# Register custom quality metric
register_quality_metric <- function(metric_name, metric_function) {
  validate_quality_metric(method_function)
  QUALITY_METRICS[[metric_name]] <- metric_function
}

# Register custom output format
register_output_format <- function(format_name, format_function) {
  validate_output_format(format_function)
  OUTPUT_FORMATS[[format_name]] <- format_function
}
```

## 🔍 Error Handling

### Standard Error Codes

**Pipeline Error Codes:**
```r
# Error code definitions
PIPELINE_ERRORS <- list(
  SUCCESS = 0,
  GENERAL_ERROR = 1,
  INVALID_ARGUMENTS = 2,
  FILE_NOT_FOUND = 3,
  PERMISSION_DENIED = 4,
  INSUFFICIENT_MEMORY = 5,
  QUALITY_THRESHOLD_NOT_MET = 6,
  CONFIGURATION_ERROR = 7,
  PROCESSING_TIMEOUT = 8,
  INVALID_INPUT_FORMAT = 9,
  ALIGNMENT_FAILED = 10,
  PWM_CONSTRUCTION_FAILED = 11,
  VALIDATION_FAILED = 12
)
```

### Exception Handling

**Structured Error Objects:**
```r
# Error object structure
create_error <- function(code, message, details = NULL, suggestions = NULL) {
  structure(
    list(
      code = code,
      message = message,
      details = details,
      suggestions = suggestions,
      timestamp = Sys.time(),
      call = sys.call(-1)
    ),
    class = c("pipeline_error", "error", "condition")
  )
}

# Example error handling
tryCatch({
  result <- build_pwm_robust(sequences)
}, pipeline_error = function(e) {
  cat("Pipeline error occurred:\n")
  cat("Code:", e$code, "\n")
  cat("Message:", e$message, "\n")
  if (!is.null(e$suggestions)) {
    cat("Suggestions:", paste(e$suggestions, collapse = "\n"), "\n")
  }
})
```

---

## 📖 Related Documentation

- **[Scripts Reference](08-scripts-reference.md)** - Detailed script documentation
- **[Configuration Guide](09-configuration.md)** - Complete configuration reference
- **[Extending the Pipeline](13-extending-pipeline.md)** - Custom development guide

---

*This comprehensive API reference provides all technical specifications needed for integration, customization, and extension of the CTCF PWM Testing Pipeline.*
