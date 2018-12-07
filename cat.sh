find \
    attachments/2018/ \
    -type f \
    -name 'mlogsort-06*' \
    -or -name 'mlogsort-0701*' \
  | grep -v -e 0601 -e zixc3 -e zixc4 -e zixc10 \
  | xargs -I{} tail -n+2 {} \
  | cat csv/columns.csv - \
  | sed '/^$/d' \
  | sed '/encode$/d' \
  | sed '/decode$/d' \
  | sed '/^ew2\\h\$$/d' \
  | sed "/UNKOWN_PFID/ s/|/\t/" \
  | sed 's/"//g' \
  | sed "s/'//g" \
