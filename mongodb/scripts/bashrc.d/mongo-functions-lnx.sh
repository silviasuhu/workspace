
mongo-jira-summary()
{
	JIRA_URL="https://jira.mongodb.org"

	dir=$1
	if [ -z $dir ]; then
		branch=$(git rev-parse --abbrev-ref HEAD)
	else
		pushd "$dir" > /dev/null
		branch=$(git rev-parse --abbrev-ref HEAD)
		popd > /dev/null
	fi

	jiraId=$(echo $branch | awk -F/ '{print $NF}')
	jira-ticket-info $jiraId
}

# Deletes all files generated by running `mongo-build` function (i.e.
# executables and object files). However, it does not delete the files
# corresponding to the build configuration (i.e. `build.ninja` and
# `compile_commands.json`).
#
# Options:
#   - Branch: --master (default), --v5.3, --v5.0, --v4.4, --v4.2
#   - Compiler family: --clang (default), --gcc
#   - Executables to delete: --all (default), --core
#   - All those of buildscripts/scons.py
# mongo-clean ()
# {
# 	( set -e;
# 	__mongo-check-wrkdir;
# 	__mongo-parse-args $@;

# 	case ${__mongo_branch} in
# 		v4.4 | v5.0 | v5.3 | v6.0 | master)
# 			${__cmd_prefix} ninja -t clean;
# 			${__cmd_prefix} ccache -c
# 		;;
# 		v4.2)
# 			__mongo-check-venv;
# 			${__cmd_prefix} ./buildscripts/scons.py \
# 					--variables-files=etc/scons/mongodbtoolchain_${MONGO_TOOLCHAIN_VER}_${__toolchain}.vars \
# 					--clean \
# 					${__target}
# 		;;
# 		*)
# 			echo "ERROR: ${__mongo_branch} branch is not supported by ${FUNCNAME[0]}" 1>&2;
# 			return 1
# 		;;
# 	esac )
# }

# # Runs on the current machine the infrastructure to process the specified
# # JavaScript test. This proposes the last commit comment as a description of the
# # patch, however it also allows to provide a custom message.
# #
# # Options:
# #   - Concurrency: --single-task (default), --multi-task
# #   - All those of buildscripts/resmoke.py
# mongo-test-locally ()
# {
# 	( set -e;
# 	__mongo-check-wrkdir;
# 	__mongo-check-venv;
# 	__mongo-parse-args --master $@;

# 	${__cmd_prefix} \rm -f executor.log fixture.log tests.log;
# 	set +e;
# 	${__cmd_prefix} ./buildscripts/resmoke.py run \
# 			--storageEngine=wiredTiger \
# 			--storageEngineCacheSizeGB=0.5 \
# 			--mongodSetParameters='{logComponentVerbosity: {verbosity: 2, sharding: {verbosity: 2}}}' \
# 			--jobs=${__tasks} \
# 			--log=file \
# 			${__args[@]};
#     res=$?;
#     ${__cmd_prefix} \mkdir -p lastTest;
#     ${__cmd_prefix} \cp executor.log fixture.log tests.log lastTest;
#     return $res;)
# }

# # Creates a new Evergreen path where it is possible to select the specific
# # suites to run. By default, all required suites are pre-selected.
# #
# # Options:
# #   - All those of evergreen patch
# mongo-test-remotely ()
# {
# 	( set -e;
# 	__mongo-check-wrkdir;
# 	__mongo-parse-args $@;

# 	msg=$(git log -n 1 --pretty=%B | head -n 1);
# 	if [[ ${__cmd_prefix} != echo ]]; then
# 		echo ${msg};
# 		read -p "Do you want change the title of this Evergreen patch? [y/N] ";
# 		if [[ ${REPLY} =~ (y|Y) ]]; then
# 			read -p "Type the custom title: " msg;
# 		fi;
# 	fi;

# 	${__cmd_prefix} evergreen patch \
# 			--project mongodb-mongo-${__mongo_branch} \
# 			--skip_confirm \
# 			--description "$(git branch --show-current) ${msg}" \
# 			${__args[@]} )
# }

# ################################################################################


# mongo-debug ()
# {
# 	( set -e;
# 	__mongo-parse-args $@;

# 	echo __cmd_prefix=${__cmd_prefix};
# 	echo __mongo_branch=${__mongo_branch};
# 	echo __toolchain=${__toolchain};
# 	echo __build_mode=${__build_mode};
# 	echo __link_model=${__link_model};
# 	echo __format=${__format};
# 	echo __target=${__target};
# 	echo __tasks=${__tasks};
# 	echo __args=${__args} )
# }

# ################################################################################

# ###
# ### Global settings
# ###

# MONGO_VENV_DIRNAME=${MONGO_VENV_DIRNAME:-'.venv'}
# MONGO_TOOLCHAIN_VER=${MONGO_TOOLCHAIN_VER:-'v4'}
# MONGO_TOOLCHAIN_DIRNAME=${MONGO_TOOLCHAIN_DIRNAME:-'/opt/mongodbtoolchain'}

# ###
# ### Internal functions
# ###

# __mongo-check-wrkdir ()
# {
# 	if [[ ! -d buildscripts ]]; then
# 		echo "ERROR: ${PWD} is not a mongo working directory" 1>&2;
# 		return 1;
# 	fi
# }

