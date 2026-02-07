CBOP
C    !ROUTINE: SIZE.h
C    !INTERFACE:
C    include SIZE.h
C    !DESCRIPTION: \bv
C     *==========================================================*
C     | SIZE.h - Subglacial Plume (4-Processor Parallel Domain)
C     | Domain: Nx=40 x Ny=8 x Nr=40
C     | Conduit: 20m wide x 10m high at west boundary (seafloor)
C     | dx: 5m (west) -> 20m (east), telescoping
C     | dy: 5m uniform
C     | dz: 5m uniform
C     | Processors: 4 (nPx=2, nPy=2)
C     *==========================================================*
C     \ev
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
     &           sNy =   4,
     &           OLx =   4,
     &           OLy =   4,
     &           nSx =   1,
     &           nSy =   1,
     &           nPx =   2,
     &           nPy =   2,
     &           Nx  = sNx*nSx*nPx,
     &           Ny  = sNy*nSy*nPy,
     &           Nr  =  40)

C     MAX_OLX :: Set to the maximum overlap region size
C     MAX_OLY    
      INTEGER MAX_OLX
      INTEGER MAX_OLY
      PARAMETER ( MAX_OLX = OLx,
     &            MAX_OLY = OLy )
