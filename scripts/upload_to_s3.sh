BUCKET=olist-raw-2026
LOAD_DATE=2026-09-22

for f in *.csv; do
  t=${f#olist_}; t=${t%_dataset.csv}; t=${t%.csv}
  aws s3 cp "$f" "s3://$BUCKET/raw/olist/$t/load_date=$LOAD_DATE/$f"
done