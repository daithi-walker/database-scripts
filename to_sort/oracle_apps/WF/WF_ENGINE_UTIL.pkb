create or replace package body WF_ENGINE_UTIL as
/* $Header: wfengb.pls 115.214 2009/03/12 10:07:44 sstomar ship $ */

type InstanceArrayTyp is table of pls_integer
index by binary_integer;
type TypeArrayTyp is table of varchar2(8)
index by binary_integer;
type NameArrayTyp is table of varchar2(30)
index by binary_integer;

--
-- Exception
--
no_savepoint exception;
bad_format   exception; --</rwunderl:2307104>

pragma EXCEPTION_INIT(no_savepoint, -1086);
pragma EXCEPTION_INIT(bad_format, -6502); --<rwunderl:2307104/>

--
-- Activity_Parent_Process globals
--   Globals used to cache values retrieved in activity_parent_process
--   for performance, to avoid fetching the same value many times.
-- NOTE: In SYNCHMODE, this stack must be the complete call stack
-- of subprocesses at all times.  In normal mode, the stack may or may
-- not be accurate, because
-- 1. calls for different items can be interwoven
-- 2. calls can jump anywhere on the process tree in some situations
--    (HandleError, etc).
-- ALWAYS check the key values before using values on the stack.
--

app_itemtype varchar2(8) := '';
app_itemkey  varchar2(240) := '';

app_level pls_integer := '';
app_parent_itemtype TypeArrayTyp;
app_parent_name NameArrayTyp;
app_parent_id InstanceArrayTyp;

-- Bug 3824367
-- Optimizing the code using a single cursor with binds
cursor curs_activityattr (c_actid NUMBER, c_aname VARCHAR2) is
select WAAV.PROCESS_ACTIVITY_ID, WAAV.NAME, WAAV.VALUE_TYPE,
       WAAV.TEXT_VALUE, WAAV.NUMBER_VALUE, WAAV.DATE_VALUE
from   WF_ACTIVITY_ATTR_VALUES WAAV
where  WAAV.PROCESS_ACTIVITY_ID = c_actid
and    WAAV.NAME = c_aname;

--
-- ClearCache
--   Clear runtime cache
procedure ClearCache
is
begin
  wf_engine_util.app_itemtype := '';
  wf_engine_util.app_itemkey := '';
  wf_engine_util.app_level := '';
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'ClearCache');
    raise;
end ClearCache;

--
-- AddProcessStack
--   Add a new subprocess to activity_parent_process call stack.
--   Called when a new (sub)process is entered.
-- IN
--   itemtype - item itemtype
--   itemkey - item itemkey
--   act_itemtype - activity itemtype of process
--   act_name - activity name of process
--   actid - instance id of process
--   rootflag - TRUE if this is the root process
--
procedure AddProcessStack(
  itemtype in varchar2,
  itemkey in varchar2,
  act_itemtype in varchar2,
  act_name in varchar2,
  actid in number,
  rootflag in boolean)
is
begin
  -- SYNCHMODE: Error if item doesn't match the cache, unless
  -- starting a new process.
  -- NOTE: Chance for an error here if you try to initiate a new process
  -- while a synch process is still running.  In that case you will
  -- should eventually get an error from app for the process 1
  -- because process 2 has trashed the stack.  Can't think of a way to
  -- detect the error directly here.
  if (itemkey = wf_engine.eng_synch) then
    if ((not rootflag) and
        ((nvl(wf_engine_util.app_itemtype, 'x') <> itemtype) or
         (nvl(wf_engine_util.app_itemkey, 'x') <> itemkey))) then
      Wf_Core.Token('ITEMTYPE', itemtype);
      Wf_Core.Token('ITEMKEY', itemkey);
      Wf_Core.Raise('WFENG_SYNCH_ITEM');
    end if;
  end if;

  -- If this is the root process, OR this is a different item,
  -- then re-initialize the stack.
  if ((rootflag) or
      (nvl(wf_engine_util.app_itemtype, 'x') <> itemtype) or
      (nvl(wf_engine_util.app_itemkey, 'x') <> itemkey)) then
    wf_engine_util.app_itemtype := itemtype;
    wf_engine_util.app_itemkey := itemkey;
    wf_engine_util.app_level := 0;
  end if;

  -- Add the process to the stack
  wf_engine_util.app_level := wf_engine_util.app_level + 1;
  wf_engine_util.app_parent_itemtype(wf_engine_util.app_level) := act_itemtype;
  wf_engine_util.app_parent_name(wf_engine_util.app_level) := act_name;
  wf_engine_util.app_parent_id(wf_engine_util.app_level) := actid;
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'AddProcessStack',
        itemtype, itemkey, act_itemtype, act_name, to_char(actid));
    raise;
end AddProcessStack;

--
-- RemoveProcessStack
--   Remove a process from the process stack.
--   Called when a (sub)process exits.
-- IN
--   itemtype - item type
--   itemkey - itemkey
--   actid - instance id of process just completed
--
procedure RemoveProcessStack(
  itemtype in varchar2,
  itemkey in varchar2,
  actid in number)
is
begin
  -- If this is the top process on the stack, pop it off.
  -- Must check if type/key/actid match, in case items and processes
  -- are being interwoven and this is not the correct stack.
  if (nvl(wf_engine_util.app_level, 0) > 0) then
    if ((wf_engine_util.app_itemtype = itemtype) and
        (wf_engine_util.app_itemkey = itemkey) and
        (wf_engine_util.app_parent_id(wf_engine_util.app_level) = actid)) then
      wf_engine_util.app_level := wf_engine_util.app_level - 1;
    end if;
  end if;
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'RemoveProcessStack', itemtype,
        itemkey, to_char(actid));
    raise;
end RemoveProcessStack;

--
-- Activity_Parent_Process (PRIVATE)
--   Get the activity's direct parent process.
-- IN
--   itemtype  - Item type
--   itemkey   - Item key
--   actid     - The activity instance id.
--
function activity_parent_process(
  itemtype in varchar2,
  itemkey in varchar2,
  actid in number)
return number
is
  parentid pls_integer;
  status   PLS_INTEGER;

begin
  -- Retrieve parent activity name
  WF_CACHE.GetProcessActivity(activity_parent_process.actid, status);

  if (status <> WF_CACHE.task_SUCCESS) then

    select WPA.PROCESS_ITEM_TYPE, WPA.PROCESS_NAME, WPA.PROCESS_VERSION,
           WPA.ACTIVITY_ITEM_TYPE, WPA.ACTIVITY_NAME, WPA.INSTANCE_ID,
           WPA.INSTANCE_LABEL, WPA.PERFORM_ROLE, WPA.PERFORM_ROLE_TYPE,
           WPA.START_END, WPA.DEFAULT_RESULT
    into   WF_CACHE.ProcessActivities(activity_parent_process.actid)
    from   WF_PROCESS_ACTIVITIES WPA
    where  WPA.INSTANCE_ID = activity_parent_process.actid;

  end if;

  -- Check the cached values in the call stack for a match, starting
  -- at the bottom.  If
  --   1. Itemtype and key
  --   2. Parent type and name
  -- are the same, then the parent id must be the same.
  -- Return it directly.
  if ((nvl(wf_engine_util.app_level, 0) > 0) and
      (itemtype = wf_engine_util.app_itemtype) and
      (itemkey = wf_engine_util.app_itemkey)) then
    for i in reverse 1 .. wf_engine_util.app_level loop
      if ((WF_CACHE.ProcessActivities(actid).PROCESS_ITEM_TYPE =
             wf_engine_util.app_parent_itemtype(i)) and
          (WF_CACHE.ProcessActivities(actid).PROCESS_NAME =
             wf_engine_util.app_parent_name(i))) then
        -- Found a match.
        return(wf_engine_util.app_parent_id(i));
      end if;
    end loop;
  end if;

  -- SYNCHMODE: If we don't have a match in the cache, then some restricted
  -- activity must have happened.  Raise an error.
  if (itemkey = wf_engine.eng_synch) then
    Wf_Core.Token('ITEMTYPE', itemtype);
    Wf_Core.Token('ITEMKEY', itemkey);
    Wf_Core.Raise('WFENG_SYNCH_ITEM');
  end if;

  -- If no match was found, then either
  --   1. Activity has a different parent process name
  --   2. This is a new item
  --   3. This is the first call to app
  -- In any case, join to WIAS to find an active instance for the
  -- parent process name.  Note there will be more than one instance
  -- matching the parent activity name because of:
  --   1. The same activity may be used in multiple processes,
  --      (even though the activity is used only once any particular
  --       process tree).
  --   2. Versions
  -- The join to active rows in WAIS for this item should choose
  -- exactly one of these.

  -- bug 1663684 - Added hint to choose a different driving table
  SELECT /*+ leading(wias) index(wias,WF_ITEM_ACTIVITY_STATUSES_PK) */
       WPA.INSTANCE_ID
  INTO parentid
  FROM WF_ITEM_ACTIVITY_STATUSES WIAS,
       WF_PROCESS_ACTIVITIES WPA
  WHERE WPA.ACTIVITY_ITEM_TYPE =
                             WF_CACHE.ProcessActivities(actid).PROCESS_ITEM_TYPE
  AND WPA.ACTIVITY_NAME = WF_CACHE.ProcessActivities(actid).PROCESS_NAME
  AND WPA.INSTANCE_ID = WIAS.PROCESS_ACTIVITY
  AND WIAS.ITEM_TYPE = activity_parent_process.itemtype
  AND WIAS.ITEM_KEY = activity_parent_process.itemkey;

  -- Re-initialize process stack, starting with the new value
  Wf_Engine_Util.AddProcessStack(itemtype, itemkey,
                         WF_CACHE.ProcessActivities(actid).PROCESS_ITEM_TYPE,
      WF_CACHE.ProcessActivities(actid).PROCESS_NAME, parentid, TRUE);

  return parentid;
exception
  when no_data_found then
    Wf_Core.Context('Wf_Engine_Util', 'Activity_Parent_Process',
        to_char(actid));
    Wf_Core.Token('ITEMTYPE', itemtype);
    Wf_Core.Token('ITEMKEY', itemkey);
    Wf_Core.Token('CHILDPROCESS', to_char(actid));
    Wf_Core.Token('FUNCTION', 'Activity_Parent_Process');
    Wf_Core.Raise('WFSQL_INTERNAL');
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Activity_Parent_Process',
        to_char(actid));
    raise;

end activity_parent_process;

--
-- Complete_Activity (PRIVATE)
--   Mark an activity complete (after checking post-notification function
--   if requested), then clean up and prepare to continue process:
--      - Kill any outstanding child activities
--      - Complete the parent process if this is an END activity
--      - Follow any transitions to further activities in process
-- IN
--   itemtype - A valid item type
--   itemkey - A string generated from the application object's primary key.
--   actid - The activity instance id.
--   result - The activity result.
--   runpntf - if TRUE then check the post-notification function before
--          completion
--
procedure complete_activity(itemtype in varchar2,
                            itemkey  in varchar2,
                            actid    in number,
                            result   in varchar2,
                            runpntf in boolean)
is
  -- Select all the transition activities for a given from activity
  -- and result
  cursor children (fromact pls_integer, fromact_result varchar2) is
    SELECT WAT1.FROM_PROCESS_ACTIVITY, WAT1.RESULT_CODE,
           WAT1.TO_PROCESS_ACTIVITY
    FROM WF_ACTIVITY_TRANSITIONS WAT1
    WHERE WAT1.FROM_PROCESS_ACTIVITY = fromact
    AND (WAT1.RESULT_CODE in (fromact_result, wf_engine.eng_trans_any)
         OR (WAT1.RESULT_CODE = wf_engine.eng_trans_default
             AND NOT EXISTS
                (SELECT NULL
                FROM WF_ACTIVITY_TRANSITIONS WAT2
                WHERE WAT2.FROM_PROCESS_ACTIVITY = fromact
                AND WAT2.RESULT_CODE = fromact_result)
            )
        );
  childarr InstanceArrayTyp;
  i pls_integer := 0;

  pntfstatus varchar2(8);     -- Status of post-notification function
  pntfresult varchar2(30);    -- Result of post-notification function
  lresult varchar2(30);       -- Local result buffer

  parent_status varchar2(8);  -- Status of parent activity

  actdate date;               -- Active date
  acttype varchar2(8);        -- Activity type

  notid pls_integer;          -- Notification id
  user varchar2(320);         -- Not. assigned user
  msgtype varchar2(8);        -- Not. message type
  msgname varchar2(30);       -- Not. messaage name
  priority number;            -- Not. priority
  duedate date;               -- Not. duedate
  not_status varchar2(8);     -- Not. status

  root varchar2(30);          -- Root process of activity
  version pls_integer;        -- Root process version
  rootid pls_integer;         -- Id of root process

  status  PLS_INTEGER;

--<rwunderl:2412971>
  TransitionCount pls_integer := 0;
  l_baseLnk       NUMBER;
  l_prevLnk       NUMBER;
  watIND          NUMBER;
  l_LinkCollision BOOLEAN;

