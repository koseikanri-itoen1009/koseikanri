CREATE OR REPLACE PROCEDURE xxcmn_get_present_time
  (itemtype in varchar2,
   itemkey in varchar2,
   actid in number,
   funcmode in varchar2,
   resultout out varchar2) IS
--
   lv_dt varchar2(20);
--
BEGIN
     IF (funcmode = 'RUN') THEN
       SELECT TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
       INTO lv_dt
       FROM dual;
--
       wf_engine.SetItemAttrText (itemtype => itemtype,
         itemkey => itemkey,
         aname => 'PRESENT_TIME',
         avalue => lv_dt);
--
       resultout :='COMPLETE';
       RETURN;
--
     END IF;
     
     IF (funcmode = 'CANCEL') THEN
       resultout :='COMPLETE';
       return;
     END IF;
--
     IF (funcmode = 'TIMEOUT') THEN
       resultout :='COMPLETE';
       RETURN;
     END IF;
--
     EXCEPTION
       WHEN OTHERS THEN
         wf_core.context('WF_MYFUNC','xxcmn_get_present_time',itemtype,
           itemkey,actid,funcmode);
         RAISE;
--
END xxcmn_get_present_time;