CBOP
C     !ROUTINE: SIZE.h
C     !INTERFACE:
C     include SIZE.h
C     !DESCRIPTION:
C     Cycle 0: Small domain for 4-processor MPI test
C     Global domain: 40x40 cells, 10 vertical levels
C     Decomposition: 2x2 MPI grid (4 processors)
C     Cell size: 100m horizontal, 10m vertical
C
C     sNx  :: Number of points in X for each local tile
C     sNy  :: Number of points in Y for each local tile
C     OLx  :: Overlap extent in X for halo exchanges
C     OLy  :: Overlap extent in Y for halo exchanges
C     nSx  :: Number of tiles in X per processor
C     nSy  :: Number of tiles in Y per processor
C     nPx  :: Number of processors in X
C     nPy  :: Number of processors in Y
C     Nx   :: Number of points in X for the full domain
C     Ny   :: Number of points in Y for the full domain
C     Nr   :: Number of points in vertical direction
C
CEOP

      INTEGER sNx
      INTEGER sNy
      INTEGER OLx
      INTEGER OLy
      INTEGER nSx
      INTEGER nSy
      INTEGER nPx
      INTEGER nPy
      INTEGER Nx
      INTEGER Ny
      INTEGER Nr

      PARAMETER (
     &           sNx =  20,
     &           sNy =  20,
     &           OLx =   4,
     &           OLy =   4,
     &           nSx =   1,
     &           nSy =   1,
     &           nPx =   2,
     &           nPy =   2,
     &           Nx  = sNx*nSx*nPx,
     &           Ny  = sNy*nSy*nPy,
     &           Nr  =  10)

C     MAX_OLX :: Set to the maximum overlap region size of any array
C     MAX_OLY    that will be exchanged. Controls the sizing of exch
C                routine buffers.

      INTEGER MAX_OLX
      INTEGER MAX_OLY

      PARAMETER ( MAX_OLX = OLx,
     &            MAX_OLY = OLy )

