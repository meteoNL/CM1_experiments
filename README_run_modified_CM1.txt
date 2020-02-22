This altered version of CM1 ran on Mogon2 in Mainz. Mogon2 is operqated and maintained by ZDV. 

To run an experiment: 
Set-up
0. run the make file on your machine by navigating to ./cm1r19.8/src and commanding "make".
1. choose a name for a folder inside cm1r19.8/run, such as "my_experiment1". Put this name in "run_model.sh" with the mkdir command.
2. edit namelist.input, or copy one of the reference namelists in cases_reference_namelists/subfolders to cm1r19.8/run/
3. load the libraries that are required on Mogon2, by running modules_required_run.sh 
4. if necessary edit the SBATCH reservations of time and memory. The default settings are suitable for the supercell and ordinary multicell experiments at 200x200x100 m. If the coldpool initialisation for a squall line is used, approximately 20-25% more time would probably be required. 
5. Submit the job with "sbatch run_model.sh"

Actual running
6. The model should run. The reference simulations take about 18.5 hours on 3 nodes. All files are copied into the folder belonging to the experiment.


Postprocessing
7. Edit the .py-scripts in the /cm1r19.8/run/scripts/ folder if non-default cross sections and other figures have to be made. For example: the cross sections of Moist Static Energy, condensation and momentum budgets are in their current status ready to make a cross section along constant y for the squall line case. Adapt the script to your requirements. Unfortunately this component does not use any input on the command line as variable, but this can be implemented. In addition there are pseudo radar pictures at z = 3 km (if in default setting, or another level can be selected) generated and various vertical velocity pictures at the selected level: overviews with the whole range of w's and specific ones to study waves propagating outward from the convective event that go beyond the convective cloud itself (-4 to +4 m/s). A divergence script calculates divergence fields. Note that these have not been optimised and some scripts take a while to run, but they are much faster than the model itself.
8. Load the modules to run python, for which the .sh script is found in the same folder.
9. The general python script jobs are defined in python_wrapper.sh. Here the model level and latent heat fraction of the run have to be delivered as they are taken into account in post-processing and creating figures. Again, edit reservations and everything else you like.
10. Submit the job with sbatch python_wrapper.sh. After running the figures appear in the folder belonging to the experiment and its subfolder /pngs/ (automatically made).

--- budget analysis ---
11./??. With the figures made in the post-processing, it is interesting to select a domain in which the budget of the processes and quantities of interest are computed. This domain is selected with x1, x2, y1 and y2 in the python script "integrated vertical profiles.py". After selecting a domain and time stamp in this script, budgets per layer are stored in .csv-files in the directory of the run.

--- plot budgets ---
??. By running ./newvalues.py, a PDF and PNG with vertical budget overviews will be saved  belonging to the selected subdomains (integrated... script). This appears in the /cm1r19.8/run/budgets/ folder. The script runs in principle only if four folders for four experiments are provided, unless modified by the user. 




