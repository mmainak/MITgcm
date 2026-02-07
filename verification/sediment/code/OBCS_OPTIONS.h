C     *==========================================================*
C     | OBCS_OPTIONS.h
C     | Compile-time options for Open Boundary Conditions
C     *==========================================================*

#ifndef OBCS_OPTIONS_H
#define OBCS_OPTIONS_H
#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"

#ifdef ALLOW_OBCS

C     Enable individual boundary options
#define ALLOW_OBCS_NORTH
#define ALLOW_OBCS_SOUTH
#define ALLOW_OBCS_EAST
#define ALLOW_OBCS_WEST

C     Enable prescribed boundary conditions
#define ALLOW_OBCS_PRESCRIBE

C     Enable sponge layer
#define ALLOW_OBCS_SPONGE

C     Enable balance (volume conservation)
#define ALLOW_OBCS_BALANCE

C     Enable Orlanski radiation (needed for PARM02 namelist)
#define ALLOW_ORLANSKI

#endif /* ALLOW_OBCS */
#endif /* OBCS_OPTIONS_H */
