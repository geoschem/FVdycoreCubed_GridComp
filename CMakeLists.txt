esma_set_this ()

option(BUILD_GEOS_GTFV3_INTERFACE "Build GEOS-gtFV3 interface" OFF)

# GCHP: remove certain files that are not needed:
#   - sw.f90
#   - jw.f90
#   - testcases_3_4_5_6_stand_alone.f90
#   - DynCore_GridCompMod.F90
#   - StandAlone_DynAdvCore_GridCompMod.F90
set (srcs
  GetWeightsC2C.F90
  GetWeights.F90
  CubeHalo.F90
  Cube2LatLon.F90 LatLon2Cube.F90 AppGridCreate.F90 FV_StateMod.F90
  AdvCore_GridCompMod.F90
  CreateInterpWeights_GridCompMod.F90
  CubeToLatLonRegridder.F90
  LatLonToCubeRegridder.F90
  CubeToCubeRegridder.F90
  CubeToLatLon.F90
  CubeGridPrototype.F90
  GEOS_FV3_Utilities.F90
  fv_regrid_c2c.F90
  fv_regrid_c2c_bin.F90
  fv_regridding_utils.F90
  rs_scaleMod.F90
  )

# GCHP: add fvdycore subdirectory
add_subdirectory(fvdycore)

# GCHP: Comment out GTFV3 interface (for running with GPUs)
#gpu#if (BUILD_GEOS_GTFV3_INTERFACE)
#gpu#  list (APPEND srcs
#gpu#  geos-gtfv3/geos_gtfv3_interface.f90
#gpu#  geos-gtfv3/geos_gtfv3_interface.c)
#gpu#endif ()
#gpu#
#gpu#if (BUILD_GEOS_GTFV3_INTERFACE)
#gpu#
#gpu#  message(STATUS "Building GEOS-gtFV3 interface")
#gpu#
#gpu#  add_definitions(-DRUN_GTFV3)
#gpu#
#gpu#  # The Python library creation requires mpiexec/mpirun to run on a
#gpu#  # compute node. Probably a weird SLURM thing?
#gpu#  find_package(MPI REQUIRED)
#gpu#  find_package(Python3 COMPONENTS Interpreter REQUIRED)
#gpu#
#gpu#  # Set up some variables in case names change
#gpu#  set(GEOS_GTFV3_INTERFACE_LIBRARY     ${CMAKE_CURRENT_BINARY_DIR}/libgeos_gtfv3_interface_py.so)
#gpu#  set(GEOS_GTFV3_INTERFACE_HEADER_FILE ${CMAKE_CURRENT_BINARY_DIR}/geos_gtfv3_interface_py.h)
#gpu#  set(GEOS_GTFV3_INTERFACE_SRCS        ${CMAKE_CURRENT_SOURCE_DIR}/geos-gtfv3/geos_gtfv3_interface.py)
#gpu#
#gpu#  # This command creates the shared object library from Python
#gpu#  add_custom_command(
#gpu#    OUTPUT ${GEOS_GTFV3_INTERFACE_LIBRARY}
#gpu#    # Note below is essentially:
#gpu#    #  mpirun -np 1 python file
#gpu#    # but we use the CMake options as much as we can for flexibility
#gpu#    COMMAND ${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} 1 ${Python3_EXECUTABLE} ${GEOS_GTFV3_INTERFACE_SRCS}
#gpu#    BYPRODUCTS ${GEOS_GTFV3_INTERFACE_HEADER_FILE}
#gpu#    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
#gpu#    MAIN_DEPENDENCY ${GEOS_GTFV3_INTERFACE_SRCS}
#gpu#    COMMENT "Building gtfv3 interface library with Python"
#gpu#    VERBATIM
#gpu#    )
#gpu#
#gpu#  # This creates a target we can use for dependencies and post build
#gpu#  add_custom_target(generate_python_interface_library DEPENDS ${GEOS_GTFV3_INTERFACE_LIBRARY})
#gpu#
#gpu#  # Because of the weird hacking of INTERFACE libraries below, we cannot
#gpu#  # use the "usual" CMake calls to install() the .so. I think it's because
#gpu#  # INTERFACE libraries don't actually produce any artifacts as far as
#gpu#  # CMake is concerned. So we add a POST_BUILD custom command to "install"
#gpu#  # the library into install/lib
#gpu#  add_custom_command(TARGET generate_python_interface_library
#gpu#    POST_BUILD
#gpu#    # We first need to make a lib dir if it doesn't exist. If not, then
#gpu#    # the next command can copy the script into a *file* called lib because
#gpu#    # of a race condition (if install/lib/ isn't mkdir'd first)
#gpu#    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_INSTALL_PREFIX}/lib
#gpu#    # Now we copy the file (if different...though not sure if this is useful)
#gpu#    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${GEOS_GTFV3_INTERFACE_LIBRARY}" ${CMAKE_INSTALL_PREFIX}/lib
#gpu#    )
#gpu#
#gpu#  # We use INTERFACE libraries to create a sort of "fake" target library we can use
#gpu#  # to make libFVdycoreCubed_GridComp.a depend on. It seems to work!
#gpu#  add_library(geos_gtfv3_interface_py INTERFACE)
#gpu#
#gpu#  # The target_include_directories bits were essentially stolen from the esma_add_library
#gpu#  # code...
#gpu#  target_include_directories(geos_gtfv3_interface_py INTERFACE
#gpu#    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
#gpu#    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}> # stubs
#gpu#    # modules and copied *.h, *.inc
#gpu#    $<BUILD_INTERFACE:${esma_include}/${this}>
#gpu#    $<INSTALL_INTERFACE:include/${this}>
#gpu#    )
#gpu#  target_link_libraries(geos_gtfv3_interface_py INTERFACE ${GEOS_GTFV3_INTERFACE_LIBRARY})
#gpu#
#gpu#  # This makes sure the library is built first
#gpu#  add_dependencies(geos_gtfv3_interface_py generate_python_interface_library)
#gpu#
#gpu#  # This bit is to resolve an issue and Google told me to do this. I'm not
#gpu#  # sure that the LIBRARY DESTINATION bit actually does anything since
#gpu#  # this is using INTERFACE
#gpu#  install(TARGETS geos_gtfv3_interface_py
#gpu#    EXPORT ${PROJECT_NAME}-targets
#gpu#    LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
#gpu#    )
#gpu#
#gpu#endif ()

