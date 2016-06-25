DECLARE
  ObjList dbms_stats.ObjectTab;
BEGIN
  dbms_output.enable(1000000);
  --DBMS_STATS.GATHER_SCHEMA_STATS(ownname=>'APPS', objlist=>ObjList, options=>'LIST STALE');
  --DBMS_STATS.GATHER_DATABASE_STATS(objlist=>ObjList, options=>'LIST STALE');
  DBMS_STATS.GATHER_DATABASE_STATS(objlist=>ObjList, options=>'LIST EMPTY');
  FOR i in ObjList.FIRST..ObjList.LAST
  LOOP
    dbms_output.put_line(ObjList(i).ownname || '.' || ObjList(i).ObjName || ' - ' || ObjList(i).ObjType || ' - ' || ObjList(i).partname);
  END LOOP;
END;