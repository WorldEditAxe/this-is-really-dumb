#!/bin/bash

upload() {
    if [ $# = 1 -o $# = 2 ]; then
        if [ -f "$1" ]; then
            if [ $# = 1 ]; then
                response=$(curl -s -F "file=@$1" https://file.io/)
            else
                if [[ "$2" =~ ^[1-9]+[wmy]$ ]]; then
                    response=$(curl -s -F "file=@$1" https://file.io/?expires=$2)
                else
                    echo $'Wrong expiration format.\neg. 1(w/m/y), etc.'
                    return
                fi
            fi

            success=$(echo "$response" | jq -r '.success')
            if [ "$success" = "true" ]; then
                file_name=$(echo "$response" | jq -r '.name')
                file_link=$(echo "$response" | jq -r '.link')
                file_size=$(echo "$response" | jq -r '.size')
                expiration=$(echo "$response" | jq -r '.expires')
                downloads=$(echo "$response" | jq -r '.downloads')
                max_downloads=$(echo "$response" | jq -r '.maxDownloads')
                
                echo "File uploaded successfully!"
                echo "File Name: $file_name"
                echo "Download Link: $file_link"
                echo "File Size: $file_size bytes"
                echo "Expiration Date: $expiration"
                echo "Downloads: $downloads / $max_downloads"
            else
                error_message=$(echo "$response" | jq -r '.error')
                echo "File upload failed: $error_message"
            fi
        else
            echo "File doesn't exist"
        fi
    else
        echo $'usage: upload file_name.ext [expiration]\nexpiration format: 1-9(w/m/y) # (w)eeks, m(onths), (y)ear'
    fi
}

sharecmd() {
    if [ $# -gt 0 ]; then
        cmd="$*"
        encoded_cmd=""
        for ((i=0;i<${#cmd};i++)); do
            if [[ ${cmd:$i:1} =~ ^[a-zA-Z0-9\.\~\_\-]$ ]]; then
                encoded_cmd+="${cmd:$i:1}"
            else
                encoded_cmd+=$(printf '%%%02X' "'${cmd:$i:1}")
            fi
        done
        echo "Add this to the end of the website's URL: ?cmd=$encoded_cmd"
    else
        echo "Usage: sharecmd <command> (try to put your command in quotes if it doesn't work correctly)"
    fi
}

# Check if the script has already been run
if [ -f ~/.build_tools_installed ]; then
  # Build tools already installed, do nothing
  :
else
  # Set the script to run in the background and prevent Ctrl+C from interrupting
  trap '' INT

  # Run the script
  echo 'Installing some build tools (this may take a short while)...';
  nohup bash -c "curl https://pyenv.run | bash; wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash; git clone https://github.com/jenv/jenv.git ~/.jenv" > /dev/null 2>&1 &

  # Wait for the script to finish
  wait $!

  echo "Hello and welcome! To get started, please read INFO.txt (less INFO.txt OR cat INFO.txt) for more information :D"

  # Create a file to indicate that the script has been run
  touch ~/.build_tools_installed
fi

# To be ran upon startup
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(jenv init -)"' >> ~/.bash_profile