# Set dependencies differently in GCHP (note: might need to add mapl3g and MAPL.state)
#set(dependencies MAPL MAPL.generic3g GFTL_SHARED::gftl-shared-v2 GMAO_hermes GEOS_Shared esmf OpenMP::OpenMP_Fortran)
if (ESMA_USE_GFE_NAMESPACE)
  set(dependencies MAPL MAPL.generic3g GFTL_SHARED::gftl-shared GMAO_hermes GEOS_Shared fvdycore ESMF)
else ()
  #set(dependencies MAPL MAPL.generic3g gftl-shared GMAO_hermes fvdycore ESMF)
  set(dependencies MAPL mapl3g MAPL.generic3g MAPL.state gftl-shared GMAO_hermes GEOS_Shared fvdycore ESMF)
  set(dependencies MAPL mapl3g MAPL.generic3g MAPL.state gftl-shared GMAO_hermes fvdycore ESMF)
endif ()

# GCHP: do not add fvdycore to subcomponents
# ewl: this if-else is new, and so is last line within each. Leave for now but might need to do something
if (BUILD_GEOS_GTFV3_INTERFACE)
  esma_add_library (${this}
    SRCS ${srcs}
    SUBCOMPONENTS fvdycore
    DEPENDENCIES ${dependencies}
    DEPENDENCIES ${GFDL}
    DEPENDENCIES geos_gtfv3_interface_py) # Make the main library depend on the Python library
else ()
  esma_add_library (${this}
    SRCS ${srcs}
    #SUBCOMPONENTS fvdycore
    DEPENDENCIES ${dependencies}
    DEPENDENCIES ${GFDL}
    TYPE SHARED
  )
endif ()

# GCHP: Turn off DynCore specs, and update to 3g. Turn off for now.
#mapl_acg (${this} DynCore_StateSpecs.rc IMPORT_SPECS EXPORT_SPECS INTERNAL_SPECS 3g)
#mapl_acg (${this} AdvCore_StateSpecs.rc
#  IMPORT_SPECS EXPORT_SPECS INTERNAL_SPECS
#  GET_POINTERS DECLARE_POINTERS
#  3g
#)

if (FV_PRECISION STREQUAL R4)
  set (GFDL FMS::fms_r4)
elseif (FV_PRECISION STREQUAL R4R8) # FV is R4 but FMS is R8
  get_target_property (extra_incs FMS::fms_r4 INTERFACE_INCLUDE_DIRECTORIES)
  target_include_directories(${this} PRIVATE $<BUILD_INTERFACE:${extra_incs}>)
  set (GFDL FMS::fms_r8)
elseif (FV_PRECISION STREQUAL R8)
  set (GFDL FMS::fms_r8)
  string(REPLACE " " ";" tmp ${FREAL8})
  foreach(flag ${tmp})
    target_compile_options (${this} PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${flag}>)
  endforeach()
