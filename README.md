# GenApp Recovery Kits

## Summary
The SIOS Steeleye Protection Suite &copy; Generic Application (GenApp) is an entry point into the world of custom Highly Available applications. GenApp is a harness that allows you to interface your application with the SPS framework. Quickly and easily make any application highly available with GenApp!

Steeleye Protection Suite (SPS) is an enterprise class application and data high availability supporting single & multi-site clusters leveraging any server and storage environment.

More information, including evaluation copies, can be found at http://us.sios.com.


### Purpose
* GenApp kits provide a robust harness to protect custom applications
* Easily integrate many applications with the SPS solution


### Technologies
* Requires the Steeleye Protection Suite installed on all nodes of the cluster.
* SPS for Linux is supported on either Red Hat Enterprise Linux (RHEL) or SuSE Linux Enterprise Server (SLES)
* Any Scipting language or binary can be used for with the GenApp. All it has to do is be executable and can interact with Linux's send event API.

	
### Installation
* Install SPS for Linux.
* Verify your custom application is properly installed and configured for your needs
* Write the scripts (or the executables) that will be used to protect your application.
* Using the included lkGUIapp or the web based GUI management console, create your GenApp and extend it to all nodes within your cluster. For more information on how to do this visit http://docs.us.sios.com/
* Now your application is Highly Available!
