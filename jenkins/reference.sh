#!/bin/bash
#
# Build the reference page
#
COLUMNS=256;
LINES=24;
export COLUMNS LINES;
REFERENCE=reference.txt

#function courierizer { echo "$1" | sed -e "s,<\([^>]*\)>,<i>\1</i>,g" -e "s,'\([^']*\)',<font face='courier'>\1</font>,g"; }
function courierizer { echo "$1" | sed -e "s,'\([^']*\)',\`\1\`,g"; }
function dtizer {
  echo $1 | sed -e "s,\(-[^#]*\) # \(.*\)$,**\1**\n: \2," |
    sed -e 's/\[//g' -e 's/]//g'
}

echo 'Below you can find a full reference of supported UNIX command-line interface (CLI) commands. The commands are alphabetized.  You can also use the <font face="Courier">hpcloud help [<em>command</em>]</font> tool (where <em>command</em> is the name of the command on which you want help, for example <font face="Courier">account:setup</font>) to display usage, description, and option information from the command line.' >${REFERENCE}
echo >>${REFERENCE}
echo 'Many of the commands support a `--debug` option to print verbose trace.  This trace may help you diagnose problems if the CLI is having difficulty communicating with the servers.' >>${REFERENCE}
echo >>${REFERENCE}
echo 'The <font face="Courier">hpcloud complete</font> command will attempt to install a bash completion file into your environment.  This will help if you like to use tab completion of commands.' >>${REFERENCE}
echo >>${REFERENCE}
hpcloud help | grep hpcloud | while read HPCLOUD COMMAND ROL
do
  if [ "${SAVE}" ]
  then
    echo "WARNING: Text in save buffer before ${COMMAND}" >&2
  fi
  SAVE=''
  STATE='start'
  SHORT=$(echo $ROL | sed -e 's/.*# //')
  export SHORT
  hpcloud help $COMMAND |
  sed -e 's/Alias:/###Aliases\n /' -e 's/Aliases:/###Aliases\n /' |
  while true
  do
    read LINE
    if [ $? -ne 0 ]
    then
      if [ "${SAVE}" ]
      then
        echo
        echo -ne "${SAVE}"
        SAVE=''
      else
        echo
      fi
      break
    fi
    case ${STATE} in
    start)
      if [ "${LINE}" == "Usage:" ]
      then
        echo -ne "##${COMMAND}## {#${COMMAND}}\n${SHORT}\n\n"
        echo "###Syntax"
        STATE='usage'
      fi
      ;;
    usage)
      if [ "${LINE}" == "Options:" ]
      then
        SAVE="\n\n###Options\n"
        STATE='options'
      else
        if [ "${LINE}" == "Description:" ]
        then
          echo -ne "\n\n###Description\n"
          SAVE=''
          STATE='description'
        else
          if [ "${LINE}" ]
          then
            #LINE=$(echo ${LINE} | sed -e 's/\[/\[ITALICS_START/g' -e 's/]/ITALICS_END]/g' -e 's/</\&lt;ITALICS_START/g' -e 's,>,ITALICS_END\&gt;,g' -e 's/ITALICS_START/<i>/g' -e 's,ITALICS_END,</i>,g' )
            echo -ne "\`${LINE}\`"
          fi
        fi
      fi
      ;;
    options)
      if [ "${LINE}" == "Description:" ]
      then
        echo -ne "${SAVE}###Description\n"
        SAVE=''
        STATE='description'
      else
        if [ "${LINE}" == "" ]
        then
          SAVE="${SAVE}\n${LINE}\n"
        else
          LINE=$(dtizer "${LINE}")
          SAVE="${SAVE}${LINE}\n\n"
        fi
      fi
      ;;
    description)
      if [ "${LINE}" == "Examples:" ]
      then
        echo "###Examples"
        STATE='examples'
      else
        courierizer "${LINE}"
      fi
      ;;
    examples)
      if [ "${LINE}" == "###Aliases" ]
      then
        echo "${LINE}"
        STATE='aliases'
      else
        if [ "${LINE}" != "" ]
        then
          COMMENT=$(echo "${LINE}" | sed -e 's/.*# \(.*\)$/\1/')
          COMMENT=$(echo "${COMMENT}" | sed -e 's/:$//')
          EXAMPLE=$(echo "${LINE}" | sed -e 's/\(.*\) *# .*$/\1/' -e 's/ *$//g')
          if [ "${COMMENT}" == "${EXAMPLE}" ]
          then
            echo -ne "    ${EXAMPLE}\n"
          else
            echo "${COMMENT}:"
            echo -ne "\n    ${EXAMPLE}\n\n"
          fi
        fi
      fi
      ;;
    aliases)
      echo "\`${LINE}\`"
      ;;
    esac
  done
done >>${REFERENCE}
