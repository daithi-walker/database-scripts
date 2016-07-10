for i in $(find /data/ds-olive-3/data/ds3/ -type f -name '700000001152516-campaign_conversions*2016-07*.csv.gz' -printf '%T@ %p\n' | sort | awk '{print $2}');
do
    ls -ltr $i;
    zcat $i \
    | grep -v dfaActions \
    | awk -F',' '{print $1,$4}' \
    | sort \
    | awk '{sum2[$1] += $2}; END{ for (dt in sum2) { print dt, sum2[dt] } }' \
    | sort;
done
