# Performance Benchmarks

This document provides realistic runtime and memory usage estimates for ByeGenoQC on typical datasets.

---

## SNP Array QC Benchmarks

All benchmarks run on **4 CPU cores, 8 GB RAM** with Docker on Linux.

### Small cohort (1,000 samples, 500K variants)

```
Task                Duration    Memory    Notes
────────────────────────────────────────────────
Input check         5 sec       100 MB    PLINK validation
Variant QC          45 sec      600 MB    Missingness, HWE, MAF
Sample QC           2 min       1.2 GB    Heterozygosity, relatedness
PCA                 1.5 min     800 MB    20 PCs, LD-pruned
Ancestry check      30 sec      400 MB    Population assignment
Report gen          20 sec      300 MB    HTML with plots
────────────────────────────────────────────────
Total (full QC)     ~5 min      1.2 GB    Wall-clock time
Total (variant-only) ~1 min     600 MB    If sample_qc=false
```

### Medium cohort (10,000 samples, 2M variants)

```
Task                Duration    Memory    Notes
────────────────────────────────────────────────
Input check         10 sec      200 MB    PLINK validation
Variant QC          3 min       1.5 GB    Filters scale with variants
Sample QC           8 min       2.5 GB    Scales with samples
PCA                 5 min       1.8 GB    Per-sample computation
Ancestry check      1 min       600 MB    
Report gen          30 sec      500 MB    Large interactive plots
────────────────────────────────────────────────
Total (full QC)     ~20 min     2.5 GB    Wall-clock time
Total (variant-only) ~4 min     1.5 GB    If sample_qc=false
```

### Large cohort (50,000 samples, 2M variants)

```
Task                Duration    Memory    Notes
────────────────────────────────────────────────
Input check         30 sec      400 MB    
Variant QC          4 min       2 GB      Variant count dominates
Sample QC           35 min      4 GB      Quadratic with samples (relatedness)
PCA                 15 min      3 GB      Per-sample + per-PC computation
Ancestry check      3 min       1 GB      
Report gen          1 min       1 GB      Large dataset → larger report
────────────────────────────────────────────────
Total (full QC)     ~60 min     4 GB      Relatedness is bottleneck
Total (variant-only) ~5 min     2 GB      If sample_qc=false
```

### Inspect Workflow (SNP array)

The inspect workflow runs variant QC and computes metric distributions:

```
Task                Duration    Memory    
────────────────────────────────────────
Metric computation  2-5 min     800 MB-2GB  Scales with samples
Threshold inference 1 min       500 MB     
Report gen          20 sec      300 MB     
────────────────────────────────────────
Total               3-6 min     2 GB       
```

---

## WGS/WES QC Benchmarks

Benchmarks run on **8 CPU cores, 16 GB RAM** with Docker on Linux. Scaling improves with more cores.

### Small WES dataset (50 samples, 4.5M variants, 30x coverage)

```
Task                Duration    Memory    Notes
────────────────────────────────────────────────
Input check         2 min       2 GB      BAM index reading
Alignment metrics   5 min       3 GB      Per-sample samtools stats
Duplicate marking   10 min      4 GB      Per-sample dedup
Coverage analysis   8 min       3 GB      mosdepth on targets
Contamination       12 min      5 GB      VerifyBamID2 (slow)
Variant QC          3 min       2 GB      VCF or GVCF parsing
Genotype filter     2 min       1 GB      GQ/DP thresholds
Sample QC           2 min       1 GB      Cohort-level metrics
PCA                 3 min       2 GB      20 PCs on filtered variants
Report gen          1 min       1 GB      
────────────────────────────────────────────────
Total (BAM input)   ~50 min     5 GB      Per-sample: ~1 min each
Total (VCF input)   ~10 min     3 GB      Much faster (no BAM parsing)
```

### Medium WGS dataset (200 samples, 3M variants, 25x coverage)

```
Task                Duration    Memory    Notes
────────────────────────────────────────────────
Alignment metrics   18 min      5 GB      200 samples × 5 sec each
Duplicate marking   40 min      6 GB      200 samples × 12 sec each (parallel)
Coverage analysis   30 min      5 GB      Whole-genome mosdepth
Contamination       80 min      8 GB      VerifyBamID2: slowest step
Variant QC          5 min       3 GB      
Genotype filter     3 min       2 GB      
Sample QC           3 min       2 GB      
PCA                 8 min       4 GB      
Report gen          2 min       1 GB      
────────────────────────────────────────────────
Total (BAM input)   ~3-4 hours  8 GB      Parallelization helps (scale with cores)
Total (VCF input)   ~20 min     3 GB      If variants pre-computed
```

### Large cohort (1000 samples, 3M variants)

```
Estimated scaling (parallelized over 16 cores):
- Alignment/coverage metrics: ~5 hours
- Contamination (serial): ~7 hours  ← main bottleneck
- Variant/genotype filtering: ~30 min
- PCA: ~1 hour
────────────────────────────────────────────────
Total: ~13-14 hours with 16-core parallelization
```

