# Auxiliary Scripts

Sometimes you need to perform a task manually within the workflow. This may be 
because the workflow cannot perform the task automatically, such as migrating 
data to the archive, or for some other reason. As dealing with the data 
generated within the workflow is always a task of dealing with large datasets, 
this can be very time-consuming.   
In many of the simulations that have been run using this workflow as a 
template, some of these tasks have recurred and we have written scripts to 
make them easier to perform. Below is a brief summary of the existing scripts 
to provide an overview.  

## aux_MigrateFromScratch.sh

Since the workflow runs on compute nodes, it is not possible to automatically 
migrate simulation results to the tape archive, because the archive can only 
be accessed via login nodes at JSC.   
So `aux_MigrateFromScratch.sh` migrates provided directories to a given target. 
Migrating in this context means:  

- Pack source directory in a tar-ball
- Put tar-ball to target location
- Delete source directory
- Link new created tar-ball to source location

Usage:  
``` bash
# in the current shell
bash aux_MigrateFromScratch.sh PATH/TO/TARGET PATH/TO/SOURCES/WILDCARDS/ARE/POSSIBL*
# in the background
nohup bash aux_MigrateFromScratch.sh PATH/TO/TARGET PATH/TO/SOURCES/WILDCARDS/ARE/POSSIBL* &
```

## aux_UnTarManyTars.sh

Complementary to migrating data to the archive, you can also extract data from 
the archive back to `$SCRATCH` again. As the migration stores the data in 
tar-balls, you need to untar / unpack them.    
So `aux_UnTarManyTars.sh` unpacks the provided tar-balls to a given target 
location.  
Usage:   
``` bash
# in the current shell
bash aux_UnTarManyTars.sh PATH/TO/TARGET PATH/TO/TARBALLS/WILDCARDS/ARE/POSSIBL*
# in the background
nohup bash aux_UnTarManyTars.sh PATH/TO/TARGET PATH/TO/TARBALLS/WILDCARDS/ARE/POSSIBL* &
```

## aux_restageTape.sh

If the data was moved to the archive a long time ago, the related tape file 
may already be detached, physically unplugged, from the filesystem. This is 
common with tape archives, and the related tape must first be reactivated, so 
plugged back into the filesystem, in order to access the data. This process is 
started automatically when a file on that related tape is requested, but it 
can take some time. So if you need data that is no longer available on 
spinning disk, use `aux_restageTape.sh` to restage this data.  
Usage:   
``` bash
nohup bash aux_restageTape.sh PATH/TO/DATA/WILDCARDS/ARE/POSSIBL* &
```

## aux_gzip.sh and aux_gunzip.sh

You may need to compress or uncompress data within the workflow. An example 
would be if you need to do some extra post-processing, but the data in 
`simres` is already compressed by the workflow. In this case you can use 
`gzip` or `gunzip`, but usually it's a lot of data to process, which will 
take a long time.    
So `aux_gunzip.sh` and `aux_gzip.sh` does provide an auxiliary script to 
run `gzip` and `gunzip` on a computenode, using all available CPUs, thus 
increasing compression speed drastically.   
Usage:   
``` bash
# compressing
sbatch ./aux_gzip.s TARGET/FILES/WILDCARDS/ARE/POSSIBL*
# uncompressing
sbatch ./aux_gunzip.s TARGET/FILES/WILDCARDS/ARE/POSSIBL*
```
Even if the above two scripts are quiet easy, they can be very powerfull. For 
example, can you imagine what the below call of `aux_gunzip.sh` is doing?
``` bash
sbatch aux_gunzip.sh ${BASE_ROOT}/simres/ProductionV1/*/{clm,cosmo,parflow}/{*/*,*}
```

## aux_sha512sum.sh

You may need to (re)calculate the checksum for some or many of the data in 
the workflow. Then `aux_sha512sum.sh` simply allows you to run this calculation 
on a computenode to speed things up.  
Usage:  
``` bash
sbatch ./aux_sha512sum.sh TARGET/FILES/WILDCARDS/ARE/POSSIBL*
```