begin
  actdate := Wf_Item.Active_Date(itemtype, itemkey);
  acttype := Wf_Activity.Instance_Type(actid, actdate);

  if (runpntf and (acttype = wf_engine.eng_notification)) then
    -- First execute possible post-notification function to see if activity
    -- should really complete.
    Wf_Engine_Util.Execute_Post_NTF_Function(itemtype, itemkey, actid,
        wf_engine.eng_run, pntfstatus, pntfresult);

    if (pntfstatus = wf_engine.eng_waiting) then
      -- Either post-notification function is not complete, or error occurred.
      -- In either case exit immediately without changing status.

      -- Bug 2078211
      -- if the status is waiting and the input parameter result is
      -- wf_engine.eng_timedout, continue executing as the activity
      -- needs to be timedout as determined by the procedure
      -- Wf_Engine_Util.processtimeout

      if (result = wf_engine.eng_timedout) then
         lresult := result;
      else
         return;
      end if;
    elsif (pntfstatus = wf_engine.eng_completed) then
      -- Post-notification activity is complete.
      -- Replace result with result of post-notification function.
      lresult := pntfresult;
    else
      -- Any pntfstatus other than waiting or complete means this is not
      -- a post-notification activity, so use original result.
      lresult := result;
    end if;
  else
    lresult := result;
  end if;

  -- Update the item activity status
  Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
                      wf_engine.eng_completed, lresult, '', SYSDATE);

  if (acttype = wf_engine.eng_process) then
    -- If this activity is a process, kill any deferred children.
    Wf_Engine_Util.Process_Kill_Children(itemtype, itemkey, actid);

    -- Remove myself from the process call stack
    Wf_Engine_Util.RemoveProcessStack(itemtype, itemkey, actid);
  elsif (acttype = wf_engine.eng_notification) then
    -- Cancel any outstanding notifications for this activity if
    -- a response is expected.
    -- (Response expected is signalled by a non-null result)
    Wf_Item_Activity_Status.Notification_Status(itemtype, itemkey, actid,
                                                notid, user);
    if ((notid is not null) and (lresult <> wf_engine.eng_null)) then
      begin
        Wf_Notification.CancelGroup(gid=>notid, timeout=>TRUE);
      exception
        when others then
          -- Ignore any errors from cancelling notifications
          null;
      end;
    end if;
  end if;

  -- If this is the root process of the item, then exit immediately.
  Wf_Item.Root_Process(itemtype, itemkey, root, version);
  rootid := Wf_Process_Activity.RootInstanceId(itemtype, itemkey, root);
  if (actid = rootid) then
    return;
  end if;

  -- Also exit immediately if parent process no longer active.
  -- This is to:
  -- 1. avoid re-completing the parent if this happens to be
  --    an end activity (immediately below).
  -- 2. avoid creating confusing COMPLETE/#FORCE rows in process_activity
  --    for activities following this one.
  -- SYNCHMODE: No need to check, parent must always be active.
  if (itemkey <> wf_engine.eng_synch) then
    Wf_Item_Activity_Status.Status(itemtype, itemkey,
        Wf_Engine_Util.Activity_Parent_Process(itemtype, itemkey, actid),
        parent_status);
    if (parent_status in (wf_engine.eng_completed, wf_engine.eng_error)) then
      return;
    end if;
  end if;

  -- Check if this is an ending activity.
  -- If so, then also complete the parent process.
  -- You can also exit immediately, because,
  -- 1. If this is a process activity, then completing the parent process
  --    will complete all of its children recursively, so there is no
  --    need for this process to kill it's children.  Instead, the
  --    complete_activity is allowed to filter up to the top-level
  --    ending process, which kills all the children in its tree in one shot.
  -- 2. There are no transitions out of an ending process.
  if (Wf_Activity.Ending(actid, actdate)) then

    -- SS: Get the result code to complete the parent process with.
    -- The result for the parent process will always be the default_result
    -- of the ending activity, regardless of the result of the activity
    -- itself.

  WF_CACHE.GetProcessActivity(complete_activity.actid, status);

  if (status <> WF_CACHE.task_SUCCESS) then
    select WPA.PROCESS_ITEM_TYPE, WPA.PROCESS_NAME, WPA.PROCESS_VERSION,
           WPA.ACTIVITY_ITEM_TYPE, WPA.ACTIVITY_NAME, WPA.INSTANCE_ID,
           WPA.INSTANCE_LABEL, WPA.PERFORM_ROLE, WPA.PERFORM_ROLE_TYPE,
           WPA.START_END, WPA.DEFAULT_RESULT
    into   WF_CACHE.ProcessActivities(complete_activity.actid)
    from   WF_PROCESS_ACTIVITIES WPA
    where  WPA.INSTANCE_ID = complete_activity.actid;

  end if;

    -- Complete the parent process and return immediately.
    Wf_Engine_Util.Complete_Activity(itemtype, itemkey,
        Wf_Engine_Util.Activity_Parent_Process(itemtype, itemkey, actid),
        WF_CACHE.ProcessActivities(complete_activity.actid).DEFAULT_RESULT);
    return;
  end if;

  --<rwunderl:2412971>
  -- Check WF_CACHE
  WF_CACHE.GetActivityTransitions(FromActID=>actid,
                                  result=>lresult,
                                  status=>status,
                                  watIND=>watIND);


  if (status <> WF_CACHE.task_SUCCESS) then
    -- The transitions for this activity/result is not in cache, so we will
    -- store them using a for loop to get all the next transition activities.
    -- Then we will access the list from cache  to avoid maximum open cursor
    -- problem.  First we need to retain the base index to be used later.
    l_baseLnk := watIND;
    l_linkCollision := FALSE;
    for child in children(actid, lresult) loop
      if (TransitionCount > 0) then --Second and succeeding iterations
        --We will locally store the record index from the last loop iteration.
        l_prevLnk := watIND;
        --We will now generate an index for the next transition from the
        --actid, lresult, and the current TO_PROCESS_ACTIVITY.
        watIND := WF_CACHE.HashKey(actid||':'||lresult||':'||
                      WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY);
        --Check to make sure a record is not already here.
        if (WF_CACHE.ActivityTransitions.EXISTS(watIND)) then
          if ((WF_CACHE.ActivityTransitions(watIND).FROM_PROCESS_ACTIVITY <>
               child.FROM_PROCESS_ACTIVITY) or
               (WF_CACHE.ActivityTransitions(watIND).RESULT_CODE <>
                child.RESULT_CODE) or
               (WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY <>
                child.TO_PROCESS_ACTIVITY)) then
            l_linkCollision := TRUE;  --We will continue
                                      --populating this linked list, but after
                                      --we use it, we will clear the pl/sql table.
          end if;
        end if;

        --Now the PL/SQL table index has moved to the next link, so we will
        --populate the prev_lnk with our locally stored index.  This feature,
        --not yet used, allows us to traverse backwards through the link list
        --if needed.  Since it is not yet used, it is commented out.
        --WF_CACHE.ActivityTransitions(watIND).PREV_LNK := l_prevLnk;

        --l_prevLnk represents the index of the previous record, and we need
        --to update its NEXT_LNK field with the current index.
        WF_CACHE.ActivityTransitions(l_prevLnk).NEXT_LNK := watIND;
     -- else
     --   WF_CACHE.ActivityTransitions(watIND).PREV_LNK := -1;

      end if;

      WF_CACHE.ActivityTransitions(watIND).FROM_PROCESS_ACTIVITY :=
                                                  child.FROM_PROCESS_ACTIVITY;

      WF_CACHE.ActivityTransitions(watIND).RESULT_CODE := child.RESULT_CODE;

      WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY :=
                                                      child.TO_PROCESS_ACTIVITY;

      TransitionCount := TransitionCount+1;
    end loop;
    WF_CACHE.ActivityTransitions(watIND).NEXT_LNK := -1;
    watIND := l_baseLnk; --Reset the index back to the beginning.
    status := WF_CACHE.task_SUCCESS;  --We now have the records successfully
                                      --in cache.

  end if;

  -- Load a local InstanceArrayTyp, we do this because of the recursion that
  -- occurs.  Since the ActivityTransitions Cache is global, any hashCollision
  -- would clear the cache and could cause problems as we process activities.
  while (watIND <> -1) loop
    childarr(i) := WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY;
    i := i+1;
    watIND := WF_CACHE.ActivityTransitions(watIND).NEXT_LNK;
  end loop;
  childarr(i) := '';

  if (l_linkCollision) then
    --When populating the linked list, we discovered that a hash collision
    --caused us to overwrite a link belonging to another list.  This would
    --cause the other list to be incorrect.  We will clear the table so the
    --lists will be rebuilt after this transaction.
    WF_CACHE.ActivityTransitions.DELETE;

  end if;
 --</rwunderl:2412971>

  -- SYNCHMODE:  Check for branching.
  -- If more than one transition out, this is an illegal branch point.
  if ((itemkey = wf_engine.eng_synch) and (i > 1)) then
    Wf_Core.Token('ACTID', to_char(actid));
    Wf_Core.Token('RESULT', lresult);
    Wf_Core.Raise('WFENG_SYNCH_BRANCH');
  end if;

  i := 0;
  -- While loop to hande the next transition activities.
  while (childarr(i) is not NULL) loop
    Wf_Engine_Util.Process_Activity(itemtype, itemkey,
                      childarr(i),
                      WF_ENGINE.THRESHOLD);
    i := i+1;
  end loop;

exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Complete_Activity', itemtype, itemkey,
                    actid, result);
    raise;
end complete_activity;

------------------------------------------------------------------
--Bug 2259039
--The start process code is consolidated into the new API
--start_process_internal.
------------------------------------------------------------------
--
-- Start_Process_Internal
--   Begins execution of the process. The process will be identified by the
--   itemtype and itemkey.  The engine locates the starting activities
--   of the root process and executes them.
-- IN
--   itemtype - A valid item type
--   itemkey  - Item Key
--   runmode - Start mode.  Valid values are:
--   START : a valid startprocess
--   ACTIVITY : called in complete_activity
--   EVENT : when process is started from a receive event.
--
procedure Start_Process_Internal(
  itemtype in varchar2,
  itemkey  in varchar2,
  runmode  in varchar2)
is
  -- Select all the start activities in this parent process with
  -- no in-transitions.
  cursor starter_children (itemtype in varchar2,
                           process in varchar2,
                           version in number) is
    SELECT PROCESS_ITEM_TYPE, PROCESS_NAME, PROCESS_VERSION,
           ACTIVITY_ITEM_TYPE, ACTIVITY_NAME, INSTANCE_ID,
           INSTANCE_LABEL, PERFORM_ROLE, PERFORM_ROLE_TYPE,
           START_END, DEFAULT_RESULT
    FROM   WF_PROCESS_ACTIVITIES WPA
    WHERE  WPA.PROCESS_ITEM_TYPE = itemtype
    AND    WPA.PROCESS_NAME = process
    AND    WPA.PROCESS_VERSION = version
    AND    WPA.START_END = wf_engine.eng_start
    AND NOT EXISTS (
      SELECT NULL
      FROM WF_ACTIVITY_TRANSITIONS WAT
      WHERE WAT.TO_PROCESS_ACTIVITY = WPA.INSTANCE_ID);

  childarr InstanceArrayTyp;  -- Place holder for all the instance id
                              -- selected from starter_children cursor
  i pls_integer := 0;         -- Counter for the for loop
  process varchar2(30) := ''; -- root process activity name
  version pls_integer;        -- root process activity version
  processid pls_integer;
  actdate date;
  rerun varchar2(8);         -- Activity rerun flag
  acttype  varchar2(8);      -- Activity type
  cost  number;              -- Activity cost
  ftype varchar2(30);        -- Activity function type
  defer_mode boolean := FALSE;

  TransitionCount pls_integer := 0;
  l_baseLnk       NUMBER;
  l_prevLnk       NUMBER;
  psaIND          NUMBER;
  l_linkCollision BOOLEAN;
  status          PLS_INTEGER;

  trig_savepoint exception;
  pragma exception_init(trig_savepoint, -04092);
  dist_savepoint exception;
  pragma exception_init(dist_savepoint, -02074);
begin
  -- Check if the item exists and also get back the root process name
  -- and version
  Wf_Item.Root_Process(itemtype, itemkey, process, version);
  if (process is null) then
    Wf_Core.Token('TYPE', itemtype);
    Wf_Core.Token('KEY', itemkey);
    Wf_Core.Raise('WFENG_ITEM');
  end if;

  -- Insert a row for the process into WIAS table.
  -- Get the id of the process root.
  processid := Wf_Process_Activity.RootInstanceId(itemtype, itemkey,
                                                  process);
  if (processid is null) then
    Wf_Core.Token('TYPE', itemtype);
    Wf_Core.Token('NAME', process);
    Wf_Core.Raise('WFENG_PROCESS_RUNNABLE');
  end if;

  Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, processid,
      wf_engine.eng_active, wf_engine.eng_null, SYSDATE, null,
      newStatus=>TRUE);

  -- Initialize process call stack with the root process.
  Wf_Engine_Util.AddProcessStack(itemtype, itemkey, itemtype, process,
      processid, TRUE);

  -- Get the cost of the parent process.
  -- If the cost is over the threshold, then set a flag to immediately
  -- defer child activities.
  -- NOTE:  Ordinarily it would be ok to let process_activity do the
  -- job and defer activities if needed, but the savepoint in the loop
  -- below causes failures if StartProcess is called from a db trigger.
  -- This is a workaround to avoid the savepoints altogether if
  -- the process is to be immediately deferred.
  --
  --
  -- SYNCHMODE: Synch processes cannot be deferred.
  actdate := Wf_Item.Active_Date(itemtype, itemkey);
  Wf_Activity.Info(processid, actdate, rerun, acttype, cost, ftype);
  if ((itemkey <> wf_engine.eng_synch) and
      (cost > wf_engine.threshold)) then
    defer_mode := TRUE;
  end if;

  --<rwunderl:2412971>
  -- Retrieve the starting activities from cache.
  WF_CACHE.GetProcessStartActivities(itemType=>itemtype,
                                     name=>process,
                                     version=>version,
                                     status=>status,
                                     psaIND=>psaIND);

  if (status <> WF_CACHE.task_SUCCESS) then
    -- Starting activities are not in cache, so we will store them using a for
    -- loop to get all the next transition activities.
    -- Then we will access the list from cache to avoid maximum open cursor
    -- problem.  First we need to retain the base index to be used later.
    l_baseLnk := psaIND;
    l_linkCollision := FALSE;
    for child in starter_children(itemtype, process, version) loop
      if (TransitionCount > 0) then --Second and succeeding iterations
        --We will locally store the record index from the last loop iteration.
        l_prevLnk := psaIND;
        --We will now generate an index for the start activity from the
        --itemType, name, version, and the current INSTANCE_ID
        psaIND := WF_CACHE.HashKey(itemType||':'||process||':'||version||
                      ':'||WF_CACHE.ProcessStartActivities(psaIND).INSTANCE_ID);

        --Check to make sure a record is not already here.
        if (WF_CACHE.ProcessStartActivities.EXISTS(psaIND)) then
          l_linkCollision := TRUE;  --There should be no record here, so this
                                    --is a hash collision.  We will continue
                                    --populating this linked list, but after
                                    --we use it, we will clear the pl/sql table
        end if;

        --Now the PL/SQL table index has moved to the next link, so we will
        --populate the prev_lnk with our locally stored index.  This feature,
        --not yet used, allows us to traverse backwards through the link list
        --if needed.  Since it is not yet used, it is commented out.
        --WF_CACHE.ProcessStartActivities(psaIND).PREV_LNK := l_prevLnk;

        --l_prevLnk represents the index of the previous record, and we need
        --to update its NEXT_LNK field with the current index.
        WF_CACHE.ProcessStartActivities(l_prevLnk).NEXT_LNK := psaIND;
      --else
      --  WF_CACHE.ProcessStartActivities(psaIND).PREV_LNK := -1;

      end if;

      WF_CACHE.ProcessStartActivities(psaIND).PROCESS_ITEM_TYPE :=
                                                  child.PROCESS_ITEM_TYPE;

      WF_CACHE.ProcessStartActivities(psaIND).PROCESS_NAME :=
                                                  child.PROCESS_NAME;

      WF_CACHE.ProcessStartActivities(psaIND).PROCESS_VERSION :=
                                                      child.PROCESS_VERSION;

      WF_CACHE.ProcessStartActivities(psaIND).INSTANCE_ID := child.INSTANCE_ID;

      --While we are here, we can populate the ProcessActivities cache hoping
      --that a later request of any of these process activities will save us
      --another trip to the DB.
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).PROCESS_ITEM_TYPE :=
                                                    child.PROCESS_ITEM_TYPE;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).PROCESS_NAME :=
                                                    child.PROCESS_NAME;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).PROCESS_VERSION :=
                                                    child.PROCESS_VERSION;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).ACTIVITY_ITEM_TYPE :=
                                                    child.ACTIVITY_ITEM_TYPE;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).ACTIVITY_NAME :=
                                                    child.ACTIVITY_NAME;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).INSTANCE_ID :=
                                                    child.INSTANCE_ID;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).INSTANCE_LABEL :=
                                                    child.INSTANCE_LABEL;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).PERFORM_ROLE :=
                                                    child.PERFORM_ROLE;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).PERFORM_ROLE_TYPE :=
                                                    child.PERFORM_ROLE_TYPE;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).START_END :=
                                                    child.START_END;
      WF_CACHE.ProcessActivities(child.INSTANCE_ID).DEFAULT_RESULT :=
                                                    child.DEFAULT_RESULT;

      TransitionCount := TransitionCount+1;
    end loop;
    WF_CACHE.ProcessStartActivities(psaIND).NEXT_LNK := -1;
    psaIND := l_baseLnk; --Reset the index back to the beginning.
    status := WF_CACHE.task_SUCCESS;  --We now have the records successfully
                                      --in cache.

  end if;

  -- Load a local InstanceArrayTyp, we do this because of the recursion that
  -- occurs.  Since the ProcessStartActivities Cache is global, any
  -- hashCollision would clear the cache and could cause problems as we
  -- process activities in recursive calls.
  while (psaIND <> -1) loop
    childarr(i) := WF_CACHE.ProcessStartActivities(psaIND).INSTANCE_ID;
    i := i+1;
    psaIND := WF_CACHE.ProcessStartActivities(psaIND).NEXT_LNK;
  end loop;
  childarr(i) := '';

  if (l_linkCollision) then
    --When populating the linked list, we discovered that a hash collision
    --caused us to overwrite a link belonging to another list.  This would
    --cause the other list to be incorrect.  We will clear the table so the
    --lists will be rebuilt after this transaction.
    WF_CACHE.ProcessStartActivities.DELETE;

  end if;
 --</rwunderl:2412971>

  -- SYNCHMODE: Only 1 starter allowed in synch processes
  if ((itemkey = wf_engine.eng_synch) and
      (i > 1)) then
    Wf_Core.Token('ACTID', process);
    Wf_Core.Token('RESULT', 'START');
    Wf_Core.Raise('WFENG_SYNCH_BRANCH');
  end if;

  -- SS: Process all 'true' start activities of this process.
  -- 'True' start activities are those which are marked as starts,
  -- and also have no in-transitions.
  --   Activities with in-transitions may be marked as starters if it
  -- is possible to jump into the middle of a process with a
  -- completeactivity call.  If this is the case, we don't want to
  -- separately start these activities when starting the process as
  -- a whole, because they will presumably already have been executed
  -- in the flow starting from the 'true' starts.
  i := 0;
  while(childarr(i) is not null) loop
    if (runmode in ('EVENT','ACTIVITY')) then
      -- For runmode modes, just mark starters as NOTIFIED,
      -- and thus ready for external input, but don't actually run
      -- them.  Only the start activities matching the specific
      -- activity/event will be run (below).
      Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, childarr(i),
          wf_engine.eng_notified, wf_engine.eng_null, SYSDATE, null,
          newStatus=>TRUE);
    elsif (defer_mode) then
      -- Insert child rows as deferred with no further processing
      Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, childarr(i),
          wf_engine.eng_deferred, wf_engine.eng_null, SYSDATE, null,
          newStatus=>TRUE);
    else  -- Must be START mode, and not deferred
      -- Process start activity normally
      if (itemkey = wf_engine.eng_synch) then
        -- SYNCHMODE: No fancy error processing!
        Wf_Engine_Util.Process_Activity(itemtype, itemkey, childarr(i),
              WF_ENGINE.THRESHOLD);
      else
        begin
          savepoint wf_savepoint;
          Wf_Engine_Util.Process_Activity(itemtype, itemkey, childarr(i),
                WF_ENGINE.THRESHOLD);
        exception
          when trig_savepoint or dist_savepoint then
            -- Oops, you forgot to defer your trigger or distributed
            -- transaction initiated process!  I'll do it for you.
            Wf_Item_Activity_Status.Create_Status(itemtype, itemkey,
                 childarr(i), wf_engine.eng_deferred, wf_engine.eng_null,
                 SYSDATE, null, newStatus=>TRUE);
          when others then
            -- If anything in this process raises an exception:
            -- 1. rollback any work in this process thread
            -- 2. set this activity to error status
            -- 3. execute the error process (if any)
            -- 4. clear the error to continue with next activity
            rollback to wf_savepoint;
            Wf_Core.Context('Wf_Engine', 'Start_Process_Internal', itemtype, itemkey);
            Wf_Item_Activity_Status.Set_Error(itemtype, itemkey, processid,
                wf_engine.eng_exception, FALSE);
            Wf_Engine_Util.Execute_Error_Process(itemtype, itemkey, processid,
                wf_engine.eng_exception);
            Wf_Core.Clear;
            return;
        end;
      end if;
    end if;
    i := i+1;
  end loop;

   -- Report an error if no start activities can be found.
   if (i = 0) then
     Wf_Core.Token('PROCESS', process);
     Wf_Core.Raise('WFENG_NO_START');
  end if;

