CREATE OR REPLACE FUNCTION form_url_encode (
   data    IN VARCHAR2
   )
RETURN VARCHAR2
AS 
BEGIN 
  RETURN utl_url.escape(data, TRUE); -- note use of TRUE
END;

select form_url_encode(v_url) from 
(select 'Is the use of the "$" sign okay?' v_url from dual
union all
select 'http://www.acme.com/a url with space.html' from dual
union all
select 'http://www.acme.com/check$ampersand' from dual
);

CREATE OR REPLACE FUNCTION form_url_decode(
   data    IN VARCHAR2
   )
RETURN VARCHAR2
AS
BEGIN 
  RETURN utl_url.unescape(
     replace(data, '+', ' ')); 
END;

select form_url_decode(v_url) from 
(select 'Is%20the%20use%20of%20the%20%22%24%22%20sign%20okay%3F' v_url from dual
union all
select 'http%3A%2F%2Fwww.acme.com%2Fa%20url%20with%20space.html' from dual
union all
select 'http%3A%2F%2Fwww.acme.com%2Fcheck%24ampersand' from dual
);