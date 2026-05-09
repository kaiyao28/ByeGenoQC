#!/usr/bin/env python3
"""
generate_test_data.py — create synthetic test data for GenoClean smoke tests.

Run from the repository root:
    python3 test_data/generate_test_data.py

Writes:
    test_data/reference/mini.fa          500bp chr22 reference
    test_data/reference/mini.fa.fai      FASTA index
    test_data/wgs_wes/toy_chr22.vcf      20-variant 5-sample VCF
    test_data/wgs_wes/samplesheet_vcf.csv
    test_data/snp_array/toy.bed          PLINK binary (SNP-major)
    test_data/snp_array/toy.bim          variant info
    test_data/snp_array/toy.fam          sample info

Designed QC triggers
--------------------
SNP array — sample-level:
  S01 : ~25 % missing genotypes → fails sample callrate (>2 %)
  S02 : identical genotypes to S03 → relatedness filter (PI_HAT ≈ 1.0)
  S03 : identical genotypes to S02 → relatedness filter (PI_HAT ≈ 1.0)
  S07 : 70 % of autosomal calls forced heterozygous → het rate outlier
  S09 : PEDSEX=female but all chrX calls homozygous → sex check failure

SNP array — variant-level:
  v201-210 : ~35 % missing per sample → fail variant callrate (>2 %)
  v211-213 : monomorphic (MAF=0) → fail MAF filter
  v214-215 : all heterozygous → extreme HWE departure
  v216-235 : chrX (chr23) — enable PLINK sex check

VCF:
  rs013 : FAIL site filter (QD < 2)
  rs015 : FAIL site filter (FS > 60)
  rs013 + rs018 : low DP/GQ genotypes for genotype-level filter demo
"""
import os
import random
import struct

random.seed(42)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
os.chdir(ROOT)


