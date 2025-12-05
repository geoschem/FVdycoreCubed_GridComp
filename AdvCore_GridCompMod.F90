#include "MAPL_Generic.h"
#include "MAPL.h"

module AdvCore_GridCompMod

  use ESMF
  use mapl3
  use fv_arrays_mod, only: REAL4, REAL8
  use pflogger, only: logger_t => logger

!  ! Copied from DynCore_GridCompMod.F90 - don't need all. Cull later.
!  use mapl_ErrorHandlingMod, only: MAPL_Verify, MAPL_Assert, MAPL_Return
!  use MAPL_Constants, only: MAPL_RADIUS, MAPL_CP, MAPL_PI, MAPL_PI_R8, MAPL_OMEGA, MAPL_KAPPA
!  use MAPL_Constants, only: MAPL_P00, MAPL_GRAV, MAPL_RGAS, MAPL_RVAP, MAPL_CPVAP, MAPL_O3MW, MAPL_AIRMW
!  use MAPL_Constants, only: MAPL_VectorField ! pchakrab: TODO - need MAPL3 equivalent
!  use MAPL_Constants, only: MAPL_UNDEFINED_REAL
!  use ESMFL_Mod, only: ESMFL_BundleGetPointerToData, MAPL_AreaMean
!  use MAPL_AbstractRegridderMod, only: AbstractRegridder
!  use MAPL_GridManagerMod, only: grid_manager
!  use MAPL_RegridderManagerMod, only: regridder_manager
!  use MAPL_RegridMethods, only: REGRID_METHOD_BILINEAR
!  use MAPL_CFIOMod, only: MAPL_CFIORead
!  use MAPL_FieldPointerUtilities, only: MAPL_FieldDestroy
!  use MAPL_MaxMinMod, only: MAPL_MaxMin
!  use MAPL_CommsMod, only: MAPL_AM_I_ROOT, MAPL_ArrayGather => ArrayGather
!  use FileIOSharedMod, only: WRITE_PARALLEL
!  use mapl3g_generic, only: MAPL_GridCompSetGeometry
!  use mapl3g_generic, only: MAPL_GridCompGet, MAPL_GridCompGetResource
!  use mapl3g_generic, only: MAPL_GridCompSetEntryPoint, MAPL_GridCompGetInternalState
!  use mapl3g_generic, only: MAPL_GridCompAddSpec, MAPL_STATEITEM_FIELDBUNDLE
!  use mapl3g_generic, only: MAPL_UserCompSetInternalState, MAPL_UserCompGetInternalState
!  use mapl3g_generic, only: MAPL_GridCompTimerStart, MAPL_GridCompTimerStop
!  use mapl3g_VerticalStaggerLoc, only: VERTICAL_STAGGER_NONE, VERTICAL_STAGGER_CENTER, VERTICAL_STAGGER_EDGE
!  use mapl3g_Geom_API, only: MAPL_GridGetCoordinates
!  use mapl3g_State_API, only: MAPL_StateGetPointer
!  use mapl3g_Field_API, only: MAPL_FieldCreate
!  use mapl3g_FieldBundle_API, only: MAPL_FieldBundleAdd
!  use mapl3g_RestartModes, only: MAPL_RESTART_SKIP, MAPL_RESTART_REQUIRED
   
  implicit none
  private

  public SetServices
  public Initialize
  public Run
  public Finalize

  integer,  parameter :: r4 = REAL4
  integer,  parameter :: r8 = REAL8

