#ifdef ALLOW_PTRACERS
C
C     *==========================================================*
C     | PTRACERS_SIZE.h
C     | o Basic parameter header for passive tracer package.
C     *==========================================================*

C     PTRACERS_num :: number of passive tracers
      INTEGER PTRACERS_num
      PARAMETER(PTRACERS_num = 1 )

#ifdef ALLOW_AUTODIFF_TAMC
      INTEGER    maxpass
      PARAMETER( maxpass     = PTRACERS_num + 2 )
#endif

#endif /* ALLOW_PTRACERS */

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
