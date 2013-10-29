/*=================================================================
 *
 *  --- matlabmpi - version 1.1 ---
 *
 *  This program, including its separate functions, makes it
 *  possible for the MATLAB programmer to use MPI without calling
 *  MPI functions.
 *
 *  This program will always start a MATLAB function 'matlabmain'
 *  with a verbosity parameter and, if compiled with -DTIMINGS,
 *  a "save timings" flag.
 *
 *  Prerequisites:
 *           - MATLAB (with compiler)
 *           - MCR (MATLAB Compiler Runtime) environment
 *           - MPI
 *
 * Copyright 2013 Jeroen Engelberts, SURFsara
 *=================================================================*/

#include <stdio.h>
#include <mpi.h>
#include <unistd.h>

/* Include the MCR header file and the library specific header file 
 * as generated by MATLAB Compiler */
#include "libmmpi.h"

/* MPI rank and size and verbosity declared globally, to be present in main and run_main */
int mpi_rank, mpi_size;
int verbosity=0;
int savetimings=0;

int run_main(int argc, char **argv)
{
    mxArray *MLmpi_size, *MLmpi_rank, *MLverbosity, *MLsavetimings;
    
    /* Call the library intialization routine and make sure that the
     * library was initialized properly. */
    if (!libmmpiInitialize()){
        fprintf(stderr,"Could not initialize the library.\n");
        return -2;
    }
    else
    {
    /* Set mpisize, mpirank, verbosity and timings (on/off) */
        double *buf;
        MLmpi_size = mxCreateDoubleMatrix(1,1,mxREAL);
        buf = mxGetPr(MLmpi_size);
        *buf = (double) mpi_size;
        MLmpi_rank = mxCreateDoubleMatrix(1,1,mxREAL);
        buf = mxGetPr(MLmpi_rank);
        *buf = (double) mpi_rank;
        mlfSetmpistuff(MLmpi_size,MLmpi_rank);
        MLverbosity = mxCreateDoubleMatrix(1,1,mxREAL);
        buf = mxGetPr(MLverbosity);
        *buf = (double) verbosity;
        MLsavetimings = mxCreateDoubleMatrix(1,1,mxREAL);
        buf = mxGetPr(MLsavetimings);
        *buf = (double) savetimings;
    /* Call the library function */
        mlfMatlabmain(MLverbosity,MLsavetimings);
    }
    /* Free the memory created */
    mxDestroyArray(MLmpi_size); MLmpi_size=0;
    mxDestroyArray(MLmpi_rank); MLmpi_rank=0; 
     
    /* Call the library termination routine */
    libmmpiTerminate();

/* Note that you should call mclTerminate application at the end of
 * your application.
 */
    mclTerminateApplication();
    return 0;
}

int main(int argc, char *argv[])
{
    int rc;
    int ch;
    int provided;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_SINGLE, &provided);
    MPI_Comm_rank(MPI_COMM_WORLD,&mpi_rank);
    MPI_Comm_size(MPI_COMM_WORLD,&mpi_size);
    while ((ch = getopt(argc, argv, "htv:")) !=-1) {
        switch(ch) {
        case 'v':
            verbosity=atoi(optarg);
            if (mpi_rank==0) {
                printf("Setting verbosity to level %d.\n",verbosity);
            }
            break;
        case 't':
            savetimings=1;
            if (mpi_rank==0) {
                printf("Timings will be saved.\n");
            }
            break;
        case 'h':
        case '?':
        default:
            if (mpi_rank==0) {
                printf("\nmatlabprog can be run without command line options.\n");
                printf("\nThese are the optional command line parameters:\n");
                printf("\t-h Prints this help message.\n");
                printf("\t-t Save timings.\n");
                printf("\t-v Sets the verbosity level [0-3].\n\n");
            }
            MPI_Finalize();
            return 5;
        }
    }
    if (mpi_size<2) {
        printf("\nThis program can only be run on more than one processor!\n");
        rc=7;
    } else {
        const char* options[3];
        options[0] = "-nojvm";
        options[1] = "-nodisplay";
        options[2] = "-singleCompThread";
    /* Call the mclInitializeApplication routine. Make sure that the application
     * was initialized properly by checking the return status. This initialization
     * has to be done before calling any MATLAB API's or MATLAB Compiler generated
     * shared library functions.  */

        if( !mclInitializeApplication(options,3) )
        {
            fprintf(stderr, "Could not initialize the application.\n");
        	return -1;
        }
        mclmcrInitialize();
        rc=mclRunMain((mclMainFcnType)run_main,0,NULL);
    }
    MPI_Finalize();
    return rc;
}
