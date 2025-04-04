
#!/bin/bash




# Reset variable
RESET='\033[0m'
# Regular Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
# Bold Colors
BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_PURPLE='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# GLOBAL VARIABLES
BANNER="
     ┏┓┓   ┓ 
     ┗┓┃┏┓┏┃┏
     ┗┛┗┗┛┗┛┗
"
           
INPUT_FILE="output/data.json"
CURRENT_PATH=$(pwd)

# ADD API KEYS HERE
DNS_DUMPSTER_API=""
PUBLICW_API=""




domains=$1




# code strucutre
#
#      : passive enumuration -> 
#       dumpster ()
#       crtsh()
#
#
#
#






function previouse_directry (){
    echo -e "${BOLD_RED}     [$] Target > ${RESET}$domains"
    
    local directory="$CURRENT_PATH/output/"

    if [ -d "$directory" ]; then
        #echo -e "${BOLD_YELLOW}"
        read -p "$(echo -e "${BOLD_YELLOW}     Did you want to remove the previous output (y/n) : ${RESET}")" answer
        #read -p "     Did you want to remove the previouce output (y/n) : " answer
        #echo -e "${RESET}"
        if [ "$answer" != "n" ]; then
            rm -rf "$directory"
        fi
    fi
}


function setup_environment() {
    local OUTPUT_DIR="output"
    if [ -d "$OUTPUT_DIR" ]; then
        echo -e "${BOLD_CYAN}      [!]${RESET}${BOLD_WHITE} Output directory already exists: $OUTPUT_DIR ${RESET}"
        return 0
    fi

    mkdir -p "$OUTPUT_DIR"
    echo -e "${BOLD_YELLOW}      [~]${RESET} ${BOLD_WHITE}Created output directory: $OUTPUT_DIR ${RESET}"
    return 0
}

function dumpster() {
    echo -e "${BOLD_GREEN}      [~] ${RESET}${BOLD_WHITE}Querying DNS Dumpster${RESET}"
    rm -f "$INPUT_FILE"  # Use correct file path

    export api_key=$DNS_DUMPSTER_API
    curl -s -H "X-API-Key: $api_key" "https://api.dnsdumpster.com/domain/$domains" > "$INPUT_FILE"
}

function extract_from_dumpster() {
    #echo -e "${BOLD_GREEN}    |->${RESET}${BOLD_WHITE} Fetching data from: $INPUT_FILE${RESET}"

    if ! command -v jq &>/dev/null; then
        echo -e "${BOLD_RED}Error:${RESET} 'jq' is required but not installed. Please install it first."
        echo "On Ubuntu/Debian: sudo apt install jq"
        echo "On CentOS/RHEL: sudo yum install jq"
        exit 1
    fi

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo -e "${BOLD_RED}Error:${RESET} The file '$INPUT_FILE' was not found."
        exit 1
    fi

    if ! jq empty "$INPUT_FILE" &>/dev/null; then
        echo -e "${BOLD_RED}Error:${RESET} Invalid JSON data in '$INPUT_FILE'."
        exit 1
    fi

    declare -A domains

    while IFS= read -r record; do
        domains["$(jq -r '.host' <<< "$record")"]=1
    done < <(jq -c '.a[]?' "$INPUT_FILE")
    while IFS= read -r record; do
        domains["$(jq -r '.host' <<< "$record")"]=1
    done < <(jq -c '.mx[]?' "$INPUT_FILE")
    
    while IFS= read -r record; do
        domains["$(jq -r '.host' <<< "$record")"]=1
    done < <(jq -c '.ns[]?' "$INPUT_FILE")
    
    printf "%s\n" "${!domains[@]}" | sort >> "output/dumpster.txt"

    echo -e "${BOLD_CYAN}          ↳${RESET}${BOLD_WHITE} Subdomains from DNS Dumpster: ${BOLD_YELLOW}$(wc -l < "output/dumpster.txt")${RESET}"
    rm "output/data.json"
}

function crtsh() {
    echo -e "${BOLD_GREEN}      [~]${RESET} ${BOLD_WHITE}Querying crt.sh...${RESET}"
    local response=$(curl -s "https://crt.sh/?q=%25.$domains&output=json")
    echo "$response" | jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' >> "output/crtsh.txt"
    echo -e "${BOLD_CYAN}          ↳${RESET}${BOLD_WHITE} Subdomains from crtsh${BOLD_YELLOW} : $(wc -l < "output/crtsh.txt")${RESET}" 


}



function subfinder_ (){
    
    echo -e "${BOLD_GREEN}      [~]${RESET}${BOLD_WHITE} Subfinder is running ${RESET}"
    subfinder -d $domains -silent >> "$CURRENT_PATH/output/subfinder.txt" 
    echo -e "${BOLD_CYAN}          ↳${RESET}${BOLD_WHITE} Subfinder${BOLD_YELLOW}$(wc -l < "$CURRENT_PATH/output/subfinder.txt")${RESET}"



}

function assetfinder_ (){
    
    echo -e "${BOLD_GREEN}      [~]${RESET}${BOLD_WHITE} Assetfinder is running  ${RESET}"
    assetfinder -subs-only $domains | sort -u > "$CURRENT_PATH/output/assetfinder.txt"
    echo -e "${BOLD_CYAN}          ↳${RESET}${BOLD_WHITE} Assetfinder${BOLD_YELLOW} $(wc -l < "$CURRENT_PATH/output/assetfinder.txt")${RESET}"

}


function findomain_ (){
    
    echo -e "${BOLD_GREEN}      [~]${RESET}${BOLD_WHITE} Findomain is running  ${RESET}"
    findomain -t $domains -q >> "$CURRENT_PATH/output/findomain.txt"
    echo -e "${BOLD_CYAN}          ↳${RESET}${BOLD_WHITE} Findomains ${BOLD_YELLOW} $(wc -l < "$CURRENT_PATH/output/findomain.txt")${RESET}"

}









function main() {

    clear

    echo -e "$BANNER"


    previouse_directry
    setup_environment
    
    subfinder_ # subfinder
    assetfinder_ # assetfinder
    findomain_ # findomain


    crtsh
    dumpster
    extract_from_dumpster

    echo -e "${BOLD_YELLOW}      [+] Done !${RESET} "



}

main
