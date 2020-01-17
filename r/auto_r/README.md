# Automatic R Generator and Executor

This tools allow the automatic generation of figures for all repositories that have been analysed
This tool allows for the insertion in a db of the data that was extracted using the python GitExtract tool

## External Requirements

Need to have R install on the machine with the RPostgreSQL library installed. This library can be installed from R 
using the following command:

    install.packages("RPostgreSQL")
    
*note: You may need to have r devel and postgresql devel files for this to work

## Python Libraries

The following libraries need to be installed:

    sudo python -m easy_install psycopg2
    
## Configure

Run the settings files to get your local machine username

    python settings.py
    
The settings file allows for multiple users to be configured. Add a dictionary entry in the settings.py with your
    postgresql host, database name, username and password

## Run

Run the following command to automatically generate all of the R figures

    python auto_r.py
    
This will automatically generate all the figures in the 4Model/incrementality/figures folder
    
    
    
    
    
    