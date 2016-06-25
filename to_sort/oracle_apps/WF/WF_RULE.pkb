create or replace package body WF_RULE as
/* $Header: wfruleb.pls 115.30 2006/02/17 03:25:40 smayze ship $ */
--------------------------------------------------------------------------
/*
** get_sub_parameters (PRIVATE) - retrieve the value of the PARAMETERS
**                                column from the wf_event_subscriptions
**                                table for the specified guid
*/
FUNCTION get_sub_parameters(p_subscription_guid in raw) return varchar2
is
  parm varchar2(4000);
begin
  select parameters into parm
  from   wf_event_subscriptions
  where  guid = p_subscription_guid;

  return parm;
exception
  when no_data_found then
    wf_core.context('Wf_Rule', 'get_sub_parameters', p_subscription_guid);
    wf_core.raise('WFE_SUBSC_NOTEXIST');
end;
--------------------------------------------------------------------------
/*
** log - <Described in wfrules.pls>
*/
FUNCTION log(p_subscription_guid in     raw,
             p_event             in out nocopy wf_event_t) return varchar2
is
  i                     number;
  parmlist              wf_parameter_list_t;
  srctype               varchar2(100);
  istmp                 number;
  myclob                clob;
  clob_len              number;
  clob_bufsize constant number := 240; -- using 240 instead of larger number
                                       -- so dbms_output.putline-version of
                                       -- logging for standalone version
                                       -- works ok
  offset                number;

begin
  wf_log_pkg.string(wf_log_pkg.level_procedure, 'wf.plsql.wf_rule.log.begin',
                    'Begin wf_rule.log rule function');

  if (p_event is null) then
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.event_null',
                      'Event is null. Returning.');
    return 'SUCCESS';
  end if;

  -- Reimplementation with wf_log_pkg

  if (p_event.getFromAgent() is not null) then
    -- Log message only
    -- BINDVAR_SCAN_IGNORE[2]
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.from_agent',
                      'From Agent Name: '||p_event.getFromAgent().getName());
    -- BINDVAR_SCAN_IGNORE[2]
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.from_agent.from_agent_sys',
                      'From Agent System: '||p_event.getFromAgent().getSystem());
  end if;

  if (p_event.getToAgent() is not null) then
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.to_agent',
                      'To Agent Name: '||p_event.getToAgent().getName());
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.to_agent_sys',
                      'To Agent System: '||p_event.getToAgent().getSystem());
  end if;

  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.priority',
                   'Priority: '||p_event.getPriority());
  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.send_date',
                   'Send Date: '||to_char(p_event.getSendDate(), wf_core.canonical_date_mask));
  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.receive_date',
                   'Receive Date: '||to_char(p_event.getReceiveDate(), wf_core.canonical_date_mask));
  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.corr_id',
                   'Correlation ID: '||p_event.getCorrelationID());

  parmlist := p_event.getParameterList();
  if (parmlist is not null) then
    i := parmlist.FIRST;
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.param_list',
                     'Begin Parameterlist');

    while (i <= parmlist.LAST) loop
      wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.param',
                       'Name: '||parmlist(i).getName()||' Value: '||parmlist(i).getValue());

      i := parmlist.NEXT(i);
    end loop;
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.param_list',
                     'End Parameterlist');
  end if;

  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.event_name',
                   'Event Name: '||p_event.getEventName());
  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.event_key',
                   'Event Key: '||p_event.getEventKey());

  select source_type into srctype from wf_event_subscriptions
  where guid = p_subscription_guid;

  -- Need to check if clob is temporary instead of null
  IsTmp := dbms_lob.istemporary(p_event.GetEventData());
  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.istemp',
                   'Event Data is Temp: '||IsTmp);
  if ((IsTmp= 1 and srctype = 'LOCAL')
  or (IsTmp= 0 and srctype in ('EXTERNAL','ERROR'))) then
    wf_log_pkg.string(wf_log_pkg.level_statement,
    			'wf.plsql.wf_rule.log.event_data', 'Begin EventData');
    myclob := p_event.getEventData();
    if myclob is not null then
      offset := 1;
      clob_len := dbms_lob.getlength(myclob);
      while( offset <= clob_len ) loop
        wf_log_pkg.string( wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.message',
          dbms_lob.substr( myclob, clob_bufsize, offset ));
        offset := offset + clob_bufsize;
      end loop;
    end if;
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.event_data', 'End EventData');
  else
    wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.event_data', 'Event Data is Empty');
  end if;

  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.error_sub',
                   'Error Subscription: '||p_event.getErrorSubscription());
  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.error_msg',
                   'Error Message: '||p_event.getErrorMessage());
  wf_log_pkg.string(wf_log_pkg.level_statement, 'wf.plsql.wf_rule.log.error_stk',
                   'Error Stack: '||p_event.getErrorStack());

  wf_log_pkg.string(wf_log_pkg.level_procedure, 'wf.plsql.wf_rule.log.end',
                   'Completed wf_rule.log rule function');

  return 'SUCCESS';
