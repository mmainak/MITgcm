# Reference: tutorial_cfc_offline Structure

**Location**: `/Users/pinta/Documents/Work/Code_bases/MITgcm/verification/tutorial_cfc_offline/`

This is the **perfect reference** for PTRACERS-based passive tracer configuration.

## Key Findings

### 1. PTRACERS_SIZE.h (New File Required!)

```fortran
#ifdef ALLOW_PTRACERS
      INTEGER PTRACERS_num
      PARAMETER(PTRACERS_num = 2)
#endif
```

**Purpose**: Specifies number of passive tracers.  
**For Cycle 0 (sediment)**: Set to 1 (one sediment tracer)

### 2. Domain & MPI Setup (from SIZE.h)

```
sNx = 64,  sNy = 32,   (tile size)
nSx = 1,   nSy = 2,    (tiles per processor)
nPx = 2,   nPy = 1,    (processors: 2x1 = 2 CPUs, but can extend)
Nr = 15    (vertical levels)
```

**For Cycle 0 (sediment, 4 CPU)**: Can adapt this to 2×2 MPI

### 3. packages.conf

```
gfd
-mom_common
-mom_fluxform
gmredi
offline
ptracers         ← KEY
gchem
cfc
timeave
```

**For Cycle 0 (sediment)**: Should include `ptracers` (enabled)

### 4. data.ptracers (Runtime Input)

```fortran
&PTRACERS_PARM01
  PTRACERS_numInUse = 2,        ! Number of active tracers
  PTRACERS_Iter0 = 4248000,      ! Starting iteration
  PTRACERS_monitorFreq = 43200., ! Monitor every 12 hours
  
  ! Tracer 1 config
  PTRACERS_names(1) = 'cfc11',
  PTRACERS_advScheme(1) = 77,
  PTRACERS_diffKh(1) = 0.E3,
  PTRACERS_diffKr(1) = 5.E-5,
  PTRACERS_useGMRedi(1) = .TRUE.,
  PTRACERS_initialFile(1) = ' ',
  
  ! Tracer 2 config (similar)
  ...
&
```

**For Cycle 0 (sediment)**: 
- `PTRACERS_numInUse = 1` (one sediment tracer)
- No special advection scheme needed
- Diffusivities set to zero or small value
- No GMREDI needed

## What Cycle 0 Should Include

```
code/
├── SIZE.h                      (existing, modify for 4 CPU)
├── PTRACERS_SIZE.h             ← NEW! (set PTRACERS_num = 1)
├── CPP_OPTIONS.h               (existing)
├── OBCS_OPTIONS.h              (existing)
├── PTRACERS_OPTIONS.h          (blank, already created)
├── packages.conf               (update to include ptracers)
└── README_CYCLE0.md
```

## Key Lesson

**PTRACERS_SIZE.h must be defined separately** to allocate the passive tracer array. This is the critical missing piece!

## Next Steps

1. Add `PTRACERS_SIZE.h` to `cycle0_complete/` with `PTRACERS_num = 1`
2. Create sample `data.ptracers` in a reference input directory
3. Verify build recognizes PTRACERS package
4. Then proceed to Cycle 1 settling physics

