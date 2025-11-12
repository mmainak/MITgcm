# Cycle 1: Deployment & Validation Checklist

**Date**: November 6, 2025  
**Cycle**: 1 - Minimal Settling Tracer  
**Status**: Ready for HPC deployment

---

## ✅ Pre-Deployment Checklist (Local)

- [x] sediment.h written and commented (57 lines)
- [x] sediment_init.F written and commented (134 lines)
- [x] sediment_settling.F written and commented (186 lines)
- [x] SEDIMENT_OPTIONS.h written and commented (124 lines)
- [x] data.sediment.cycle1 template created (60 lines)
- [x] README_CYCLE1.md documentation (150+ lines)
- [x] CYCLE_1_COMPLETE.md full summary (310+ lines)
- [x] CYCLE_1_DEPLOYMENT.md integration guide (170+ lines)
- [x] DEPLOYMENT_INDEX.md project index (250+ lines)
- [x] FILES_READY.txt manifest (this structure)
- [x] All files located in: `/Users/pinta/Documents/Work/Code_bases/MITgcm/verification/sediment/codepatch_cycle1/`

**Status**: ✅ All local files ready

---

## 📋 HPC Deployment Steps

### Step 1: Copy Source Files

**Command**:
```bash
cp /Users/pinta/Documents/Work/Code_bases/MITgcm/verification/sediment/codepatch_cycle1/{sediment.h,sediment_init.F,sediment_settling.F,SEDIMENT_OPTIONS.h} \
   $MITGCM_ROOT/verification/sediment/code/
```

**Verification**:
```bash
ls -la $MITGCM_ROOT/verification/sediment/code/sediment*
```

**Expected Output**:
```
-rw-r--r--  sediment.h                    (57 lines)
-rw-r--r--  sediment_init.F              (134 lines)
-rw-r--r--  sediment_settling.F          (186 lines)
-rw-r--r--  SEDIMENT_OPTIONS.h           (124 lines)
```

**Status After Step 1**: [ ] Complete

---

### Step 2: Update Input Namelist

**File**: `$MITGCM_ROOT/verification/sediment/input/data.sediment`

**Add** (or verify existing):
```fortran
&SEDIMENT_PARM01
  SEDIMENT_ws0 = 0.01,
&END
```

**Verification**:
```bash
grep SEDIMENT_ws0 $MITGCM_ROOT/verification/sediment/input/data.sediment
```

**Expected Output**:
```
SEDIMENT_ws0 = 0.01,
```

**Status After Step 2**: [ ] Complete

---

### Step 3: Check Build Configuration

**File**: `$MITGCM_ROOT/verification/sediment/code/packages.conf`

**Should contain**:
```
gfd
diagnostics
mdsio
mnc
sediment          ← CRITICAL
ptracers          ← CRITICAL
```

**Verification**:
```bash
grep -E "sediment|ptracers" $MITGCM_ROOT/verification/sediment/code/packages.conf
```

**Status After Step 3**: [ ] Complete

---

### Step 4: Compile

**Commands**:
```bash
cd $MITGCM_ROOT/verification/sediment
rm -rf build run
mkdir build run

cd build
../code_dir/genmake2 -mods ../code -of /path/to/optfile
make depend
make -j 8
```

**Watch For**:
- genmake2 should complete with "Done"
- make depend should show no errors
- make should show compilation progress, ending with link step

**Verification**:
```bash
ls -lh mitgcmuv
# Should show: -rwxr-xr-x  mitgcmuv  (5-20 MB, depending on options)
```

**Expected Size**: 5–20 MB (varies by compiler options)

**Status After Step 4**: [ ] Complete

---

### Step 5: Prepare Run Directory

**Commands**:
```bash
cd $MITGCM_ROOT/verification/sediment/run
ln -s ../input/* .
```

**Verification**:
```bash
ls -la | grep data
# Should show: data, data.diagnostics, data.sediment, etc.
```

**Status After Step 5**: [ ] Complete

---

### Step 6: Run Short Test

**Command**:
```bash
cd $MITGCM_ROOT/verification/sediment/run
../build/mitgcmuv
```

(Or with MPI):
```bash
mpirun -np 4 ../build/mitgcmuv
```

**Expected Duration**: 
- Single-process: 10–30 seconds (1 hour simulation, 36 timesteps)
- Multi-process: May vary with MPI overhead

**Status After Step 6**: [ ] Complete

---

## ✅ Runtime Validation Checklist

### Immediate Checks (While Run Completes)

- [ ] No error messages in initial output
- [ ] No "Segmentation fault" or "Aborted"
- [ ] See SEDIMENT_INIT diagnostic block printed

