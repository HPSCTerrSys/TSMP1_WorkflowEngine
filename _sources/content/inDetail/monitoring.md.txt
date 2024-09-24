# Simulation Monitoring

The monitoring functionality in this workflow is implemented using Python scripts located in the `ctrl/monitoring/` directory. These scripts enable the generation of monitoring plots based on simulation data and are called from inside `start_postpro.sh`. This way the monitoring plots are generated automatically for each sub-step of the simulation. The following is an example of how the script is called:

``` bash
python monitoring_SanityCheck.py \
  --configFile CONFIG_SanityCheck_postpro \
  --dataRootDir ${PostProStoreDir} \
  --saveDir ${newMonitoringDir} \
  --runName ${CaseID} &
```

The call of the script includes the following parameters:

`configFile`: The path to the configuration file.  
`dataRootDir`: The root directory to simulation results used for the monitoring plot.     
`saveDir`: The directory where the final monitoring plots will be saved.  
`runName`: A string that is displayed in the figure title for easier identification.  
 
To configure the monitoring plots according to specific requirements, a configuration file is used. The configuration file specifies the variables to be plotted and their corresponding output files. It also provides control over various aspects of plot appearance, including unit changes, value masking, and colormaps. This flexible configuration allows for easy addition or removal of plots based on monitoring needs. However, it is important to have familiarity with the simulation output in order to correctly set up the configuration file, such as understanding the units and dimensions of the input fields.   
An example of such a config files is shown below:  

``` bash
[template]
varName:    None
fileName:   None
unitsOrig:  None
unitsPlot:  None
unitCoef:   None
unitOffset: None
Slices:     None
SanityKind: None
maskBelow:  None
maskAbove:  None
cmapName:   None  
valueRange: None

[DEFAULT]
cmapName:   Spectral  
valueRange: None

# CLM
[clm_RAIN]
varName:    RAIN
fileName:   clm/RAIN.nc
unitsOrig:  [mm/s]
unitsPlot:  [mm/h]
unitCoef:   3600
unitOffset: None
Slices:     None
SanityKind: mean
maskBelow:  None
maskAbove:  1e35
valueRange: 0.1 0.2 0.5 1 2 5 10 15 
cmapName:   precip3_16lev

# ParFlow
[pfl_evaptrans]
varName:    evaptrans
fileName:   parflow/evaptrans.nc
unitsOrig:  [1/h]
unitsPlot:  [mm]
unitCoef:   20
unitOffset: None
Slices:     None, -1
SanityKind: sum
maskBelow:  -1e35
maskAbove:  None
cmapName:   GMT_no_green_r
```

The configuration file consists of different sections, including `[template]`, `[default]`, `[clm_RAIN]`, and `[pfl_evaptrans]`, each representing an individual monitoring plot. The `[template]` and `[default]` sections have special purposes. The `[template]` section provides a template for adding new plots, and the `[default]` section holds default values that are applied to all sections unless overridden. But both are ignored for the actuall monitoring plots, that under the line above config files is generating monitoring plots `[clm_RAIN]` and `[pfl_evaptrans]`.

Each section in the configuration file includes the following settings:

- `varName`: The variable name of the netCDF file used as the data source for the monitoring plot.   
- `fileName`: The netCDF file name, with a relative path from the `dataRootDir` passed as argument to the monitoring script. In this example the monitoring script is processing the file `${PostProStoreDir}/clm/RAIN.nc` and `${PostProStoreDir}/parflow/evaptrans.nc`.     
- `unitsOrig`: The original units of the variable (for informational purposes).   
- `unitsPlot`: The desired units after unit conversion, which will be displayed in the plot title.   
- `unitCoef`: The coefficient used to convert the units. For example, if the original units are [mm/s], a `unitCoef` of 3600 converts it to [mm/h].   
- `unitOffset`: The offset used to convert the units. For example, if the original units are [K], a `unitOffset` of -275.15 converts it to [°C].   
- `Slices`: Defines how to slice the source field before creating the monitoring plot. It allows working with multi-dimensional fields by selecting specific slices only. For example, `Slices None,-1` corresponds to the Python syntax `array[:,-1]`, which e.g. selects the surface layer of a 4D ParFlow output (time, z, y, x).   
- `SanityKind`: Determines whether the lower-left subplot shows the mean or sum along the time axis of the source field.   
- `maskBelow`: Defines a lower value bound. Values below this threshold are masked out (before unit conversion!!).   
- `maskAbove`: Defines an upper value bound. Values above this threshold are masked out (before unit conversion!!).   
- `cmapName`: Specifies the name of the Python colorbar to be used in the monitoring plot. Colormaps from [colormaps](https://github.com/pratiman-91/colormaps/tree/ce4320c85ba3eeef32f4c749d13b449540387c5a) and the [official ones](https://matplotlib.org/stable/tutorials/colors/colormaps.html) are supported.
- `valueRange`: Specifies the values range of the colorbar, by setting all bin values for the colorbar.