# ══════════════════════════════════════════════════════════════════════════════
#  Reference FASTA  (500 bp chr22)
# ══════════════════════════════════════════════════════════════════════════════
PATTERN = "ATCGATCG"
REF_LEN = 500
SEQ = (PATTERN * (REF_LEN // len(PATTERN) + 1))[:REF_LEN]

def ref_base(pos1, length=1):
    return SEQ[pos1 - 1: pos1 - 1 + length]

os.makedirs("test_data/reference", exist_ok=True)

with open("test_data/reference/mini.fa", "w") as fh:
    fh.write(f">22\n{SEQ}\n")

with open("test_data/reference/mini.fa.fai", "w") as fh:
    fh.write(f"22\t{REF_LEN}\t4\t{REF_LEN}\t{REF_LEN + 1}\n")

print(f"[OK] Reference: test_data/reference/mini.fa  ({REF_LEN} bp, chr22)")


# ══════════════════════════════════════════════════════════════════════════════
#  WGS/WES VCF  (5 samples, 20 variants on chr22)
# ══════════════════════════════════════════════════════════════════════════════
SAMPLES_VCF = ["SAMPLE1", "SAMPLE2", "SAMPLE3", "SAMPLE4", "SAMPLE5"]

SNPS = [
    ( 25, "rs001", "A", "G",  60, "PASS", 10.0,  2.0, 60.0,  0.5,  0.2, "Ti"),
    ( 50, "rs002", "T", "C",  55, "PASS",  9.5,  1.5, 59.0,  0.3,  0.1, "Ti"),
    ( 75, "rs003", "C", "T",  65, "PASS", 11.0,  2.5, 60.0, -0.2, -0.3, "Ti"),
    (100, "rs004", "G", "A",  70, "PASS", 12.0,  1.0, 61.0,  0.1,  0.0, "Ti"),
    (125, "rs005", "A", "C",  58, "PASS",  9.0,  3.0, 59.5,  0.4,  0.2, "Tv"),
    (150, "rs006", "T", "G",  62, "PASS", 10.5,  2.0, 60.0, -0.1, -0.1, "Tv"),
    (175, "rs007", "C", "T",  67, "PASS", 11.5,  1.5, 60.5,  0.2,  0.1, "Ti"),
    (200, "rs008", "G", "A",  72, "PASS", 12.5,  1.0, 61.0,  0.0,  0.0, "Ti"),
    (225, "rs009", "A", "G",  60, "PASS", 10.0,  2.5, 59.0,  0.3,  0.2, "Ti"),
    (250, "rs010", "T", "A",  54, "PASS",  8.5,  3.5, 58.5,  0.5,  0.3, "Tv"),
    (275, "rs011", "C", "T",  68, "PASS", 11.0,  2.0, 60.0, -0.2, -0.1, "Ti"),
    (300, "rs012", "G", "A",  73, "PASS", 12.0,  1.5, 61.0,  0.1,  0.0, "Ti"),
    (325, "rs013", "A", "G",  45, "FAIL",  1.0,  5.0, 60.0,  0.0,  0.0, "Ti"),  # FAIL: QD<2
    (350, "rs014", "T", "C",  59, "PASS",  9.5,  2.0, 59.5,  0.4,  0.2, "Ti"),
    (375, "rs015", "C", "A",  61, "FAIL",  8.0,100.0, 60.0,  0.3,  0.1, "Tv"),  # FAIL: FS>60
    (400, "rs016", "G", "A",  74, "PASS", 12.5,  1.0, 61.0,  0.0,  0.0, "Ti"),
    (425, "rs017", "A", "G",  63, "PASS", 10.5,  2.0, 60.0,  0.2,  0.1, "Ti"),
    (450, "rs018", "T", "A",  56, "PASS",  8.8,  3.2, 58.0,  0.4,  0.3, "Tv"),
]

INDELS = [
    (475, "rs019", ref_base(475, 2), ref_base(475)),
    (500, "rs020", ref_base(500),    ref_base(500) + "A"),
]

for pos, rsid, ref_allele, alt, *_ in SNPS:
    actual = ref_base(pos)
    assert actual == ref_allele, f"REF mismatch at pos {pos} ({rsid})"

GENO_SNPS = [
    [("0/0",25,99),("0/1",20,85),("1/1",22,90),("0/1",18,80),("0/0",30,99)],
    [("0/1",18,80),("0/0",25,99),("0/1",21,82),("1/1",15,75),("0/0",28,99)],
    [("0/0",30,99),("0/1",22,88),("0/0",25,99),("0/1",20,85),("1/1",18,90)],
    [("0/1",20,85),("1/1",17,88),("0/1",23,90),("0/0",28,99),("0/1",19,82)],
    [("0/0",25,99),("0/0",22,99),("0/1",20,80),("0/1",18,75),("0/0",30,99)],
    [("0/1",22,88),("0/0",25,99),("0/0",28,99),("1/1",15,85),("0/1",20,82)],
    [("1/1",18,90),("0/1",20,85),("0/0",25,99),("0/0",28,99),("0/1",22,88)],
    [("0/0",28,99),("0/1",22,88),("0/1",19,80),("0/0",30,99),("1/1",16,85)],
    [("0/1",20,82),("0/0",26,99),("1/1",17,88),("0/1",21,85),("0/0",25,99)],
    [("0/0",25,99),("0/1",20,80),("0/0",28,99),("0/1",18,78),("0/0",30,99)],
    [("0/1",19,82),("1/1",16,88),("0/1",22,85),("0/0",27,99),("0/1",20,80)],
    [("0/0",27,99),("0/1",21,85),("0/1",18,78),("1/1",14,85),("0/0",29,99)],
    [("0/1", 5,12),("0/0", 7,18),("0/1", 6,15),("0/0", 8,10),("1/1", 5,14)],  # rs013 low DP/GQ
    [("0/0",24,99),("0/1",19,82),("0/1",21,85),("0/0",26,99),("1/1",16,88)],
    [("0/1",20,80),("0/0",25,99),("0/0",27,99),("0/1",18,78),("0/0",30,99)],
    [("0/0",30,99),("0/1",22,88),("1/1",18,90),("0/1",20,85),("0/0",25,99)],
    [("0/1",21,85),("0/0",27,99),("0/1",19,80),("1/1",15,85),("0/0",28,99)],
    [("0/1",18, 8),("0/0",25,99),("0/0",28,99),("0/1",19, 9),("1/1",14,85)],  # rs018 low GQ
]
GENO_INDELS = [
    [("0/1",20,82),("0/0",25,99),("0/1",18,80),("0/0",27,99),("1/1",15,85)],
    [("0/0",28,99),("0/1",21,85),("0/0",25,99),("0/1",19,82),("0/0",30,99)],
]

os.makedirs("test_data/wgs_wes", exist_ok=True)

vcf_header = [
    "##fileformat=VCFv4.2",
    f"##contig=<ID=22,length={REF_LEN}>",
    '##FILTER=<ID=PASS,Description="All filters passed">',
    '##FILTER=<ID=FAIL,Description="Failed site-level QC filter">',
    '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
    '##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read depth">',
    '##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype quality">',
    '##INFO=<ID=QD,Number=1,Type=Float,Description="Quality by depth">',
    '##INFO=<ID=FS,Number=1,Type=Float,Description="Fisher strand bias">',
    '##INFO=<ID=MQ,Number=1,Type=Float,Description="Mapping quality">',
    '##INFO=<ID=MQRankSum,Number=1,Type=Float,Description="MQ rank sum">',
    '##INFO=<ID=ReadPosRankSum,Number=1,Type=Float,Description="Read position rank sum">',
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t" + "\t".join(SAMPLES_VCF),
]

vcf_records = []
for i, (pos, rsid, ref, alt, qual, flt, qd, fs, mq, mqrs, rprs, _) in enumerate(SNPS):
    info = f"QD={qd};FS={fs};MQ={mq};MQRankSum={mqrs};ReadPosRankSum={rprs}"
    gts  = "\t".join(f"{g}:{d}:{q}" for g, d, q in GENO_SNPS[i])
    vcf_records.append(f"22\t{pos}\t{rsid}\t{ref}\t{alt}\t{qual}\t{flt}\t{info}\tGT:DP:GQ\t{gts}")
for j, (pos, rsid, ref, alt) in enumerate(INDELS):
    info = "QD=9.0;FS=2.0;MQ=60.0;MQRankSum=0.0;ReadPosRankSum=0.0"
    gts  = "\t".join(f"{g}:{d}:{q}" for g, d, q in GENO_INDELS[j])
    vcf_records.append(f"22\t{pos}\t{rsid}\t{ref}\t{alt}\t65\tPASS\t{info}\tGT:DP:GQ\t{gts}")

vcf_records.sort(key=lambda l: int(l.split("\t")[1]))

with open("test_data/wgs_wes/toy_chr22.vcf", "w") as fh:
    fh.write("\n".join(vcf_header + vcf_records) + "\n")

with open("test_data/wgs_wes/samplesheet_vcf.csv", "w") as fh:
    fh.write("sample,file1\n")
    fh.write("toy_cohort,test_data/wgs_wes/toy_chr22.vcf\n")

n_ti = sum(1 for *_, t in SNPS if t == "Ti")
n_tv = sum(1 for *_, t in SNPS if t == "Tv")
print(f"[OK] VCF: test_data/wgs_wes/toy_chr22.vcf")
print(f"     {len(SNPS)} SNPs (Ti={n_ti}, Tv={n_tv}, Ti/Tv={n_ti/n_tv:.1f})"
      f"  +  {len(INDELS)} indels  =  {len(SNPS)+len(INDELS)} variants")
print(f"     {len(SAMPLES_VCF)} samples  |  2 FAIL site filters  |  2 low-DP/GQ variants")


# ══════════════════════════════════════════════════════════════════════════════
#  SNP Array — 15 samples, 235 variants
#  Written directly as PLINK binary (BED/BIM/FAM) — no plink required
# ══════════════════════════════════════════════════════════════════════════════
#
# Sample design
# ─────────────
# (fid, iid, sex, pheno, role)
#  sex: 1=male, 2=female  |  pheno: 1=control, 2=case
SAMPLES_SNP = [
    ("FAM1", "S01", 1, 2, "smiss"),    # male case   — sample missingness outlier
    ("FAM1", "S02", 1, 2, "related"),  # male case   — related pair A
    ("FAM1", "S03", 1, 2, "related"),  # male case   — related pair B (copy of S02)
    ("FAM1", "S04", 1, 2, "normal"),
    ("FAM1", "S05", 1, 2, "normal"),
    ("FAM1", "S06", 2, 2, "normal"),
    ("FAM1", "S07", 2, 2, "het_out"),  # female case — heterozygosity outlier
    ("FAM1", "S08", 2, 1, "normal"),
    ("FAM1", "S09", 2, 1, "sex_disc"), # female ctrl — sex discordant (X looks male)
    ("FAM1", "S10", 2, 1, "normal"),
    ("FAM1", "S11", 1, 1, "normal"),
    ("FAM1", "S12", 1, 1, "normal"),
    ("FAM1", "S13", 2, 2, "normal"),
    ("FAM1", "S14", 2, 1, "normal"),
    ("FAM1", "S15", 2, 1, "normal"),
]
N_SAMPLES_SNP = len(SAMPLES_SNP)

# Variant counts by block
N_AUTO_NORMAL = 200  # chr22, HWE genotypes, MAF 0.10–0.40
N_AUTO_HMISS  = 10   # chr22, ~35 % missing  → fail variant callrate
N_AUTO_MONO   = 3    # chr22, monomorphic     → fail MAF filter
N_AUTO_HET    = 2    # chr22, all-het         → fail HWE test
N_CHRX        = 20   # chr23 (X)              → enable sex check

N_VARIANTS_SNP = N_AUTO_NORMAL + N_AUTO_HMISS + N_AUTO_MONO + N_AUTO_HET + N_CHRX

IDX_HMISS_START = N_AUTO_NORMAL
IDX_MONO_START  = N_AUTO_NORMAL + N_AUTO_HMISS
IDX_HET_START   = N_AUTO_NORMAL + N_AUTO_HMISS + N_AUTO_MONO
IDX_CHRX_START  = N_AUTO_NORMAL + N_AUTO_HMISS + N_AUTO_MONO + N_AUTO_HET

ALLELE_PAIRS = [("A","G"), ("C","T"), ("A","T"), ("G","C"), ("A","C"), ("G","T")]

def ap(v):
    return ALLELE_PAIRS[v % len(ALLELE_PAIRS)]

# Index helpers
s_idx  = {s[1]: i   for i, s in enumerate(SAMPLES_SNP)}
s_role = {s[1]: s[4] for s in SAMPLES_SNP}
s_sex  = {s[1]: s[2] for s in SAMPLES_SNP}

# ── Build genotype matrix  [sample][variant] = (a1_code, a2_code) ─────────────
# Internal codes per variant: 0=missing, 1=hom-major(A2), 2=het, 3=hom-minor(A1)
# A1 = minor allele = ap(v)[1], A2 = major allele = ap(v)[0]
# BED 2-bit encoding: 00=hom-A1, 01=missing, 10=het, 11=hom-A2
CODE_MISSING  = 1   # 01
CODE_HOM_A2   = 3   # 11  hom major
CODE_HET      = 2   # 10
CODE_HOM_A1   = 0   # 00  hom minor

geno_matrix = [[CODE_MISSING] * N_VARIANTS_SNP for _ in range(N_SAMPLES_SNP)]

# ── Step 1: Normal autosomal variants (v0–199) for all samples ────────────────
for s in range(N_SAMPLES_SNP):
    for v in range(N_AUTO_NORMAL):
        maf = 0.10 + (v % 7) * 0.05   # cycles: 0.10 0.15 0.20 0.25 0.30 0.35 0.40
        r = random.random()
        if r < (1 - maf) ** 2:
            geno_matrix[s][v] = CODE_HOM_A2
        elif r < (1 - maf) ** 2 + 2 * maf * (1 - maf):
            geno_matrix[s][v] = CODE_HET
        else:
            geno_matrix[s][v] = CODE_HOM_A1

# ── Step 2: S02/S03 related pair — copy S02 autosomal genotypes to S03 ────────
for v in range(N_AUTO_NORMAL):
    geno_matrix[s_idx["S03"]][v] = geno_matrix[s_idx["S02"]][v]

# ── Step 3: S01 sample missingness — 25 % of autosomal calls set to missing ───
miss_v = random.sample(range(N_AUTO_NORMAL), k=int(N_AUTO_NORMAL * 0.25))
for v in miss_v:
    geno_matrix[s_idx["S01"]][v] = CODE_MISSING

# ── Step 4: S07 heterozygosity outlier — 70 % of calls forced het ─────────────
het_v = random.sample(range(N_AUTO_NORMAL), k=int(N_AUTO_NORMAL * 0.70))
for v in het_v:
    geno_matrix[s_idx["S07"]][v] = CODE_HET

# ── Step 5: High-missingness variant block (v200–209) ─────────────────────────
for s in range(N_SAMPLES_SNP):
    for v in range(IDX_HMISS_START, IDX_HMISS_START + N_AUTO_HMISS):
        geno_matrix[s][v] = CODE_MISSING if random.random() < 0.35 else CODE_HOM_A2

# ── Step 6: Monomorphic variants (v210–212) — all hom-major ──────────────────
for s in range(N_SAMPLES_SNP):
    for v in range(IDX_MONO_START, IDX_MONO_START + N_AUTO_MONO):
        geno_matrix[s][v] = CODE_HOM_A2

# ── Step 7: All-het variants (v213–214) — extreme HWE departure ───────────────
for s in range(N_SAMPLES_SNP):
    for v in range(IDX_HET_START, IDX_HET_START + N_AUTO_HET):
        geno_matrix[s][v] = CODE_HET

# ── Step 8: chrX variants (v215–234) — sex-specific + S09 discordance ─────────
# Males:    hemizygous → hom only (no het)
# Females:  HWE-like calls (het allowed)
# S09:      declared female but all hom on X → sex check flags as discordant
for s in range(N_SAMPLES_SNP):
    iid  = SAMPLES_SNP[s][1]
    sex  = s_sex[iid]
    role = s_role[iid]
    for vx in range(N_CHRX):
        v = IDX_CHRX_START + vx
        if role == "sex_disc":
            geno_matrix[s][v] = CODE_HOM_A2
        elif sex == 1:  # males: hemizygous, no het
            geno_matrix[s][v] = CODE_HOM_A1 if random.random() < 0.30 else CODE_HOM_A2
        else:           # females: HWE-like, MAF 0.30
            maf_x = 0.30
            r = random.random()
            if r < (1 - maf_x) ** 2:
                geno_matrix[s][v] = CODE_HOM_A2
            elif r < (1 - maf_x) ** 2 + 2 * maf_x * (1 - maf_x):
                geno_matrix[s][v] = CODE_HET
            else:
                geno_matrix[s][v] = CODE_HOM_A1

# S01 also has missing calls on chrX (consistent 25 % missingness)
for vx in range(N_CHRX):
    if random.random() < 0.25:
        geno_matrix[s_idx["S01"]][IDX_CHRX_START + vx] = CODE_MISSING

# ── Write FAM ─────────────────────────────────────────────────────────────────
os.makedirs("test_data/snp_array", exist_ok=True)

with open("test_data/snp_array/toy.fam", "w") as fh:
    for fid, iid, sex, pheno, _ in SAMPLES_SNP:
        fh.write(f"{fid}\t{iid}\t0\t0\t{sex}\t{pheno}\n")

# ── Write BIM ─────────────────────────────────────────────────────────────────
# Columns: CHR, SNP_ID, CM, BP, A1 (minor), A2 (major)
with open("test_data/snp_array/toy.bim", "w") as fh:
    for v in range(N_AUTO_NORMAL + N_AUTO_HMISS + N_AUTO_MONO + N_AUTO_HET):
        major, minor = ap(v)
        fh.write(f"22\trs_snp{v+1:03d}\t0\t{(v+1)*10000}\t{minor}\t{major}\n")
    for vx in range(N_CHRX):
        v = IDX_CHRX_START + vx
        major, minor = ap(v)
        fh.write(f"23\trs_chrx{vx+1:03d}\t0\t{60000000+(vx+1)*10000}\t{minor}\t{major}\n")

# ── Write BED (SNP-major PLINK binary format) ─────────────────────────────────
# Magic: 0x6c 0x1b 0x01  (SNP-major mode)
# For each SNP: N_SAMPLES genotype codes packed 4-per-byte, LSB first
# 2-bit code: 00=hom-A1, 01=missing, 10=het, 11=hom-A2
bytes_per_snp = (N_SAMPLES_SNP + 3) // 4

with open("test_data/snp_array/toy.bed", "wb") as bed:
    bed.write(bytes([0x6c, 0x1b, 0x01]))
    for v in range(N_VARIANTS_SNP):
        for byte_start in range(0, N_SAMPLES_SNP, 4):
            byte_val = 0
            for bit_pos in range(4):
                s = byte_start + bit_pos
                code = geno_matrix[s][v] if s < N_SAMPLES_SNP else 0
                byte_val |= (code << (bit_pos * 2))
            bed.write(bytes([byte_val]))

# ── Summary ───────────────────────────────────────────────────────────────────
n_male   = sum(1 for _, _, sex, _, _   in SAMPLES_SNP if sex   == 1)
n_female = sum(1 for _, _, sex, _, _   in SAMPLES_SNP if sex   == 2)
n_case   = sum(1 for _, _, _, pheno, _ in SAMPLES_SNP if pheno == 2)
n_ctrl   = sum(1 for _, _, _, pheno, _ in SAMPLES_SNP if pheno == 1)

print(f"\n[OK] test_data/snp_array/toy.fam  ({N_SAMPLES_SNP} samples, "
      f"{n_male}M/{n_female}F, {n_case} cases/{n_ctrl} controls)")
print(f"[OK] test_data/snp_array/toy.bim  ({N_VARIANTS_SNP} variants)")
print(f"[OK] test_data/snp_array/toy.bed  "
      f"({3 + N_VARIANTS_SNP * bytes_per_snp} bytes, SNP-major)")
print(f"     Sample QC triggers:")
print(f"       S01: ~{int(N_AUTO_NORMAL*0.25)}/{N_AUTO_NORMAL} autosomal calls missing"
      f" → sample callrate failure (>2 %)")
print(f"       S02+S03: identical autosomal genotypes → relatedness (PI_HAT ≈ 1.0)")
print(f"       S07: {int(N_AUTO_NORMAL*0.70)}/{N_AUTO_NORMAL} calls forced het"
      f" → het rate outlier (>>3 SD)")
print(f"       S09: PEDSEX=female, all chrX calls hom → sex check failure")
print(f"     Variant QC triggers:")
print(f"       rs_snp{IDX_HMISS_START+1:03d}–rs_snp{IDX_HMISS_START+N_AUTO_HMISS:03d}: "
      f"~35 % missing → fail variant callrate (>2 %)")
print(f"       rs_snp{IDX_MONO_START+1:03d}–rs_snp{IDX_MONO_START+N_AUTO_MONO:03d}: "
      f"monomorphic → fail MAF filter")
print(f"       rs_snp{IDX_HET_START+1:03d}–rs_snp{IDX_HET_START+N_AUTO_HET:03d}: "
      f"all-het → fail HWE test")
print(f"       rs_chrx001–rs_chrx{N_CHRX:03d}: "
      f"chrX (chr23) — sex check input")
