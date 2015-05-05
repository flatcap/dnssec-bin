function log_error()
{
	if [ -t 1 ]; then
		echo -e "\e[1;31m$@\e[0m"
	else
		echo -e "$@"
	fi
}

function log_warning()
{
	if [ -t 1 ]; then
		echo -e "\e[1;33m$@\e[0m"
	else
		echo -e "$@"
	fi
}

function log_info()
{
	if [ -t 1 ]; then
		echo -e "\e[1;32m$@\e[0m"
	else
		echo -e "$@"
	fi
}