exception
  when others then
    -- Bug 4117740
    -- Call clearcache() when #SYNCH flow is in error
    if ((itemkey = WF_ENGINE.eng_synch) and
        (wf_core.error_name is null or wf_core.error_name <> 'WFENG_SYNCH_ITEM') and
        (not WF_ENGINE.debug)) then
      Wf_Item.ClearCache;
    end if;

    Wf_Core.Context('Wf_Engine_Util', 'Start_Process_Internal',
        itemtype, itemkey);
    raise;
end Start_Process_Internal;


--
-- Process_Activity (PRIVATE)
--   Execute a single activity (function, notification, or sub-process),
--   after checking parent and activity statuses and conditions.
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--   actid     - The activity instance id.
--   threshold - Max cost to process without deferring
--   activate  - A flag to indicate that if the assigned activity is currently
--               active, should process_activity() still process it?
--
procedure process_activity(
  itemtype in varchar2,
  itemkey  in varchar2,
  actid    in number,
  threshold in number,
  activate in boolean)
is
  actdate date;

  -- Select all the start activities in a process with no in-transitions.
  cursor starter_children(parent in pls_integer) is
    SELECT C.INSTANCE_ID
    FROM WF_PROCESS_ACTIVITIES P, WF_PROCESS_ACTIVITIES C,
         WF_ACTIVITIES A
    WHERE P.INSTANCE_ID = parent
    AND   P.ACTIVITY_ITEM_TYPE = C.PROCESS_ITEM_TYPE
    AND   P.ACTIVITY_NAME = C.PROCESS_NAME
    AND   C.PROCESS_VERSION = A.VERSION
    AND   A.NAME = C.PROCESS_NAME
    AND   A.ITEM_TYPE = C.PROCESS_ITEM_TYPE
    AND   actdate >= A.BEGIN_DATE
    AND   actdate < NVL(A.END_DATE, actdate+1)
    AND   C.START_END = wf_engine.eng_start
    AND NOT EXISTS (
      SELECT NULL
      FROM WF_ACTIVITY_TRANSITIONS WAT
      WHERE WAT.TO_PROCESS_ACTIVITY = C.INSTANCE_ID);

  rerun varchar2(8);         -- Activity rerun flag
  cost  number;              -- Activity cost
  status varchar2(8);        -- Activity status
  result varchar2(30);       -- Activity result
  acttype  varchar2(8);      -- Activity type
  act_itemtype varchar2(8);  -- Activity itemtype
  act_name varchar2(30);     -- Activity name
  act_functype varchar2(30); -- Activity function type
  childarr InstanceArrayTyp; -- Place holder for all the instance id
                             -- selected from starter_children cursor
  i pls_integer := 0;

  trig_savepoint exception;
  pragma exception_init(trig_savepoint, -04092);
  dist_savepoint exception;
  pragma exception_init(dist_savepoint, -02074);
begin

  -- Check this activity's parent process
  -- SYNCHMODE: No need to check parent, will always be active.
  if (itemkey <> wf_engine.eng_synch) then
    Wf_Item_Activity_Status.Status(itemtype, itemkey,
        Wf_Engine_Util.Activity_Parent_Process(itemtype, itemkey, actid),
        status);

    if (status is null) then
      -- return WF_PARENT_PROCESS_NOT_RUNNING;
      -- TO BE UPDATED
      -- Actually this case should not happen
      return;
    elsif ((status = wf_engine.eng_completed) or
           (status = wf_engine.eng_error)) then
      -- Mark it as completed cause the parent process is completed/errored
      Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
          wf_engine.eng_completed, wf_engine.eng_force, sysdate, sysdate);
      return;

    elsif (status = wf_engine.eng_suspended) then
      -- Insert this activity as deferred
      Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
                                            wf_engine.eng_deferred, null,
                                            sysdate, null, suspended=>TRUE);
      return;
    elsif (status in (wf_engine.eng_notified, wf_engine.eng_waiting,
                      wf_engine.eng_deferred)) then
      -- NOTE: This should never happened because the engine will never
      -- set the status of a process to be 'WAITING' or 'NOTIFIED'
      -- return;
      Wf_Core.Token('ITEM_TYPE', itemtype);
      Wf_Core.Token('ITEM_KEY', itemkey);
      Wf_Core.Token('PROCESS', to_char(actid));
      Wf_Core.Token('STATUS', status);
      Wf_Core.Raise('WFSQL_INTERNAL');
    end if;
  end if;

  -- If we came here, that means the parent process is ACTIVE

  -- Get the information of this activity
  -- Out of these three return variables, cost is the only one could be null
  actdate := Wf_Item.Active_Date(itemtype, itemkey);
  Wf_Activity.Info(actid, actdate, rerun, acttype,
                   cost, act_functype);

  -- If this activity is currently active, do nothing
  -- If this activity has already been completed, check the rerun flag
  --
  -- SYNCHMODE: Ignore the current status of the activity.  No loop
  -- reset or other processing is allowed.
  if (itemkey = wf_engine.eng_synch) then
    status := '';
    result := '';
  else
    Wf_Item_Activity_Status.Result(itemtype, itemkey, actid, status, result);
    if (status is not null) then
      if ( (status = wf_engine.eng_active) AND (activate = FALSE) )then
        -- Maybe don't have to do anything because it is running already
        return;

      -- Bug 2111183
      -- resetting activity with status eng_notified prevents a orphaned
      -- notification in WF_NOTIFICATIONS if the notification activity
      -- is revisited in a loop simultaneously by two incoming transitions

      elsif (status in (wf_engine.eng_completed, wf_engine.eng_error,
                        wf_engine.eng_notified)) then
        -- Check the rerun flag to see what should be done
        if (rerun = wf_engine.eng_ignore) then
          -- No loop - do nothing
          return;
        elsif (rerun = wf_engine.eng_reset) then
          -- Reset activities, cancel mode
          Wf_Engine_Util.Reset_Activities(itemtype, itemkey, actid, TRUE);
        elsif (rerun = wf_engine.eng_loop) then
          -- Reset activities, no-cancel mode
          Wf_Engine_Util.Reset_Activities(itemtype, itemkey, actid, FALSE);
        end if;
      elsif ((status = wf_engine.eng_suspended) AND
             (acttype <> wf_engine.eng_process))then
        -- Only the process type of activity can have a 'SUSPENDED' status
        -- If this is not a process type activity, then THIS IS A PROBLEM
        -- CAN NOT DO ANYTHING
        Wf_Core.Token('ITEM_TYPE', itemtype);
        Wf_Core.Token('ITEM_KEY', itemkey);
        Wf_Core.Token('ACTIVITY_TYPE', acttype);
        Wf_Core.Token('STATUS', status);
        Wf_Core.Raise('WFSQL_INTERNAL');
      end if;
    end if;
  end if;

  -- If we came here, we have
  -- (1) not yet run this activity before
  -- (2) this is a deferred activity
  -- (3) this is a waiting activity (including logical_and)
  -- (4) this is re-runnable activity and we did a reset already
  --
  -- SYNCHMODE: Ignore cost, always run process immediately
  if ((itemkey = wf_engine.eng_synch) or
      (cost is null and act_functype = 'PL/SQL') or
      (cost <= nvl(threshold, cost) and act_functype = 'PL/SQL')) then
    -- If status is null, we want to create the status
    -- If status is not null, we want to update the status back to active
    -- except for a suspended process

   if (status is null ) then
    -- Insert this activity as active into the WIAS table
    Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
                                          wf_engine.eng_active, null,
                                          sysdate, null, newStatus=>TRUE);

   elsif (status <> wf_engine.eng_suspended) then
    Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
                                          wf_engine.eng_active, null,
                                          sysdate, null, newStatus=>FALSE);
   end if;

    if (acttype = wf_engine.eng_process) then
      -- PROCESS activity
      -- Add this subprocess to the call stack
      Wf_Process_Activity.ActivityName(actid, act_itemtype, act_name);
      Wf_Engine_Util.AddProcessStack(itemtype, itemkey, act_itemtype,
          act_name, actid, FALSE);

      -- For loop to get all the start activities first.
      -- This is to avoid the maximum open cursor problem
      for child in starter_children(actid) loop
        childarr(i) := child.instance_id;
        i := i+1;
      end loop;
      childarr(i) := '';

      -- SYNCHMODE: Only one starter allowed in synch process
      if ((itemkey = wf_engine.eng_synch) and (i > 1)) then
        Wf_Core.Token('ACTID', act_name);
        Wf_Core.Token('RESULT', 'START');
        Wf_Core.Raise('WFENG_SYNCH_BRANCH');
      end if;

      -- While loop to handle all the start activities
      i := 0;
      while(childarr(i) is not null) loop
        Wf_Engine_Util.Process_Activity(itemtype, itemkey, childarr(i),
            threshold);
        i := i+1;
      end loop;
    else
      -- Function/Notification/Event type activities
      begin
        Wf_Engine_Util.Execute_Activity(itemtype, itemkey, actid,
            wf_engine.eng_run);
        exception
          when trig_savepoint or dist_savepoint then
            -- Oops, you forgot to defer your trigger or distributed
            -- transaction initiated process!  I'll do it for you.
            -- (Note this is only needed here for restarting a
            -- process using CompleteActivity, all other will be caught
            -- by error handling savepoints before this.)
            Wf_Item_Activity_Status.Create_Status(itemtype, itemkey,
                 actid, wf_engine.eng_deferred, null,
                 SYSDATE, null, newStatus=>TRUE);
        end;
    end if;
  else
    -- Cost is over the threshold or this is a callout function
    -- Insert this activity into the WIAS table and mark it as deferred
    Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
                                          wf_engine.eng_deferred, null,
                                          sysdate, null, newStatus=>TRUE);
  end if; -- end if deferred

  return;
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Process_Activity', itemtype, itemkey,
                    to_char(actid), to_char(threshold));
    raise;
end process_activity;

--
-- Reset_Activities (PRIVATE)
--   Reset completed activities to redo a loop
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--   itemactid - The activity instance id.
--   cancel - Cancel the activities before resetting or not
--
procedure reset_activities(itemtype in varchar2,
                           itemkey  in varchar2,
                           actid    in number,
                           cancel   in boolean)
is
  actdate date;

  -- Select all the start activities for this parent process
  cursor starter_children(parent in pls_integer) is
    SELECT C.INSTANCE_ID
    FROM WF_PROCESS_ACTIVITIES P, WF_PROCESS_ACTIVITIES C,
         WF_ACTIVITIES A
    WHERE P.INSTANCE_ID = parent
    AND   P.ACTIVITY_ITEM_TYPE = C.PROCESS_ITEM_TYPE
    AND   P.ACTIVITY_NAME = C.PROCESS_NAME
    AND   C.PROCESS_VERSION = A.VERSION
    AND   A.NAME = C.PROCESS_NAME
    AND   A.ITEM_TYPE = C.PROCESS_ITEM_TYPE
    AND   actdate >= A.BEGIN_DATE
    AND   actdate < NVL(A.END_DATE, actdate+1)
    AND   C.START_END = wf_engine.eng_start;

  -- Select the to activity(ies) by given the from activity and result
  cursor to_activities(fromact in pls_integer, fromact_result varchar2) is
    SELECT WAT1.FROM_PROCESS_ACTIVITY, WAT1.RESULT_CODE,
           WAT1.TO_PROCESS_ACTIVITY
    FROM WF_ACTIVITY_TRANSITIONS WAT1
    WHERE WAT1.FROM_PROCESS_ACTIVITY = fromact
    AND (WAT1.RESULT_CODE in (fromact_result, wf_engine.eng_trans_any)
         OR (WAT1.RESULT_CODE = wf_engine.eng_trans_default
             AND NOT EXISTS
                (SELECT NULL
                FROM WF_ACTIVITY_TRANSITIONS WAT2
                WHERE WAT2.FROM_PROCESS_ACTIVITY = fromact
                AND WAT2.RESULT_CODE = fromact_result)
            )
        );

  childarr InstanceArrayTyp;
  i pls_integer := 0;        -- counter for the childarr
  savearr InstanceArrayTyp;  -- Save all the children and then process them
                             -- at the reversed order
  result varchar2(30);
  status varchar2(8);
  typ varchar2(8);
  notid pls_integer;
  user varchar2(320);
  pntfstatus varchar2(8);
  pntfresult varchar2(30);

  --<rwunderl:2412971>
  TransitionCount pls_integer := 0;
  l_baseLnk       NUMBER;
  l_prevLnk       NUMBER;
  watIND          NUMBER;
  l_LinkCollision BOOLEAN;

begin
  Wf_Item_Activity_Status.Result(itemtype, itemkey, actid, status, result);

  if (status is null) then
    return; -- This means the end of a path
  end if;

  -- Undo the current activity, depending on type
  actdate := Wf_Item.Active_Date(itemtype, itemkey);
  typ := Wf_Activity.Instance_Type(actid, actdate);
  if (typ = wf_engine.eng_process) then
    -- For loop to get the starting activities of this process
    i := 0;
    for child in starter_children(actid) loop
      childarr(i) := child.instance_id;
      i := i + 1;
    end loop;
    childarr(i) := '';

    -- Reset all starting activities of child process.
    i := 0;
    while (childarr(i) is not null) loop
      Wf_Engine_Util.Reset_Activities(itemtype, itemkey, childarr(i), cancel);
      i := i + 1;
    end loop;
  elsif (typ = wf_engine.eng_notification) then
    if (cancel) then
      -- Run post-notification function in cancel mode if there is one.
      Wf_Engine_Util.Execute_Post_NTF_Function(itemtype, itemkey, actid,
          wf_engine.eng_cancel, pntfstatus, pntfresult);

      -- Cancel any open notifications sent by this activity
      Wf_Item_Activity_Status.Notification_Status(itemtype, itemkey, actid,
                                                  notid, user);
      if (notid is not null) then
        begin
          Wf_Notification.CancelGroup(notid);
        exception
          when others then
            null; -- Ignore errors in cancelling
        end;
      end if;
    end if;
  elsif (typ in (wf_engine.eng_function, wf_engine.eng_event)) then
    if (cancel) then
      -- Call function in cancel mode
      Wf_Engine_Util.Execute_Activity(itemtype, itemkey, actid,
          wf_engine.eng_cancel);
    end if;
  end if;

  -- Move the WIAS record to the history table.
  -- Note: Do NOT move this call.  The move_to_history() must be before any
  -- recursive calls to reset_activities() in the current process,
  -- or infinite recursion will result.
  Wf_Engine_Util.Move_To_History(itemtype, itemkey, actid);

  -- Reset all activities following this one in current process,
  -- but only if this activity really completed.
  if (status = wf_engine.eng_completed) then
    --<rwunderl:2412971>
    -- Check WF_CACHE
    WF_CACHE.GetActivityTransitions(FromActID=>actid,
                                    result=>result,
                                    status=>status,
                                    watIND=>watIND);


    if (status <> WF_CACHE.task_SUCCESS) then
      -- The transitions for this activity/result is not in cache, so we will
      -- store them using a for loop to get all the next transition activities.
      -- Then we will access the list from cache  to avoid maximum open cursor
      -- problem.  First we need to retain the base index to be used later.
      l_baseLnk := watIND;
      l_linkCollision := FALSE;

      for to_activity in to_activities(actid, result) loop
        if (TransitionCount > 0) then --Second and succeeding iterations
          --We will locally store the record index from the last loop iteration.
          l_prevLnk := watIND;
          --We will now generate an index for the next transition from the
          --actid, result, and the current TO_PROCESS_ACTIVITY.
          watIND := WF_CACHE.HashKey(actid||':'||result||':'||
                      WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY);

          --Check to make sure a record is not already here.
          if (WF_CACHE.ActivityTransitions.EXISTS(watIND)) then
            if ((WF_CACHE.ActivityTransitions(watIND).FROM_PROCESS_ACTIVITY <>
                 to_activity.FROM_PROCESS_ACTIVITY) or
                 (WF_CACHE.ActivityTransitions(watIND).RESULT_CODE <>
                  to_activity.RESULT_CODE) or
                 (WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY <>
                  to_activity.TO_PROCESS_ACTIVITY)) then
              l_linkCollision := TRUE;  --We will continue
                                        --populating this linked list, but after
                                        --we use it, we will clear the pl/sql table.
            end if;
          end if;

          --Now the PL/SQL table index has moved to the next link, so we will
          --populate the prev_lnk with our locally stored index.  This feature,
          --not yet used, allows us to traverse backwards through the link list
          --if needed.  Since it is not yet used, it is commented out.
         -- WF_CACHE.ActivityTransitions(watIND).PREV_LNK := l_prevLnk;

          --l_prevLnk represents the index of the previous record, and we need
          --to update its NEXT_LNK field with the current index.
          WF_CACHE.ActivityTransitions(l_prevLnk).NEXT_LNK := watIND;
       -- else
        --  WF_CACHE.ActivityTransitions(watIND).PREV_LNK := -1;

        end if;

        WF_CACHE.ActivityTransitions(watIND).FROM_PROCESS_ACTIVITY :=
                                              to_activity.FROM_PROCESS_ACTIVITY;

        WF_CACHE.ActivityTransitions(watIND).RESULT_CODE :=
                                                        to_activity.RESULT_CODE;

        WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY :=
                                                to_activity.TO_PROCESS_ACTIVITY;

        TransitionCount := TransitionCount+1;
      end loop;
      WF_CACHE.ActivityTransitions(watIND).NEXT_LNK := -1;
      watIND := l_baseLnk; --Reset the index back to the beginning.
      status := WF_CACHE.task_SUCCESS;  --We now have the records successfully
                                        --in cache.

    end if;

    -- Load a local InstanceArrayTyp, we do this because of the recursion that
    -- occurs.  Since the ActivityTransitions Cache is global, any hashCollision
    -- would clear the cache and could cause problems as we process activities.
    while (watIND <> -1) loop
      childarr(i) := WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY;
      i := i+1;
      watIND := WF_CACHE.ActivityTransitions(watIND).NEXT_LNK;
    end loop;
    childarr(i) := '';

    i := 0;
    while (childarr(i) is not null) loop
      Wf_Engine_Util.Reset_Activities(itemtype, itemkey, childarr(i), cancel);
      i := i + 1;
    end loop;
  end if;

  if (l_linkCollision) then
    --When populating the linked list, we discovered that a hash collision
    --caused us to overwrite a link belonging to another list.  This would
    --cause the other list to be incorrect.  We will clear the table so the
    --lists will be rebuilt after this transaction.
    WF_CACHE.ActivityTransitions.DELETE;

  end if;
 --</rwunderl:2412971>
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Reset_Activities', itemtype, itemkey,
                    to_char(actid));
    raise;