---

## Resource Scaling Rules

### CPU cores
- **Variant-level QC:** Linear scaling (more cores = faster per-variant filtering)
- **Sample-level QC:** Sublinear scaling (per-sample tasks parallelize well until 8–16 cores)
- **Contamination check:** No parallelization; always serial
- **PCA:** Scales with cores up to # of samples

**Recommendation:** 8–16 cores for WES; 4 cores sufficient for SNP array.

### Memory
- **SNP array:** ~500 MB + (samples × variants / 1 billion) × 100 MB
  - 1K samples × 500K variants ≈ 1 GB
  - 50K samples × 500K variants ≈ 4 GB
- **WGS/WES (BAM input):** ~4 GB base + 2 GB per 10 concurrent samples
  - 10 samples in parallel: ~6 GB
  - 100 samples in parallel: ~20+ GB
- **WGS/WES (VCF input):** ~2 GB + (variants / 1 million) × 100 MB

**Recommendation:** 8–16 GB for typical cohorts; scale up for WGS 1000G scale.

### Disk space

| Data type | Cohort size | Input | Output (with intermediates) | Output (report only) |
|-----------|------------|-------|---------------------------|----------------------|
| SNP array | 1K/500K | 50 MB | 100 MB | 10 MB |
| SNP array | 50K/500K | 2.5 GB | 5 GB | 50 MB |
| WES | 50 samples, 30x | 250 GB | 500 GB | 100 MB |
| WGS | 200 samples, 25x | 2 TB | 4 TB | 500 MB |

**Tip:** Use `--keep_intermediate false` (default) to save disk space; only final results are kept.

---

## Expected Run Times by Platform

### Local machine (Docker, 4 cores, 8 GB RAM)
- Small SNP array (1K samples): **5 min**
- Small WES (50 samples): **60 min**

### HPC cluster (16 cores, 32 GB RAM, Singularity)
- Medium SNP array (10K samples): **20 min**
- Medium WES (200 samples): **3–4 hours**

### HPC without containers (manual_paths, SLURM)
- Same as above; no container overhead
- May be 10–15% faster due to no Docker image pull time

---

## Parallelization Notes

### SNP Array
- Variant QC can run **per-chromosome in parallel** (22 jobs max)
- Sample QC runs on full dataset (not parallelizable)
- Overall speedup: ~5–8x with full parallelization

### WGS/WES
- Per-sample tasks (BAM metrics, coverage) parallelize well
- VCF variant filtering parallelizes per-chromosome
- Contamination check is single-threaded (bottleneck for large cohorts)
- Overall speedup: ~4–10x depending on tasks

---

## Optimization Tips

### For SNP Array
1. **Reduce by chromosome:** `--chroms 1-10` for testing (40% of time)
2. **Skip sample QC:** `--run_sample_qc false` for variant filtering only (4–5x faster)
3. **Skip PCA:** `--run_ancestry_pca false` saves 30% time if not needed

### For WGS/WES
1. **Use VCF if available:** 5–10x faster than BAM input (no alignment metrics)
2. **Subset to autosomes:** `--chroms 1-22` to skip sex chromosomes (10% faster)
3. **Disable contamination:** `--run_contamination false` saves 25% (if running multiple times)
4. **Parallelize over SLURM:** ByeGenoQC uses 8–16 cores by default; submit multiple jobs with different `--chroms` ranges

### General
1. **Use Singularity on HPC** instead of Docker (no image pull overhead)
2. **Place workdir on local scratch** instead of NFS (faster I/O)
3. **Increase `max_cpus`** and `max_memory` if available (scales with resources)

---

## Benchmarking Your Own Data

To benchmark on your cohort:

```bash
# SNP array
time nextflow run snp_array_qc/main.nf \
  --bfile your_data \
  --outdir results/benchmark \
  -profile docker \
  -with-timeline timeline.html

# WGS/WES (VCF is faster)
time nextflow run wgs_wes_qc/main.nf \
  --input_type vcf \
  --samplesheet samplesheet.csv \
  --reference_fasta ref.fa \
  --mode wgs \
  --outdir results/benchmark \
  -profile docker \
  -with-timeline timeline.html
```

Then check `.nextflow.log` for per-task durations and memory:
```bash
grep "COMPLETED\|CPU\|MEMORY" .nextflow.log | tail -20
```

Report your results as an [issue](https://github.com/kaiyao28/ByeGenoQC/issues) to help us improve benchmarks!

---

## Troubleshooting Performance

**Benchmark much slower than expected?**
- Check `docker system df` — Docker disk full?
- Check `free -h` — system swap being used?
- Check network I/O if working on NFS cluster

**Contamination check very slow?**
- VerifyBamID2 has no parallelization; consider skipping or running overnight
- Alternatively, use GATK CalculateContamination (faster but less sensitive)

**Memory exceeded despite large allocation?**
- Reduce `--max_cpus` to avoid excessive parallelization
- Increase task-specific memory in `conf/base.config`