contains

  !=============================================================================
  ! SetServices -- Sets ESMF services for this component
  !
  ! The SetServices for the CTM needs to register its Initialize and Run.
  ! It uses the MAPL_Generic construct for defining state specs.

  subroutine SetServices(GC, RC)

     type(ESMF_GridComp)  :: gc     ! composite gridded component 
     integer, intent(out) :: rc     ! Error code, 0 all is well

     integer :: status
     class(logger_t), pointer :: logger

    _HERE, 'testing'
     
    call MAPL_GridCompGet(gc, logger=logger, _RC)
    call logger%debug("AdvCore_GridCompMod.F90::SetServices starting...")

    !#include "AdvCore_Import___.h"
    !#include "AdvCore_Export___.h"
    !#include "AdvCore_Internal___.h" 
    
    ! Register services for this component
    call MAPL_GridCompSetEntryPoint(gc, ESMF_Method_Initialize,  Initialize, _RC)
    call MAPL_GridCompSetEntryPoint(gc, ESMF_Method_Run, Run, phase_name="Run", _RC)
    call MAPL_GridCompSetEntryPoint(gc, ESMF_Method_Finalize, Finalize, _RC)

    call logger%debug("AdvCore_GridCompMod.F90::SetServices done")

    _RETURN(_SUCCESS)
      
   end subroutine SetServices

   !=============================================================================
   ! Initialize -- The Initialize method of the CTM Derived Gridded Component.

   subroutine Initialize(GC, IMPORT, EXPORT, CLOCK, RC)

     type(ESMF_GridComp)  :: gc     ! composite gridded component 
     type(ESMF_State)     :: import ! import state
     type(ESMF_State)     :: export ! export state
     type(ESMF_Clock)     :: clock  ! the clock
     integer, intent(out) :: rc     ! Error code, 0 all is well

     integer :: status
     class(logger_t), pointer :: logger

     call MAPL_GridCompGet(gc, logger=logger, _RC)
     call logger%debug("AdvCore_GridCompMod.F90::Initialize starting...")

     call logger%debug("AdvCore_GridCompMod.F90::Initialize done")

     _RETURN(_SUCCESS)
      
   end subroutine Initialize

   !=============================================================================
   ! Run -- The Run method of the derived variables CTM Gridded Component.

   subroutine Run(GC, IMPORT, EXPORT, CLOCK, RC)

     type(ESMF_GridComp)  :: gc     ! composite gridded component 
     type(ESMF_State)     :: import ! import state
     type(ESMF_State)     :: export ! export state
     type(ESMF_Clock)     :: clock  ! the clock
     integer, intent(out) :: rc     ! Error code, 0 all is well

     integer            :: status
     type(ESMF_Grid)    :: esmfGrid
     type(ESMF_HConfig) :: hconfig

     class(logger_t), pointer :: logger

     ! Saved variables
     logical, save :: firstRun = .true.

!#include "AdvCore_DeclarePointer___.h"
     
     ! Get logger and grid
     call MAPL_GridCompGet(gc, grid=esmfgrid, hconfig=hconfig, logger=logger, _RC)
     call logger%debug("AdvCore_GridCompMod.F90::Run starting...")

     call ESMF_GridValidate(esmfgrid, _RC)

!#include "AdvCore_GetPointer___.h" 

     call logger%debug("AdvCore_GridCompMod.F90::Run done")

     _RETURN(_SUCCESS)

   end subroutine Run

   !=============================================================================
   ! Run -- The Finalize method of the derived variables CTM Gridded Component.

   subroutine Finalize( GC, IMPORT, EXPORT, CLOCK, RC )

     type(ESMF_GridComp)  :: gc     ! composite gridded component 
     type(ESMF_State)     :: import ! import state
     type(ESMF_State)     :: export ! export state
     type(ESMF_Clock)     :: clock  ! the clock
     integer, intent(out) :: rc     ! Error code, 0 all is well

     integer :: status
     class(logger_t), pointer :: logger

     call MAPL_GridCompGet(gc, logger=logger, _RC)
     call logger%debug("AdvCore_GridCompMod.F90::Finalize starting...")

     call logger%debug("AdvCore_GridCompMod.F90::Finalize done")

     _RETURN(ESMF_SUCCESS)

   end subroutine Finalize
   
end module AdvCore_GridCompMod

subroutine SetServices(gc, rc)
   use ESMF
   use AdvCore_GridCompMod, only : mySetservices=>SetServices
   type(ESMF_GridComp) :: gc
   integer, intent(out) :: rc
   call mySetServices(gc, rc=rc)
end subroutine SetServices