# __mongo-check-venv ()
# {
# 	if [[ -z ${VIRTUAL_ENV} ]]; then
# 		if [[ -d ./${MONGO_VENV_DIRNAME} ]]; then
# 			echo "NOTE: Implicit activation of Python virtual environment";
# 			. ${MONGO_VENV_DIRNAME}/bin/activate;
# 		else
# 			echo "ERROR: No Python virtual environment to activate" 1>&2;
# 			return 1;
# 		fi
# 	fi
# }

# __mongo-parse-args ()
# {
# 	[[ -z ${__parsed_args} ]] && __parsed_args=true || return 0;

# 	__cmd_prefix=;
# 	__mongo_branch=master;
# 	__toolchain=clang;
# 	__build_mode='--opt=off --dbg=on';
# 	__link_model='--link-model=dynamic';
# 	__format=1;
# 	__target=all;
# 	__tasks=1;
# 	__args=();

# 	while [[ $# -gt 0 ]]; do
# 		case $1 in
# 			--echo)
# 				__cmd_prefix=echo;
# 				shift
# 			;;
# 			--master)
# 				__mongo_branch=master;
# 				shift
# 			;;
# 			--v6.0)
# 				__mongo_branch=v6.0;
# 				shift
# 			;;
# 			--v5.3)
# 				__mongo_branch=v5.3;
# 				shift
# 			;;
# 			--v5.0)
# 				__mongo_branch=v5.0;
# 				shift
# 			;;
# 			--v4.4)
# 				__mongo_branch=v4.4;
# 				shift
# 			;;
# 			--v4.2)
# 				__mongo_branch=v4.2;
# 				shift
# 			;;
# 			--clang)
# 				__toolchain=clang;
# 				shift
# 			;;
# 			--gcc)
# 				__toolchain=gcc;
# 				shift
# 			;;
# 			--debug)
# 				__build_mode='--opt=off --dbg=on';
# 				shift
# 			;;
# 			--release)
# 				__build_mode='--opt=on --dbg=off';
# 				shift
# 			;;
# 			--dynamic)
# 				__link_model='--link-model=dynamic';
# 				shift
# 			;;
# 			--static)
# 				__link_model='--link-model=static';
# 				shift
# 			;;
# 			--format)
# 				__format=1;
# 				shift
# 			;;
# 			--no-format)
# 				__format=0;
# 				shift
# 			;;
# 			--all)
# 				__target=all;
# 				shift
# 			;;
# 			--core)
# 				__target=core;
# 				shift
# 			;;
# 			--mono-task)
# 				__tasks=1;
# 				shift
# 			;;
# 			--multi-task)
# 				__tasks=`cat /proc/cpuinfo | grep processor | wc -l`;
# 				shift
# 			;;
# 			*)
# 				__args+=($1);
# 				shift
# 			;;
# 		esac;
# 	done;

# 	# if [[ ${__mongo_branch} != master && ${__mongo_branch} != v5.0 && ${__mongo_branch} != v4.4 && ${__mongo_branch} != v4.2 ]]; then
# 	# 	echo "WARNING: ${__mongo_branch} is not a Git origin branch" 1>&2;
# 	# 	read -p "Do you want to use the master branch as a reference? [y/N] ";
# 	# 	[[ ${REPLY} =~ (y|Y) ]] && __mongo_branch=master || return 2;
# 	# fi
# }

# __mongo-configure-ninja ()
# {
# 	( set -e;
# 	__mongo-check-wrkdir;
# 	__mongo-check-venv;
# 	__mongo-parse-args $@;

# 	case ${__mongo_branch} in
# 		v4.4 | v5.0 | v5.3 | v6.0 | master)
# 			${__cmd_prefix} ./buildscripts/scons.py \
# 					--variables-files=etc/scons/mongodbtoolchain_${MONGO_TOOLCHAIN_VER}_${__toolchain}.vars \
# 					${__build_mode} \
# 					${__link_model} \
# 					--ninja generate-ninja \
# 					ICECC=icecc \
# 					CCACHE=ccache \
# 					${__args[@]}
# 		;;
# 		# *)
# 		# 	echo "ERROR: ${__mongo_branch} branch is not supported by ${FUNCNAME[0]}" 1>&2;
# 		# 	return 1
# 		# ;;
# 	esac )
# }

# __mongo-configure-compilation-db ()
# {
# 	( set -e;
# 	__mongo-check-wrkdir;
# 	__mongo-parse-args $@;

# 	case ${__mongo_branch} in
# 		v4.4 | v5.0 | v5.3 | v6.0 | master)
# 			${__cmd_prefix} ninja \
# 					compiledb \
# 					${__args[@]}
# 		;;
# 		v4.2)
# 			__mongo-check-venv;
# 			${__cmd_prefix} ./buildscripts/scons.py \
# 					--variables-files=etc/scons/mongodbtoolchain_${MONGO_TOOLCHAIN_VER}_${__toolchain}.vars \
# 					${__build_mode} \
# 					ICECC=icecc \
# 					compiledb \
# 					${__args[@]}
# 		;;
# 		*)
# 			echo "ERROR: ${__mongo_branch} branch is not supported by ${FUNCNAME[0]}" 1>&2;
# 			return 1
# 		;;
# 	esac )
# }

