http \
  --verify=no \
  --form \
  post \
  https://zixc1s4.strongport.com:8443/zixcorp/j_spring_security_check \
  j_username=brandon \
  j_password=`lpass show --password exm/zix/c7s4` \
  _action_Sign+In='Sign+In'