end reset_activities;

--
-- Reset_Tree (PRIVATE)
--   Reset an activity and all parent activities above it in a tree
--   and prepare for re-execution.  Used to reset the process to an
--   arbitrary point in HandleError.
-- IN
--   itemtype - Item type
--   itemkey - Item key
--   rootid - Instance id of process root
--   goalid - Instance id of activity to reset
-- RETURNS
--   TRUE if goalid found
--
function Reset_Tree(
  itemtype in varchar2,
  itemkey in varchar2,
  rootid in number,
  goalid in number,
  actdate in date)
return boolean is

  -- Cursor to select children of activity
  cursor children(parentid in pls_integer, actdate in date) is
    select WPA2.INSTANCE_ID
    from WF_PROCESS_ACTIVITIES WPA1,
         WF_ACTIVITIES WA,
         WF_PROCESS_ACTIVITIES WPA2
    where WPA1.INSTANCE_ID = parentid
    and WPA2.PROCESS_ITEM_TYPE = WA.ITEM_TYPE
    and WPA2.PROCESS_NAME = WA.NAME
    and WA.ITEM_TYPE = WPA1.ACTIVITY_ITEM_TYPE
    and WA.NAME = WPA1.ACTIVITY_NAME
    and actdate >= WA.BEGIN_DATE
    and actdate < NVL(WA.END_DATE, actdate+1)
    and WPA2.PROCESS_VERSION = WA.VERSION;

  childarr InstanceArrayTyp;
  i number := 0;

  -- Cursor to select following activities
  cursor to_activities(fromact in pls_integer, fromact_result in varchar2) is
    SELECT WAT1.FROM_PROCESS_ACTIVITY, WAT1.RESULT_CODE,
           WAT1.TO_PROCESS_ACTIVITY
    FROM WF_ACTIVITY_TRANSITIONS WAT1
    WHERE WAT1.FROM_PROCESS_ACTIVITY = fromact
    AND (WAT1.RESULT_CODE in (fromact_result, wf_engine.eng_trans_any)
         OR (WAT1.RESULT_CODE = wf_engine.eng_trans_default
             AND NOT EXISTS
                (SELECT NULL
                FROM WF_ACTIVITY_TRANSITIONS WAT2
                WHERE WAT2.FROM_PROCESS_ACTIVITY = fromact
                AND WAT2.RESULT_CODE = fromact_result)
            )
        );

  actarr InstanceArrayTyp;
  j pls_integer := 0;

  status varchar2(8);
  result varchar2(30);

  --<rwunderl:2412971>
  TransitionCount pls_integer := 0;
  l_baseLnk       NUMBER;
  l_prevLnk       NUMBER;
  watIND          NUMBER;
  l_LinkCollision BOOLEAN;

begin
  -- Goal has been found.  Reset the activity and all following it on this
  -- level, then set status to waiting for possible re-execution.
  if (rootid = goalid) then
    Wf_Engine_Util.Reset_Activities(itemtype, itemkey, goalid, TRUE);
    Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, goalid,
        wf_engine.eng_active, wf_engine.eng_null, sysdate, null);
    return(TRUE);
  end if;

  -- Otherwise, loop through children of rootid.
  for child in children(rootid, actdate) loop
    childarr(i) := child.instance_id;
    i := i + 1;
  end loop;
  childarr(i) := '';

  i := 0;
  while (childarr(i) is not null) loop
    -- Check if goal is in the subtree rooted at this child
    if (Wf_Engine_Util.Reset_Tree(itemtype, itemkey, childarr(i), goalid,
        actdate)) then

      -- Goal has been found in a child of this activity.
      Wf_Item_Activity_Status.Result(itemtype, itemkey, rootid,
          status, result);

      -- Reset any activities FOLLOWING the root.
      -- Do not reset the root itself - it is a process and its children
      -- were already reset in the recursive call.
      -- Likewise, do not reset actual child - it has already been reset.
      if (status = wf_engine.eng_completed) then
        --<rwunderl:2412971>
        -- Check WF_CACHE
        WF_CACHE.GetActivityTransitions(FromActID=>rootid,
                                        result=>result,
                                        status=>status,
                                        watIND=>watIND);

        if (status <> WF_CACHE.task_SUCCESS) then
        -- The transitions for this activity/result is not in cache, so we will
        -- store them using a for loop to get all the next transition
        -- activities.  Then we will access the list from cache  to avoid
        -- maximum open cursor problem.  First we need to retain the base index
        -- to be used later.
          l_baseLnk := watIND;
          l_linkCollision := FALSE;
          for to_activity in to_activities(rootid, result) loop
            if (TransitionCount > 0) then --Second and succeeding iterations
              --We will locally store the record index from the last loop
              --iteration.
              l_prevLnk := watIND;

              --We will now generate an index for the next transition from the
              --actid, result, and the current TO_PROCESS_ACTIVITY.
              watIND := WF_CACHE.HashKey(rootid||':'||result||':'||
                      WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY);
              --Check to make sure a record is not already here.
              if (WF_CACHE.ActivityTransitions.EXISTS(watIND)) then
                if ((WF_CACHE.ActivityTransitions(watIND).FROM_PROCESS_ACTIVITY <>
                     to_activity.FROM_PROCESS_ACTIVITY) or
                    (WF_CACHE.ActivityTransitions(watIND).RESULT_CODE <>
                     to_activity.RESULT_CODE) or
                    (WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY <>
                     to_activity.TO_PROCESS_ACTIVITY)) then
                  l_linkCollision := TRUE;  --We will continue
                                            --populating this linked list, but after
                                            --we use it, we will clear the pl/sql
                                            --table.
                end if;
              end if;

              --Now the PL/SQL table index has moved to the next link, so we
              --will populate the prev_lnk with our locally stored index.
              --This feature, not yet used, allows us to traverse backwards
              --through the link list if needed.   Since it is not yet used,
              --it is commented out.
         --     WF_CACHE.ActivityTransitions(watIND).PREV_LNK := l_prevLnk;

              --l_prevLnk represents the index of the previous record, and we
              --need to update its NEXT_LNK field with the current index.
              WF_CACHE.ActivityTransitions(l_prevLnk).NEXT_LNK := watIND;
          --  else
          --    WF_CACHE.ActivityTransitions(watIND).PREV_LNK := -1;

            end if;

            WF_CACHE.ActivityTransitions(watIND).FROM_PROCESS_ACTIVITY :=
                                              to_activity.FROM_PROCESS_ACTIVITY;

            WF_CACHE.ActivityTransitions(watIND).RESULT_CODE :=
                                                        to_activity.RESULT_CODE;

            WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY :=
                                                to_activity.TO_PROCESS_ACTIVITY;

            TransitionCount := TransitionCount+1;
          end loop;
          WF_CACHE.ActivityTransitions(watIND).NEXT_LNK := -1;
          watIND := l_baseLnk; --Reset the index back to the beginning.
          status := WF_CACHE.task_SUCCESS;  --We now have the records
                                            --successfully in cache.
        end if;

        j := 0;
        -- Load a local InstanceArrayTyp, we do this because of the recursion
        -- that occurs.  Since the ActivityTransitions Cache is global, any
        -- hashCollision would clear the cache and could cause problems as we
        -- process activities.
        while (watIND <> -1) loop
          actarr(j) := WF_CACHE.ActivityTransitions(watIND).TO_PROCESS_ACTIVITY;
          j := j+1;
          watIND := WF_CACHE.ActivityTransitions(watIND).NEXT_LNK;
        end loop;
        actarr(j) := '';

        j := 0;
        while (actarr(j) is not null) loop
          Wf_Engine_Util.Reset_Activities(itemtype, itemkey, actarr(j), TRUE);
          j := j + 1;
        end loop;
      end if;

      if (l_linkCollision) then
        --When populating the linked list, we discovered that a hash collision
        --caused us to overwrite a link belonging to another list.  This would
        --cause the other list to be incorrect.  We will clear the table so the
        --lists will be rebuilt after this transaction.
        WF_CACHE.ActivityTransitions.DELETE;

      end if;
      --</rwunderl:2412971>

      -- Set the root activity status to active if not already
      if (nvl(status, 'x') <> wf_engine.eng_active) then
        Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, rootid,
            wf_engine.eng_active, wf_engine.eng_null, sysdate, null);
      end if;

      -- Goal has been found, so exit now
      return(TRUE);
    end if;

    i := i + 1;
  end loop;

  -- Goal not found anywhere.
  return(FALSE);
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Reset_Tree', itemtype, itemkey,
        to_char(rootid), to_char(goalid), to_char(actdate));
    raise;
end Reset_Tree;

--
-- Move_To_History (PRIVATE)
--   Move the item activity status row from WF_ITEM_ACTIVITY_STATUSES to
--   WF_ITEM_ACTIVITY_STATUSES_H table.
-- IN
--   itemtype  - A valid item type from (WF_ITEM_TYPES table).
--   itemkey   - A string generated from the application object's primary key.
--   actid     - The activity instance id.
--
procedure move_to_history(itemtype in varchar2,
                          itemkey  in varchar2,
                          actid    in number) is
begin

    -- Copy row to history table, changing status to COMPLETE/#FORCE
    -- if status is not already complete.
    INSERT INTO WF_ITEM_ACTIVITY_STATUSES_H (
      ITEM_TYPE,
      ITEM_KEY,
      PROCESS_ACTIVITY,
      ACTIVITY_STATUS,
      ACTIVITY_RESULT_CODE,
      ASSIGNED_USER,
      NOTIFICATION_ID,
      OUTBOUND_QUEUE_ID,
      BEGIN_DATE,
      END_DATE,
      DUE_DATE,
      EXECUTION_TIME,
      ERROR_NAME,
      ERROR_MESSAGE,
      ERROR_STACK,
      ACTION,
      PERFORMED_BY
    ) SELECT
      ITEM_TYPE,
      ITEM_KEY,
      PROCESS_ACTIVITY,
      wf_engine.eng_completed,
      decode(ACTIVITY_STATUS,
             wf_engine.eng_completed, ACTIVITY_RESULT_CODE,
             wf_engine.eng_force),
      ASSIGNED_USER,
      NOTIFICATION_ID,
      OUTBOUND_QUEUE_ID,
      nvl(BEGIN_DATE, sysdate),
      nvl(END_DATE, sysdate),
      DUE_DATE,
      EXECUTION_TIME,
      ERROR_NAME,
      ERROR_MESSAGE,
      ERROR_STACK,
      ACTION,
      PERFORMED_BY
    FROM WF_ITEM_ACTIVITY_STATUSES
    WHERE ITEM_TYPE = itemtype
    AND   ITEM_KEY = itemkey
    AND   PROCESS_ACTIVITY = actid;

    -- 3966635 Workflow Provisioning Project
    -- Insert added so as not to loose the change. This insert
    -- should replace the one above.
    -- INSERT INTO WF_ITEM_ACTIVITY_STATUSES_H (
    --  ITEM_TYPE,
    --  ITEM_KEY,
    --  PROCESS_ACTIVITY,
    --  ACTIVITY_STATUS,
    --  ACTIVITY_RESULT_CODE,
    --  ASSIGNED_USER,
    --  NOTIFICATION_ID,
    --  OUTBOUND_QUEUE_ID,
    --  BEGIN_DATE,
    --  END_DATE,
    --  DUE_DATE,
    --  EXECUTION_TIME,
    --  ERROR_NAME,
    --  ERROR_MESSAGE,
    --  ERROR_STACK,
    --  ACTION,
    --  PERFORMED_BY,
    --  PROV_REQUEST_ID
    --) SELECT
    --  ITEM_TYPE,
    --  ITEM_KEY,
    --  PROCESS_ACTIVITY,
    --  wf_engine.eng_completed,
    --  decode(ACTIVITY_STATUS,
    --         wf_engine.eng_completed, ACTIVITY_RESULT_CODE,
    --         wf_engine.eng_force),
    --  ASSIGNED_USER,
    --  NOTIFICATION_ID,
    --  OUTBOUND_QUEUE_ID,
    --  nvl(BEGIN_DATE, sysdate),
    --  nvl(END_DATE, sysdate),
    --  DUE_DATE,
    --  EXECUTION_TIME,
    --  ERROR_NAME,
    --  ERROR_MESSAGE,
    --  ERROR_STACK,
    --  ACTION,
    --  PERFORMED_BY,
    --  PROV_REQUEST_ID
    --FROM WF_ITEM_ACTIVITY_STATUSES
    --WHERE ITEM_TYPE = itemtype
    --AND   ITEM_KEY = itemkey
    --AND   PROCESS_ACTIVITY = actid;

    if (Wf_Engine.Debug) then
      commit;
    end if;

    Wf_Item_Activity_Status.Delete_Status(itemtype, itemkey, actid);

EXCEPTION
  when OTHERS then
    Wf_Core.Context('Wf_Engine_Util', 'Move_To_History', itemtype, itemkey,
                    to_char(actid));
    raise;

END move_to_history;

--
-- Execute_Activity (PRIVATE)
--   Execute a notification or function activity and process the result.
-- IN
--   itemtype  - A valid item type from (WF_ITEM_TYPES table).
--   itemkey   - A string generated from the application object's primary key.
--   actid     - The activity instance id.
--   funmode   - function mode (RUN/CANCEL/TIMEOUT)
--
procedure execute_activity(itemtype in varchar2,
                           itemkey  in varchar2,
                           actid    in number,
                           funmode  in varchar2)
is
  funcname    varchar2(240); -- Name of activity function
  result      varchar2(370); -- Function result
  id          varchar2(30);  -- Id for error code or notification id
  notuser     varchar2(320);  -- Notification user
  col1 pls_integer;
  col2 pls_integer;
  actdate date;
  acttype varchar2(8);
  resume_date date;
begin
  actdate := Wf_Item.Active_Date(itemtype, itemkey);
  acttype := Wf_Activity.Instance_Type(actid, actdate);

  if (acttype = wf_engine.eng_function) then
    funcname := Wf_Activity.Activity_Function(itemtype, itemkey, actid);
    if (funcname is null) then
      Wf_Core.Token('TYPE', itemtype);
      Wf_Core.Token('NAME', to_char(actid));
      Wf_Core.Raise('WFENG_ACTIVITY_FUNCTION');
    end if;
  end if;

  -- Execute the activity function
  Wf_Core.Clear;
  begin
    if (acttype = wf_engine.eng_notification) then
      Wf_Engine_Util.Notification(itemtype, itemkey, actid, funmode, result);
    elsif (acttype = wf_engine.eng_function) then
      Wf_Engine_Util.Function_Call(funcname, itemtype, itemkey, actid,
          funmode, result);
    elsif (acttype = wf_engine.eng_event) then
      Wf_Engine_Util.Event_Activity(itemtype, itemkey, actid, funmode, result);
    else
      -- Bad activity type, don't know how to execute.
      Wf_Core.Token('ITEM_TYPE', itemtype);
      Wf_Core.Token('ITEM_KEY', itemkey);
      Wf_Core.Token('ACTIVITY_ID', to_char(actid));
      Wf_Core.Token('ACTIVITY_TYPE', acttype);
      Wf_Core.Raise('WFSQL_INTERNAL');
    end if;
  exception
    when others then
      if (itemkey = wf_engine.eng_synch) then
        -- SYNCHMODE:  No saved errors allowed.
        -- Raise exception directly to calling process.
        raise;
      elsif (funmode <> wf_engine.eng_cancel) then
        -- Set error info columns if activity function raised exception,
        -- unless running in cancel mode.
        Wf_Item_Activity_Status.Set_Error(itemtype, itemkey, actid,
            wf_engine.eng_exception, FALSE);
        result := wf_engine.eng_error||':'||wf_engine.eng_exception;
      end if;
  end;

  -- The engine does not care about the result when undoing a function
  if (funmode = wf_engine.eng_cancel) then
    return;
  end if;

  -- Possible results :
  -- ERROR[:errcode]
  -- WAITING
  -- DEFERRED[:resume_date]
  -- NOTIFIED[:notid:user]
  -- COMPLETE[:result]
  -- result -> this implies COMPLETE:result

  -- Handle different results
  if (substr(result, 1, length(wf_engine.eng_error)) =
      wf_engine.eng_error) then
    -- Get the error code
    id := substr(result, length(wf_engine.eng_error)+2, 30);
    Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
                                          wf_engine.eng_error, id);

    -- Call error_process to execute any error processes.
    Wf_Engine_Util.Execute_Error_Process(itemtype, itemkey, actid, id);

  elsif (result = wf_engine.eng_waiting) then
    Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
        wf_engine.eng_waiting, '', to_date(NULL), to_date(NULL));

  elsif (substr(result, 1, length(wf_engine.eng_deferred)) =
         wf_engine.eng_deferred) then
    -- Extract the resume_date if one was returned
    col1 := instr(result, ':', 1, 1);
    if (col1 <> 0) then
      resume_date := to_date(substr(result, col1+1), wf_engine.date_format);
    else
      resume_date := to_date(NULL);
    end if;

    -- Set the status to 'DEFERRED', and reset the begin_date to the
    -- extracted resume_date if there is one.
    Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
        wf_engine.eng_deferred, wf_engine.eng_null, resume_date,
        to_date(NULL));

  elsif (substr(result, 1, length(wf_engine.eng_notified)) =
         wf_engine.eng_notified) then
    -- Get the notification id and user
    col1 := instr(result, ':', 1, 1);
    col2 := instr(result, ':', 1, 2);
    if ((col1 <> 0) and (col2 <> 0)) then
      id := substr(result, col1+1, col2-col1-1);
      notuser := substr(result, col2+1, 320);

      -- Set notification id and user, but only if not null.
      -- This is to allow for pseudo-notifications that are only blocking
      -- waiting for external completion.
      if (nvl(id, wf_engine.eng_null) <> wf_engine.eng_null) then
        Wf_Item_Activity_Status.Update_Notification(itemtype, itemkey, actid,
                                to_number(id), notuser);
      end if;
    end if;

    if ((nvl(id, wf_engine.eng_null) <> wf_engine.eng_null) and
        not Wf_Notification.OpenNotificationsExist(id)) then
      -- Notification has already been closed, presumably by an
      -- auto-routing rule that has already submitted the response.
      -- If this is the case, the notification has been responded to
      -- and is closed, but CB did NOT continue execution following
      -- completion (see comments in 'complete' processing in CB).
      -- Call complete_activity here to continue processing immediately
      -- instead of just marking activity as notified.

      result := Wf_Engine.GetItemAttrText(itemtype, itemkey, 'RESULT');
      Wf_Engine_Util.Complete_Activity(itemtype, itemkey, actid, result);

    else
      -- Notification not auto-routed, or pseudo-notification.
      -- In either case, mark status NOTIFIED to block execution.
      Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
           wf_engine.eng_notified, '', to_date(NULL),to_date(NULL));
    end if;

  else -- Assume COMPLETE
     -- Strip off optional 'COMPLETE:' tag
     if (substr(result, 1, length(wf_engine.eng_completed)+1) =
         wf_engine.eng_completed||':') then
       result := substr(result, length(wf_engine.eng_completed)+2, 30);
     else
       result := substr(result, 1, 30);
     end if;

     Wf_Engine_Util.Complete_Activity(itemtype, itemkey, actid, result);
  end if;

exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Execute_Activity', itemtype, itemkey,
                     to_char(actid), funmode);
    raise;
end execute_activity;

--
-- Function_Call (PRIVATE)
--   Call an arbitrary function using dynamic sql.
--   The function must conform to Workflow interface standard.
-- IN
--   funname   - The name of the function that is going to be executed.
--   itemtype  - A valid item type from (WF_ITEM_TYPES table).
--   itemkey   - A string generated from the application object's primary key.
--   actid     - The activity instance id.
--   funmode   - Function mode (RUN/CANCEL/TIMEOUT)
-- OUT
--   result    - The result of executing this function.
--
procedure function_call(funname    in varchar2,
                        itemtype   in varchar2,
                        itemkey    in varchar2,
                        actid      in number,
                        funmode    in varchar2,
                        result     out NOCOPY varchar2)
is
    sqlbuf              varchar2(2000);
    temp varchar2(120);
    defer_mode  boolean := false;
    setctx_mode boolean := false;
    acttype varchar2(8);
    actdate date;
    executed boolean;
begin
  --<6133861:rwunderl> If this is a no-op, we do not need to perform any
  --processing including the selector function.
  if ( upper(funname) = 'WF_STANDARD.NOOP') then
    result := wf_engine.eng_completed||':'||wf_engine.eng_null;
    return;
  end if;

  begin
   begin
    savepoint do_execute;
    -- bug 4307516
    -- do not run set context via selector function within a post-
    -- notification function
    if (Wf_Engine.context_nid is null) then
      -- First initialize context if not already done in this session
      if (wf_engine.setctx_itemtype is null or
          wf_engine.setctx_itemtype <> itemtype or
          wf_engine.setctx_itemkey is null or
          wf_engine.setctx_itemkey <> itemkey) then
        -- Context is not set, call selector.
        -- NOTE: Be sure to set setctx globals BEFORE calling
        -- execute_selector_function or recursive loop will develop.
        wf_engine.setctx_itemtype := itemtype;
        wf_engine.setctx_itemkey := itemkey;

        -- check TEST_CTX
        temp := Wf_Engine_Util.Execute_Selector_Function(itemtype, itemkey,
                    wf_engine.eng_testctx);
        if (nvl(temp, 'TRUE') = 'TRUE' ) then
          -- it does not care about the context (null)
          -- or the context is already correct ('TRUE')
          -- do nothing in either case
          null;
        elsif (temp = 'FALSE') then
          if (wf_engine.preserved_context) then
            defer_mode := true;
            --<rwunderl:5971238> Unset the itemType/itemKey context since we
            --are deferring this item to the background engine and the
            --selector has not really been called in set_ctx mode.
            wf_engine.setctx_itemtype := null;
            wf_engine.setctx_itemkey := null;

          else
            setctx_mode := true;
          end if;
        elsif (temp = 'NOTSET') then
          setctx_mode := true;
        end if;
      end if;

      if (defer_mode) then
        -- defer to background engine means return a result of 'DEFERRED'
        -- do not run the actual function, return right away.
        result := wf_engine.eng_deferred;
        return;
      end if;

      if (setctx_mode) then
       temp := Wf_Engine_Util.Execute_Selector_Function(itemtype, itemkey,
                 wf_engine.eng_setctx);
      end if;
    end if;

    Wf_Core.Clear;

    temp := '012345678901234567890123456789012345678901234567890123456789'||
            '012345678901234567890123456789012345678901234567890123456789';

    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
      wf_log_pkg.string2(wf_log_pkg.level_statement,
                        'wf.plsql.wf_engine_util.function_call.actfunc_callout',
                        'Start executing PLSQL procedure - '||funname, true);
    end if;

    Wf_Function_Call.Execute(funname, itemtype, itemkey, actid, funmode,
                             temp, executed);

    if (not executed) then
       -- Funname came from info entered through builder
       -- We may further check if there are ilegal characters like ';'
       -- However, this may cause performance impact.  Maybe better
       -- verify somewhere else first.
       -- BINDVAR_SCAN_IGNORE
       sqlbuf := 'begin ' || funname || ' (:v1, :v2, :v3, :v4, :v5); end;';
       execute immediate sqlbuf using
         in itemtype,
         in itemkey,
         in actid,
         in funmode,
         in out temp;
    end if;

    if (wf_log_pkg.level_statement >= fnd_log.g_current_runtime_level) then
      wf_log_pkg.string2(wf_log_pkg.level_statement,
                        'wf.plsql.wf_engine_util.function_call.actfunc_callout',
                        'End executing PLSQL procedure - '||funname, false);
    end if;

    -- Check for no return value error.
    -- No value was returned if temp is still the placeholder
    -- value sent in.
    if (temp =
        '012345678901234567890123456789012345678901234567890123456789'||
        '012345678901234567890123456789012345678901234567890123456789')
    then
      if (actid is null) then
         -- This is a selector function call so we expect null result
         -- Set result to null so the calling function will ignore it.
         temp := '';
      else
         --Check if the acitvity is of type Notification.
         /* Bug 1341139
           Check the activity type and incase of a post-notification function
           make Resultout optional */
        -- actdate := Wf_Item.Active_Date(itemtype, itemkey);
        -- acttype := Wf_Activity.Instance_Type(actid, actdate);

        -- if (acttype = wf_engine.eng_notification) then
	 if (Wf_Engine.context_nid is not null) then
             temp := null;
         else
             -- This is a real function.  Set an error.
             Wf_Item_Activity_Status.Set_Error(itemtype, itemkey, actid,
                                          wf_engine.eng_noresult, FALSE);
             temp := wf_engine.eng_error||':'||wf_engine.eng_noresult;
         end if;

       end if;
    end if;

    if (substr(temp, 1, 5) = wf_engine.eng_error) then
      rollback to do_execute;
    end if;

    result := temp;

   exception
     when OTHERS then
       rollback to do_execute;
       raise;
   end;
  exception
    when NO_SAVEPOINT then
      Wf_Core.Token('FUNCTION', funname);
      Wf_Core.Token('ACTIVITY', Wf_Engine.GetActivityLabel(actid));
      Wf_Core.Raise('WFENG_COMMIT_INSIDE');
  end;

exception
  when OTHERS then
    wf_engine.setctx_itemtype := '';
    wf_engine.setctx_itemkey := '';
    result := wf_engine.eng_error;
    Wf_Core.Context('Wf_Engine_Util', 'Function_Call', funname, itemtype,
        itemkey, to_char(actid), funmode);
    raise;
end function_call;

--
-- Execute_Selector_Function (PRIVATE)
--   Execute the selector function in the requested mode
-- IN
--   itemtype - itemtype
--   itemkey - itemkey
--   runmode - mode to run selector process with
-- RETURNS
--   Result of selector function, if any
--
function Execute_Selector_Function(
  itemtype in varchar2,
  itemkey in varchar2,
  runmode in varchar2)
return varchar2
is

  result varchar2(30);

  status PLS_INTEGER;
  witIND NUMBER;

begin
  -- Look for selector function.
  begin
    WF_CACHE.GetItemType(itemtype, status, witIND);

    if (status <> WF_CACHE.task_SUCCESS) then

      SELECT NAME, WF_SELECTOR
      INTO   WF_CACHE.ItemTypes(witIND)
      FROM   WF_ITEM_TYPES
      WHERE  NAME = itemtype;

    end if;

  exception
    when no_data_found then
      Wf_Core.Token('TYPE', itemtype);
      Wf_Core.Raise('WFENG_ITEM_TYPE');
  end;

  -- If no selector found, then nothing to do
  if (WF_CACHE.ItemTypes(witIND).WF_SELECTOR is null) then
    return(null);
  end if;

  -- Call selector function
  begin
    Wf_Engine_Util.Function_Call(WF_CACHE.ItemTypes(witIND).WF_SELECTOR,
                                 itemtype, itemkey, null, runmode, result);
  exception
    when others then
      -- If this is setctx call and the function failed, unset the setctx
      -- globals so that subsequent calls will attempt the function again.
      -- This is so repeated calls can be made in the same session when
      -- debugging selector functions.
      -- NOTE: Do NOT unset the flag inside function_call itself or
      -- recursive loop might develop.
      if (runmode = wf_engine.eng_setctx) then
        wf_engine.setctx_itemtype := '';
        wf_engine.setctx_itemkey := '';
      end if;
      raise;
  end;

  -- Return result unless set mode
  if (runmode <> wf_engine.eng_setctx) then
    return(result);
  else
    return(null);
  end if;
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Execute_Selector_Function',
                    itemtype, itemkey, runmode);
    raise;
end Execute_Selector_Function;

--
-- Get_Root_Process (PRIVATE)
--   Get the root process name by calling the workflow selector.
--   If there is no workflow selector available for this item type,
--   attempt to pick a default one based on starting activity.
-- IN
--   itemtype - itemtype
--   itemkey - itemkey
--   activity - starting activity instance to search for, if any
-- RETURNS
--   Root process name, or null if can't be found.
--
function Get_Root_Process(itemtype in varchar2,
                          itemkey  in varchar2,
                          activity in varchar2 default '')
return varchar2
is
  selector varchar2(240);
  root varchar2(30); -- The root process for this item key
  actdate date;
  colon pls_integer;
  process varchar2(30);  -- Start activity parent process
  label varchar2(30);    -- Start activity instance label
begin
  -- Look for selector function to execute
  root := Wf_Engine_Util.Execute_Selector_Function(itemtype, itemkey,
              wf_engine.eng_run);

  -- Return root function if one found
  if (root is not null) then
    return(root);
  end if;

  -- If no selector and no start activity, return null so calling proc
  -- can raise error.
  if (activity is null) then
    return(null);
  end if;

  -- Parse activity arg into <process_name> and <instance_label> components.
  colon := instr(activity, ':');
  if (colon <> 0) then
    -- Activity arg is <process name>:<instance label>
    process := substr(activity, 1, colon-1);
    label := substr(activity, colon+1);
  else
    -- Activity arg is just instance label
    process := '';
    label := activity;
  end if;

  --   If no selector function is defined, then query if there is one and only
  -- one root process for this itemtype with the given activity instance as a
  -- starting activity.
  --   If there is not one and only one such process return null so
  -- calling function will raise error.

  -- SS: Sysdate is not totally correct for the active date, but is the best
  -- we can do.  The item can't be created yet, because it doesn't have a
  -- root process, and you can't find the root process until the item is
  -- created - chicken or egg syndrome.  Anyway, sysdate should be close
  -- enough for almost every case since the assumption is the item will
  -- be created almost immediately after finding the root process.
  actdate := sysdate;
  begin
    select WPAP.ACTIVITY_NAME
    into root
    from WF_PROCESS_ACTIVITIES WPAP, WF_ACTIVITIES WAP,
         WF_PROCESS_ACTIVITIES WPAC, WF_ACTIVITIES WAC
    where WAP.ITEM_TYPE = get_root_process.itemtype
    and WAP.NAME = 'ROOT'
    and actdate >= WAP.BEGIN_DATE
    and actdate < nvl(WAP.END_DATE, get_root_process.actdate+1)
    and WPAP.PROCESS_ITEM_TYPE = WAP.ITEM_TYPE
    and WPAP.PROCESS_NAME = WAP.NAME
    and WPAP.PROCESS_VERSION = WAP.VERSION
    and WAC.ITEM_TYPE = WPAP.ACTIVITY_ITEM_TYPE
    and WAC.NAME = WPAP.ACTIVITY_NAME
    and get_root_process.actdate >= WAC.BEGIN_DATE
    and get_root_process.actdate <
        nvl(WAC.END_DATE, get_root_process.actdate+1)
    and WPAC.PROCESS_ITEM_TYPE = WAC.ITEM_TYPE
    and WPAC.PROCESS_NAME = WAC.NAME
    and WPAC.PROCESS_VERSION = WAC.VERSION
    and WPAC.PROCESS_NAME = nvl(get_root_process.process, WPAC.PROCESS_NAME)
    and WPAC.INSTANCE_LABEL = get_root_process.label
    and WPAC.START_END = wf_engine.eng_start;
  exception
    when too_many_rows then
      -- Multiple processes use this start activity.
      -- No way to distinguish which one to use - error.
      return(null);
    when no_data_found then
      -- No processes use this start activity.  Error.
      return(null);
  end;

  return(root);
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Get_Root_Process', itemtype, itemkey,
                    activity);
    raise;
end Get_Root_Process;

--
-- Process_Kill_ChildProcess (PRIVATE)
--   Completes all incomplete child processes with the 'FORCE' result
--   under this process.
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--
procedure process_kill_childprocess(itemtype in varchar2,
                                    itemkey in varchar2)
is
  --Cursor get all children and/or master for this process
  --and abort in cascade

  --First select all Child Processes to be aborted
  CURSOR child_proc (p_itemtype varchar2, p_itemkey varchar2) is
    SELECT wi.item_type, wi.item_key
    FROM   WF_ITEMS WI
    WHERE  END_DATE IS NULL
    AND    (WI.ITEM_TYPE <> p_itemtype
      or    WI.ITEM_KEY  <> p_itemkey)
    START  WITH WI.ITEM_TYPE = p_itemtype
    AND    WI.ITEM_KEY       = p_itemkey
    CONNECT BY PRIOR WI.ITEM_TYPE = WI.PARENT_ITEM_TYPE
    AND PRIOR WI.ITEM_KEY         = WI.PARENT_ITEM_KEY;

   /*
   --We only kill the child process
   --Select all masters
   CURSOR master_proc (p_itemtype varchar2, p_itemkey varchar2) is
     SELECT  wi.item_type, wi.item_key
     FROM    WF_ITEMS WI
     WHERE   END_DATE IS NULL
     AND     WI.ITEM_TYPE <> p_itemtype
     AND     WI.ITEM_KEY  <> p_itemkey
     START   WITH WI.ITEM_TYPE = p_itemtype
     AND     WI.ITEM_KEY       = p_itemkey
     CONNECT BY PRIOR WI.PARENT_ITEM_TYPE = WI.ITEM_TYPE
     AND PRIOR WI.PARENT_ITEM_KEY         = WI.ITEM_KEY;
    */

begin
   --Now open each cursor and call abort for each
   for child_curs in child_proc(itemtype , itemkey) loop
     wf_engine.abortprocess(child_curs.item_type,child_curs.item_key);
   end loop;

   --We only kill child process for this as master
   --Now master
   /*
   for master_curs in master_proc(itemtype , itemkey) loop
     wf_engine.abortprocess(master_curs.item_type,master_curs.item_key);
   end loop;
   */
exception
   when others then
     Wf_Core.Context('Wf_Engine_Util', 'Process_kill_childprocess', itemtype, itemkey);
     raise;
end Process_kill_childprocess;

