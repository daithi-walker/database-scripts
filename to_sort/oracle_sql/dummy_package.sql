create or replace package xxdwtest
as
   procedure xxdwtest(p_errbuf           out varchar2
                     ,p_retcode          out number
                     ); 
   procedure xxdwtest1(p_errbuf           out varchar2
                     ,p_retcode          out number
                     );    
end xxdwtest;
/

create or replace package body xxdwtest
as
   procedure xxdwtest(p_errbuf           out varchar2
                     ,p_retcode          out number
                     )
   is
   begin
      fnd_file.put_line (apps.fnd_file.log, 'hello world');
   end xxdwtest;
  
   procedure xxdwtest1(p_errbuf           out varchar2
                     ,p_retcode          out number
                     )
   is
      v_request_id            number        := 0;
      cnt  number;
   begin
      for cnt in 1..4000
      loop
         v_request_id := fnd_request.submit_request(application   => ''
                                                   ,program       => ''
                                                   ,description   => 'TEST-'||cnt
                                                   ,start_time    => sysdate
                                                   ,sub_request   => null
                                                   );
         fnd_file.put_line (apps.fnd_file.log, 'loop: '||cnt||'...v_request_id: '||v_request_id);
      end loop;
      commit;
   end xxdwtest1;

end xxdwtest; 
/