exception
  when others then
    wf_log_pkg.string(wf_log_pkg.level_error, 'wf.plsql.wf_rule.log.end',
                     'Error in wf_rule.log rule function');
    wf_core.context('Wf_Event', 'Log', p_event.getEventName(), p_subscription_guid);
    wf_event.setErrorInfo(p_event, 'ERROR');
    return 'ERROR';
end;
---------------------------------------------------------------------------
/*
** error - <described in wfrules.pls>
*/
FUNCTION error(p_subscription_guid in     raw,
               p_event             in out nocopy wf_event_t) return varchar2
is
  msg varchar2(4000);
  l_parameters varchar2(4000);
begin
  l_parameters := upper(wf_rule.get_sub_parameters(p_subscription_guid));
  msg := WF_EVENT_FUNCTIONS_PKG.SUBSCRIPTIONPARAMETERS(l_parameters, 'ERROR_MESSAGE');
  wf_event.setErrorInfo(p_event, 'ERROR');
  p_event.setErrorMessage(wf_core.substitute('WFERR', msg));

  return 'ERROR';
end;
---------------------------------------------------------------------------
/*
** warning - <described in wfrules.pls>
*/
FUNCTION warning(p_subscription_guid in     raw,
                 p_event             in out nocopy wf_event_t) return varchar2
is
  msg varchar2(4000);
  l_parameters varchar2(4000);
begin
  l_parameters := upper(wf_rule.get_sub_parameters(p_subscription_guid));
  msg := WF_EVENT_FUNCTIONS_PKG.SUBSCRIPTIONPARAMETERS(l_parameters, 'ERROR_MESSAGE');
  wf_event.setErrorInfo(p_event, 'WARNING');
  p_event.setErrorMessage(wf_core.substitute('WFERR', msg));

  return 'WARNING';
end;
---------------------------------------------------------------------------
/*
** success - <described in wfrules.pls>
*/
FUNCTION success(p_subscription_guid in     raw,
                 p_event             in out nocopy wf_event_t) return varchar2
is
begin
  return 'SUCCESS';
end;
---------------------------------------------------------------------------
/*
** default_rule - <described in wfrules.pls>
*/
FUNCTION default_rule(p_subscription_guid in     raw,
                      p_event             in out nocopy wf_event_t) return varchar2
is
  out_guid  raw(16);
  to_guid   raw(16);
  wftype    varchar2(30);
  wfname    varchar2(30);
  res       varchar2(30);
  pri       number;
  ikey      varchar2(240);
  lparamlist wf_parameter_list_t;
  subparams varchar2(4000);
  lcorrid   varchar2(240);

  --Define an exception to capture the resource_busy error
  resource_busy exception;
  pragma EXCEPTION_INIT(resource_busy,-00054);


