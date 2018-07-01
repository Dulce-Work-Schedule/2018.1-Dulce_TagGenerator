USER_CREDENTIALS="eliseuegewarth:90121994eliseue5"
DOMAINS=("Dulce-Work-Schedule" "interlegis")
for DOMAIN in ${DOMAINS[@]}; do
	CURRENT_URL="https://api.github.com/orgs/${DOMAIN}/repos"
	repos=$(curl --user $USER_CREDENTIALS --include --request GET $CURRENT_URL | grep full_name | cut -f 2 -d':' | cut -f 2 -d'"' | cut -f 1 -d'"');
	for CURRENT_REPOSITORY in ${repos[@]}; do
			echo $CURRENT_REPOSITORY;
	done;
done;

USER_CREDENTIALS="eliseuegewarth:90121994eliseue5"
CURRENT_URL="https://api.github.com/orgs/${DOMAIN}/repos"
DOMAIN="Dulce-Work-Schedule"
curl --user $USER_CREDENTIALS --include --request GET $CURRENT_URL | grep "rel=\"last\"" | cut -f 1 -d'>'
