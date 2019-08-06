 #pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=4
#pragma Version=1.0

// NASA AMES 1001 file exporter for Igor Pro
// Version 2.0
// Jonathan Taylor, University of Manchester
// jonathan.taylor@manchester.ac.uk
// Original by James Allan
//See the Word document for a guide explaining how to use these functions

// Note: independent variable must be included in the list of data waves.


//This section is based on James Allan's old code (so it's not my fault it's messy and poor comments)

static strconstant inputtitles="Originator names(s);Organisation;Data source(s);Campaign name;Flight number;Flight date (YYYY MM DD);Revision date (YYYY MM DD);Interval;"


menu "Data"
	submenu "NASA AMES"
		"Input Windows", AMES_input()
		"Export", AMES_export()
	end
end

Function AMES_input()
	setdatafolder root:
	variable i,n
	if (!waveexists($"AMES_wave"))
		make /o/n=1/t AMES_wave,AMES_scale,AMES_name,AMES_form,AMES_title
		//MAke default example data
		AMES_Wave[0] = "Root:Pure_incand_Particles:incand_con"
		AMES_name[0] = "SP2 refractory black carbon number concentration (particles per cubic centimetre at standard temperature and pressure)"
		AMES_Title[0] = "SP2_BC_num_con"
		AMES_Form[0] = "%.3f"
		AMES_Scale[0] = "1"
	endif
	if(!waveexists($"Timewave_paths"))
		make/o/t/n=2 Timewave_Paths = {"Root:Pure_incand_particles:SP2_time_start","Root:Pure_incand_particles:SP2_time_end"}
	endif
	n=itemsinlist(inputtitles)
	make /o/n=(n)/t Input_Titles=stringfromlist(p,inputtitles),Input_Data
	if (!wintype("AMES_table"))
		execute("AMES_table()")
	else
		dowindow /f AMES_table
	endif
	if (!wintype("AMES_special"))
		newnotebook /f=0/n=AMES_special as "Special Comments"
	else
		dowindow /f AMES_special
	endif
	if (!wintype("AMES_normal"))
		newnotebook /f=0/n=AMES_normal as "Normal Comments"
	else
		dowindow /f AMES_normal
	endif
end

window AMES_table() : Table
	pauseupdate; silent 1
	Edit/W=(9,127.25,885,335) Input_Titles,Input_Data,AMES_wave,AMES_name,AMES_title
	AppendToTable AMES_form,AMES_scale, Timewave_Paths
	ModifyTable width(Input_Titles)=155,title(Input_Titles)="Metadata Required",alignment(Input_Data)=0
	ModifyTable width(Input_Data)=143,title(Input_Data)="Metadata",title(AMES_wave)="Data Waves"
	ModifyTable title(AMES_name)="Data Names",title(AMES_title)="Data Titles",title(AMES_form)="Data Formats"
	ModifyTable title(AMES_scale)="Data Scaling",title(Timewave_Paths)="Start & End Time"
end