begin
  select out_agent_guid,to_agent_guid,wf_process_type,wf_process_name,priority
         , parameters
  into   out_guid, to_guid, wftype, wfname, pri, subparams
  from   wf_event_subscriptions
  where  guid = p_subscription_guid;

  -- Check if need to generate Unique Correlation Id
  if subparams is not null then
    if (wf_event_functions_pkg.subscriptionparameters(p_string=>subparams
                        ,p_key=>'CORRELATION_ID') = 'UNIQUE') then
      select wf_error_processes_s.nextval
      into lcorrid
      from dual;

      lcorrid := p_event.event_key||'-'||lcorrid;
      p_event.SetCorrelationId(lcorrid);
    end if;
  end if;

  -- Workflow --
  if (wftype is not null) then

    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(wf_log_pkg.level_statement,
                        'wf.plsql.WF_RULE.default_rule.event',
                        'Calling wf_engine.event()');
    end if;

    lparamlist := p_event.Parameter_List;
    wf_event.AddParameterToList('SUB_GUID', p_subscription_guid,lparamlist);
    p_event.Parameter_List := lparamlist;
    --p_event.addParameterToList('SUB_GUID', p_subscription_guid);

    if (wftype = 'WFERROR') then
      select to_char(WF_ERROR_PROCESSES_S.nextval) into ikey from dual;
    else
      ikey := nvl(p_event.Correlation_ID, p_event.Event_Key);
    end if;

    --The resource busy exception will be raised by wf_engine.event
    --and caught in the exception block.
    wf_engine.event(
       itemtype      => wftype,
       itemkey       => ikey,
       process_name  => wfname,
       event_message => p_event);
  end if;

  -- Route --
  /** single consumer queues do not need a To Agent  **/
  -- if (to_guid is not null) then
  if (out_guid is not null) then
    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(wf_log_pkg.level_statement,
                        'wf.plsql.WF_RULE.default_rule.route',
                        'Routing...');
    end if;

    p_event.From_Agent := wf_event.newAgent(out_guid);
    p_event.To_Agent := wf_event.newAgent(to_guid);
    p_event.Priority := pri;
    p_event.Send_Date := nvl(p_event.getSendDate(),sysdate);

    --p_event.Address(wf_event.newAgent(out_guid), wf_event.newAgent(to_guid),
    --                pri, nvl(p_event.getSendDate(),sysdate));

    wf_event.send(p_event);
  end if;

  -- Debug --
  if (wf_log_pkg.wf_debug_flag = TRUE) then
    begin
      res := wf_rule.log(p_subscription_guid, p_event);
    exception
      when others then null;
    end;
  end if;

  return 'SUCCESS';
exception
  --This exception alone raise to caller
  when resource_busy then
    --Raise this exception to caller
    raise;

  when others then
    wf_core.context('Wf_Rule', 'Default_Rule', p_event.getEventName(),
                                                p_subscription_guid);
    wf_event.setErrorInfo(p_event, 'ERROR');
    return 'ERROR';
end;

---------------------------------------------------------------------------
/*
** default_rule2 - Executes default_rule only if the subscription contains
**                 parameters that are in the event parameter list.
*/
FUNCTION default_rule2(p_subscription_guid in     raw,
                       p_event             in out nocopy wf_event_t)
         return varchar2 is
begin
  if (WF_EVENT_FUNCTIONS_PKG.SubParamInEvent(p_subscription_guid, p_event)) then
    return (default_rule(p_subscription_guid, p_event));

  else
    return 'SUCCESS';

  end if;

end;

---------------------------------------------------------------------------
/*
** workflow_protocol - <described in wfrules.pls>
*/
FUNCTION workflow_protocol(p_subscription_guid in     raw,
                      p_event             in out nocopy wf_event_t) return varchar2
is
  wftype    varchar2(30);
  wfname    varchar2(30);
  param	    varchar2(4000);
  res       varchar2(30);
  pri       number;
  ikey      varchar2(240);
  ackreq    varchar2(1);
  sndack    varchar2(1);
