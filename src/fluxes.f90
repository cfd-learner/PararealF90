!>
!! This module computes the advective manages the buffers that store the advective fluxes in x, z and z direction. It is used by the modules for upwind and weno5 discretization of the advective part \\( F_{\\text{adv}} \\) to avoid double allocation.
!!
MODULE fluxes

USE omp_lib, only : omp_get_num_threads

IMPLICIT NONE

!> A collection of parameters needed by the advection modules
TYPE advection_parameter
    INTEGER :: Nthreads, i_start, i_end, j_start, j_end, k_start, k_end
    INTEGER :: i_min, i_max, j_min, j_max, k_min, k_max
    LOGICAL :: echo_on
END TYPE

TYPE(advection_parameter) :: param

!> Buffer for interface fluxes in x direction
DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:,:,:,:) :: FluxI

!> Buffer for interface fluxes in y direction
DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:,:,:,:) :: FluxJ

!> Buffer for interface fluxes in z direction
DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:,:,:,:) :: FluxK

!> Buffer for cell values in x direction
DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:,:,:,:) :: FluxI_Cell

!> Buffer for cell values in y direction
DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:,:,:,:) :: FluxJ_Cell

!> Buffer for cell values in z direction
DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:,:,:,:) :: FluxK_Cell

CONTAINS

    !> Initializes the module and allocates the needed buffers.
    SUBROUTINE InitializeFluxes(i_min, i_max, j_min, j_max, k_min, k_max, Nthreads, echo_on)
    
        INTEGER, INTENT(IN) :: Nthreads, i_min, i_max, j_min, j_max, k_min, k_max
        LOGICAL, INTENT(IN) :: echo_on
        
        INTEGER :: i, thread_nr
        
        param%echo_on   = echo_on
        param%nthreads  = Nthreads

        param%i_min = i_min
        param%i_max = i_max
        param%j_min = j_min
        param%j_max = j_max
        param%k_min = k_min
        param%k_max = k_max

        ! The index in the "thread-dimension" starts with zero, so that
        ! it directly coincides with thread numbers

        ! If there are Nx horizontal cells, there are Nx+1 horizontal interfaces,
        ! plus 2x1 interfaces for ghost cells
        ALLOCATE(FluxI( i_min:i_max+1,   j_min:j_max,   k_min:k_max,   0:Nthreads-1))
        ALLOCATE(FluxJ( i_min:i_max,     j_min:j_max+1, k_min:k_max,   0:Nthreads-1))
        ALLOCATE(FluxK( i_min:i_max,     j_min:j_max,   k_min:k_max+1, 0:Nthreads-1))
        
        ALLOCATE(FluxI_Cell( i_min:i_max, j_min:j_max, k_min:k_max, 0:Nthreads-1))
        ALLOCATE(FluxJ_Cell( i_min:i_max, j_min:j_max, k_min:k_max, 0:Nthreads-1))
        ALLOCATE(FluxK_Cell( i_min:i_max, j_min:j_max, k_min:k_max, 0:Nthreads-1))
        
        ! Now perform first-touch initialization, i.e. every thread initializes its
        ! part of the buffers
        
        !$OMP PARALLEL private(thread_nr)
        !$OMP DO schedule(static)
        DO i=0,Nthreads-1
            FluxI(:,:,:,i)      = 0.0
            FluxJ(:,:,:,i)      = 0.0
            FluxK(:,:,:,i)      = 0.0
            FluxI_Cell(:,:,:,i) = 0.0
            FluxJ_Cell(:,:,:,i) = 0.0
            FluxK_Cell(:,:,:,i) = 0.0            
        END DO
        !$OMP END DO
        !$OMP END PARALLEL
        
    END SUBROUTINE InitializeFluxes

    !> Deallocates buffers and finalizes module.
    SUBROUTINE FinalizeFluxes()

        ! Deallocate all buffers in this module
        DEALLOCATE(FluxI)
        DEALLOCATE(FluxJ)
        DEALLOCATE(FluxK)
        DEALLOCATE(FluxI_Cell)
        DEALLOCATE(FluxJ_Cell)
        DEALLOCATE(FluxK_Cell)
                
    END SUBROUTINE FinalizeFluxes

END MODULE fluxes