function AMES_export()
	setdatafolder root:
	variable n_norm,n_spec,n_var,i,fileref,n_dat,j
	string norm,spec
	wave /t AMES_wave,AMES_scale,AMES_name,AMES_form,AMES_title,input_data, Timewave_paths
	string missing_value_str = "99999999.9999" //The value for NaNs. This has to be hard coded now
	
	string datestr = input_data[5]	//YYYY MM DD
	string datestr_dash = datestr[0,3] + "-" + datestr[5,6] + "-" + datestr[8,9]	//YYYY-MM-DD
	
	make /o/n=15/t AMES_metadata=""
	notebook AMES_special selection={startOfFile, endOfFile}
	getselection notebook,AMES_special,2
	spec=s_selection
	n_spec=itemsinlist(spec,"\r")
	notebook AMES_normal selection={startOfFile, endOfFile}
	getselection notebook,AMES_normal,2
	norm=s_selection
	n_norm=itemsinlist(norm,"\r")
	n_var=numpnts(ames_wave)+1	//The number of data waves, plus one for the end time wave
	ames_metadata[0]=num2str(15+n_spec+n_var+n_norm+1)+" 1001"	//Number of lines of metadata, and NASA AMES file format type
	ames_metadata[1,4]=(input_data[p-1])[0,131]
	ames_metadata[5]="1 1"
	ames_metadata[6]=input_data[5]+" "+input_data[6]
	ames_metadata[7]=input_data[7]
	
	
	ames_metadata[8]="Start time in seconds since " + datestr_dash		//Specify the timewaves
	ames_metadata[9]=num2str(n_var)	//Number of data waves, plus 1 for end time
	ames_metadata[12]=num2str(n_spec+1)	//Number of lines of special comments - add 1 because you add the flight/date at the start
	ames_metadata[13]=num2str(n_norm+1)	//Number of lines of normal comments- I don't know why you have to add 1
	ames_metadata[14]="Start_time_SSM" + "    " + "End_time_SSM" + "    "	//The name of the time waves when loaded, then 4 spaces by request of CEDA	//ames_title[0]+" "
	
	//Add in the end time
	ames_metadata[10] = "1 "
	ames_metadata[11] = missing_value_str+" "
	for (i=0;i<n_var-1;i+=1)	//Add in the names and missing values for each data wave
		ames_metadata[10]+=ames_scale[i]+" "	//The scaling
		ames_metadata[11]+=missing_value_str+" "	//Missing value
		ames_metadata[14]+=ames_title[i]+"    "	//Description of data wave
	endfor
	if (n_norm>0)
		insertpoints 14,n_norm, ames_metadata
		ames_metadata[14,14+n_norm-1]=stringfromlist(p-14,norm,"\r")
	endif
	if (n_spec>0)	//Insert special comments
		insertpoints 13,n_spec+1, ames_metadata
		if(stringmatch(input_data[4],""))	//If flight is blank, just put the date
			ames_metadata[13] = datestr_dash
		else
			ames_metadata[13] = input_data[4] + ", " + datestr_dash	//Otherwise put the flight and date
		endif
		ames_metadata[14,14+n_spec-1]=stringfromlist(p-14,spec,"\r")
	endif
	insertpoints 12,n_var,ames_metadata
	ames_metadata[12] = "End time in seconds since " + datestr_dash	//Title of end time wave
	ames_metadata[13,13+n_var-2]=ames_name[p-13]
	String fileFilters = "Data Files (*.na):.na;"
	open /F=fileFilters /z=2/m="Save NASA AMES file" fileref
	if (v_flag==0)
		for (i=0;i<numpnts(ames_metadata);i+=1)
			fprintf fileref, (ames_metadata[i]+"\r\n")	//Print the metadata to the file
		endfor
		wave source=$ames_wave[0]
		n_dat=numpnts(source)
		for (i=0;i<n_dat;i+=1)
			wave Time_Start = $Timewave_Paths[0]
			wave Time_End = $Timewave_Paths[1]
			if(numtype(Time_Start[i]) || numtype(Time_End[i]))	//If the timewave is a NaN
				//Don't save the data point!
			else
				//Same the time wave in seconds since midnight
				fprintf fileref,"%g" +"    ",mod(Time_Start[i],3600*24)
				fprintf fileref,"%g" +"    ",mod(Time_End[i],3600*24)
				for (j=0;j<n_var-1;j+=1)
					wave source=$ames_wave[j]
					if (numtype(source[i]))
						fprintf fileref,missing_value_str+"    "
					else
						fprintf fileref,ames_form[j]+"    ",source[i]
					endif
				endfor
				fprintf fileref,"\r\n"
			Endif
		endfor
	endif
	close fileref
end











/////////////////////////////////////////////////////////////////
/////SOME USEFUL FUNCTIONS///////////////////////////////////////
/////////////////////////////////////////////////////////////////



//Function to make start and end time waves for the AMS
//Run from within AMS SQUIRREL experiment, in the folder root:index
Function AMS_make_time_waves_AMES()
	wave/d t_series
	wave DurationOfRun = ::diagnostics:DurationOfRun
	make/o/d/n=(numpnts(t_series)) AMS_time_start,AMS_time_mid,AMS_Time_end

	//First need to fix nans due to blacklisted runs
	Differentiate AMS_Time_end/D=AMS_Time_end_DIF
	Duplicate/o DurationOfRun, :DurationOfRun2
	wave DurationOfRun2

	variable i
	For(i=0;i<(numpnts(AMS_time_end));i+=1)
		variable thisduration = DurationOfRun2[i]
		If(numtype(thisduration) != 0 || thisduration == 0)	//If it's a nan or durationofrun is 0 for no reason
			DurationOfRun2[i] = AMS_Time_end_DIF[i]
		Endif
	Endfor

	AMS_time_end = t_series
	AMS_time_start = t_series - DurationOfRun2
	AMS_time_mid = t_series - DurationOfRun2/2
	setscale d,0,0,"dat", AMS_time_start,AMS_time_mid,AMS_Time_end
	killwaves/z AMS_Time_end_DIF,DurationOfRun2

	make/o/n=(numpnts(AMS_time_Start)) AMS_Time_Start_SSM = mod(AMS_Time_Start,3600*24)	//Time in seconds since midnight
	make/o/n=(numpnts(AMS_time_Start)) AMS_Time_End_SSM = mod(AMS_Time_End,3600*24)