### After Run Completes

**Command**:
```bash
echo "=== Check 1: SEDIMENT_INIT Output ===" 
grep -A 10 "SEDIMENT_INIT: Initializing" STDOUT.0000

echo ""
echo "=== Check 2: CFL Diagnostics ===" 
grep CFLset STDOUT.0000

echo ""
echo "=== Check 3: NaN Check ===" 
grep -i NaN STDOUT.0000 || echo "✓ No NaNs found"

echo ""
echo "=== Check 4: Output Files ===" 
ls -lh *.data *.meta | head -20
```

---

### Check 1: SEDIMENT_INIT Output

**Expected**:
```
SEDIMENT_INIT: Initializing sediment module
---SEDIMENT_INIT: Parameters---
  Settling velocity ws0 =  1.0000E-02 m/s
  Time step deltaT =  1.0000E+02
  Min grid spacing =  1.0000E+01 m (at k=XX)
  CFL number CFLset =  1.0000E-01
---SEDIMENT_INIT: End---
```

**Pass Criteria**: Message appears without errors

**Status**: [ ] Pass / [ ] Fail

---

### Check 2: CFL Verification

**Command**:
```bash
grep CFLset STDOUT.0000
```

**Expected Output**:
```
CFL number CFLset =  1.0000E-01
```

**Pass Criteria**: 
- ✅ CFLset < 0.5 (optimal: < 0.3)
- ⚠️ 0.5 ≤ CFLset < 1.0 (warning appears; continue if no NaNs)
- ❌ CFLset ≥ 1.0 (critical; may produce NaNs)

**Actual CFLset Value**: `___________`

**Status**: [ ] Pass (< 0.5) / [ ] Warn (0.5-1.0) / [ ] Fail (> 1.0)

---

### Check 3: NaN Detection

**Command**:
```bash
grep -i NaN STDOUT.0000 | wc -l
```

**Pass Criteria**: 
- ✅ 0 lines (no NaNs)
- ❌ > 0 lines (NaNs present → FAIL)

**Number of NaN Lines**: `___________`

**Status**: [ ] Pass (0 NaNs) / [ ] Fail (NaNs present)

---

### Check 4: Output Files

**Command**:
```bash
ls -lh *.data *.meta | wc -l
```

**Expected**: Multiple files (varies with diagnostic settings)

**Sample Output**:
```
-rw-r--r--  dynDiag.0000.0000.data      (1.2 MB)
-rw-r--r--  dynDiag.0000.0000.meta      (5.3 KB)
-rw-r--r--  sedDiag.0000.0000.data      (0.8 MB)
-rw-r--r--  sedDiag.0000.0000.meta      (4.2 KB)
... (more)
```

**Pass Criteria**: 
- ✅ At least 4 files present (.data and .meta pairs)
- ❌ 0 files (I/O failed)

**Number of Output Files**: `___________`

**Status**: [ ] Pass (files present) / [ ] Fail (no files)

---

### Check 5: Solver Convergence

**Command**:
```bash
grep "cg2dIters" STDOUT.0000 | head -5
```

**Expected Output**:
```
cg2dIters[1] = XXX (iterations to converge)
cg2dIters[2] = XXX
... (continues for each timestep)
```

**Pass Criteria**: 
- ✅ All convergences complete (no "FAIL" or "NOT CONVERGED")
- ❌ Any "NOT CONVERGED" messages (solver failed)

**Sample Iteration Counts**: `___________`

**Status**: [ ] Pass / [ ] Fail

---

### Check 6: Physics Validation (Optional)

If you want to visualize settling:

**Command**:
```bash
# Extract tracer concentrations (if binary diagnostics enabled)
# Check with python/matlab: plot vertical profile at different times
# Should show: concentration decreases at top, increases at bottom
```

**Status**: [ ] Visual check attempted / [ ] Skipped (for now)

---

## 📊 Results Summary

**Complete this section after all checks**:

| Check | Status | Value | Notes |
|-------|--------|-------|-------|
| Build | [ ] Pass | executable size: ___ MB | Compilation successful? |
| CFL | [ ] Pass | CFLset = ___ | < 0.5? |
| NaNs | [ ] Pass | 0 NaNs | No floating-point errors? |
| Files | [ ] Pass | ___ files | Output generated? |
| Solver | [ ] Pass | convergence OK | No failed iterations? |
| Physics | [ ] Pass | settling observed | Tracer moves down? |

---

## ✅ Overall Status

**Cycle 1 Validation Result**:

```
BUILD:                     [ ] PASS  [ ] FAIL
RUNTIME (No crash):        [ ] PASS  [ ] FAIL
CFL CHECK (< 0.5):         [ ] PASS  [ ] WARN  [ ] FAIL
NO NaNs:                   [ ] PASS  [ ] FAIL
OUTPUT FILES:              [ ] PASS  [ ] FAIL
SOLVER CONVERGENCE:        [ ] PASS  [ ] FAIL
PHYSICS (optional):        [ ] PASS  [ ] SKIP  [ ] FAIL

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OVERALL: [ ] ✅ CYCLE 1 PASSES  [ ] ❌ CYCLE 1 FAILS
```

---

## 🔧 Troubleshooting (If Failures Occur)

### If Build Fails

**Error**: "sediment.h: No such file or directory"
- [ ] Verify sediment.h copied to $MITGCM_ROOT/verification/sediment/code/
- [ ] Run: `ls -la $MITGCM_ROOT/verification/sediment/code/sediment*`
- [ ] Rerun: `../code_dir/genmake2 -mods ../code`

**Error**: "Undefined reference to `sediment_init_'"
- [ ] Verify sediment_init.F copied
- [ ] Verify packages.conf includes "sediment"
- [ ] Check for syntax errors in .F files

**Action Taken**: ______________________________

**Status**: [ ] Resolved / [ ] Escalate

---

### If Runtime Crashes

**Error**: "Segmentation fault"
- [ ] Check available memory: `free -h`
- [ ] Try single-process: `../build/mitgcmuv` (not mpirun)
- [ ] Reduce nTimeSteps in input/data

**Action Taken**: ______________________________

**Status**: [ ] Resolved / [ ] Escalate

---

### If CFL Warning Appears

**Warning**: "CFLset > 0.5"
- [ ] This is expected behavior (not an error)
- [ ] Continue if no NaNs
- [ ] If NaNs appear: reduce SEDIMENT_ws0 to 0.005

**Action Taken**: ______________________________

**Status**: [ ] Continue with warning / [ ] Fix CFL

---

### If NaNs Appear

**NaNs Detected**: grep shows NaN lines
- [ ] Check CFL (may be > 1.0)
- [ ] Check initial condition files (should be non-negative)
- [ ] Reduce SEDIMENT_ws0 by half, rerun

**Action Taken**: ______________________________

**Status**: [ ] Resolved / [ ] Escalate

---

### If Output Files Missing

**No Files**: `*.data` files not generated
- [ ] Check I/O settings in input/data
- [ ] Verify dumpFreq is set (e.g., dumpFreq = 3600.)
- [ ] Check disk space: `df -h`

**Action Taken**: ______________________________

**Status**: [ ] Resolved / [ ] Escalate

---

## 📝 Notes & Observations

**Performance**:
- Run took approximately _________ seconds
- Compiler used: __________________ (gfortran/ifort/pgf90)
- System cores/threads: ___________

**Anything Unusual?**:
```


```

**Any Physics Observations?**:
```


```

---

## 🎯 Next Steps

### If Cycle 1 PASSES ✅

- [ ] Commit to version control: `git add codepatch_cycle1/; git commit -m "Cycle 1: Settling tracer complete"`
- [ ] Note passing build config (compiler, flags)
- [ ] Save STDOUT.0000 for reference
- [ ] **PROCEED TO CYCLE 2** — EOS buoyancy coupling (code will be generated)

### If Cycle 1 FAILS ❌

- [ ] Debug using troubleshooting section above
- [ ] Consult CYCLE_1_DEPLOYMENT.md § "Troubleshooting"
- [ ] Review code comments in sediment_init.F and sediment_settling.F
- [ ] **REPORT ISSUE** with:
  - [ ] Error message (full)
  - [ ] STDOUT.0000 output
  - [ ] System info (compiler, MPI, HPC environment)

---

## 📞 Support Documents

**For Help With**:
- **Code Overview**: CYCLE_1_COMPLETE.md
- **Step-by-Step Guide**: CYCLE_1_DEPLOYMENT.md
- **Quick Reference**: README_CYCLE1.md
- **Project Structure**: DEPLOYMENT_INDEX.md
- **File Inventory**: FILES_READY.txt

---

## 📋 Checklist Complete

**Date Completed**: _______________  
**By**: _______________  
**Overall Result**: [ ] PASS ✅ / [ ] FAIL ❌  
**Notes**: ________________________________________________

---

**Ready for Cycle 2?** [ ] YES (after validation passes) / [ ] NO (fix issues first)

**Cycle 1 Checklist Complete** ✅



