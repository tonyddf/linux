### Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi


### Load additional configuration files
for FILE in ~/.bashrc.d/*.sh
do
  source "${FILE}"
done
