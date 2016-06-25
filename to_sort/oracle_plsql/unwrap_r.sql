create or replace procedure unwrap_r(aname varchar2)
is
    	root sys.pidl.ptnod;
    	status   sys.pidl.ub4;
      loc number;
	--
    	procedure recurse (n sys.pidl.ptnod) is
	--
    		seq sys.pidl.ptseqnd;
		len integer;
    	--
    	begin

    		--
		--dbms_output.put_line('Node :'||n);
		--dbms_output.put_line('code (DEC) :'||pidl.ptkin(n));
		--dbms_output.put_line('Node Type :'||pidl.ptattnnm(pidl.ptkin(n)));
		--dbms_output.put_line('--');    		
      loc := 100;
         dbms_output.put_line(pidl.ptkin(n));
    		if(pidl.ptkin(n) = diana.d_comp_u) then
         loc := 110;
    			recurse(diana.a_unit_b(n));
    		elsif (pidl.ptkin(n) = diana.d_s_body) then
         loc := 120;
			dbms_output.put_line('CREATE OR REPLACE ');
         loc := 130;
			recurse(diana.a_d_(n));
         loc := 140;
			recurse(diana.a_header(n));
         loc := 150;
			recurse(diana.a_block_(n));
         loc := 160;
			dbms_output.put_line('END;');
			dbms_output.put_line('/');
    		elsif(pidl.ptkin(n) = diana.di_proc) then
         loc := 190;
			dbms_output.put_line('PROCEDURE '||diana.l_symrep(n));
    		elsif(pidl.ptkin(n) = diana.d_p_) then
         loc := 200;
    			recurse(diana.as_p_(n));
    		elsif(pidl.ptkin(n) = diana.ds_param) then
         loc := 210;
    			-- not implemented
    			null;
    		elsif(pidl.ptkin(n) = diana.d_block) then
         loc := 220;
    			dbms_output.put_line('IS ');
            loc := 230;
    			recurse(diana.as_item(n));
    			dbms_output.put_line('BEGIN');
            loc := 240;
    			recurse(diana.as_stm(n));
            loc := 250;
    			recurse(diana.as_alter(n));
    		elsif(pidl.ptkin(n) = diana.ds_item) then
         loc := 260;
    			-- not implemented
    			null;
    		elsif(pidl.ptkin(n) = diana.ds_stm) then
         loc := 270;
			seq := diana.as_list(n);
         loc := 280;
			len := pidl.ptslen(seq) - 1;
         loc := 290;
			for i in 0..len loop
         loc := 300;
				recurse(pidl.ptgend(seq,i));
			end loop;
         loc := 310;
    		elsif(pidl.ptkin(n) = diana.d_null_s) then
         loc := 320;
    			dbms_output.put_line('NULL;');
    		elsif(pidl.ptkin(n) = diana.ds_alter) then
         loc := 330;
    			-- not implemented
    			null;
    		else
         loc := 340;
    			dbms_output.put_line('****ERROR*****');
    		end if;
    		--
    	end recurse;
    	--
begin

   loc := 10;
	dbms_output.put_line('Start up');
   loc := 20;
	sys.diutil.get_diana(
		aname, NULL, NULL,
		NULL, status, root,
		1);
	
   loc := 30;
	if (status <> sys.diutil.s_ok) then
      loc := 40;
		sys.dbms_output.put_line('Error: couldn''t find diana; status:  ' ||
                           to_char(status));
		raise sys.diutil.e_subpNotFound;
	end if;
	-- 
	-- recurse through the DIANA nodes
	--
   loc := 50;
	recurse(root);
	--
end unwrap_r;
/ 