End

//Function to make start and end time waves for the SP2
//Run from wherever your SP2 time waves is, normally root:pure_incand_particles
Function SP2_make_time_waves_AMES()
	wave/d hk_time_av_incand
	make/o/d/n=(numpnts(incand_con)) SP2_time_start = hk_time_av_incand - 0.5, SP2_time_end = hk_time_av_incand + 0.5
	setscale d,0,0,"dat" SP2_time_start,SP2_time_end
end


//Average SP2 scatter data into the incand time waves, ready for exporting data
Function SP2_prep_AMES()
	//Make the pure scatter timewaves
	setdatafolder root:pure_scatter_particles
	wave/d hk_time_av
	make/o/d/n=(numpnts(hk_time_av)) Scatter_time_start = hk_time_av - 0.5, Scatter_time_end = hk_time_av + 0.5
	setscale d,0,0,"dat" Scatter_time_start, Scatter_time_end

	setdatafolder root:pure_incand_particles
	//Make a wave on BC mass con in micrograms per m3
	wave incand_mass_con
	make/o/d/n=(numpnts(incand_mass_con)) incand_mass_con_ugm3 = incand_mass_con / 1e3
	//Make SP2 timewaves and average scattering conc to the incand timewave
	SP2_make_time_waves_AMES()
	wave SP2_time_start,SP2_time_end
	Avg_data_startstop_time_AMES(root:pure_scatter_particles:scatter_con,root:pure_scatter_particles:scatter_time_start,root:pure_scatter_particles:scatter_time_end,sp2_time_start,sp2_time_end,newwavename="SP2_LSP_con")
end


//Function to average data from one time series to another
//datawave is the wave you want to average, with averaging periods between datatime_start and datatime_end
//This data is averaged to the time periods between time_start and time_end
Function Avg_data_startstop_time_AMES(datawave,datatime_start,datatime_end,time_start,time_end[,newwavename])
	wave datawave
	wave/d datatime_start,datatime_end,time_start,time_end
	string newwavename

	If(paramisdefault(newwavename))
		string datawavename = nameofwave(datawave)
		If(strlen(datawavename) > 27)	//If name too long, shorten it
			newwavename = datawavename[0,26] + "_avg"
		Else
			newwavename = datawavename + "_avg"
		Endif
	Endif

	if(waveexists(datawave) && waveexists(datatime_start) && waveexists(datatime_end)&& waveexists(time_start)&& waveexists(time_end))
		//OK
	else
		Print "Average_data_startstop_time cannot average data as one wave does not exists"
		return 0
	endif

	Duplicate/o datawave, $newwavename
	wave datawave_avg = $newwavename
	redimension/n=(numpnts(time_start)) datawave_avg
	datawave_avg = NaN

	variable i
	for(i=0; i<(numpnts(time_start)); i+=1)
		variable/d sample_start_time = time_start[i]
		variable/d sample_end_time = time_end[i]
		variable data_start_point = binarysearch(datatime_start,sample_start_time)	//Find the points to average between
		variable data_end_point = binarysearch(datatime_end, sample_end_time)
		variable data_start_point_last	//The point you started averaging from last time in the loop- knowing thi prevents you from averaging over the same data twice
		if(i==0)
			data_start_point_last =-1
		else
			data_start_point_last = binarysearch(datatime_start,time_start[i-1])
		endif
	
		if(data_start_point >=0 && data_end_point >=0 && data_start_point != data_start_point_last)	//If the 2 timewaves overlap and there's not a big gap between data
			datawave_avg[i] = nan_average_AMES(datawave,data_start_point,data_end_point)	//Average this periods data
		endif
	endfor

	If(datawave_avg[0] == 0 && numtype(datawave_avg[1]) !=0)
		datawave_avg[0] = NaN	//Probably the case
	Endif
end

//Averaging function required for Avg_data_startstop_time_AMES
//sp = start point, ep = end point
function nan_average_AMES(thiswave,sp,ep)
	wave thiswave
	variable sp,ep
	variable npoints = numpnts(thiswave)
  
	if(ep == -1)	//Shortcut, if you input 0 to -1 then usses the first and last points
		ep = numpnts(thiswave) -1
	endif
  
	if(ep>=npoints)
		print "Warning: endpoint outside wave range when running nan_average"
		ep = npoints-1
	endif
	variable i, total=0, numreal=0, avg=0
	for(i=sp;i<=ep;i+=1)
		if(numtype(thiswave[i]) == 0)
			total = total+thiswave[i]
			numreal+=1
		endif
	endfor
	avg = total/numreal
	return avg
end