begin

  select wf_process_type,wf_process_name,priority,parameters
  into   wftype, wfname, pri, param
  from   wf_event_subscriptions
  where  guid = p_subscription_guid;

  -- Workflow --
  if (wftype is not null) then
    if (wf_log_pkg.level_procedure >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(wf_log_pkg.level_procedure,
                        'wf.plsql.WF_RULE.workflow_protocol.event',
                        'Calling wf_engine.event()');
    end if;
    --
    -- Add Parameters to List
    --
    ackreq := p_event.GetValueForParameter('ACKREQ');
    sndack := p_event.GetValueForParameter('SNDACK');

    if ackreq = 'Y' then
      -- The Received Message will be waiting for acknowledgement
      sndack := 'Y';
    else
      sndack := 'N';
    end if;

    -- Does the new message require acknowledgement
    ackreq := wf_event_functions_pkg.subscriptionparameters
					(param, 'ACKREQ');

    p_event.addParameterToList('ACKREQ', nvl(ackreq,'N'));
    p_event.addParameterToList('SNDACK', nvl(sndack,'N'));
    p_event.addParameterToList('SUB_GUID', p_subscription_guid);

    if (wftype = 'WFERROR') then
      select to_char(WF_ERROR_PROCESSES_S.nextval) into ikey from dual;
    else
      ikey := nvl(p_event.getCorrelationID(), p_event.getEventKey());
    end if;

    wf_engine.event(
       itemtype      => wftype,
       itemkey       => ikey,
       process_name  => wfname,
       event_message => p_event);
  end if;

  -- Debug --
  if (wf_log_pkg.wf_debug_flag = TRUE) then
    res := wf_rule.log(p_subscription_guid, p_event);
  end if;

  return 'SUCCESS';
exception
  when others then
    wf_core.context('Wf_Rule', 'Workflow_Protocol', p_event.getEventName(),
                                                p_subscription_guid);
    wf_event.setErrorInfo(p_event, 'ERROR');
    return 'ERROR';
end;
---------------------------------------------------------------------------
/*
** error_rule - <described in wfrules.pls>
*/
FUNCTION error_rule(p_subscription_guid in     raw,
                    p_event          in out nocopy wf_event_t) return varchar2
is
  out_guid  raw(16);
  to_guid   raw(16);
  wftype    varchar2(30);
  wfname    varchar2(30);
  res       varchar2(30);
  pri       number;
  ikey      varchar2(240);
begin
  select out_agent_guid,to_agent_guid,wf_process_type,wf_process_name,priority
  into   out_guid, to_guid, wftype, wfname, pri
  from   wf_event_subscriptions
  where  guid = p_subscription_guid;

  -- Workflow --
  if (wftype is not null) then
    if (wf_log_pkg.level_procedure >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(wf_log_pkg.level_procedure,
                        'wf.plsql.WF_RULE.error_rule.event',
                        'Calling wf_engine.event()');
    end if;

    p_event.addParameterToList('SUB_GUID', p_subscription_guid);

    if (wftype = 'WFERROR') then
      select to_char(WF_ERROR_PROCESSES_S.nextval) into ikey from dual;
    else
      ikey := nvl(p_event.getCorrelationID(), p_event.getEventKey());
    end if;

    wf_engine.event(
       itemtype      => wftype,
       itemkey       => ikey,
       process_name  => wfname,
       event_message => p_event);
  end if;

  -- Route --
  /** single consumer queues do not need a To Agent  **/
  -- if (to_guid is not null) then
  if (out_guid is not null) then
    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(wf_log_pkg.level_statement,
                        'wf.plsql.WF_RULE.error_rule.route',
                        'Routing...');
    end if;
    p_event.From_Agent := wf_event.newAgent(out_guid);
    p_event.To_Agent := wf_event.newAgent(to_guid);
    p_event.Priority := pri;
    p_event.Send_Date := nvl(p_event.getSendDate(),sysdate);

    --p_event.Address(wf_event.newAgent(out_guid), wf_event.newAgent(to_guid),
    --                pri, nvl(p_event.getSendDate(),sysdate));

    wf_event.send(p_event);
  end if;


  -- Debug --
  if (wf_log_pkg.wf_debug_flag = TRUE) then
    begin
      res := wf_rule.log(p_subscription_guid, p_event);
    exception
      when others then null;
    end;
  end if;

  return 'SUCCESS';
exception
  when others then
    wf_core.context('Wf_Rule', 'Error_Rule', p_event.getEventName(),
                                                p_subscription_guid);
    raise;
end;
----------------------------------------------------------------------------
/*
** setParametersIntoParameterList - <described in wfrules.pls>
**
*/
FUNCTION setParametersIntoParameterList(p_subscription_guid in     raw,
                           p_event          in out nocopy wf_event_t) return varchar2
is
  l_parameters    varchar2(4000);
  l_start         integer := 0;
  l_end           integer := 0;
  l_endposition   number;
  l_namevalue     varchar2(4000);
  l_value         varchar2(4000);
  l_name          varchar2(4000);
  l_equalpos      number;

  CURSOR  c_parameters IS
  SELECT  parameters
  FROM    wf_event_subscriptions
  WHERE   guid = p_subscription_guid;

begin

  -- Get the Subscription Parameter String
  OPEN c_parameters;
  FETCH c_parameters INTO l_parameters;
  CLOSE c_parameters;

  -- If not null then continue
  if l_parameters is not null then
    -- Replace New Line, tab and CR Characters
    l_parameters := replace(l_parameters,wf_core.newline,' ');
    l_parameters := replace(l_parameters,wf_core.tab,' ');
    l_parameters := replace(l_parameters,wf_core.cr,'');
    l_parameters := l_parameters||' ';

    -- Initialize Start and End
    l_start:= 1;
    l_end := length(l_parameters);
    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(wf_log_pkg.level_statement,
                        'wf.plsql.WF_RULE.setparametersintoparameterlist.params',
                        'Length of Parameters is '||l_end);
    end if;

    while l_start < l_end loop
      if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
         wf_log_pkg.string(wf_log_pkg.level_statement,
                          'wf.plsql.WF_RULE.setparametersintoparameterlist.st_pos',
                          'Start Position is:'||l_start);
      end if;
      -- Get End of Name=Value pair
      l_endposition := instr(l_parameters, ' ', l_start, 1);

      if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
         wf_log_pkg.string(wf_log_pkg.level_statement,
                          'wf.plsql.WF_RULE.setparametersintoparameterlist.end_pos',
                          'EndPosition of Name=Value Pair: '||l_endposition);
      end if;

      -- Extract Name=Value Pair
      l_namevalue := rtrim(ltrim(substr(l_parameters, l_start, l_endposition-l_start)));

      if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
         wf_log_pkg.string(wf_log_pkg.level_statement,
                          'wf.plsql.WF_RULE.setparametersintoparameterlist.namevalue',
                          'Name=Value Pair is:'||l_namevalue);
      end if;

      -- Extract Name part of Name=Value pair
      l_equalpos := instr(l_namevalue, '=', 1, 1);
      l_name := substr(l_namevalue,1,l_equalpos-1);
      if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
         wf_log_pkg.string(wf_log_pkg.level_statement,
                          'wf.plsql.WF_RULE.setparametersintoparameterlist.paramname',
                          'Parameter Name='||l_name);
      end if;

      -- Extract Value part of Name=Value pair
      l_value := substr(l_namevalue,l_equalpos+1,length(l_namevalue));
      if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
          wf_log_pkg.string(wf_log_pkg.level_statement,
                           'wf.plsql.WF_RULE.setparametersintoparameterlist.paramvalue',
                           'Parameter Value='||l_value);
      end if;

      -- OK, Set the Value into the Parameter List
      -- unless we are dealing with reserved words CORRELATION_ID, ITEMKEY
      -- in which case we will set these values into the Event Header
      -- properties
      if (l_name in ('CORRELATION_ID','ITEMKEY')) then
        p_event.SetCorrelationId(l_value);
      else
        p_event.AddParameterToList(l_name, l_value);
      end if;

      -- Reset Starting Point
      l_start := l_endposition+1;

    end loop;
  end if;

  return 'SUCCESS';
exception
  when others then
    wf_core.context('Wf_Rule', 'SetParametersIntoParameterList',
		p_event.getEventName(),p_subscription_guid);
    wf_event.setErrorInfo(p_event, 'ERROR');
    return 'ERROR';
end;

---------------------------------------------------------------------------
--Bug 2193561
--To provide better access to worklist by non-workflow products
FUNCTION SendNotification (p_subscription_guid in    raw,
                    p_event            in out nocopy wf_event_t)
return varchar2
is

  pos number := 1;
  l_nid number;
  l_message_type varchar2(8);
  l_message_name varchar2(30);
  l_recipient_role varchar2(320);
  l_callback varchar2(240);
  l_context varchar2(2000);
  l_send_comment varchar2(2000);
  l_priority number;
  l_due_date date;

  l_parameter_list wf_parameter_list_t;
  l_pname varchar2(30);
  l_pvalue varchar2(2000);
  l_result  varchar2(100);

begin
  --Bug 3520032
  --Call setParametersIntoParameterList to set the subscription
  --parameters into event parameterlist.
  l_result := setParametersIntoParameterList(p_subscription_guid,p_event);

  --If l_result returned is ERROR also give it a try in this
  --rule function assuming maybe it has an event parameterlist set

  l_parameter_list:= p_event.getParameterList();

  -- Get the WF_NOTIFICATION.SEND arguments
  pos := l_parameter_list.LAST;
  while(pos is not null) loop
    if (l_parameter_list(pos).getName() = 'RECIPIENT_ROLE') then
      l_recipient_role := l_parameter_list(pos).getValue();
    elsif (l_parameter_list(pos).getName() = 'MESSAGE_TYPE') then
      l_message_type := l_parameter_list(pos).getValue();
    elsif (l_parameter_list(pos).getName() = 'MESSAGE_NAME') then
      l_message_name := l_parameter_list(pos).getValue();
    elsif (l_parameter_list(pos).getName() = 'CALLBACK') then
      l_callback := l_parameter_list(pos).getValue();
    elsif (l_parameter_list(pos).getName() = 'CONTEXT') then
      l_context := l_parameter_list(pos).getValue();
    elsif (l_parameter_list(pos).getName() = 'SEND_COMMENT') then
      l_send_comment := l_parameter_list(pos).getValue();
    elsif (l_parameter_list(pos).getName() = 'PRIORITY') then
      l_priority := to_number(l_parameter_list(pos).getValue());
    elsif (l_parameter_list(pos).getName() = 'DUE_DATE') then
      l_due_date := to_date(l_parameter_list(pos).getValue(),'DD-MM-YYYY HH24:MI:SS');
    end if;
    pos := l_parameter_list.PRIOR(pos);
  end loop;
  l_nid:=wf_notification.send(
    ROLE         => l_recipient_role,
    MSG_TYPE     => l_message_type,
    MSG_NAME     => l_message_name,
    DUE_DATE     => l_due_date,
    CALLBACK     => l_callback,
    CONTEXT      => l_context,
    SEND_COMMENT => l_send_comment,
    PRIORITY     => l_priority);

  if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
     wf_log_pkg.string(wf_log_pkg.level_statement,
                      'wf.plsql.WF_RULE.SendNotification.nid',
                      'Nid:'||to_char(l_nid));
  end if;

  --Get the Text Notification Attributes
  pos := l_parameter_list.LAST;
  while(pos is not null) loop
    if (l_parameter_list(pos).getName() NOT IN
        ('RECIPIENT_ROLE','MESSAGE_TYPE','MESSAGE_NAME','CALLBACK',
        'CONTEXT','SEND_COMMENT','PRIORITY','DUE_DATE')) then
        wf_notification.setAttrText ( NID=>l_nid ,
            ANAME=>l_parameter_list(pos).getName(),
            AVALUE=>l_parameter_list(pos).getValue());
    end if;
    pos := l_parameter_list.PRIOR(pos);
  end loop;

  --Insert the notification id into the parameter list
  p_event.Addparametertolist('#NID',l_nid);

  wf_notification.denormalize_notification(l_nid);
  return 'SUCCESS';
exception
  when others then
    wf_core.context('Wf_Notification', 'Send_Rule', p_event.getEventName(),
                                                p_subscription_guid);
    wf_event.setErrorInfo(p_event, 'ERROR');
    return 'ERROR';
end;

---------------------------------------------------------------------
--Bug 2786192
/*
**
This rule function sets the parameterlist for the
the event from the subscription parameter list and subsequently
calls the default rule to execute the default processing
**
*/


FUNCTION default_rule3(p_subscription_guid in     raw,
                      p_event             in out nocopy wf_event_t)
return varchar2 is
 l_result varchar2(30);

begin
 l_result := setParametersIntoParameterList(p_subscription_guid,p_event);
 return (default_rule(p_subscription_guid, p_event));
end;

/* Bug 2472743
This rule function can be used to restart multiple Workflow process waiting
for this event (or a null event) where the event activity has item attribute
named #BUSINESS_KEY which has the specified value.
*/

FUNCTION instance_default_rule(p_subscription_guid in    raw,
                               p_event     in out nocopy wf_event_t)
return varchar2
is
  out_guid  raw(16);
  to_guid   raw(16);
  wftype    varchar2(30);
  wfname    varchar2(30);
  res       varchar2(30);
  pri       number;
  ikey      varchar2(240);
  lparamlist wf_parameter_list_t;
  subparams varchar2(4000);
  lcorrid   varchar2(240);
  l_result varchar2(30);
  --Define an exception to capture the resource_busy error
  resource_busy exception;
  pragma EXCEPTION_INIT(resource_busy,-00054);

begin

  select out_agent_guid,to_agent_guid,wf_process_type,wf_process_name,priority
         , parameters
  into   out_guid, to_guid, wftype, wfname, pri, subparams
  from   wf_event_subscriptions
  where  guid = p_subscription_guid;

  l_result := setParametersIntoParameterList(p_subscription_guid,p_event);

  --The resource busy exception could be raise here
  wf_engine.event2(event_message => p_event);

  -- Route --
  /** single consumer queues do not need a To Agent  **/
  if (out_guid is not null) then
    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
       wf_log_pkg.string(wf_log_pkg.level_statement,
                        'wf.plsql.WF_RULE.instance_default_rule.route',
                        'Routing...');
    end if;
    p_event.From_Agent := wf_event.newAgent(out_guid);
    p_event.To_Agent := wf_event.newAgent(to_guid);
    p_event.Priority := pri;
    p_event.Send_Date := nvl(p_event.getSendDate(),sysdate);

    wf_event.send(p_event);
  end if;

  -- Debug --
  if (wf_log_pkg.wf_debug_flag = TRUE) then
    begin
      res := wf_rule.log(p_subscription_guid, p_event);
    exception
      when others then null;
    end;
  end if;

  return 'SUCCESS';
exception
  when resource_busy then
    --Raise the error to the caller to handle it
    raise;
  when others then
    wf_core.context('Wf_Rule', 'Instance_Default_Rule', p_event.getEventName(),
                                                p_subscription_guid);
    wf_event.setErrorInfo(p_event, 'ERROR');
    return 'ERROR';
end;

/*
** default_rule_or - Executes default_rule only if the subscription contains
**                 a parameter that is in the event parameter list.
*/
FUNCTION default_rule_or(p_subscription_guid in     raw,
                       p_event             in out nocopy wf_event_t)
         return varchar2 is
begin

  if (WF_EVENT_FUNCTIONS_PKG.SubParamInEvent(p_subscription_guid, p_event,'ANY')) then
    return (default_rule(p_subscription_guid, p_event));


  else
    return 'SUCCESS';

  end if;

end;

/*
** Default_Generate - This function is a generic event generation function
**                    that will generate an XML document based on the
**                    p_event_name, p_event_key and the p_parameter_list.
*/
function Default_Generate(p_event_name in varchar2,
                          p_event_key in varchar2,
                          p_parameter_list in wf_parameter_list_t)
   return clob
is
   doc CLOB;
   l_str varchar2(32000);
   generateTime varchar2(200);

   timeMask varchar2(100) := 'mm-dd-rr hh:mi:ss';

begin

   select to_char(sysdate, timeMask)
   into generateTime
   from sys.dual;

   dbms_lob.createTemporary(doc, true, DBMS_LOB.CALL);

   l_str := '<?xml version="1.0"?>'||wf_core.newLine;

   l_str := l_str||'<BUSINESSEVENT event-name="'||p_event_name||
            '" key="'||p_event_key||'">'||wf_core.newline;

   l_str := l_str||'<GENERATETIME mask="'||timeMask||'">'||'<![CDATA['||
            generateTime||']]></GENERATETIME>'||wf_core.newline;

   if p_parameter_list is not null and p_parameter_list.COUNT > 0 then
      l_str := l_str||'<PARAMETERS count="'||
                      trim(to_char(p_parameter_list.COUNT))||'">'||
                      wf_core.newline;

      -- Write out the buffer to date since the next section could be
      -- larger.
      dbms_lob.writeAppend(lob_loc => doc,
                           amount => length(l_str),
                           buffer => l_str);


      -- Loop through the parameter structure, outputting each parameter in turn.

      for p in 1..p_parameter_list.COUNT loop
         l_str := '<PARAMETER parameter-name="'||p_parameter_list(p).getName()||
                  '"><![CDATA['||p_parameter_list(p).getValue()||
                  ']]></PARAMETER>';
         dbms_lob.writeAppend(lob_loc => doc,
                              amount => length(l_str),
                              buffer => l_str);

      end loop;

      l_str := '</PARAMETERS>'||wf_core.newline;

   end if;

   l_str := l_str||'</BUSINESSEVENT>'||wf_core.newLine;

   dbms_lob.writeAppend(lob_loc => doc,
                        amount => length(l_str),
                        buffer => l_str);

   return doc;

exception
when others then
   wf_core.context('WF_RULE', 'Default_Generate', p_event_name, p_event_key);
   raise;
end Default_Generate;



end WF_RULE;
