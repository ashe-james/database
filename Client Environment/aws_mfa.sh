if [ -z $1 ]; then
	echo "Enter One-Time Password:"
	read OTP
else
	OTP=$1
fi

#  Remove previous token from env and .bash_profile
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

sed -i.bu '/AWS_ACCESS_KEY_ID/d' ~/.bash_profile
sed -i.bu '/AWS_SECRET_ACCESS_KEY/d' ~/.bash_profile
sed -i.bu '/AWS_SESSION_TOKEN/d' ~/.bash_profile


#  Receive new token
TOKEN=$(aws sts get-session-token --serial-number arn:aws-us-gov:iam::725587987368:mfa/James.Ashe --token-code $OTP )

ACCESS=$(echo "$TOKEN" | sed -n 's!.*"AccessKeyId": "\(.*\)".*!\1!p')
SECRET=$(echo "$TOKEN" | sed -n 's!.*"SecretAccessKey": "\(.*\)".*!\1!p')
SESSION=$(echo "$TOKEN" | sed -n 's!.*"SessionToken": "\(.*\)".*!\1!p')
EXPIRE=$(echo "$TOKEN" | sed -n 's!.*"Expiration": "\(.*\)".*!\1!p')


#  Export new token to env and .bash_profile
export AWS_ACCESS_KEY_ID=$ACCESS
export AWS_SECRET_ACCESS_KEY=$SECRET
export AWS_SESSION_TOKEN=$SESSION

echo export AWS_ACCESS_KEY_ID=$ACCESS >> ~/.bash_profile
echo export AWS_SECRET_ACCESS_KEY=$SECRET >> ~/.bash_profile
echo export AWS_SESSION_TOKEN=$SESSION >> ~/.bash_profile


#  Output Result
if [[ -n "$ACCESS" && -n "$SECRET" && -n "$SESSION" ]]; then
	echo "New credentials obtained.  Expiration date: $EXPIRE"
else
	echo "Failed to obtain new credentials."
fi