--
-- Process_Kill_Children (PRIVATE)
--   Completes all incomplete children activities with the 'FORCE' result
--   under this process.
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--   processid - The process instance id.
--
procedure process_kill_children(itemtype in varchar2,
                                itemkey in varchar2,
                                processid in number) is

    childid pls_integer;
    actdate date;

    cursor children_to_kill (pid in pls_integer) is
    SELECT
      WIAS.PROCESS_ACTIVITY, WIAS.ACTIVITY_STATUS
    FROM WF_PROCESS_ACTIVITIES PA, WF_PROCESS_ACTIVITIES PA1,
         WF_ACTIVITIES A1, WF_ITEM_ACTIVITY_STATUSES WIAS
    WHERE PA.INSTANCE_ID = pid
    AND   PA.ACTIVITY_ITEM_TYPE = PA1.PROCESS_ITEM_TYPE
    AND   PA.ACTIVITY_NAME = PA1.PROCESS_NAME
    AND   PA1.PROCESS_VERSION = A1.VERSION
    AND   PA1.PROCESS_ITEM_TYPE = A1.ITEM_TYPE
    AND   PA1.PROCESS_NAME = A1.NAME
    AND   actdate >= A1.BEGIN_DATE
    AND   actdate < NVL(A1.END_DATE, actdate+1)
    AND   PA1.INSTANCE_ID = WIAS.PROCESS_ACTIVITY
    AND   WIAS.ITEM_TYPE = itemtype
    AND   WIAS.ITEM_KEY = itemkey
    AND   WIAS.ACTIVITY_STATUS <> 'COMPLETE';

    childarr InstanceArrayTyp; -- Place holder for all the instance id
                               -- selected from children_be_suspended cursor
    type StatusArrayTyp is table of varchar2(8)
    index by binary_integer;

    statusarr StatusArrayTyp;
    i pls_integer := 0;

    status varchar2(8);
    notid pls_integer;
    user varchar2(320);
begin
    -- SYNCHMODE: Do nothing here.
    -- Synchmode processes must be straight-line, no branching, no
    -- blocking, so there can't be anything left to kill (and if there
    -- was, we couldn't know about it anyway because nothing is saved).
    if (itemkey = wf_engine.eng_synch) then
      return;
    end if;

    -- Get the active date of the item to use for process versions.
    actdate := Wf_Item.Active_Date(itemtype, itemkey);

    -- For loop to get all the children processes ids
    for child in children_to_kill(processid) loop
      childarr(i) := child.process_activity;
      statusarr(i) := child.activity_status;
      i := i + 1;
    end loop;
    childarr(i) := '';

    -- While loop to handle all the children processes
    i := 0;
    while (childarr(i) is not null) loop
      childid := childarr(i);

      if (Wf_Activity.Instance_Type(childid, actdate) =
          wf_engine.eng_process) then
        -- If child is a process then recursively kill its children
        Wf_Engine_Util.Process_Kill_Children(itemtype, itemkey, childid);
      else
        -- Cancel any open notifications sent by this activity
        Wf_Item_Activity_Status.Notification_Status(itemtype, itemkey,
                                                    childid, notid, user);
        if (notid is not null) then
          begin
            Wf_Notification.CancelGroup(notid,'');
          exception
            when others then
              null;  -- Ignore errors in cancelling
          end;
        end if;
      end if;

      -- If activity is defered then remove it from the deferred queue
      -- if you dont remove it then the background engine will remove
      -- it when it processes and finds it doesnt correspond.
      if statusarr(i) = wf_engine.eng_deferred then
         wf_queue.PurgeEvent(wf_queue.DeferredQueue,
                  wf_queue.GetMessageHandle(wf_queue.DeferredQueue,
                           itemtype , itemkey, childid));
      end if;

      -- Complete the activity with the force result
      Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, childid,
          wf_engine.eng_completed, wf_engine.eng_force, to_date(NULL),
          SYSDATE);

      -- No needs to check null type because this is internal function
      i := i + 1;
    end loop;

exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Process_Kill_Children', itemtype,
        itemkey, to_char(processid));
    raise;

end process_kill_children;

--
-- Suspend_Child_Processes (PRIVATE)
--   Suspends all the immediate children process activities.
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--   processid - The process instance id.
--
procedure suspend_child_processes(itemtype in varchar2,
                                  itemkey in varchar2,
                                  processid in number) is

    actdate date;

    -- Select all the active children process(es) under this parent process
    cursor children_be_suspended(parent in pls_integer) is
      SELECT
        WIAS.PROCESS_ACTIVITY
      FROM WF_ITEM_ACTIVITY_STATUSES WIAS, WF_PROCESS_ACTIVITIES WPA1,
           WF_ACTIVITIES WA1, WF_PROCESS_ACTIVITIES WPA2, WF_ACTIVITIES WA2
      WHERE WPA1.INSTANCE_ID = processid
      AND WPA1.ACTIVITY_ITEM_TYPE = WA1.ITEM_TYPE
      AND WPA1.ACTIVITY_NAME = WA1.NAME
      AND actdate >= WA1.BEGIN_DATE
      AND actdate < NVL(WA1.END_DATE, actdate+1)
      AND WA1.ITEM_TYPE = WPA2.PROCESS_ITEM_TYPE
      AND WA1.NAME = WPA2.PROCESS_NAME
      AND WA1.VERSION = WPA2.PROCESS_VERSION
      AND WPA2.ACTIVITY_ITEM_TYPE = WA2.ITEM_TYPE
      AND WPA2.ACTIVITY_NAME = WA2.NAME
      AND actdate >= WA2.BEGIN_DATE
      AND actdate < NVL(WA2.END_DATE, actdate+1)
      AND WA2.TYPE = wf_engine.eng_process
      AND WPA2.INSTANCE_ID = WIAS.PROCESS_ACTIVITY
      AND WIAS.ITEM_TYPE = itemtype
      AND WIAS.ITEM_KEY = itemkey
      AND WIAS.ACTIVITY_STATUS = 'ACTIVE'; --use literal to force index

    childarr InstanceArrayTyp; -- Place holder for all the instance id
                               -- selected from children_be_suspended cursor
    i pls_integer := 0;
begin
    -- Get the active date of the item to use for process versions.
    actdate := Wf_Item.Active_Date(itemtype, itemkey);

    -- For loop to get all the children processes ids
    for child in children_be_suspended(processid) loop
      childarr(i) := child.process_activity;
      i := i + 1;
    end loop;
    childarr(i) := '';

    -- While loop to handle all the children processes
    i := 0;
    while (childarr(i) is not null) loop
      Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, childarr(i),
          wf_engine.eng_suspended, null, to_date(NULL), SYSDATE);
      suspend_child_processes(itemtype, itemkey, childarr(i));
      i := i + 1;
    end loop;

exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Suspend_Child_Processes', itemtype,
                    itemkey, to_char(processid));
    raise;
end suspend_child_processes;

--
-- Resume_Child_Processes (PRIVATE)
--   Resumes all the children process activities.
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--   processid - The process instance id.
--
procedure resume_child_processes(itemtype in varchar2,
                                 itemkey in varchar2,
                                 processid in number) is

    actdate date;

    -- Select all the suspended children processes under this parent process
    cursor children_be_resumed(parent in pls_integer) is
      SELECT
      WIAS.PROCESS_ACTIVITY
      FROM WF_ITEM_ACTIVITY_STATUSES WIAS, WF_PROCESS_ACTIVITIES WPA1,
           WF_PROCESS_ACTIVITIES WPA2, WF_ACTIVITIES WA
      WHERE WPA1.INSTANCE_ID = processid
      AND WPA1.ACTIVITY_ITEM_TYPE = WA.ITEM_TYPE
      AND WPA1.ACTIVITY_NAME = WA.NAME
      AND actdate >= WA.BEGIN_DATE
      AND actdate < NVL(WA.END_DATE, actdate+1)
      AND WA.ITEM_TYPE = WPA2.PROCESS_ITEM_TYPE
      AND WA.NAME = WPA2.PROCESS_NAME
      AND WA.VERSION = WPA2.PROCESS_VERSION
      AND WPA2.INSTANCE_ID = WIAS.PROCESS_ACTIVITY
      AND WIAS.ITEM_TYPE = itemtype
      AND WIAS.ITEM_KEY = itemkey
      AND WIAS.ACTIVITY_STATUS = 'SUSPEND'; -- use literal to force index

    childarr InstanceArrayTyp; -- Place holder for all the instance id
                               -- selected from children_be_resumed cursor
    i pls_integer := 0;

begin
    -- Get the active date of the item to use for process versions.
    actdate := Wf_Item.Active_Date(itemtype, itemkey);

    -- For loop to get all the children processes id
    for child in children_be_resumed(processid) loop
      childarr(i) := child.process_activity;
      i := i + 1;
    end loop;
    childarr(i) := '';

    -- While loop to handle all the children processes
    i := 0;
    while (childarr(i) is not null) loop
      Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, childarr(i),
          wf_engine.eng_active, null, null, SYSDATE);
      resume_child_processes(itemtype, itemkey, childarr(i));
      i := i + 1;
    end loop;

exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Resume_Child_Processes', itemtype,
                    itemkey, to_char(processid));
    raise;
end resume_child_processes;

--
-- Notification (PRIVATE)
--   This is the default notification activity function.
--   It looks up the notification info and then sends it.
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--   actid     - The notification process activity(instance id).
--   funcmode  - Function mode (RUN/CANCEL)
-- OUT
--   result    - NOTIFIED:notificationid:user
--
procedure Notification(
  itemtype   in varchar2,
  itemkey    in varchar2,
  actid      in number,
  funcmode   in varchar2,
  result     out NOCOPY varchar2)
is
  msg varchar2(30);
  msgtype varchar2(8);
  prole varchar2(320);
  expand_role varchar2(1);
begin
  -- SYNCHMODE: Not allowed
  if (itemkey = wf_engine.eng_synch) then
    Wf_Core.Token('OPERATION', 'Wf_Engine.Notification');
    Wf_Core.Raise('WFENG_SYNCH_DISABLED');
  end if;

  -- Get the message, perform role, and timeout
  -- msg and prole could came back as null since they are nullable columns
  Wf_Activity.Notification_Info(itemtype, itemkey, actid, msg, msgtype,
                                expand_role);
  prole := Wf_Activity.Perform_Role(itemtype, itemkey, actid);

  Wf_Engine_Util.Notification_Send(itemtype, itemkey, actid, msg, msgtype,
                                prole, expand_role, result);

exception
  when others then
    wf_core.context('Wf_Engine_Util', 'Notification', itemtype, itemkey,
                    to_char(actid), funcmode);
    raise;
end Notification;

--
-- Notification_Send (PRIVATE)
--   Actually sends the notification
-- IN
--   itemtype  - a valid item type
--   itemkey   - a string generated from the application object's primary key.
--   actid     - the notification process activity(instance id).
--   msg       - name of msg to send
--   msgtype   - its message type
--   prole     - performer role
--   expand_role the expand role arg for notifications
-- OUT
--   result    - notified:notificationid:user
--
procedure Notification_Send(
  itemtype   in varchar2,
  itemkey    in varchar2,
  actid      in number,
  msg        in varchar2,
  msgtype    in varchar2,
  prole      in varchar2,
  expand_role in varchar2,
  result     out NOCOPY varchar2)
is
  priority number;
  notid pls_integer;
  ctx varchar2(2000);
  duedate date;
  dummy pls_integer;
  performer varchar2(320);
begin
   if (msg is null) then
        Wf_Core.Token('TYPE', itemtype);
        Wf_Core.Token('ACTID', to_char(actid));
        Wf_Core.Raise('WFENG_NOTIFICATION_MESSAGE');
   end if;

   if (prole is null) then
     Wf_Core.Token('TYPE', itemtype);
     Wf_Core.Token('ACTID', to_char(actid));
     Wf_Core.Raise('WFENG_NOTIFICATION_PERFORMER');
   end if;

/* Bug 2156047 */
  -- clear global variables to store context info
   wf_engine.g_nid := '';
   wf_engine.g_text := '';

   -- Construct context as itemtype:key:actid
   ctx := itemtype||':'||itemkey||':'||to_char(actid);

   -- Mark duedate of notification as timeout date of activity
   duedate := Wf_Item_Activity_Status.Due_Date(itemtype, itemkey, actid);

   -- Check for #PRIORITY activity attribute to override default
   -- priority of this notification
   begin
     priority := Wf_Engine.GetActivityAttrNumber(itemtype, itemkey, actid,
                     wf_engine.eng_priority, ignore_notfound=>TRUE);
   exception
     when others then
       if (wf_core.error_name = 'WFENG_ACTIVITY_ATTR') then
         -- If no priority attr default to null
         priority := '';
         Wf_Core.Clear;
       else
         raise;
       end if;
   end;

   -- Send notification, either to expanded role or singly
   -- depending on expand_role flag.
   if (expand_role = 'Y') then
     notid := Wf_Notification.SendGroup(prole, msgtype, msg, duedate,
                                        'WF_ENGINE.CB', ctx, '', priority);
   else
     notid := Wf_Notification.Send(prole, msgtype, msg, duedate,
                        'WF_ENGINE.CB', ctx, '', priority);
   end if;

   -- Check for a change in the performer.  If the notification
   -- was automatically routed by Send, the assigned_user might have
   -- been updated.  If so, reset the performer to the new role to
   -- avoid over-writing with the old value.
   performer := nvl(Wf_Activity.Perform_Role(itemtype, itemkey, actid),
                    prole);

   -- If there are no respond-type attributes to this message,
   -- then no response is expected.  Instead of returning a 'NOTIFIED'
   -- response, return a response of '' so that the activity will
   -- complete immediately instead of waiting for the notification
   -- to be responded to.
   begin
     select 1 into dummy from sys.dual where exists
     (select null
     from WF_MESSAGE_ATTRIBUTES
     where MESSAGE_TYPE = msgtype
     and MESSAGE_NAME = msg
     AND SUBTYPE = 'RESPOND');

     -- Response is expected.
     -- Return result of 'NOTIFIED:notid:role'.
     result := Wf_Engine.Eng_Notified||':'||to_char(notid)||':'||performer;

   exception
     when no_data_found then
       -- No respond attributes.
       -- Set notification id, then complete immediately.
       Wf_Item_Activity_Status.Update_Notification(itemtype, itemkey, actid,
                              notid, performer);
       result := Wf_Engine.Eng_Null;
   end;

/* Bug 2156047 */
-- Need to cache the Notification id and Performer role for
-- executing Post Notification function

  Wf_Engine.g_nid := notid;
  Wf_Engine.g_text := performer;

exception
  when others then
  Wf_Core.Context('Wf_Engine_Util', 'Notification_Send', itemtype, itemkey,
                  to_char(actid), msgtype||':'||msg);
  raise;
end Notification_Send;

--Notification_Copy (PRIVATE)
-- Copies a notification by creating a new one with same attributes.
-- IN
--   copy_nid  - the notifiation id to copy
--   itemtype  -
--   itemkey   -
-- OUT
--   nid       - tyhe new notification id that was created
--
procedure Notification_Copy (
          copy_nid in  number,
          old_itemkey in varchar2,
          new_itemkey in varchar2,
          nid in out NOCOPY number) is

gid pls_integer:=0;

cursor ntf_details is
select
     notification_id,
     group_id,
     MESSAGE_TYPE,    MESSAGE_NAME,
     RECIPIENT_ROLE,  ORIGINAL_RECIPIENT,
     STATUS,
     wf_core.random,
     MAIL_STATUS, PRIORITY,
     BEGIN_DATE,  END_DATE, DUE_DATE,
     USER_COMMENT,CALLBACK,
     CONTEXT
     from wf_notifications
     where group_id = copy_nid;

begin
   for ntf_row in ntf_details loop

      -- create a new notification
      select WF_NOTIFICATIONS_S.NEXTVAL
      into nid
      from SYS.DUAL;

      -- Use nid of the first notification as group id for the rest
      -- but only if notification is expand_roles
      if (gid =0) then
        gid := nid;
      end if;

      insert into WF_NOTIFICATIONS (
        NOTIFICATION_ID, GROUP_ID,
        MESSAGE_TYPE,    MESSAGE_NAME,
        RECIPIENT_ROLE,  ORIGINAL_RECIPIENT,
        STATUS,
        ACCESS_KEY,
        MAIL_STATUS, PRIORITY,
        BEGIN_DATE,  END_DATE, DUE_DATE,
        USER_COMMENT,CALLBACK,
        CONTEXT)
      values (
        nid, gid,
        ntf_row.MESSAGE_TYPE,    ntf_row.MESSAGE_NAME,
        ntf_row.RECIPIENT_ROLE,  ntf_row.ORIGINAL_RECIPIENT,
        ntf_row.STATUS,
        wf_core.random,
        ntf_row.MAIL_STATUS, ntf_row.PRIORITY,
        ntf_row.BEGIN_DATE,  ntf_row.END_DATE, ntf_row.DUE_DATE,
        ntf_row.USER_COMMENT,ntf_row.CALLBACK,
        replace(ntf_row.CONTEXT,':'||old_itemkey||':',':'||new_itemkey||':'));


        -- create notification attributes
        insert into WF_NOTIFICATION_ATTRIBUTES (
            NOTIFICATION_ID,
            NAME,
            TEXT_VALUE,
            NUMBER_VALUE,
            DATE_VALUE)
        select
            nid,
            NAME,
            TEXT_VALUE,
            NUMBER_VALUE,
            DATE_VALUE
        from WF_NOTIFICATION_ATTRIBUTES
        where notification_id = ntf_row.notification_id
	union all
        select nid,
               NAME,
               TEXT_DEFAULT,
               NUMBER_DEFAULT,
               DATE_DEFAULT
        from   WF_MESSAGE_ATTRIBUTES
        where  MESSAGE_TYPE = ntf_row.MESSAGE_TYPE
        and    MESSAGE_NAME = ntf_row.MESSAGE_NAME
        and    name not in
                (select name
                 from   WF_NOTIFICATION_ATTRIBUTES
                 where  notification_id = ntf_row.notification_id);

        -- Copy associated Notification Comments
        INSERT INTO wf_comments
          (notification_id,
           from_role,
           from_user,
           to_role,
           to_user,
           comment_date,
           action,
           action_type,
           user_comment,
           proxy_role)
        SELECT nid,
              from_role,
              from_user,
              to_role,
              to_user,
              comment_date,
              action,
              action_type,
              user_comment,
              proxy_role
        FROM   wf_comments
        WHERE  notification_id = ntf_row.notification_id;

   end loop;

   nid:=gid;

exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Notification_Copy');
    raise;
end notification_copy;

--Notification_refresh (PRIVATE)
-- Refreshes all itemtype message attribute
-- for all sent messages in this itemtype/itmekey
-- IN
--   itemtype  - a valid item type
--   itemkey   - a string generated from the application object's primary key.
--
procedure notification_refresh
         (itemtype in varchar2,
          itemkey in varchar2) is

  --attr_name varchar2(30);
  --attr_type varchar2(8);
  attr_tvalue varchar2(4000);
  attr_nvalue number;
  attr_dvalue date;

  cursor message_attrs_cursor(itemtype varchar2, itemkey varchar2) is
    select ma.NAME, ma.TYPE, ma.SUBTYPE,
           ma.TEXT_DEFAULT, ma.NUMBER_DEFAULT, ma.DATE_DEFAULT,
           n.notification_id
    from wf_item_activity_statuses_h ias,
         wf_notifications n,
         wf_message_attributes ma
    where ias.item_type = itemtype
    and   ias.item_key = itemkey
    and   ias.notification_id = n.notification_id
    and   ma.message_type = n.message_type
    and   ma.message_name = n.message_name
    and   ma.value_type = 'ITEMATTR';

begin

  --
  -- Look up all notification attributes and reset them
  --
  for message_attr_row in message_attrs_cursor(itemtype, itemkey) loop

     --dont call the notification callback function  because this will
     --only ever be called from the engine.

     --attr_name := message_attr_row.name;
     --attr_type := message_attr_row.type;
     attr_tvalue := '';
     attr_nvalue := '';
     attr_dvalue := '';

     if (message_attr_row.type = 'NUMBER') then
       attr_nvalue := wf_engine.GetItemAttrNumber(itemtype, itemkey, message_attr_row.TEXT_DEFAULT);
     elsif (message_attr_row.type = 'DATE') then
       attr_dvalue := wf_engine.GetItemAttrDate(itemtype, itemkey, message_attr_row.TEXT_DEFAULT);
     else
       attr_tvalue := wf_engine.GetItemAttrText(itemtype, itemkey, message_attr_row.TEXT_DEFAULT);
     end if;

     --
     -- Update the notification attribute
     --
     update WF_NOTIFICATION_ATTRIBUTES
     set    TEXT_VALUE = attr_tvalue,
            NUMBER_VALUE = attr_nvalue,
            DATE_VALUE = attr_dvalue
     where  notification_id = message_attr_row.notification_id
     and    name = message_attr_row.name;
  end loop;


exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Notification_refresh');
    raise;
end notification_refresh;


--
-- Execute_Error_Process (Private)
--   Attempts to run an error process for an activity that has error'ed out.
-- IN
--   itemtype  - a valid item type
--   itemkey   - a string generated from the application object's primary key.
--   actid     - the notification process activity(instance id).
--   result    - activity result code
--
procedure execute_error_process (
  itemtype  in varchar2,
  itemkey   in varchar2,
  actid     in number,
  result    in varchar2)
is
  errortype       varchar2(8) := '';
  errorprocess    varchar2(30) := '';
  erractid        pls_integer;
  actdate         date;
  root            varchar2(30);
  version         pls_integer;
  rootid          pls_integer;
  errkey          varchar2(240);
  notid           pls_integer;
  user            varchar2(320);
  label           varchar2(62);
  errname         varchar2(30);
  errmsg          varchar2(2000);
  errstack        varchar2(4000);
  err_url         varchar2(2000);
  err_userkey       varchar2(240);
  newstatus       varchar2(8);
  newresult       varchar2(30);

begin
  actdate := Wf_Item.Active_Date(itemtype, itemkey);

  --
  -- Look for an error process to execute.
  --   If this activity does not have an error process, look for the
  -- nearest parent process activity that does have one.
  --
  Wf_Item.Root_Process(itemtype, itemkey, root, version);
  rootid := Wf_Process_Activity.RootInstanceId(itemtype, itemkey, root);
  if (rootid is null) then
      Wf_Core.Token('TYPE', itemtype);
      Wf_Core.Token('KEY', itemkey);
      Wf_Core.Token('NAME', root);
      Wf_Core.Raise('WFENG_ITEM_ROOT');
  end if;

  erractid := actid;

  Wf_Activity.Error_Process(erractid, actdate, errortype, errorprocess);

  while ((errorprocess is null) and  (erractid <> rootid)) loop
      erractid := Wf_Engine_Util.Activity_Parent_Process(itemtype, itemkey,
                      erractid);
      Wf_Activity.Error_Process(erractid, actdate, errortype, errorprocess);
  end loop;

  --  If no error process, then nothing to do.
  --  Provided WF_HANDLEERRORS is set to 'N'
  if (errorprocess is null) then
      --Bug 2769454
      --We need to be able to launch atleast the deafult error
      --process if no process has been defined on process or
      --the parent process.
      --To maintain the old functionality we would create a token
      --WF_HANDLEERRORS which if set to 'Y' we would run the default_error
      --process and incase of 'N' (anything other than N is traeted as Y)
      -- would have the old behaviour.

      --For eliminating potential infinite loop now if
      --there is a scenario of the default error processing
      --erroring out due to some reason
      if (( wf_core.translate('WF_HANDLEERRORS') <> 'N')
             AND (itemtype <> 'WFERROR')) then
        --Set the error process and type to DEFAULT_ERROR
        errortype    := 'WFERROR';
        errorprocess := 'DEFAULT_ERROR';
      else
        return;
      end if;
  end if;

  -- Get key for errorprocess: concatenate WF to ensure unique
  select 'WF'||to_char(WF_ERROR_PROCESSES_S.NEXTVAL)
  into errkey
  from SYS.DUAL;

  -- Create process and set item parent columns with ids of
  -- activity initiating error.
  Wf_Engine.CreateProcess(errortype, errkey, errorprocess);
  wf_engine.SetItemParent(errortype, errkey, itemtype, itemkey,
                          to_char(actid));

  -- Select and set pre-defined error attributes.
  wf_item_activity_status.notification_status(itemtype, itemkey, actid,
      notid, user);
  label := Wf_Engine.GetActivityLabel(actid);

  wf_item_activity_status.error_info(itemtype, itemkey, actid,
      errname, errmsg, errstack);

  -- look up the monitor URL
  err_url := WF_MONITOR.GetEnvelopeURL
                   ( x_agent          => wf_core.translate('WF_WEB_AGENT'),
                     x_item_type      => itemtype,
                     x_item_key       => itemkey,
                     x_admin_mode     => 'YES');
  -- look up the user key
  err_userkey := Wf_Engine.GetItemUserKey(itemtype, itemkey);

  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_ITEM_TYPE', itemtype);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_ITEM_KEY', itemkey);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_ACTIVITY_LABEL', label);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'NUMBER',
      'ERROR_ACTIVITY_ID', actid);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_RESULT_CODE', result);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'NUMBER',
      'ERROR_NOTIFICATION_ID', to_char(notid));
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_ASSIGNED_USER', user);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_NAME', errname);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_MESSAGE', errmsg);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_STACK', errstack);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_MONITOR_URL', err_url);
  Wf_Engine_Util.SetErrorItemAttr(errortype, errkey, 'TEXT',
      'ERROR_USER_KEY', err_userkey);

  -- Run the error process.
  Wf_Engine.StartProcess(errortype, errkey);

exception
  when others then
    -- If an error is raised in error process, do NOT raise another exception.
    -- Append the new error to the original error in WIAS error columns,
    -- then clear and ignore the exception.
    Wf_Item_Activity_Status.Set_Error(itemtype, itemkey, actid, '', TRUE);
    Wf_Core.Clear;
end Execute_Error_Process;

--
-- SetErrorItemAttr (PRIVATE)
-- Called by execute_error_process to set error item attributes.
-- IN
--   error_type - error process itemtype
--   error_key - error process itemkey
--   attrtype - attribute type
--   item_attr - attribute name
--   avalue - attribute value
--
procedure SetErrorItemAttr (
  error_type in varchar2,
  error_key  in varchar2,
  attrtype   in varchar2,
  item_attr  in varchar2,
  avalue     in varchar2)
is
begin
  if (attrtype = 'TEXT') then
     Wf_Engine.SetItemAttrText(error_type, error_key, item_attr, avalue);
  else
     Wf_Engine.SetItemAttrNumber(error_type, error_key, item_attr, to_number(avalue));
  end if;
exception
  when others then
    if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
      if (attrtype = 'TEXT') then
        Wf_Engine.AddItemAttr(error_type, error_key, item_attr, avalue);
        WF_CORE.Clear;
      else
        Wf_Engine.AddItemAttr(error_type, error_key, item_attr, '',
            to_number(avalue));
        WF_CORE.Clear;
      end if;
    else
      raise;
    end if;
end SetErrorItemAttr;


--
-- Execute_Post_NTF_Function (PRIVATE)
--   Execute the post-notification function to see if activity should complete.
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--   actid     - The notification process activity(instance id).
--   funmode   - Run post-notification function in run or cancel mode
-- OUT
--   pntfstatus - Flag to indicate post-notification results.  Values are
--     'WAITING'  - post-notification function for activity is not yet complete
--     'COMPLETE' - post-notification function for activity is complete
--     null       - this is not a post-notification activity
--   pntfresult - Result of post-notification function if pntfstatus='COMPLETE'
--
procedure Execute_Post_NTF_Function (itemtype in varchar2,
                                     itemkey in varchar2,
                                     actid in number,
                                     funmode in varchar2,
                                     pntfstatus out NOCOPY varchar2,
                                     pntfresult out NOCOPY varchar2)
is
  message varchar2(30);
  msgtype varchar2(8);
  expand_role varchar2(1);
  funcname varchar2(240);
  result varchar2(240);
  errcode varchar2(30);
  l_notid     number;
  l_responder varchar2(320);

begin
  -- See if a post-notification function was attached
  funcname := Wf_Activity.Activity_Function(itemtype, itemkey, actid);

  -- If there is no post-notification function,
  -- then no action is required so exit immediately.
  if (funcname is null) then
    pntfstatus := null;
    pntfresult := null;
    return;
  end if;

  /* Bug 2156047 */
  -- Set global context areas.
  -- This is context information for use by post ntf function
  -- when executing in modes RUN, RESPOND, TRANSFER etc.
  Wf_Item_Activity_Status.Notification_Status(itemtype, itemkey, actid,
                                              l_notid, l_responder);
  Wf_Engine.context_nid := l_notid;
  Wf_Engine.context_text := l_responder;


  -- There is a post-notification function.  Execute it.
  begin
    Wf_Engine_Util.Function_Call(funcname, itemtype, itemkey, actid, funmode,
        result);
  exception
    -- Set error info columns if post-notification function raised exception,
    -- unless running in cancel mode.
    when others then
      if (funmode <> wf_engine.eng_cancel) then
        Wf_Item_Activity_Status.Set_Error(itemtype, itemkey, actid,
            wf_engine.eng_exception, FALSE);
        result := wf_engine.eng_error||':'||wf_engine.eng_exception;
      end if;
  end;

/* Bug 2156047 */
 -- clear context values
  Wf_Engine.context_nid := '';
  Wf_Engine.context_text := '';

  -- The engine does not care about the result when undoing a function
  if (funmode = wf_engine.eng_cancel) then
    return;
  end if;


  -- Handle different results
  if ((result is null) or (result = wf_engine.eng_null)) then
    -- Assume a null result means post-notification function is not
    -- implemented.
    pntfstatus := null;
    pntfresult := null;
  elsif (substr(result, 1, length(wf_engine.eng_error)) =
      wf_engine.eng_error) then
    -- Get the error code
    errcode := substr(result, length(wf_engine.eng_error)+2, 30);
    Wf_Item_Activity_Status.Create_Status(itemtype, itemkey, actid,
                                          wf_engine.eng_error, errcode);

    -- Call error_process to execute any error processes.
    Wf_Engine_Util.Execute_Error_Process(itemtype, itemkey, actid, errcode);

    -- Return status waiting to prevent activity from completing.
    pntfstatus := wf_engine.eng_waiting;
    pntfresult := null;
  elsif (result = wf_engine.eng_waiting) then
    -- Post-notification function is not yet completed.
    -- Return status waiting to prevent activity from completing.
    pntfstatus := wf_engine.eng_waiting;
    pntfresult := null;
  else
    -- Result must be COMPLETE.  Other statuses are not allowed for
    -- post-notification functions.

    -- Strip off optional 'COMPLETE:' tag from result
    if (substr(result, 1, length(wf_engine.eng_completed)+1) =
        wf_engine.eng_completed||':') then
      result := substr(result, length(wf_engine.eng_completed)+2, 30);
    end if;

    -- Return complete status and result.
    pntfstatus := wf_engine.eng_completed;
    pntfresult := result;
  end if;
  return;
exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Execute_Post_NTF_Function', itemtype,
        itemkey, to_char(actid), funmode);
    raise;
end Execute_Post_NTF_Function;

--
-- Execute_Notification_Callback (PRIVATE)
--   Look for a function on a notification activity and execute in
--   appropriate mode.
--   Called from CB when a notification is acted on.
-- IN
--   funcmode - callback mode (FORWARD, TRANSFER, RESPOND)
--   itemtype - item type of notification context
--   itemkey - item key of notification context
--   actid - activity of notification context
--   ctx_nid - notification id
--   ctx_text - new recipient role (FORWARD or TRANSFER)
--
procedure Execute_Notification_Callback(
  funcmode in varchar2,
  itemtype in varchar2,
  itemkey in varchar2,
  actid in number,
  ctx_nid in number,
  ctx_text in varchar2)
is
  funcname varchar2(240);
  result varchar2(2000);
  errcode varchar2(2000);

begin
  funcname := Wf_Activity.Activity_Function(itemtype, itemkey, actid);

  -- No callback function, nothing to do.
  if (funcname is null) then
    return;
  end if;

  -- Set global context areas.
  -- This is context information for use by callback function while
  -- running.
  Wf_Engine.context_nid := ctx_nid;
  Wf_Engine.context_text := ctx_text;

  -- Bug 3065814
  -- Set all context information for the post-notification function
  wf_engine.context_user           := wf_notification.g_context_user;
  wf_engine.context_user_comment   := wf_notification.g_context_user_comment ;
  wf_engine.context_recipient_role := wf_notification.g_context_recipient_role ;
  wf_engine.context_original_recipient:= wf_notification.g_context_original_recipient;
  wf_engine.context_from_role      := wf_notification.g_context_from_role ;
  wf_engine.context_new_role       := wf_notification.g_context_new_role  ;
  wf_engine.context_more_info_role := wf_notification.g_context_more_info_role  ;
  wf_engine.context_proxy          := wf_notification.g_context_proxy;

  wf_engine.context_user_key := wf_engine.GetItemUserKey(itemtype, itemkey);

  -- Call function in requested mode
  Wf_Engine_Util.Function_Call(funcname, itemtype, itemkey, actid,
                               funcmode, result);

  -- Error handling...
  -- 1. If function raises its own exception, let it trickle up.
  -- 2. If function returned a result of 'ERROR:...', convert it
  --    to a generic exception and let that trickle up so that
  --    the originating function will fail.
  if (substr(result, 1, length(wf_engine.eng_error)) =
      wf_engine.eng_error) then
    errcode := substr(result, length(wf_engine.eng_error)+2, 2000);
    Wf_Core.Token('ERRCODE', errcode);
    Wf_Core.Raise('WFENG_NOTIFICATION_FUNCTION');
  end if;

  -- Clear global context areas
  Wf_Engine.context_nid := '';
  Wf_Engine.context_text := '';

  --Bug 3065814
  wf_engine.context_user  :=  '';
  wf_engine.context_user_comment := '';
  wf_engine.context_recipient_role := '';
  wf_engine.context_original_recipient:='';
  wf_engine.context_from_role :='';
  wf_engine.context_new_role  :='';
  wf_engine.context_more_info_role  := '';
  wf_engine.context_user_key := '';
  wf_engine.context_proxy := '';

exception
  when others then
    -- Clear global context, just in case
    Wf_Engine.context_nid := '';
    Wf_Engine.context_text := '';
    -- Bug 3065814
    wf_engine.context_user  :=  '';
    wf_engine.context_user_comment := '';
    wf_engine.context_recipient_role := '';
    wf_engine.context_original_recipient:='';
    wf_engine.context_from_role :='';
    wf_engine.context_new_role  :='';
    wf_engine.context_more_info_role  := '';
    wf_engine.context_user_key := '';
    wf_engine.context_proxy := '';

    Wf_Core.Context('Wf_Engine_Util', 'Execute_Notification_Callback',
                    funcmode, itemtype, itemkey, to_char(actid),
                    to_char(ctx_nid)||':'||ctx_text);
    raise;
