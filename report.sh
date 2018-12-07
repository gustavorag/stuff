http \
  --verify=no \
  get \
  https://zixc1s4.strongport.com:8443/zixcorp/report/export \
  from==06/01/2018 \
  to==06/30/2018 \
  domains== \
  reportId==18 \
  renderingType==CSV \
  Cookie:JSESSIONID=secretfromlogin