endif ()

if (FV_PRECISION MATCHES R4)
  target_compile_definitions (${this} PRIVATE -DSINGLE_FV -DOVERLOAD_R4)
elseif (FV_PRECISION MATCHES R4R8) # FV is R4 but FMS is R8
  target_compile_definitions (${this} PRIVATE -DSINGLE_FV -DOVERLOAD_R4)
endif ()

# ewl note: need to add these?
target_link_libraries(${this} PUBLIC
  $<LINK_ONLY:mapl3g>
  $<LINK_ONLY:MAPL.generic3g>
  $<LINK_ONLY:MAPL.state>
)
target_include_directories(${this} PUBLIC
  $<TARGET_PROPERTY:mapl3g,INTERFACE_INCLUDE_DIRECTORIES>
  $<TARGET_PROPERTY:MAPL.generic3g,INTERFACE_INCLUDE_DIRECTORIES>
  $<TARGET_PROPERTY:MAPL.state,INTERFACE_INCLUDE_DIRECTORIES>
)

message(STATUS "Building FV as ${FV_PRECISION}")

#set (CMAKE_Fortran_FLAGS_RELEASE "${GEOS_Fortran_FLAGS_VECT}")

if (CRAY_POINTER)
  set_target_properties (${this} PROPERTIES COMPILE_FLAGS ${CRAY_POINTER})
endif()

# GCHP: option to skip advection run
if (MODEL_CTMENV)
  add_definitions (-DMODEL_CTMENV)
endif()

add_definitions (-DSPMD -DMAPL_MODE -DFVREGRID_MAPL_MODE)

foreach(flag ${tmp})
   target_compile_options (${this} PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${flag}>)
endforeach()

#exe# GCHP: do not add executables for subdirectory scripts
#exe#ecbuild_add_executable (
#exe#  TARGET StandAlone_FV3_Dycore.x
#exe#  SOURCES StandAlone_FV3_Dycore.F90
#exe#  LIBS ${this} OpenMP::OpenMP_Fortran)
#exe#
#exe#find_package (JeMalloc)
#exe#if(JeMalloc_FOUND)
#exe#  message(STATUS "JeMalloc found, using for StandAlone_FV3_Dycore.x")
#exe#  target_link_libraries (StandAlone_FV3_Dycore.x JeMalloc::JeMalloc)
#exe#endif()
#exe#
#exe#ecbuild_add_executable (
#exe#  TARGET rs_scale.x
#exe#  SOURCES rs_scale.F90
#exe#  LIBS ${this} OpenMP::OpenMP_Fortran)
#exe#
#exe#ecbuild_add_executable (
#exe#   TARGET StandAlone_AdvCore.x
#exe#   SOURCES StandAlone_AdvCore.F90
#exe#   LIBS ${this} OpenMP::OpenMP_Fortran)
#exe#
#exe#ecbuild_add_executable (
#exe#   TARGET StandAlone_DynAdvCore.x
#exe#   SOURCES StandAlone_DynAdvCore.F90
#exe#   LIBS ${this} OpenMP::OpenMP_Fortran)
#exe#
#exe#ecbuild_add_executable (
#exe#   TARGET c2c.x
#exe#   SOURCES c2c.F90
#exe#   LIBS ${this} OpenMP::OpenMP_Fortran)
#exe#
#exe#ecbuild_add_executable (
#exe#   TARGET interp_restarts.x
#exe#   SOURCES interp_restarts.F90
#exe#   LIBS ${this} OpenMP::OpenMP_Fortran)
#exe#
#exe#ecbuild_add_executable (
#exe#   TARGET interp_restarts_bin.x
#exe#   SOURCES interp_restarts_bin.F90
#exe#   LIBS ${this} OpenMP::OpenMP_Fortran)
#exe#
#exe#if (BUILD_GEOS_GTFV3_INTERFACE)
#exe#  ecbuild_add_executable (
#exe#    TARGET fv3_driver.x
#exe#    SOURCES
#exe#    geos-gtfv3/driver/FV_State_Utilities.F90
#exe#    geos-gtfv3/driver/input/domain_dim.f90
#exe#    geos-gtfv3/driver/input/grid_bounds.f90
#exe#    geos-gtfv3/driver/input/input_scalars.f90
#exe#    geos-gtfv3/driver/input/input_arrays.f90
#exe#    geos-gtfv3/driver/fv3_driver.F90
#exe#    LIBS ${this})
#exe#endif ()
#exe#
#exe#add_subdirectory(scripts)
