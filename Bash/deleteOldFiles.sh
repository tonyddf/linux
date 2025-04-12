#!/usr/bin/env bash

# Indicate the function is called
echo "Initiated script \"${0}\""

# There is no need to verify inputs

# For instructions on how to use the function hosts, type "/admin/bin/hosts"
# Query in PMS. from ACCE and PROD, all DAC servers
HOSTSdac=${/admin/bin/hosts -c PMS -s a -s p -e nges-dac}
# Query in PMS. from ACCE and PROD, all OIS servers
HOSTSois=${/admin/bin/hosts -c PMS -s a -s p -e nges-ois}


# Declare the folders that will undergo deletion
# Define folders for DAC
FOLDERSdac[0]="/opt/osi/monarch/data/tennet_aos/schedules/event.pms.aos.afrr-lmol/input_business_validations/archive"
# Define folders for OIS
FOLDERSoisp[0]="/opt/osi/monarch/data/tennet_aos/schedules"
FOLDERSoisp[1]="/opt/osi/monarch/data/tennet_aos_eq/schedules"


# Loop through all DAC servers and remove the files older than 7 days
for HOST in ${HOSTSdac}
do
	
	for FOLDER in ${FOLDERSdac}
	logger "Removing in server \"${HOST}\" files in the folder \"${FILE}\"."
	do
		osisudo ssh ${HOST} find ${FOLDER} -type f -mtime +7 -delete;
		logger "Removed in server \"${HOST}\" files in the folder \"${FILE}\"."
	done
	
done

# Loop through all OIS servers and remove the files older than 7 days
for HOST in ${HOSTSois}
do
	for FOLDER in ${FOLDERSois}
	logger "Removing in server \"${HOST}\" files in the folder \"${FILE}\"."
	do
		osisudo ssh ${HOST} find ${FOLDER} -type f -mtime +7 -delete;
		logger "Removed in server \"${HOST}\" files in the folder \"${FILE}\"."
	done
done
