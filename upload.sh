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
