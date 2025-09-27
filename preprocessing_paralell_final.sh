#!/bin/bash

# Directories for fastp and salmon output
FASTP_DIR="/mnt/h/preprocessing_output_2/fastp_output"
SALMON_DIR="/mnt/h/preprocessing_output_2/salmon_output"

# Arrays to store paired-end and single-end files
single_end_samples=()
paired_end_samples=()

# Check for single-end and paired-end files
echo "Checking FASTQ files..."
for fastq_file in /mnt/h/FASTQ/*.fastq; do
    filename=$(basename "$fastq_file")
    if [[ "$filename" =~ _1\.fastq$ || "$filename" =~ _2\.fastq$ ]]; then
        # Paired-end files (check for _1 or _2 suffix)
        paired_end_samples+=("$fastq_file")
    else
        # Single-end files (no _1 or _2 suffix)
        single_end_samples+=("$fastq_file")
    fi
done

# Output to confirm how many of each type were found
echo "Single-end files found: ${#single_end_samples[@]}"
echo "Paired-end files found: ${#paired_end_samples[@]}"

# Process single-end samples first
if [ ${#single_end_samples[@]} -gt 0 ]; then
    echo "Processing single-end samples..."
    for sample in "${single_end_samples[@]}"; do
        echo "Processing single-end sample: $sample"
        R1="$sample"  # For single-end, R1 is just the single file
        OUT_R1="$FASTP_DIR/$(basename "$sample" .fastq)_trimmed.fastq"
        JSON="$FASTP_DIR/$(basename "$sample" .fastq)_fastp.json"
        
        echo "Running fastp on single-end file: $R1"
        fastp -i "$R1" -o "$OUT_R1" --json "$JSON" 

        echo "Running Salmon for single-end file: $R1"
        salmon quant -i /mnt/h/salmon_index -l A -r "$OUT_R1" -p 8 --validateMappings --output "$SALMON_DIR/$(basename "$sample" .fastq)_salmon"
    done
else
    echo "No single-end files to process."
fi

# Process paired-end samples after
if [ ${#paired_end_samples[@]} -gt 0 ]; then
    echo "Processing paired-end samples..."
    for sample in "${paired_end_samples[@]}"; do
        echo "Processing paired-end sample: $sample"
        
        # Define R1 and R2 for paired-end files
        if [[ "$sample" =~ _1\.fastq$ ]]; then
            R1="$sample"
            R2="${sample/_1.fastq/_2.fastq}"  # Assuming _2.fastq exists for paired-end files

            OUT_R1="$FASTP_DIR/$(basename "$R1" .fastq)_trimmed_R1.fastq"
            OUT_R2="$FASTP_DIR/$(basename "$R1" .fastq)_trimmed_R2.fastq"
            JSON="$FASTP_DIR/$(basename "$R1" .fastq)_fastp.json"
            
            echo "Running fastp on paired-end files: $R1 and $R2"
            fastp -i "$R1" -I "$R2" -o "$OUT_R1" -O "$OUT_R2" --json "$JSON"

            echo "Running Salmon for paired-end files: $R1 and $R2"
            salmon quant -i /mnt/h/salmon_index -l A -1 "$OUT_R1" -2 "$OUT_R2" -p 8 --validateMappings --output "$SALMON_DIR/$(basename "$R1" .fastq)_salmon"
        fi
    done
else
    echo "No paired-end files to process."
fi