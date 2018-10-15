# 
# Copright Professional Services 2018 
BuildDate: 26Sep2018-17.15.24
BuildTime: 17.15.24
Build User: 0
Build Host: hancock
 
Contents:
===============================================
 
enhancedNasMounter.pm
MD5SUMs/enhancedNasMounter.pm.md5sum
quickCheck
MD5SUMs/quickCheck.md5sum
recover
MD5SUMs/recover.md5sum
remove
MD5SUMs/remove.md5sum
restore
MD5SUMs/restore.md5sum
setup
MD5SUMs/setup.md5sum
REVISION=05.00.21



Description:
==================================================
This gen/app will mount and unmount a NFS share on the host
via the SPS-L (LifeKeeper) gen/app resource.  To use this script
a gen/app resource must be created.  The info field for the gen/app 
resource must contain the information required to mount the share in
the info field.
	Application Info: system_mount_point nfs_host nfs_export nfs_options
	Example from Node1:
	/sapmnt/JS1 peter /exports/sapmnt/JS1 rw-sync-bg-nfsvers=4

IMPORTANT NOTE: The directory where you extract these scripts must have execute permissions,
and not prevent the root user from running setup, or any of the other scripts



REQUIREMENTS:
==================================================
SIOS Protection Suite for LInux must be installed and operational



DIRECTIONS:
==================================================
1) run the setup script in the local directory
# ./setup
2) Verify setup is complete:
# ls -l /opt/LifeKeeper/lkadm/subsys/gen/app/lib
# The ls -l output should show the file: enhancedNasMounter.pm
3) If another application will use the mount point outside of SPS-L
	set the GLOBAL_NAS_APP_SKIP_REMOVE=1 value in the
	/etc/default/LifeKeeper file, or the _<tag> specific value.
	See APPENDIX below.
4) Use the UI to create the gen/app resource specifying
	the proper script at each prompt and set the info
	field as explained above. The nfs_options filed within the
	Application Info section can be left blank.  If it is left
	blank, the defaults will be used.
5) Verify the file system is mounted when the app is restored
# df -h



APPENDIX:
==================================================
Tunable values in /etc/default/LifeKeeper:
GLOBAL_NAS_APP_SKIP_REMOVE (default=1)
- When set to 1, the remove will skip unmounting all gen/app resources that
	use this gen/app Library
SKIP_REMOVE_<tag> (default=1), where tag is the resource tag
	Example: SKIP_REMOVE_my_sapmnt_share=1
- When set to 1, the remove will skip unmounting the specific gen/app resource
	specified by the _<tag>
NAS_APP_DEBUG (default=0)
- When set to 1, this will turn on additional messages in the output



TROUBLESHOOTING:
==================================================
1) FS won't mount
- verify the correct entry was specified in the information field
2) Wrong FS is mounted or wrong options
- verify the correct entry was specified in the information field
3) How do I turn on debug
- See APPENDIX
