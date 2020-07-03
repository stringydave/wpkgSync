# read the package.xml files, list the folder for each package
# read the log file, get a list of all the packages we tried to install
# delete the entries for the packages we want
# what's left is a list of folders to exclude

# 03/07/20  dce  also don't exclude folders of packages in process of being removed

BEGIN {
	IGNORECASE = 1
	print "# ====================================================="
	print "# rsync folder exclude list autogenerated by wpkgsync"
	print "# standard excludes:"
    print "lost+found"
    print "client"
    print "profiles.sites"
	print "# ====================================================="
	print "# packages required:"
}

# for each package in the xml files, get the package_id
#      id='7zip' 
/[[:space:]]id[[:space:]]*=/ {
	package_id = $0
	gsub(/^.*id[[:space:]]*=/,"",package_id)
	gsub(/\"/,"",package_id)  # "
	gsub(/'/,"",package_id)
	gsub(/ /,"",package_id)
}

# and do the same for any chained packages
# <depends package-id="chassistype"/>
# <chain package-id="libreofficehelppackengb" />
/depends[[:space:]]+package-id/ || /chain[[:space:]]+package-id/ {
	id = $0
	# print
    gsub(/^.*=/,"",id)	# remove everything up to the "="
	gsub(/\"/,"",id)  	# "
	gsub(/'/,"",id)		# '
	gsub(/ /,"",id)		# space
	gsub(/\/>/,"",id)	
	referenced[package_id] = id
}

# this code gets invoked when we're installing stuff, and tells us where it is
# <install cmd='msiexec /qn /norestart /i %SOFTWARE%\putty\putty-%version%-installer.msi' />
# we assume that at run time %SOFTWARE% points to "packages/"
(/<install.*%software%/ || /<upgrade.*%software%/) && (!/\.\./) {
	package_folder = $0
	gsub(/.*%software%\\/,"",package_folder)
	gsub(/\\.*$/,"",package_folder)
	
	folder_for[package_id] = "packages/" package_folder "/"
}

# now we can read the wpkg log to see what applies to this machine
# 2020-05-03 17:52:04, DEBUG   : Adding package with ID 'putty' to profile packages.
/Adding package with ID/ {
	# package_id is the bit in ''
	split ($0, stringparts, "'")
	package_id     = stringparts[2]

	if (package_id in folder_for) {
		printf("# %-20s : %s\n", package_id, folder_for[package_id])
		# and delete that element from the array
		delete folder_for[package_id]
		# if there are any referenced packages
		delete folder_for[referenced[package_id]]
	} else {
		printf("# %-20s\n", package_id)
	}
}

# and we also keep any which are currently marked for removal, as we may need code in 
# 2020-05-13 19:05:28, DEBUG   : Package 'AVG Client 18' (avgclient18): Marked for removal.
/: Marked for removal/ {
	# package_id is the bit in ()
	package_id = $0
    gsub(/^.*\(/,"",package_id)	# remove everything up to the "("
	gsub(/\).*$/,"",package_id) # remove anything after "")"

	if (package_id in folder_for) {
		printf("# %-20s - %s \[remove\]\n", package_id, folder_for[package_id])
		# and delete that element from the array
		delete folder_for[package_id]
	} else {
		printf("# %-20s\n", package_id)
	}
}

END {
	print "# ====================================================="
	print "# package folders to exclude:"
	for (i in folder_for) {
		print folder_for[i]
	}
	print "# ====================================================="
}