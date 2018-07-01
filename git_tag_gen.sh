#!/bin/bash
NC='\033[0m' && ORANGE='\033[0;33m' && YELLOW='\033[1;33m' && RED='\033[0;31m'
BLUE='\033[0;34m' && LIGHT_BLUE='\033[1;34m' && LIGHT_PURPLE='\033[1;35m'
CYAN='\033[0;36m' && LIGHT_CYAN='\033[1;36m'

if [ -z $CRON_JOB_DAY ];
then
	echo -e "${ORANGE}This is not a cron job, right?${NC}"
else
	if [ ! $(date +%u) == "$CRON_JOB_DAY" ];
	then
		echo -e "${RED}This task will run only at day ${BLUE}'$CRON_JOB_DAY'${NC}.\n(Day count starts on ${BLUE}'1'${NC} |Monday|)"
		exit 0;
	fi
fi

git_tag_gen_path=$(git rev-parse --show-toplevel)

echo "$git_credentials" > ~/.git-credentials;
git config credential.helper store;
DEFAULT_TAG="v1.0.0";
if [ -z "$(env | grep REPOSITORY_ )" ];
then
	echo -e "${CYAN}Getting repos from repos.txt${NC}"
	repos=($(echo $(cat repos.txt)))
else
	echo -e "${CYAN}Getting repos from env REPOSITORY_*...${NC}"
	repos=($(env | grep REPOSITORY_ | cut -f 2 -d '='))
fi
for CURRENT_REPOSITORY_ORIGIN in ${repos[@]}; 
do
	ORIGIN=$(echo $CURRENT_REPOSITORY_ORIGIN | cut -f 1 -d '/')
	echo "ORIGIN: $ORIGIN"
	CURRENT_REPOSITORY=$(echo $CURRENT_REPOSITORY_ORIGIN | cut -f 2 -d '/')
	echo "CURRENT_REPOSITORY: $CURRENT_REPOSITORY"
	mkdir -p $ORIGIN && cd $ORIGIN
	echo "ORIGIN: $PWD"
	echo -e "${LIGHT_PURPLE}Checking for repository $CURRENT_REPOSITORY...${NC}"
	if [ ! -d "$CURRENT_REPOSITORY" ]; then
		echo -e "${ORANGE}Cloning repository...${NC}"
		git clone https://github.com/$ORIGIN/$CURRENT_REPOSITORY.git || (echo -e "${RED}Failed to clone repository...${NC}" && exit 1)
	fi
	cd $CURRENT_REPOSITORY && \
	echo "REPO_DIR: $PWD"
	git config credential.helper store && \
	echo -e "${LIGHT_BLUE}git rebase...${NC}" && \
	git pull --rebase origin master && \
	echo -e "${LIGHT_BLUE}Getting last git tag...${NC}" && \
	LOG_DIFF="" && \
	CURRENT_TAG=$(git describe --tags --abbrev=0)
	if [ "$?" -eq 0 ];
	then
		last_commit=$(git log -n 1 --oneline HEAD  | cut -f 1 -d' ') && \
		tag_commit=$(git rev-list -n 1 ${CURRENT_TAG} --oneline | cut -f 1 -d' ') && \
		if [ $last_commit == $tag_commit ]
		then
			echo -e "${YELLOW}Tag ${CURRENT_TAG} have the last commit $last_commit...${NC}"
			cd $git_tag_gen_path;
			continue
		else
			echo -e "${LIGHT_BLUE}Current tag: ${CURRENT_TAG}${NC}" && \
			IFS='.' read -ra CURRENT_TAG_ARRAY <<< "${CURRENT_TAG}" && \
			CURRENT_TAG_ARRAY_LEN=$(expr ${#CURRENT_TAG_ARRAY[@]} - 1) && \
			NEW_TAG="" && \
			for (( i=0; i<${CURRENT_TAG_ARRAY_LEN}; i++ ));
			do
			  NEW_TAG="${NEW_TAG}${CURRENT_TAG_ARRAY[$i]}."
			done
			echo -e "${LIGHT_CYAN}Increment patch version...${NC}" && \
			NEW_TAG="${NEW_TAG}$(expr ${CURRENT_TAG_ARRAY[${CURRENT_TAG_ARRAY_LEN}]} + 1)" && \
			echo ${NEW_TAG} && \
			LOG_DIFF="${CURRENT_TAG}..HEAD"
		fi
	else
		echo -e "${LIGHT_CYAN}No version found...${NC}" && \
		echo -e "${LIGHT_CYAN}Setting DEFAULT_TAG value...${NC}" && \
		NEW_TAG="$DEFAULT_TAG" && \
		echo ${NEW_TAG}
	fi
	echo -e "${LIGHT_BLUE}Getting commit messages...${NC}" && \
	git log $LOG_DIFF --oneline | grep -v "@" | grep "#" | grep -v "Merge" | tr -s '[:space:]' | cut -c 9- > tag_message.txt && \
	echo -e "${LIGHT_BLUE}Creating git tag...${NC}" && \
	git tag -a $NEW_TAG -F tag_message.txt && \
	git push origin $NEW_TAG && \
	echo -e "${CYAN}Removing tag_message file...${NC}" && \
	rm tag_message.txt && \
	cd $git_tag_gen_path
done
exit 0