end Execute_Notification_Callback;

--
-- Activity_Timeout (PUBLIC)
-- IN
--   actid    - Process activity (instance id).
function Activity_Timeout(actid in number) return varchar2
is
  waavIND NUMBER;
  status  PLS_INTEGER;

begin
  -- Check Arguments
  if (actid is null) then
    Wf_Core.Token('ACTID', nvl(actid, 'NULL'));
    Wf_Core.Raise('WFSQL_ARGS');
  end if;
  -- Check value_type flag for possible item_attribute ref.
  WF_CACHE.GetActivityAttrValue(actid, '#TIMEOUT', status, waavIND);

  if (status <> WF_CACHE.task_SUCCESS) then
    open curs_activityattr (actid, '#TIMEOUT');
    fetch curs_activityattr into WF_CACHE.ActivityAttrValues(waavIND);
    close curs_activityattr;
  end if;

  if (WF_CACHE.ActivityAttrValues(waavIND).NUMBER_VALUE is not null) then
    return(to_char(WF_CACHE.ActivityAttrValues(waavIND).NUMBER_VALUE));
  elsif (WF_CACHE.ActivityAttrValues(waavIND).DATE_VALUE is not null) then
    return(to_char(WF_CACHE.ActivityAttrValues(waavIND).DATE_VALUE)||' '||
           to_char(WF_CACHE.ActivityAttrValues(waavIND).DATE_VALUE,
                   'HH24:MI:SS'));

  elsif (WF_CACHE.ActivityAttrValues(waavIND).VALUE_TYPE = 'ITEMATTR') then
    return(substrb(WF_CACHE.ActivityAttrValues(waavIND).TEXT_VALUE, 1, 30));

  else
    return(null);

  end if;

exception
  when no_data_found then
    --Check to ensure that cursor is not open
    if (curs_activityattr%ISOPEN) then
      CLOSE curs_activityattr;
    end if;

    WF_CACHE.ActivityAttrValues(waavIND).PROCESS_ACTIVITY_ID := actid;
    WF_CACHE.ActivityAttrValues(waavIND).NAME := '#TIMEOUT';
    WF_CACHE.ActivityAttrValues(waavIND).VALUE_TYPE := 'CONSTANT';
    WF_CACHE.ActivityAttrValues(waavIND).TEXT_VALUE := '';
    WF_CACHE.ActivityAttrValues(waavIND).NUMBER_VALUE := '';
    WF_CACHE.ActivityAttrValues(waavIND).DATE_VALUE := to_date(NULL);
    return(null);

  when others then
    --Check to ensure that cursor is not open
    if (curs_activityattr%ISOPEN) then
      CLOSE curs_activityattr;
    end if;

    return(null);

end Activity_Timeout;

--
-- Event_Activity (PRIVATE)
--   Execute an event activity.
-- IN
--   itemtype  - A valid item type
--   itemkey   - A string generated from the application object's primary key.
--   actid     - The event process activity(instance id).
--   funcmode  - Function mode (RUN/CANCEL)
-- OUT
--   result    - event activity reslt
--
procedure Event_Activity(
  itemtype   in varchar2,
  itemkey    in varchar2,
  actid      in number,
  funcmode   in varchar2,
  result     out NOCOPY varchar2)
is
  event_name varchar2(240); -- Event name filter
  direction varchar2(8);    -- Event direction (receive/raise/send)
  evtname varchar2(240);    -- Event name (for raise)
  evtkey  varchar2(2000);   -- Event key (for raise)
  msgdata clob;             -- Message contents as clob (for raise)
  evtmsg  wf_event_t;       -- Event message (for send)
  attr varchar2(4000);      -- Attrs for event override (for send)
  priority number;          -- Event priority (for send)
  atsign pls_integer;       -- Used to parse agent@system
  outagent wf_agent_t;      -- Out agent override (send)
  toagent wf_agent_t;       -- To agent override (send)
  atype    varchar2(8);
  asubtype varchar2(8);
  aformat  varchar2(240);
  avalue   varchar2(4000);
  parameterlist wf_parameter_list_t;
  parametert wf_parameter_t;
  counter  pls_integer;
  block_mode varchar2(1);
  cb_event_name varchar2(240);
  cb_event_key varchar2(2000);

  -- BUG 2452470 CTILLEY
  -- Updated the cursor to select value_type and text_value to pass based
  -- on the type since the item attribute may not be the same name as the
  -- activity attribute

  CURSOR CURS_ACTATTRS IS
  SELECT NAME, VALUE_TYPE, TEXT_VALUE
  FROM WF_ACTIVITY_ATTR_VALUES
  WHERE PROCESS_ACTIVITY_ID = EVENT_ACTIVITY.ACTID
  AND substrb(NAME,1,1) <> '#';

  --Bug 2761887
  l_length    integer;

  -- Bug 3908657
  l_fresh_parameterlist boolean;

begin
  -- Do nothing in cancel or timeout mode
  if (funcmode <> wf_engine.eng_run) then
    result := wf_engine.eng_null;
    return;
  end if;

  -- Get event name and direction
  Wf_Activity.Event_Info(itemtype, itemkey, actid, event_name,
      direction);

  if (direction = wf_engine.eng_receive) then
    -- RECEIVE event
    -- Block and wait for event to be received.
    result := wf_engine.eng_notified||':'||wf_engine.eng_null||
                 ':'||wf_engine.eng_null;
    return;

  elsif (direction = wf_engine.eng_raise) then
    -- RAISE event
    -- Retrieve applicable attrs
    -- #EVENTNAME
    evtname := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid,
                   wf_engine.eng_eventname);
    if (evtname is null) then
      Wf_Core.Token('#EVENTNAME', '');
      Wf_Core.Raise('WFSQL_ARGS');
    end if;
    -- #EVENTKEY
    evtkey := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid,
                  wf_engine.eng_eventkey);
    if (evtkey is null) then
      Wf_Core.Token('#EVENTKEY', '');
      Wf_Core.Raise('WFSQL_ARGS');
    end if;

    -- #EVENTMESSAGE (may be null)
    msgdata := Wf_Engine.GetActivityAttrClob(itemtype, itemkey, actid,
                      Wf_Engine.eng_eventmessage);

    --Bug #2761887
    --Now verify if we have the reserved activity attribute
    --#EVENTMESSAGE2 is set
    begin
      evtmsg := Wf_Engine.getActivityAttrEvent(itemtype, itemkey,
                                            actid, wf_engine.eng_defaultevent);

    exception
      when others then
        --If this atrribute does not exist the exception is
        --raised we just ignore it.
        if (wf_core.error_name ='WFENG_ACTIVITY_ATTR') then
          --we will initialise the event here so that the
          --parameterlist is usable down the line
          wf_event_t.initialize(evtmsg);
          --clear the error stack
          wf_core.clear;
        else
          --Any other error raise it
          raise;
        end if;

    end ;

    --If the clob and parameterlist exist we will just set them
    l_length := dbms_lob.getlength(msgdata);
    IF l_length IS NULL THEN
      --Set the event message from the default #RAISEEVENT
      msgdata := evtmsg.event_data ;
      --we will add the parameterlist at the end
    end if;

    -- Check if any Activity Attributes set, these will
    -- be set in the parameter list

    for attr in curs_actattrs loop

      -- Reset Attribute Value
      avalue :=null;

      -- Bug2452470 CTILLEY: Need to take into account that the activity
      -- attribute may not be an item attribute and even if it is it may
      -- not be the same name as the activity attribute.

      -- Get the activity attribute type
      if attr.value_type = 'ITEMATTR' then
        wf_engine.GetItemAttrInfo(itemtype, attr.text_value, atype,
                                  asubtype, aformat);
      else
        wf_engine.GetActivityAttrInfo(itemtype, itemkey, actid, attr.name,
                                      atype, asubtype, aformat);
      end if;

      -- NUMBER Value
      if (atype = 'NUMBER') then
        avalue:= to_char(wf_engine.GetActivityAttrNumber(itemtype,itemkey,
                      actid, attr.name),wf_core.canonical_number_mask);

      -- DATE Value
      elsif (atype = 'DATE') then
        avalue:=to_char(wf_engine.GetActivityAttrDate(itemtype,itemkey,
            actid, attr.name),nvl(aformat,wf_core.canonical_date_mask));

      -- TEXT/LOOKUP/ROLE/ATTR etc Value
      else
        avalue:=substr(wf_engine.GetActivityAttrText(itemtype,itemkey,
                       actid, attr.name),1,2000);
      end if;

      --Set the Value into the Parameter List
      --Bug 2761887
      --Lets use the addparametertolist for the event parameterlist
      --so that any attribute of the same name overwrites
      --existing ones in the default events parameter list.

      evtmsg.AddParameterToList(attr.name,avalue);

    end loop;

    -- We also need to set the current work item as the master
    -- work item or context into the parameter list, this will be picked
    -- up during the Receive Event processing

    --Bug 2761887
    evtmsg.addparametertolist('#CONTEXT',itemtype||':'||itemkey);
    --Now set the event parameterlistr into the parameterlist
    parameterlist := evtmsg.GETPARAMETERLIST;



    -- Raise event
    Wf_Event.Raise(
        p_event_name => evtname,
        p_event_key => evtkey,
        p_event_data => msgdata,
        p_parameters => parameterlist);

  elsif (direction = wf_engine.eng_send) then
    -- SEND event

    -- Get base event struct to send
    -- #EVENTMESSAGE
    evtmsg := Wf_Engine.GetActivityAttrEvent(itemtype, itemkey, actid,
                    Wf_Engine.eng_eventmessage);
    if (evtmsg is null) then
      Wf_Core.Token('#EVENTMESSAGE', '');
      Wf_Core.Raise('WFSQL_ARGS');
    end if;

    -- Initialize the variables here
    outagent := wf_agent_t(NULL, NULL); -- Out agent override (send)
    toagent  := wf_agent_t(NULL, NULL);  -- To agent override (send)
    parametert := wf_parameter_t(null, null);
    counter  := 0;


    -- Other attributes are treated as over-rides to values in the
    -- event message struct retrieved above.
    -- Use them to reset values if present.
    -- #EVENTNAME
    attr := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid,
                wf_engine.eng_eventname);
    if (attr is not null) then
      evtmsg.SetEventName(attr);
    end if;

    -- #EVENTKEY
    attr := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid,
                wf_engine.eng_eventkey);
    if (attr is not null) then
      evtmsg.SetEventKey(attr);
    end if;

    -- #EVENTOUTAGENT
    attr := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid,
                Wf_Engine.eng_eventoutagent);
    if (attr is not null) then
      -- Value must be in format <agent>@<system>
      atsign := instr(attr, '@');
      if (atsign is null) then
        Wf_Core.Token('#EVENTOUTAGENT', attr);
        Wf_Core.Raise('WFSQL_ARGS');
      end if;
      outagent.setname(substr(attr, 1, atsign-1));
      outagent.setsystem(substr(attr, atsign+1));
      evtmsg.SetFromAgent(outagent);
    end if;

    -- #EVENTTOAGENT
    attr := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid,
                Wf_Engine.eng_eventtoagent);
    if (attr is not null) then
      -- Value must be in format <agent>@<system>
      atsign := instr(attr, '@');
      if (atsign is null) then
        Wf_Core.Token('#EVENTTOAGENT', attr);
        Wf_Core.Raise('WFSQL_ARGS');
      end if;
      toagent.setname(substr(attr, 1, atsign-1));
      toagent.setsystem(substr(attr, atsign+1));
      evtmsg.SetToAgent(toagent);
    end if;

    -- #PRIORITY
   begin
     priority := Wf_Engine.GetActivityAttrNumber(itemtype, itemkey, actid,
                     wf_engine.eng_priority);
     if (priority is not null) then
       evtmsg.SetPriority(priority);
     end if;
   exception
     when others then
       if (wf_core.error_name = 'WFENG_ACTIVITY_ATTR') then
         -- Ignore if priority attr not found
         Wf_Core.Clear;
       else
         raise;
       end if;
    end;

    -- Correlation ID
    -- Set message correlation id to itemkey if not already set
    if (evtmsg.GetCorrelationId is null) then
      evtmsg.SetCorrelationId(itemkey);
    end if;

    -- Bug 2065730
    -- Initialize the parameterlist with the existing parameterlist
    -- of the event.
    -- Obtain the activity attributes through the cursor
    -- Build the attribute name and value in the parameter list
    -- parameterlist
    -- Call setParameterList and set the parameter list
    -- This is done before passing the event to the SEND.

    parameterlist := evtmsg.getParameterList();

    -- Bug 3908657
    -- Avoid duplicate attribute by calling AddParamToList()
    -- Keep the optimization if we start with a fresh list,
    -- since addParameterToList loop through all the attributes
    -- to avoid duplicate, it could be expansive.

    if (parameterlist is null) then
      l_fresh_parameterlist := true;
    else
      l_fresh_parameterlist := false;
    end if;


    if (l_fresh_parameterlist) then
        parameterlist := wf_parameter_list_t(null);
        parametert.SetName('#CONTEXT');
        parametert.SetValue(itemtype||':'||itemkey);
        parameterlist(1) := parametert;
        counter := 1;
    else
        evtmsg.addParameterToList('#CONTEXT',itemtype||':'||itemkey);
    end if;

    for attr in curs_actattrs loop
        avalue :=null;

        wf_engine.GetActivityAttrInfo(itemtype, itemkey, actid,
                              attr.name, atype, asubtype, aformat);

        if (atype = 'NUMBER') then
            avalue := to_char(wf_engine.GetActivityAttrNumber(
                              itemtype,itemkey,actid, attr.name),
                              wf_core.canonical_number_mask);

        elsif (atype = 'DATE') then
            avalue := to_char(wf_engine.GetActivityAttrDate(
                              itemtype,itemkey,actid, attr.name),
                              nvl(aformat,wf_core.canonical_date_mask));

        else
            avalue := substr(wf_engine.GetActivityAttrText(
                             itemtype,itemkey,actid, attr.name),1,2000);
        end if;

        if (l_fresh_parameterlist) then
	  -- Set the Value into the Parameter List
	  parameterlist.extend;
	  counter := counter + 1;
	  parametert.SetName(attr.name);
	  parametert.SetValue(avalue);
	  parameterlist(counter) := parametert;
        else
          evtmsg.addParameterToList(attr.name,avalue);
        end if;
    end loop;

    if (l_fresh_parameterlist) then
      evtmsg.setParameterList(parameterlist);
    end if;
    -- End 2065730

    -- Bug 2294745 - Enh for OTA callback to workflow
    -- add activity id to event parameter list
    evtmsg.addParameterToList('ACTIVITY_ID',actid);

    -- get block mode and add to event parameterlist
    block_mode := wf_engine.GetActivityAttrText(itemtype, itemkey, actid,
                                                wf_engine.eng_block_mode, true);
    if (block_mode is not null) then
       evtmsg.addParameterToList(wf_engine.eng_block_mode, block_mode);
    end if;

    -- get cb event name and add to event parameterlist
    cb_event_name := wf_engine.GetActivityAttrText(itemtype, itemkey, actid,
                                                wf_engine.eng_cb_event_name, true);
    if (cb_event_name is not null) then
       evtmsg.addParameterToList(wf_engine.eng_cb_event_name, cb_event_name);
    end if;

    -- get cb event key and add to event parameterlist
    cb_event_key := wf_engine.GetActivityAttrText(itemtype, itemkey, actid,
                                                wf_engine.eng_cb_event_key, true);
    if (cb_event_key is not null) then
       evtmsg.addParameterToList(wf_engine.eng_cb_event_key, cb_event_key);
    end if;
    -- End 2294745

    -- Send event
    Wf_Event.Send(p_event => evtmsg);

    if (wf_core.Translate('WF_INSTALL')='EMBEDDED') then
      ECX_ERRORLOG.Outbound_Log (p_event => evtmsg);
    end if;

    --<rwunderl:2699059> Checking for reserved attribute to store msgid.
    begin
      WF_ENGINE.SetItemAttrText(itemtype, itemkey,
       WF_ENGINE.GetActivityAttrText(itemtype, itemkey, actid,
                                     '#WF_EVT_MSGID'),
       rawtohex(WF_EVENT.g_msgID));

    exception
      when others then
        if (WF_CORE.error_name = 'WFENG_ACTIVITY_ATTR') then
          null;  --If the activity attribute is not setup by the ItemType
                 --developer, we will do nothing.
        else
          raise; --Some other problem has occured.

        end if;
    end;

  else
    -- Unrecognized event direction, raise error
    Wf_Core.Token('ITEMTYPE', itemtype);
    Wf_Core.Token('ITEMKEY', itemkey);
    Wf_Core.Token('ACTID', to_char(actid));
    Wf_Core.Token('DIRECTION', direction);
    Wf_Core.Raise('WFSQL_INTERNAL');
  end if;


  --If block mode is set to 'Y'then the activity status is
  --set to NOTIFIED.
  if (block_mode = 'Y') then
     result := wf_engine.eng_notified||':'||wf_engine.eng_null||':'
                                                    ||wf_engine.eng_null;
  else
     -- when block_mode is null or is not 'Y'
     result := 'COMPLETE:#NULL';
  end if;

exception
  when others then
    Wf_Core.Context('Wf_Engine_Util', 'Event_Activity', itemtype,
        itemkey, to_char(actid), funcmode);
    raise;
end Event_Activity;

end Wf_Engine_Util;
