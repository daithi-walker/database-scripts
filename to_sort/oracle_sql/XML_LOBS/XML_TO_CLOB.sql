select   XMLSerialize(document xml_doc as clob)
as       xmlserialize_doc
from     Table_name
where    1=1
and      <condition>