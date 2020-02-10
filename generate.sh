

if [ "$1" == "generate_private_key" ]; then
  STRING="$2"
  DATA=$(./eschalot/eschalot -r "^$STRING")
  HOSTNAME=$(echo "$DATA" | sed -n 2p)
  PRIVATEKEY=$(echo "$DATA" | tail -n +3)
  jq -n --arg hostname "$HOSTNAME" --arg privatekey "$PRIVATEKEY" '{hostname:$hostname,privatekey:$privatekey}'
else
  DOMAIN=$(echo $2 | sed -e 's/\.0.*/\.*/')
  jq -n --arg domain "$DOMAIN" '{domain:$domain}'
fi