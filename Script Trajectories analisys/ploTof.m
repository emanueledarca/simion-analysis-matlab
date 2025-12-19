% TofBySpecies plot
%% fname da cambiare in base al proprio
%fname = "/Users/emanueledarca/Desktop/IAPS/IMCA/Simulazioni/Trajectories/data_raw/trajectories/manual.txt"; %inserire il file
fname = "/Users/emanueledarca/Desktop/IAPS/IMCA/Simulazioni/Trajectories/data_raw/trajectories/SRIM10keV";
xlim = [0 400];
nbin = 10; %% numero di bin
%% mode plot veere  plotTofBySpecies
mode = "interactive"; %%modalita di plot sarebbe hist-local ma non voglio O+
data = simion.importSimionTofTable(fname);

%plot
FitResult = simion.plotTofBySpecies(data, mode, nbin, 'xlim', xlim);
