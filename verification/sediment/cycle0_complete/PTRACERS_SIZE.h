#ifdef ALLOW_PTRACERS

CBOP
C    !ROUTINE: PTRACERS_SIZE.h
C    !INTERFACE:
C    #include PTRACERS_SIZE.h
C
C    !DESCRIPTION:
C    Contains passive tracer array size (number of tracers).
C
C    Cycle 0: One passive tracer for sediment transport verification
C    (Physics inert - no settling yet, just tracer framework)

C     Number of tracers
      INTEGER PTRACERS_num
      PARAMETER(PTRACERS_num = 1)

CEOP
#endif

