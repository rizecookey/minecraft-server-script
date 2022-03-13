#!/bin/bash
scriptdir="${PWD}/script/"
cachedir="${PWD}/script/cache/"
screenopt="screen.option"
runningopt="running.option"
serverjaropt="serverjar.option"
customrunscriptopt="customrunscript.option"
jvmargsopt="jvmargs.option"
setup() {
	if ! [ -d ${scriptdir} ]; then
		mkdir $scriptdir
		echo "Created script options directory ${scriptdir}."
	fi
	if ! [ -d ${cachedir} ]; then
		mkdir $cachedir
	fi
	if ! [ -f ${scriptdir}${screenopt} ]; then
		echo "minecraft-server" >${scriptdir}$screenopt
		echo "Created ${screenopt} file in directory ${scriptdir}."
	fi
	if ! [ -f ${scriptdir}${runningopt} ]; then
		echo "false" >${scriptdir}${runningopt}
	fi
	if ! [ -f ${scriptdir}${serverjaropt} ]; then
		echo "server.jar" >${scriptdir}${serverjaropt}
		echo "Created ${serverjaropt} file in directory ${scriptdir}."
	fi
	if ! [ -f ${scriptdir}${customrunscriptopt} ]; then
		touch ${scriptdir}${customrunscriptopt}
		echo "Created ${customrunscriptopt} file in directory ${scriptdir}."
	fi
	if ! [ -f ${scriptdir}${jvmargsopt} ]; then
		echo "-Xms2G -Xmx2G" >${scriptdir}${jvmargsopt}
		echo "Created ${jvmargsopt} file in directory ${scriptdir}."
	fi
}
update() {
	read running <${scriptdir}${runningopt}
	read screen <${scriptdir}${screenopt}
	read serverjar <${scriptdir}${serverjaropt}
	read customrunscript <${scriptdir}${customrunscriptopt}
	alreadyexists=$(
		screen -S $screen -X select .
		echo $?
	)
	if [ "$alreadyexists" == "1" ]; then
		echo "false" >${scriptdir}${runningopt}
	fi
	read jvmargs <${scriptdir}${jvmargsopt}
}
setup
update
stop() {
	if [ "$running" == "false" ] && [ "$alreadyexists" == "1" ]; then
		echo "The server isn't running!"
	else
		echo "Attempting to stop server..."
		echo "false" >${scriptdir}${runningopt}
		if [ "$alreadyexists" == "0" ]; then
			screen -S $screen -X stuff '\n'
			screen -S $screen -X stuff 'stop'
			screen -S $screen -X stuff '\n'
		fi
		echo "Server is stopping. Waiting for screen to close..."
		while [ "$alreadyexists" == "0" ]; do
			sleep 1
			update
		done
	fi
}
start() {
	if [ "$alreadyexists" == "0" ]; then
		if [ "$running" == "true" ]; then
			echo "Server is already running!"
		else
			echo "There's already a screen named $screen!"
			echo "Please change the screen name in the $screenopt file ."
	else
		echo "Starting minecraft server..."
		echo "true" >${scriptdir}${runningopt}
		if ! [ "$customrunscript" == "" ]; then
			echo "Using custom run script."
			echo "#!/bin/bash
                	running=\"true\"
                	while [ \"\$running\" == \"true\" ]; do
                	bash ${scriptdir}${customrunscript}
                	sleep 5
                	read running < ${scriptdir}${runningopt}
                	done
					echo \"false\" > ${scriptdir}${runningopt}" >${cachedir}cache-script.sh
		else
			echo "#!/bin/bash
                	running=\"true\"
                	while [ \"\$running\" == \"true\" ]; do
                	java ${jvmargs} -jar ${serverjar}
                	sleep 5
                	read running < ${scriptdir}${runningopt}
                	done
					echo \"false\" > ${scriptdir}${runningopt}" >${cachedir}cache-script.sh
		fi
		screen -dmS $screen bash ${cachedir}cache-script.sh
		echo "Server has been started in screen $screen."
	fi
}
help() {
	echo "Minecraft Server handling script version 1.0 by RizeCookey"
	echo "----------------------------------------------------------------------------"
	echo "-=OPTIONS=-"
	echo "start : Starts the server"
	echo "stop : Stops the server"
	echo "restart : Restarts the server"
	echo "run {command} : Run command in the server console"
	echo "-----------------------------------------------------------------------------"
	echo "-=CONFIGURATION=-"
	echo "screen.option : Defines the name of the screen the server is running in."
	echo "serverjar.option : Defines the jar to be run on startup."
	echo "customrunscript.option : Defines a custom script to be run in screen, leave  "
	echo "blank to use the default script"
	echo "jvmargs.option : Defines arguments for the Java Virtual Machine"
	echo "-----------------------------------------------------------------------------"
}

if [ "$1" == "start" ]; then
	start
elif [ "$1" == "stop" ]; then
	stop
elif [ "$1" == "restart" ]; then
	stop
	update
	start
elif [ "$1" == "run" ]; then
	if [ "$running" == "false" ] && [ "$alreadyexists" == "1" ]; then
		echo "The server isn't running! Start it first!"
	else
		echo "Running command..."
		screen -S $screen -X stuff '\n'
		screen -S $screen -X stuff "$2"
		screen -S $screen -X stuff '\n'
	fi
elif [ "$1" == "help" ]; then
	help
else
	help
fi
