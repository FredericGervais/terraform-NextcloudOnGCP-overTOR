

DATA=$(./eschalot/eschalot -r '^STRING')
HOSTNAME=$(echo "$DATA" | sed -n 2p)
PRIVATEKEY=$(echo "$DATA" | tail -n +3)
jq -n --arg hostname "$HOSTNAME" --arg privatekey "$PRIVATEKEY" '{hostname:$hostname,privatekey:$privatekey}'


