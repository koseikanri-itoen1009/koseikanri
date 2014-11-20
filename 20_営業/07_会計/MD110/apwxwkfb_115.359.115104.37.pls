REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE
REM +==================================================================+
REM |                Copyright (c) 1994 Oracle Corporation
REM |                   Redwood Shores, California, USA
REM |                        All rights reserved.
REM +==================================================================+
REM |  Name
REM |    apwxwkfb.pls
REM |
REM |  Description
REM |    Server-side stored procedure package for <TABLE_NAME>
REM |
REM |  History
REM |    XX-XXX-XX  Created by HChung
REM |    16-SEP-02  V.Srinivasan Bug 292342. In GetFinalApprover
REM |                            checking for a loop in the hierarchy.
REM |                            If a loop is found and no one in the 
REM |                            chain has sufficient authority to approve
REM |                            the expense report, then error out.
REM |    18-OCT-02  V.Srinivasan Bug 2610233. In BuildBothpayExpReport
REM |                            calling the credit card splitting logic
REM |                            if l_ccard_exists is TRUE. Commented the
REM |                            check for l_ccard_amt since this does not
REM |                            take into account -ve credit card amounts.
REM |    31-DEC-02  V.Srinivasan Bug 2351528. Setting the user_key  
REM |                            which will make it easier for the users 
REM |                            to query the expense report in workflow.
REM |    19-Feb-03  V.Srinivasan   Bug 2802799 : Have changed the
REM |                              length of name variables and
REM |                              display_name variables to refer to
REM |                              to the columns in wf_users.
REM |    11-Apr-03  V.Srinivasan   Bug 2880223 : Have changed the
REM |                              attribute_name from VIOLATION_TOTAL
REM |                              to VIOLATIONS_TOTAL in ResetAttrValues.
REM |    10-Jun-03  Amulya Mishra  Bug 2942773 : Add Merchant Name to 
REM |                              personal credit card expense table.
REM |    13-Jun-03  V.Srinivasan   Bug 2945379 : In StartExpenseReportProcess
REM |                              retrieving the org_id from 
REM |                              ap_expense_report_headers_all since this
REM |                              will always be correct.
REM |    17-Jul-03  Sweta          Bug 2767931 : Removed Set Escape Statement
REM |                              and replaced `& with ' || '&' || '
REM |    18-JUL-03  Sweta          Bug 2824304 : Removed abs function for 
REM |                              Personal Expense Amount and Total. 
REM |                              Negated the Personal Expense Amount.
REM |    24-Jul-03  Amulya Mishra  Bug 2974741: Replace sysdate with 
REM |                              l_week_end_date to get correct default
REM |                              exchange rate in AP_EXPENSE_REPORT_HEADERS.
REM |    07-Aug-03  Jani Rautiainen  Adjustment and shortpayment project changes.
REM |    20-AUG-03  Sweta          Bug 3068119: Workflow attribute PAYMENT_DUE_FROM
REM |                              is set from Report's transactions and not from
REM |                              Profile option. Parameter CardProgramID is also
REM |                              passed to function GetExpenseClearingCCID.
REM |    25-Oct-03  Amulya Mishra  Bug 2742114: Raise exception when preparer_id
REM |                              is same as tranferrTOId.
REM |    30-Oct-03  Amulya Mishra  Bug 2944363: Added code to show the table for 
REM |                              personal expenses in Both Pay.
REM |    02-Jan-04  Amulya Mishra  Bug 3248874 : If Workflow errors out, update
REM |                              source and expense sttaus code to proper 
REM |                              values so that the report will appear in 
REM |                              Active table for Update.
REM |    11-Feb-04  V.Srinivasan   Bug 3422298 : Checking if the cursor is
REM |                              open before closing it.
REM |    19-Feb-04  Amulya Mishra  Bug 3389386 : Set Expense status code to 
REM |                              PAID in BOTH PAY ONLY PERSONAL case.
REM |    09-Apr-04  skoukunt       Bug 3560082 : Comment the call to 
REM |                              SetRejectStatusInAME and add the call
REM |                              to AME_API.clearAllApprovals
REM |    19-Apr-04  V.Srinivasan   Bug 3566496 : Need to update 
REM |                              expense_current_approver_id since that
REM |                              is used to display the approver in 
REM |                              the Track expenses page.
REM |    23-Apr-04  Amulya Mishra  Bug 3581975: Dont select policy
REM |                              records if distribution line number is -1.
REm |    30-Apr-04  Amulya Mishra  Bug 2777245:Update the description and 
REM |                              justification so that multibyte spaces will
REM |                              be removed.
REM |    18-Jun-04  V.Srinivasan   Bug 3545282 : Setting the #FROM_ROLE
REM |                              for notifications.
REM |    23-Jul-04  V.Srinivasan   Bug 3772025 : Calling wf_purge.TotalPerm
REM |                              to purge workflow with persistence type
REM |                              as 'Permanent'.
REM |    29-Jul-04  V.Srinivasan   Bug 3561386 : Should add l_document to 
REM |                              the clob only if it is not null.
REM |    27-Aug-04  V.Srinivasan   Bug 3693572 : Updating submitted_amount to
REM |                              be equal to amount in UpdateHeaderLines.
REM |    07-Sep-04  V.Srinivasan   Bug 3732690 : In ProcessMileageLines
REM |                              rounding the amount before calling 
REM |                              updateExpenseMileageLines.
REM |    03-Nov-04  Albowicz       Added Header Attachments    
REM |    08-Nov-04  V.Srinivasan   Bug 3975334 : In ProcessMileageLines
REM |                              included the logic for rate per 
REM |                              passenger.
REM |    03-Jan-05  V.Srinivasan   Bug 4019412 : Calling resetAPflags in
REM |                              SetReturnStatusAndResetAttr and 
REM |                              SetRejectStatusAndResetAttr. 
REM |    28-Jun-05  V.Srinivasan   Bug 4432471 : In CheckAccess checking in  
REM |                              table wf_item_activity_statuses_h also.
REM |    27-Jul-05  V.Srinivasan   Bug 4229303 : In AddToAudit checking the  
REM |                              value of workflow_approved_flag before
REM |                              updating it.
REM |    02-Aug-05  V.Srinivasan   Bug 4298485 : Did error handling for the 
REM |                              case where the attribute RESPONSIBILITY_ID
REM |                              does not exist for old ERs.
REM |    02-Aug-05  V.Srinivasan   Bug 3016834 : Passing cascade = TRUE to
REM |                              wf_engine.AbortProcess.
REM |    10-Aug-05  V.Srinivasan   Bug 4319321 : Changed the callback function
REM |                              to check for user_id, resp_id and
REM |                              resp_appl_id also.
REM |    19-Sep-05  V.Srinivasan   Bug 4583798 : Incorrect index was used
REM |                              in processCrossThreshold while accessing
REM |                              p_mileage_line_array.
REM +==================================================================+
 
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
 
SET ESCAPE `

CREATE OR REPLACE PACKAGE BODY AP_WEB_EXPENSE_WF AS
/* $Header: apwxwkfb.pls 115.359.115104.37 2010/07/12 12:39:26 dsadipir ship $ */


--
-- Private Variables
--
-- copied from WF_NOTIFICATION package
-- /fnddev/fnd/11.5/patch/115/sql/wfntfb.pls
--

table_width  varchar2(6) := '"100%"';
table_border varchar2(3) := '"0"';
table_cellpadding varchar2(3) := '"3"';
table_cellspacing varchar2(3) := '"1"';
table_bgcolor varchar2(7) := '"white"';
th_bgcolor varchar2(9) := '"#cccc99"';
th_fontcolor varchar2(9) := '"#336699"';
th_fontface varchar2(80) := '"Arial, Helvetica, Geneva, sans-serif"';
td_bgcolor varchar2(9) := '"#f7f7e7"';
td_fontcolor varchar2(7) := '"black"';
td_fontface varchar2(80) := '"Arial, Helvetica, Geneva, sans-serif"';

--
startOraFieldTextFont varchar2(200) := '<font style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;color:#000000}">';
endOraFieldTextFont varchar2(50) := '</font>';

indent_start varchar2(200) := '<table style="{background-color:#ffffff}" width="100%" border="0" cellpadding="0" cellspacing="0"><tr><td width="20"></td><td>';
indent_end varchar2(200) := '</td></tr></table>';

----------------------------------
--.OraTableTitle {font-family:Arial,Helvetica,Geneva,sans-serif;font-size:13pt;background-color:#ffffff;color:#336699}
----------------------------------
table_title_start  varchar2(200) := '<br><font style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:11pt;font-weight:bold;background-color:#ffffff;color:#336699}">';
table_title_end  varchar2(200) := '</font><br><table width="100%"><tr bgcolor="#cccc99"><td height="1"></td></tr><tr bgcolor="#ffffff"><td height="2"></td></tr></table>';

----------------------------------
--.OraTable {background-color:#999966}
----------------------------------
table_start varchar2(200) := '<table style="{background-color:#999966}" width="100%" border="0" cellpadding="3" cellspacing="1">';
table_end varchar2(15) := '</table>';

tr_start varchar2(80) := '<tr bgcolor="#cccc99">';
tr_end varchar2(15) := '</tr>'; 

----------------------------------
--.OraTableColumnHeaderIconButton {font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;background-color:#cccc99;color:#336699;vertical-align:bottom;text-align:center}
----------------------------------
th_select varchar2(200) := '<td style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;background-color:#cccc99;color:#336699;vertical-align:bottom;text-align:center}">';

----------------------------------
-- .OraTableColumnHeader {font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;text-align:left;background-color:#cccc99;color:#336699;vertical-align:bottom}
----------------------------------
th_text varchar2(200) := '<td style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;text-align:left;background-color:#cccc99;color:#336699;vertical-align:bottom}">';

----------------------------------
-- .OraTableColumnHeaderNumber {font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;background-color:#cccc99;color:#336699;vertical-align:bottom;text-align:right}
----------------------------------
th_number varchar2(200) := '<td style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;background-color:#cccc99;color:#336699;vertical-align:bottom;text-align:right}">';

----------------------------------
-- .OraTableCellSelect {font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;text-align:center;background-color:#f7f7e7;color:#000000;vertical-align:baseline}
----------------------------------
td_select varchar2(200) := '<td style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;text-align:center;background-color:#f7f7e7;color:#000000;vertical-align:baseline}">';

----------------------------------
-- .OraTableCellText {font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;background-color:#f7f7e7;color:#000000;vertical-align:baseline}
----------------------------------
td_text varchar2(200) := '<td style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;background-color:#f7f7e7;color:#000000;vertical-align:baseline}">';

----------------------------------
-- .OraTableCellNumber {font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;text-align:right;background-color:#f7f7e7;color:#000000;vertical-align:baseline}
----------------------------------
td_number varchar2(200) := '<td style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;text-align:right;background-color:#f7f7e7;color:#000000;vertical-align:baseline}">';

td_start varchar2(10) := '<td>';
td_end varchar2(10) := '</td>';

------------------------
-- Constants definition
------------------------

-- Start from process from server validation, manager approval, ap approval
C_START_FROM_SERVER_VALIDATION CONSTANT VARCHAR2(40) := 'SERVER_VALIDATION';
C_START_FROM_MANAGER_APPROVAL  CONSTANT VARCHAR2(40) := 'MANAGER_APPROVAL';
C_START_FROM_AP_APPROVAL       CONSTANT VARCHAR2(40) := 'AP_APPROVAL';

-- Reject Status in Shortpay
C_APReject_Status		CONSTANT VARCHAR2(10) := 'AP_REJECT';

-- Number of LINE_INFO attributes
C_NUM_LINE_INFO_ATTRS          CONSTANT NUMBER := 200;
C_NUM_ADJ_LINE_ATTRS           CONSTANT NUMBER := 20;

-- Number for mileage process
C_KILOMETERS CONSTANT VARCHAR2(20) := 'KM';
C_MILES	     CONSTANT VARCHAR2(20) := 'MILES';
C_SWMILES CONSTANT VARCHAR2(20) := 'SWMILES';
KILOMETERS_TO_MILES   CONSTANT NUMBER := 0.621370;
MILES_TO_KILOMETERS   CONSTANT NUMBER := 1.609347;
SWMILES_TO_MILES   CONSTANT NUMBER := 6.21370;
MILES_TO_SWMILES   CONSTANT NUMBER := 0.160934;
KILOMETERS_TO_SWMILES   CONSTANT NUMBER := 0.1;
SWMILES_TO_KILOMETERS   CONSTANT NUMBER := 10.0;
C_THRESHOLD_TOLERANCE CONSTANT NUMBER := 1;

-- Constants for YES_NO lookup
C_YES_NO                 FND_LOOKUPS.LOOKUP_TYPE%type := 'YES_NO';
C_Y                      FND_LOOKUPS.LOOKUP_CODE%type := 'Y';
C_N                      FND_LOOKUPS.LOOKUP_CODE%type := 'N';

-- Constants for notification type
C_EMP	      CONSTANT VARCHAR2(3) := 'EMP';
C_OTHER	      CONSTANT VARCHAR2(5) := 'OTHER';

-- Constants for Policy violation value 
C_ALLOW_NO_WARNINGS VARCHAR2(50):='ALLOW_NO_WARNINGS';

-- Constants for Business Events
C_SUBMIT_EVENT_NAME   CONSTANT VARCHAR2(80) := 'oracle.apps.ap.oie.expenseReport.submit';

C_ROUNDING CONSTANT VARCHAR2(20) := 'ROUNDING';

-- Constant for multiple current approvers
C_AME_MULTIPLE_CURR_APPROVER   CONSTANT NUMBER := -99999;

-- Constant For Distance Field
C_DISTANCE_FIELD CONSTANT VARCHAR2(50) := 'DAILY_DISTANCE';

-----------------------------------------------------------------------
FUNCTION GetFlowVersion(p_item_type	IN VARCHAR2,
			p_item_key	IN VARCHAR2) RETURN NUMBER
---------------------------------------------------------------------------
IS
  l_version_num	        NUMBER := 0;
BEGIN
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetFlowVersion');

  l_version_num := WF_ENGINE.GetItemAttrNumber(p_item_type,
			      		       p_item_key,
					       'VERSION');

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetFlowVersion');

  RETURN l_version_num;

EXCEPTION
  WHEN NO_DATA_FOUND THEN 
    RETURN 0;  
  WHEN OTHERS THEN
    RETURN 0;
END GetFlowVersion;

---------------------------------------------------------------------- 
PROCEDURE SetFromRole( 
                                 p_item_type    IN VARCHAR2, 
                                 p_item_key     IN VARCHAR2, 
                                 p_actid        IN NUMBER, 
                                 p_from_role    IN VARCHAR2, 
                                 p_called_from  IN VARCHAR2) IS 
---------------------------------------------------------------------- 
  l_debug_info                  VARCHAR2(500); 
  l_role_valid                  VARCHAR2(1); 
  tvalue varchar2(4000); 
  role_info_tbl wf_directory.wf_local_roles_tbl_type; 
BEGIN 
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetFromRole'); 
 
        l_role_valid := 'Y'; 
        tvalue := p_from_role; 
        Wf_Directory.GetRoleInfo2(p_from_role,role_info_tbl); 
        tvalue := role_info_tbl(1).name; 
        -- If not internal name, check for display_name 
        if (tvalue is null) then 
          begin 
             SELECT name 
             INTO   tvalue 
             FROM   wf_role_lov_vl 
             WHERE  upper(display_name) = upper(p_from_role) 
             AND    rownum = 1; 
          exception 
            when no_data_found then 
              -- Not displayed or internal role name, error 
              l_role_valid := 'N'; 
          end; 
        end if; 
 
    if l_role_valid <> 'N' then 
    ---------------------------------------------------------------- 
    l_debug_info := 'Set #FROM_ROLE : called from : ' || p_called_from; 
    ---------------------------------------------------------------- 
    WF_ENGINE.SetItemAttrText(p_item_type,  
                              p_item_key,  
                              '#FROM_ROLE', 
                              tvalue); 
    end if; 
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetFromRole'); 
 
EXCEPTION 
  WHEN OTHERS THEN 
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetFromRole:Called From' ||  
                     p_called_from, 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info); 
    raise; 
END SetFromRole; 

---------------------------------------------------------------------------
PROCEDURE StartExpenseReportProcess(p_report_header_id	IN NUMBER,
				    p_preparer_id	IN NUMBER,
				    p_employee_id	IN NUMBER,
				    p_document_number	IN VARCHAR2,
				    p_total		IN NUMBER,
				    p_new_total		IN NUMBER,
				    p_reimb_curr	IN VARCHAR2,
				    p_cost_center	IN VARCHAR2,
				    p_purpose		IN VARCHAR2,
				    p_approver_id	IN NUMBER,
                                    p_week_end_date     IN DATE,
                                    p_workflow_flag     IN VARCHAR2,
                                    p_submit_from_oie   IN VARCHAR2,
                                    p_event_raised      IN VARCHAR2 DEFAULT 'N') IS
---------------------------------------------------------------------------
  l_item_type	VARCHAR2(100)	:= 'APEXP';
  l_item_key	VARCHAR2(100)	:= to_char(p_report_header_id);
  l_preparer_name		wf_users.name%type;
  l_preparer_display_name	wf_users.display_name%type;
  l_employee_display_name	wf_users.display_name%type;
  l_approver_name		wf_users.name%type;
  l_approver_display_name	wf_users.display_name%type;
  l_emp_cost_center		VARCHAR2(240);
  l_dummy_emp_name		VARCHAR2(240);
  l_emp_num			VARCHAR2(30);
  l_emp_name			wf_users.name%type;
  l_total			NUMBER;
  l_total_dsp			VARCHAR2(50);
  l_new_total_dsp		VARCHAR2(50);
  l_credit_total_dsp		VARCHAR2(50);
  l_credit_total		NUMBER;
  l_url				VARCHAR2(1000);
  l_debug_info			VARCHAR2(200);
  l_employee_project_enabled    VARCHAR2(1);
  C_CreditLineVersion           CONSTANT NUMBER := 1;
  C_WF_Version			NUMBER          := 0;
  l_err_name                    VARCHAR2(30);
  l_ResubmitReport              BOOLEAN := FALSE;

  -- for bug 1652106
  l_n_org_id	NUMBER;

  -- for bug 2069362
  l_AMEEnabled			VARCHAR2(1);
  l_bAMEProfileDefined		BOOLEAN;

  -- Grants Integration
  l_grants_enabled		VARCHAR2(1);

  l_textNameArr   Wf_Engine.NameTabTyp;
  l_textValArr    Wf_Engine.TextTabTyp;
  l_numNameArr   Wf_Engine.NameTabTyp;
  l_numValArr    Wf_Engine.NumTabTyp;
  iNum  NUMBER :=0;
  iText NUMBER :=0;

  --ER 1552747 - withdraw expense report
  l_mess         Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;

  -- Policy Violation
  l_violation_count	NUMBER:=0;
  l_policy_violation_value     VARCHAR2(50);
  l_policy_violation_defined   BOOLEAN;

  l_n_resp_id                   Number;
  l_userid 			VARCHAR2(80);
  l_card_program_id             NUMBER := 0;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start StartExpenseReportProcess');

-- org_context should be set while calling icx_sec.validatesession
--IF AP_WEB_INFRASTRUCTURE_PKG.ValidateSession(NULL, FALSE, FALSE) THEN

  UpdateHeaderLines(p_report_header_id);  --Bug 2777245

  -- Fix 2178792 : Added the below select 
  select nvl(AMT_DUE_CCARD_COMPANY,0)+nvl(AMT_DUE_EMPLOYEE,0)+nvl(MAXIMUM_AMOUNT_TO_APPLY, 0) 
  into   l_total
  from   ap_expense_report_headers_all 
  where  report_header_id = p_report_header_id;

  l_total_dsp := to_char(l_total,
			 FND_CURRENCY.Get_Format_Mask(p_reimb_curr,22));
  l_new_total_dsp := to_char(p_new_total, 
			     FND_CURRENCY.Get_Format_Mask(p_reimb_curr,22));
  l_credit_total := p_total - p_new_total;
  l_credit_total_dsp := to_char(l_credit_total,
				FND_CURRENCY.Get_Format_Mask(p_reimb_curr,22));
  AP_WEB_PROJECT_PKG.IsSessionProjectEnabled(
    p_employee_id,
    FND_PROFILE.VALUE('USER_ID'),
    l_employee_project_enabled);

  l_ResubmitReport := AP_WEB_DB_EXPRPT_PKG.ResubmitExpenseReport(
                         p_workflow_flag);

  -- Grants Integration
  IF (GMS_OIE_INT_PKG.IsGrantsEnabled()) THEN
    l_grants_enabled := 'Y';
  ELSE
    l_grants_enabled := 'N';
  END IF;

  IF (NOT l_ResubmitReport and p_event_raised <> 'Y') THEN
    BEGIN
    -- We need to create a process when we are submitting for the first time or
    -- expense was withdrawn.
    -- For resubmitting a rejected/returned report, we just need to start up the
    -- workflow process from the blocked activity.

    --------------------------------------------------
    l_debug_info := 'Calling WorkFlow Create Process';
    --------------------------------------------------
    WF_ENGINE.CreateProcess(l_item_type,
	  		    l_item_key,
			    'AP_EXPENSE_REPORT_PROCESS');
    EXCEPTION
        when others then
          l_err_name := wf_core.error_name;
          if (l_err_name = 'WFENG_ITEM_UNIQUE') then
            -- the workflow process with l_item_key has been created
            -- previously. we should still allow users to submit the
            -- same report for bug 2203698.
            wf_core.clear;
          else
            raise;
          end if;
    END;
  END IF;

	
  -- for bug 1652106
   --------------------------------------------------------------
  l_debug_info := 'Get Org_ID value ';
  --------------------------------------------------------------

 /* Bug 2945379 : The org_id retrieved from the table will
                  always be the correct one */
--  FND_PROFILE.GET('ORG_ID' , l_n_org_id );

  SELECT   org_id 
    INTO   l_n_org_id 
    FROM   ap_expense_report_headers_all
   WHERE   report_header_id = l_item_key; 


  -- ORG_ID was added later; therefore, it needs to be tested for upgrade purpose, and
  -- is not included in the bulk update.
  begin

    WF_ENGINE.SetItemAttrNumber(l_item_type,
                              	l_item_key,
                              	'ORG_ID',
                              	l_n_Org_ID);
    exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    -- ORG_ID item attribute doesn't exist, need to add it
	    WF_ENGINE.AddItemAttr(l_item_type, l_item_key, 'ORG_ID');
    	    WF_ENGINE.SetItemAttrNumber(l_item_type,
                              	l_item_key,
                              	'ORG_ID',
                              	l_n_Org_ID);
	  else
	    raise;
	  end if;

  end;


  begin

 /* Bug 2351528. Need to set the user_key for easier query */
    WF_ENGINE.SetItemUserKey(l_item_type,
                             l_item_key,
                             p_document_number);
                             
    --------------------------------------------------------------
    l_debug_info := 'Set User_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(l_item_type,
                              	l_item_key,
                              	'USER_ID',
                              	FND_PROFILE.VALUE('USER_ID'));

    --------------------------------------------------------------
    l_debug_info := 'Set Resp_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(l_item_type,
                              	l_item_key,
                              	'RESPONSIBILITY_ID',
                              	FND_PROFILE.VALUE('RESP_ID'));

    --------------------------------------------------------------
    l_debug_info := 'Set Resp_Appl_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(l_item_type,
                              	l_item_key,
                              	'APPLICATION_ID',
                              	FND_PROFILE.VALUE('RESP_APPL_ID'));

    ------------------------------------------------------------
    l_debug_info := 'Get responsibility id';
    ------------------------------------------------------------
    l_n_resp_id := WF_ENGINE.GetItemAttrNumber(l_item_type,
  	 				       l_item_key,
  					       'RESPONSIBILITY_ID');

  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
  end;

    ----------------------------------------------------
    l_debug_info := 'Retrieve profile option AME Enabled?';
    ----------------------------------------------------
    FND_PROFILE.GET_SPECIFIC('AME_INSTALLED_FLAG', null, l_n_resp_id, 200, l_AMEEnabled, l_bAMEProfileDefined);

    if l_bAMEProfileDefined then
      l_AMEEnabled := NVL(l_AMEENABLED,'N'); -- Default to 'N' if null
    else
      l_AMEEnabled := 'N';
    end if;

    WF_ENGINE.SetItemAttrText(l_item_type,
                              	l_item_key,
                              	'AME_ENABLED',
                              	l_AMEEnabled);

  -------------------------------------------------
  l_debug_info := 'Update Withdraw Message';
  -------------------------------------------------
  --ER 1552747 - withdraw expense report 
  if p_workflow_flag = AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_WITHDRAW then
     FND_MESSAGE.SET_NAME('SQLAP','OIE_WITHDRAW_WARNING');
     l_mess := FND_MESSAGE.GET;
     WF_ENGINE.SetItemAttrText(l_item_type,
                               l_item_key,
                               'WITHDRAW_WARNING',
                               l_mess);
  end if;

    ----------------------------------------------------
    l_debug_info := 'Set Grants Enabled Item Attribute';
    ----------------------------------------------------
    WF_ENGINE.SetItemAttrText(l_item_type,
                              	l_item_key,
                              	'GRANTS_ENABLED',
                              	l_grants_enabled);


  -------------------------------------------------
  l_debug_info := 'Set WF Purpose Item Attribute';
  -------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'PURPOSE';
    l_textValArr(iText) := p_purpose;
  
  ------------------------------------------------------
  l_debug_info := 'Set LINE_TABLE Item Attribute';
  ------------------------------------------------------

    iText := iText + 1;
    l_textNameArr(iText) := 'LINE_TABLE';
    l_textValArr(iText) := 'plsqlclob:AP_WEB_EXPENSE_WF.generateExpClobLines/'||l_item_type||':'||l_item_key;

  ------------------------------------------------------
  l_debug_info := 'Set EMP_LINE_TABLE Item Attribute';
  ------------------------------------------------------

    iText := iText + 1;
    l_textNameArr(iText) := 'EMP_LINE_TABLE';
    l_textValArr(iText) := 'plsqlclob:AP_WEB_EXPENSE_WF.generateExpClobLines/'||l_item_type||':'||l_item_key||':'||C_EMP;
  ----------------------------------------------------------
  l_debug_info := 'Set WF Expense_Report_ID Item Attribute';
  ----------------------------------------------------------
    iNum := iNum + 1;
    l_numNameArr(iNum) := 'EXPENSE_REPORT_ID';
    l_numValArr(iNum) := p_report_header_id;

  --------------------------------------------------------
  l_debug_info := 'Set WF Document_Number Item Attribute';
  --------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'DOCUMENT_NUMBER';
    l_textValArr(iText) := p_document_number;

  ------------------------------------------------------------
  l_debug_info := 'Get Name Info Associated With Preparer_Id';
  ------------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
			   p_preparer_id,
			   l_preparer_name,
			   l_preparer_display_name);

  ----------------------------------------------------------
  l_debug_info := 'Set the Owner of Workflow Process.';
  ----------------------------------------------------------
  WF_ENGINE.SetItemOwner(l_item_type, l_item_key, l_preparer_name);

  ------------------------------------------------------------
  l_debug_info := 'Get Name Info Associated With Employee_Id';
  ------------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
                           p_employee_id,
                           l_emp_name,
                           l_employee_display_name);  

  ---------------------------------------------------------------------------
  l_debug_info := 'Get the Employee Cost Center Associated With Preparer_Id';
  ---------------------------------------------------------------------------
  AP_WEB_UTILITIES_PKG.GetEmployeeInfo(l_dummy_emp_name,
				       l_emp_num,
				       l_emp_cost_center,
				       p_employee_id);

  ------------------------------------------------------
  l_debug_info := 'Set WF Preparer_ID Item Attribute';
  ------------------------------------------------------
    iNum := iNum + 1;
    l_numNameArr(iNum) := 'PREPARER_ID';
    l_numValArr(iNum) := p_preparer_id;

  ------------------------------------------------------
  l_debug_info := 'Set WF Preparer_Name Item Attribute';
  ------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'PREPARER_NAME';
    l_textValArr(iText) := l_preparer_name;

  --------------------------------------------------------------
  l_debug_info := 'Set WF Preparer_Display_Name Item Attribute';
  --------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'PREPARER_DISPLAY_NAME';
    l_textValArr(iText) := l_preparer_display_name;

  ------------------------------------------------------
  l_debug_info := 'Set WF Employee_ID Item Attribute';
  ------------------------------------------------------
    iNum := iNum + 1;
    l_numNameArr(iNum) := 'EMPLOYEE_ID';
    l_numValArr(iNum) := p_employee_id;
                                                 
  ------------------------------------------------------
  l_debug_info := 'Set WF Employee_Name Item Attribute';
  ------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'EMPLOYEE_NAME';
    l_textValArr(iText) := l_emp_name;
                                                 
  --------------------------------------------------------------
  l_debug_info := 'Set WF Preparer_Display_Name Item Attribute';
  --------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'EMPLOYEE_DISPLAY_NAME';
    l_textValArr(iText) := l_employee_display_name;

  --------------------------------------------------------------
  l_debug_info := 'Set CC Payment Due From Item Attribute';
  --------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'PAYMENT_DUE_FROM';

    IF (NOT AP_WEB_DB_EXPRPT_PKG.getPaymentDueFromReport(p_report_header_id,l_textValArr(iText))) THEN
        l_debug_info := 'Could not set workflow attribute Payment_Due_From';
    END IF;

  -------------------------------------------------------------
  l_debug_info := 'Retrieve and Set Approver Item Attributes If
		   Approver_Id is provided by the user';
  --------------------------------------------------------------

  -- Be sure to clear these values.  If we are resubmitting, we don't want 
  -- the values from the previous process traversal to hang around.
  l_approver_name := NULL;
  l_approver_display_name := NULL;

  IF (p_approver_id IS NOT NULL) THEN

    WF_DIRECTORY.GetUserName('PER',
			     p_approver_id,
			     l_approver_name,
			     l_approver_display_name);

    iNum := iNum + 1;
    l_numNameArr(iNum) := 'APPROVER_ID';
    l_numValArr(iNum) := p_approver_id;

    iText := iText + 1;
    l_textNameArr(iText) := 'APPROVER_NAME';
    l_textValArr(iText) := l_approver_name;

    iText := iText + 1;
    l_textNameArr(iText) := 'APPROVER_DISPLAY_NAME';
    l_textValArr(iText) := l_approver_display_name;
  END IF;

  ---------------------------------------------------------------
  l_debug_info := 'Set WF (Expense Report) Total Item Attribute';
  ---------------------------------------------------------------
    iNum := iNum + 1;
    l_numNameArr(iNum) := 'TOTAL';
    l_numValArr(iNum) := l_total;

  ------------------------------------------------------------------------
  l_debug_info := 'Set WF (Expense Report) Display_Total Item Attribute';
  ------------------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'DISPLAY_TOTAL';
    l_textValArr(iText) := l_total_dsp || ' ' || p_reimb_curr;

  -----------------------------------------------------
  l_debug_info := 'Get Workflow Version Number 0';
  -----------------------------------------------------
  C_WF_Version := GetFlowVersion(l_item_type, l_item_key);

  IF (C_WF_Version >= C_CreditLineVersion) THEN

    ---------------------------------------------------------------
    l_debug_info := 'Set WF (Expense Report) New Expense Total Item Attribute';
    ---------------------------------------------------------------
    iNum := iNum + 1;
    l_numNameArr(iNum) := 'POS_NEW_EXPENSE_TOTAL';
    l_numValArr(iNum) := p_new_total;

    ------------------------------------------------------------------------
    l_debug_info := 'Set WF (Expense Report) New Expense Display Total Item Attribute';
    ------------------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'POS_NEW_EXPENSE_DISPLAY_TOTAL';
    l_textValArr(iText) := l_new_total_dsp;

   ---------------------------------------------------------------
   l_debug_info := 'Set WF (Expense Report) Credit Total Item Attribute';
   ---------------------------------------------------------------
    iNum := iNum + 1;
    l_numNameArr(iNum) := 'NEG_CREDIT_TOTAL';
    l_numValArr(iNum) := l_credit_total;

    ------------------------------------------------------------------------
    l_debug_info := 'Set WF (Expense Report) Credit Display Total Item Attribute';
    ------------------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'NEG_CREDIT_DISPLAY_TOTAL';
    l_textValArr(iText) := l_credit_total_dsp;
  END IF;

  IF (C_WF_Version >= C_ProjectIntegrationVersion) THEN

    -------------------------------------------------
    l_debug_info := 'Set WF Week End Date Item Attribute';
    -------------------------------------------------
    WF_ENGINE.SetItemAttrDate(l_item_type,
			      l_item_key,
			      'WEEK_END_DATE',
			      p_week_end_date);

  END IF;

  IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_11_0_3Version) THEN
    -------------------------------------------------
    l_debug_info := 'Set whether employee is project enabled';
    -------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'EMPLOYEE_PROJECT_ENABLED';
    l_textValArr(iText) := l_employee_project_enabled;
  END IF;

  ---------------------------------------------------------------
  l_debug_info := 'Set WF (Expense Report) Currency Item Attribute';
  ---------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'CURRENCY';
    l_textValArr(iText) := p_reimb_curr;

  -------------------------------------------------------------
  l_debug_info := 'Set WF Document Cost Center Item Attribute';
  -------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'DOC_COST_CENTER';
    l_textValArr(iText) := p_cost_center;

  -------------------------------------------------------------
  l_debug_info := 'Set WF Employee Cost Center Item Attribute';
  -------------------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'EMP_COST_CENTER';
    l_textValArr(iText) := l_emp_cost_center;

  -------------------------------------------------------------
  l_debug_info := 'Set Header Attachments';
  -------------------------------------------------------------
    IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_OIEJ_Version) THEN

      iText := iText + 1;
      l_textNameArr(iText) := 'HEADER_ATTACHMENTS';
      l_textValArr(iText)  := 'FND:entity=OIE_HEADER_ATTACHMENTS'|| '&' || 'pk1name=REPORT_HEADER_ID'||'&' ||'pk1value=' || l_item_key;

    END IF;

    ----------------------------------------------------
    l_debug_info := 'Set SUBMIT_FROM_OIE Item Attribute';
    ----------------------------------------------------
    WF_ENGINE.SetItemAttrText(l_item_type,
                              	l_item_key,
                              	'SUBMIT_FROM_OIE',
                             	p_submit_from_oie);

  --------------------------------------------------------
  l_debug_info := 'Call JumpIntoFunction to retrieve URL';
  --------------------------------------------------------
  AP_WEB_INFRASTRUCTURE_PKG.JumpIntoFunction(p_report_header_id,
					'EXPENSE REPORT',
					l_url);

  -----------------------------------------------------
  l_debug_info := 'Set EXPENSE DETAILS Item Attribute';
  -----------------------------------------------------

  -- Be sure to clear these values.  If we are resubmitting, we don't want 
  -- the values from the previous process traversal to hang around.
    iText := iText + 1;
    l_textNameArr(iText) := 'EXPENSE_DETAILS';
    l_textValArr(iText) := l_url;

    -----------------------------------------------------
    l_debug_info := 'Retrieve user id';
    -----------------------------------------------------
    AP_WEB_OA_MAINFLOW_PKG.GetUserID(p_employee_id, l_userid);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve policy profile option';
    ------------------------------------------------------------
    FND_PROFILE.get_specific('AP_WEB_POLICY_VIOLATION_SUBMIT', l_userid,
    l_n_resp_id, 200, l_policy_violation_value, l_policy_violation_defined);

    if l_policy_violation_defined then
      l_policy_violation_value := NVL(l_policy_violation_value, C_ALLOW_NO_WARNINGS);
    else
      l_policy_violation_value := C_ALLOW_NO_WARNINGS;
    end if;

    --Bug 3581975:Select the policy lines with distribution_line_number > 0.
    SELECT count(*)
    INTO   l_violation_count
    FROM   ap_pol_violations
    WHERE  report_header_id = p_report_header_id
    and    distribution_line_number > 0;

    ------------------------------------------------------------
    l_debug_info := 'Do NOT set EMP_VIOLATION_NOTE when policy profile is Approver Only';
    ------------------------------------------------------------
    IF (l_violation_count > 0) THEN
      IF (l_policy_violation_value <> C_ALLOW_NO_WARNINGS) THEN
        FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_VIOLATION_NOTE');
        l_mess := FND_MESSAGE.GET;
        iText := iText + 1;
        l_textNameArr(iText) := 'EMP_VIOLATION_NOTE';
        l_textValArr(iText) := l_mess;
      END IF;

      FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_VIOLATION_NOTE');
      l_mess := FND_MESSAGE.GET;
      iText := iText + 1;
      l_textNameArr(iText) := 'VIOLATION_NOTE';
      l_textValArr(iText) := l_mess;

    ELSE
      iText := iText + 1;
      l_textNameArr(iText) := 'VIOLATION_NOTE';
      l_textValArr(iText) := '';

    END IF;
 
  -----------------------------------------------------
  l_debug_info := 'Set MILEAGE_NOTE Item Attribute';
  -----------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'MILEAGE_NOTE';
    l_textValArr(iText) := '';

  -----------------------------------------------------
  l_debug_info := 'Set VERIFY_NOTE Item Attribute';
  -----------------------------------------------------
    iText := iText + 1;
    l_textNameArr(iText) := 'VERIFY_NOTE';
    l_textValArr(iText) := '';

  -----------------------------------------------------
  l_debug_info := 'Set all number Attributes';
  -----------------------------------------------------
  WF_ENGINE.SetItemAttrNumberArray(l_item_type, l_item_key, l_numNameArr, l_numValArr);

  -----------------------------------------------------
  l_debug_info := 'Set all text Attributes';
  -----------------------------------------------------  
  WF_ENGINE.SetItemAttrTextArray(l_item_type, l_item_key, l_textNameArr, l_textValArr);
  
  BEGIN
  IF (NOT l_ResubmitReport and p_event_raised <> 'Y') THEN

    ------------------------------------------------------------
    l_debug_info := 'Start the Expense Report Workflow Process';
    ------------------------------------------------------------
    WF_ENGINE.StartProcess(l_item_type,
			   l_item_key);

  ELSIF (l_ResubmitReport) THEN

    ------------------------------------------------------------
    l_debug_info := 'clear the header/line level return/audit reason/instructions in AERH/AERL';
    ------------------------------------------------------------
    AP_WEB_DB_EXPRPT_PKG.clearAuditReturnReasonInstr(p_report_header_id);
    AP_WEB_DB_EXPLINE_PKG.clearAuditReturnReasonInstr(p_report_header_id);

    ----------------------------------------------------------
    l_debug_info := 'clear Item Attribute AUDIT_RETURN_REASON';
    ---------------------------------------------------------
    WF_ENGINE.SetItemAttrText(l_item_type,
	 		        l_item_key,
			        'AUDIT_RETURN_REASON',
			        '');

    ----------------------------------------------------------
    l_debug_info := 'Set Item Attribute AUDIT_INSTRUCTIONS';
    ---------------------------------------------------------
    WF_ENGINE.SetItemAttrText(l_item_type,
	 		        l_item_key,
			        'AUDIT_INSTRUCTIONS',
			        '');

    ------------------------------------------------------------
    l_debug_info := 'Restart the Expense Report Workflow Process';
    ------------------------------------------------------------
    WF_ENGINE.CompleteActivity(l_item_type,
			       l_item_key,
                               'RESUBMIT_BLOCK',
                               '');

  
  END IF;

  EXCEPTION
    WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'StartExpenseReportProcess', 
                     l_item_type, l_item_key, to_char(0), l_debug_info);
    raise;
  END;
--END IF;  --validatesession
  
  /*Bug 3389386:For Expense report with Both Pay only personal transactions,
                set the expense_status_code as PAID .
  */
  AP_WEB_EXPENSE_WF.SetExpenseStatusCode(p_report_header_id);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end StartExpenseReportProcess');

EXCEPTION
  WHEN OTHERS THEN

    -- bug 2203689, set workflow_approved_flag to S so that users can
    -- re-submit the report without re-entering data again

    -- Bug 3248874 : Also set expense_status_code as NULL.
    --               Source as NonValidateWebExpense.

    UPDATE ap_expense_report_headers erh
    SET    workflow_approved_flag = 'S',           
           expense_status_code = null,
           source = 'NonValidatedWebExpense'
    WHERE  report_header_id = p_report_header_id;
    COMMIT;


    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'StartExpenseReportProcess');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;

    -- always raise exceptions regardless it from StartExpenseReportProcess
    -- or other callees
    APP_EXCEPTION.RAISE_EXCEPTION;

END StartExpenseReportProcess;


---------------------------------------------------
PROCEDURE GenerateLineErrorsClob(document_id in varchar2,
                 display_type in varchar2,
                 document in out nocopy clob,
                 document_type in out nocopy varchar2,
                 p_is_ccard in boolean,
                 p_is_ap    in boolean) IS
---------------------------------------------------

  l_debug_info 			VARCHAR2(200);

  l_colon    NUMBER;
  l_item_type VARCHAR2(7);
  l_item_key  VARCHAR2(15);

  l_currency                    VARCHAR2(50);
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_num_lines			NUMBER := 0;

  l_n_org_id Number;

  ---------------------------------------------------------
  -- local procedure to build table header columns
  ---------------------------------------------------------
  PROCEDURE GenTableHeader(document in out nocopy clob,
                           p_is_ccard in boolean,
                           p_is_ap    in boolean) IS

    l_prompts                   AP_WEB_UTILITIES_PKG.prompts_table;
    l_title                     AK_REGIONS_VL.name%TYPE;
    l_table_header              VARCHAR2(2000);

    l_debug_info 			VARCHAR2(200);

  BEGIN
      ---------------------------------------------------------
      l_debug_info := 'Get AP_WEB_WF_SS_ERROR prompts';
      ---------------------------------------------------------
      AP_WEB_DISC_PKG.getPrompts(200,'AP_WEB_WF_SS_ERROR', l_title, l_prompts);

      ---------------------------------------------------------
      l_debug_info := 'Build the table column headers for sysadmin/preparer';
      ---------------------------------------------------------
      if (p_is_ccard = true) then
        l_table_header := indent_start || table_title_start || l_prompts(2) || table_title_end;
      elsif (p_is_ccard = false) then
        l_table_header := indent_start || table_title_start || l_prompts(3) || table_title_end;
      end if;

      l_table_header := l_table_header || table_start;
      l_table_header := l_table_header || tr_start;
      -- display Line Number
      l_table_header := l_table_header || th_select || l_prompts(4) || td_end;
      -- display Date
      l_table_header := l_table_header || th_text || l_prompts(5) || td_end;
      -- display Expense Type
      l_table_header := l_table_header || th_text || l_prompts(6) || td_end;
      -- display Amount
      l_table_header := l_table_header || th_number || l_prompts(7) ||' (' || l_currency || ')' || td_end;

      ---------------------------------------------------------
      l_debug_info := 'Add the Reason column to the Sys Admin table';
      ---------------------------------------------------------
      if (p_is_ap = true) then
        l_table_header := l_table_header || th_text || l_prompts(8) || td_end;
      end if;

      l_table_header := l_table_header || tr_end;

      WF_NOTIFICATION.WriteToClob(document, l_table_header);

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'GenTableHeader');
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;
      APP_EXCEPTION.RAISE_EXCEPTION;

  END GenTableHeader;

  ---------------------------------------------------------
  -- local procedure to build table rows
  ---------------------------------------------------------
  PROCEDURE GenTableRows(document in out nocopy clob,
                         p_is_ccard in boolean,
                         p_is_ap    in boolean) IS

    l_prompts                   AP_WEB_UTILITIES_PKG.prompts_table;
    l_title                     AK_REGIONS_VL.name%TYPE;

    l_table_row                 VARCHAR2(2000);
    l_line_num                  NUMBER := 0;

    ExpenseReportLinesCursor    AP_WEB_DB_EXPLINE_PKG.XpenseLineAcctCursor;
    V_DistLineNumber            AP_WEB_DB_EXPLINE_PKG.expLines_distLineNum;
    l_report_distribution_id    AP_WEB_DB_EXPDIST_PKG.expDist_REPORT_DISTRIBUTION_ID;
    V_StartExpenseDate          AP_WEB_DB_EXPLINE_PKG.expLines_startExpDate;
    V_Amount                    AP_WEB_DB_EXPLINE_PKG.expLines_amount;
    V_ExpenseType               AP_EXPENSE_REPORT_PARAMS.web_friendly_prompt%TYPE;
    V_CreditCardTrxID           AP_WEB_DB_EXPLINE_PKG.expLines_crdCardTrxID;
    V_ProjectID                 AP_WEB_DB_EXPLINE_PKG.expLines_projID;
    V_TaskID                    AP_WEB_DB_EXPLINE_PKG.expLines_taskID;
    -- Grants Integration
    V_AwardID                   GMS_OIE_INT_PKG.gms_awardId;
    V_AwardSetID                NUMBER := NULL;
    V_ExpenditureItemDate       AP_WEB_DB_EXPLINE_PKG.expLines_expendItemDate;
    V_ExpenditureType           AP_WEB_DB_EXPLINE_PKG.expLines_expendType;
    V_PAQuantity                AP_WEB_DB_EXPLINE_PKG.expLines_paQuantity;
    V_ExpenditureOrganizationID AP_WEB_DB_EXPLINE_PKG.expLines_expOrgID;
    V_WebParamID                AP_WEB_DB_EXPLINE_PKG.expLines_webParamID;
    V_AdjustmentReason          AP_WEB_DB_EXPLINE_PKG.expLines_adjReason;
    V_CategoryCode		AP_WEB_DB_EXPLINE_PKG.expLines_categorycode;
    V_FlexConcactenated         AP_EXPENSE_REPORT_PARAMS.flex_concactenated%TYPE;
    V_LineAttributeCategory     AP_WEB_DB_EXPLINE_PKG.expLines_attrCategory;
    V_LineAttribute1            AP_WEB_DB_EXPLINE_PKG.expLines_attr1;
    V_LineAttribute2            AP_WEB_DB_EXPLINE_PKG.expLines_attr2;
    V_LineAttribute3            AP_WEB_DB_EXPLINE_PKG.expLines_attr3;
    V_LineAttribute4            AP_WEB_DB_EXPLINE_PKG.expLines_attr4;
    V_LineAttribute5            AP_WEB_DB_EXPLINE_PKG.expLines_attr5;
    V_LineAttribute6            AP_WEB_DB_EXPLINE_PKG.expLines_attr6;
    V_LineAttribute7            AP_WEB_DB_EXPLINE_PKG.expLines_attr7;
    V_LineAttribute8            AP_WEB_DB_EXPLINE_PKG.expLines_attr8;
    V_LineAttribute9            AP_WEB_DB_EXPLINE_PKG.expLines_attr9;
    V_LineAttribute10           AP_WEB_DB_EXPLINE_PKG.expLines_attr10;
    V_LineAttribute11           AP_WEB_DB_EXPLINE_PKG.expLines_attr11;
    V_LineAttribute12           AP_WEB_DB_EXPLINE_PKG.expLines_attr12;
    V_LineAttribute13           AP_WEB_DB_EXPLINE_PKG.expLines_attr13;
    V_LineAttribute14           AP_WEB_DB_EXPLINE_PKG.expLines_attr14;
    V_LineAttribute15           AP_WEB_DB_EXPLINE_PKG.expLines_attr15;
    V_LineFlexConcat            AP_WEB_DB_EXPLINE_PKG.expLines_LineFlexConcat;
    V_APValidationError         AP_WEB_DB_EXPLINE_PKG.expLines_APValidationError;
    V_ReportLineId              AP_WEB_DB_EXPLINE_PKG.expLines_report_line_id;


    l_debug_info 			VARCHAR2(200);

  BEGIN

  ------------------------------------------------------------------------
  l_debug_info := 'calling AP_WEB_DB_EXPLINE_PKG.GetExpDistAcctCursor';
  ------------------------------------------------------------------------
  IF (AP_WEB_DB_EXPLINE_PKG.GetExpDistAcctCursor(l_report_header_id,
        ExpenseReportLinesCursor)) THEN

    LOOP
          FETCH ExpenseReportLinesCursor INTO
               V_DistLineNumber,
               l_report_distribution_id,
               V_StartExpenseDate,
               V_Amount,
               V_ExpenseType,
               V_CreditCardTrxID,
               V_ProjectID,
               V_TaskID,
               V_AwardID,
               V_ExpenditureItemDate,
               V_ExpenditureType,
               V_PAQuantity,
               V_ExpenditureOrganizationID,
               V_WebParamID,
               V_AdjustmentReason,
               V_FlexConcactenated,
	       V_CategoryCode,
               V_LineAttributeCategory,
               V_LineAttribute1,
               V_LineAttribute2,
               V_LineAttribute3,
               V_LineAttribute4,
               V_LineAttribute5,
               V_LineAttribute6,
               V_LineAttribute7,
               V_LineAttribute8,
               V_LineAttribute9,
               V_LineAttribute10,
               V_LineAttribute11,
               V_LineAttribute12,
               V_LineAttribute13,
               V_LineAttribute14,
               V_LineAttribute15,
               V_LineFlexConcat,
               V_APValidationError,
               V_ReportLineId;
          EXIT WHEN ExpenseReportLinesCursor%NOTFOUND;

          ---------------------------------------------------------
          l_debug_info := 'Build the row cells for sysadmin/preparer';
          ---------------------------------------------------------
          if (((p_is_ccard = true and V_CreditCardTrxID is not null) or
               (p_is_ccard = false and V_CreditCardTrxID is null)) and
              V_APValidationError is not null) then

            l_line_num := l_line_num + 1;

            l_table_row := tr_start;
            l_table_row := l_table_row || td_select || to_char(l_line_num) || td_end;
            l_table_row := l_table_row || td_text || V_StartExpenseDate || td_end;
            l_table_row := l_table_row || td_text || V_ExpenseType || td_end;
            l_table_row := l_table_row || td_number || to_char(V_Amount, FND_CURRENCY.Get_Format_Mask(l_currency,22)) || td_end;

            ---------------------------------------------------------
            l_debug_info := 'Add the Reason column to the Sys Admin table';
            ---------------------------------------------------------
            if (p_is_ap = true) then
              l_table_row := l_table_row || td_text || V_APValidationError || td_end;
            end if;

            l_table_row := l_table_row || tr_end;

            WF_NOTIFICATION.WriteToClob(document, l_table_row);
          end if;

   END LOOP; /* ExpenseReportLinesCursor */

  END IF; /* GetExpDistAcctCursor */

  if ExpenseReportLinesCursor%isopen then
     CLOSE ExpenseReportLinesCursor;
  end if;

      l_table_row := table_end || indent_end;

      WF_NOTIFICATION.WriteToClob(document, l_table_row);

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'GenTableRows');
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;
      APP_EXCEPTION.RAISE_EXCEPTION;

  END GenTableRows;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GenerateLineErrorsClob');

  ------------------------------------------------------------
  l_debug_info := 'Decode document_id';
  ------------------------------------------------------------
  l_colon    := instrb(document_id, ':');
  l_item_type := substrb(document_id, 1, l_colon - 1);
  l_item_key  := substrb(document_id, l_colon  + 1);

  ----------------------------------------------------
  l_debug_info := 'Retrieve Currency Item Attribute';
  ----------------------------------------------------
  l_currency := WF_ENGINE.GetItemAttrText(l_item_type,
                                          l_item_key,
                                          'CURRENCY');

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(l_item_type,
                                                    l_item_key,
                                                    'EXPENSE_REPORT_ID');

  --------------------------------------------
  l_debug_info := 'Get Org Id';
  --------------------------------------------
  begin

    l_n_org_id := WF_ENGINE.GetItemAttrNumber(l_item_type,
                              l_item_key,
                              'ORG_ID');
    exception
        when others then
          if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
            -- ORG_ID item attribute doesn't exist, need to add it
            WF_ENGINE.AddItemAttr(l_item_type, l_item_key, 'ORG_ID');
            IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(
                                to_number(l_item_key),
                                l_n_org_id) <> TRUE ) THEN
               l_n_org_id := NULL;
            END IF;

            WF_ENGINE.SetItemAttrNumber(l_item_type,
                                l_item_key,
                                'ORG_ID',
                                l_n_org_ID);
          else
            raise;
          end if;

  end;

  if (l_n_org_id is not null) then
    fnd_client_info.set_org_context(l_n_org_id);
  else
    -- Report was submitted before org_id being added, hence org_id
    -- item attributes hasn't been set yet. Need to get it from
    -- report header
    IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(to_number(l_item_key), l_n_org_id) <> TRUE ) THEN
      l_n_org_id := NULL;
    END IF;

    IF (l_n_org_id is not null) then
      fnd_client_info.set_org_context(l_n_org_id);
    END IF;
  end if; -- l_n_org_id

  if (p_is_ccard) then

    ------------------------------------------------------------
    l_debug_info := 'Checking number of credit card lines with errors';
    ------------------------------------------------------------
    select count(*)
    into   l_num_lines
    from   ap_expense_report_lines
    where  report_header_id = l_report_header_id
    and    credit_card_trx_id is not null
    and    ap_validation_error is not null;

    if (l_num_lines = 0) then
      return;
    end if;

  else

    ------------------------------------------------------------
    l_debug_info := 'Checking number of cash lines with errors';
    ------------------------------------------------------------
    select count(*)
    into   l_num_lines
    from   ap_expense_report_lines
    where  report_header_id = l_report_header_id
    and    credit_card_trx_id is null
    and    ap_validation_error is not null;

    if (l_num_lines = 0) then
      return;
    end if;

  end if;

  GenTableHeader(document, p_is_ccard, p_is_ap);
  GenTableRows(document, p_is_ccard, p_is_ap);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GenerateLineErrorsClob');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GenerateLineErrorsClob',
                    document_id, l_debug_info);
    raise;
END GenerateLineErrorsClob;

---------------------------------------------------
PROCEDURE CashLineErrorsAP(document_id in varchar2,
                 display_type in varchar2,
                 document in out nocopy clob,
                 document_type in out nocopy varchar2) IS
---------------------------------------------------

  l_debug_info 			VARCHAR2(200);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CashLineErrorsAP');

  GenerateLineErrorsClob(document_id,
                         display_type,
                         document,
                         document_type,
                         p_is_ccard => false,
                         p_is_ap    => true);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CashLineErrorsAP');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CashLineErrorsAP',
                    document_id, l_debug_info);
    raise;
END CashLineErrorsAP;

---------------------------------------------------
PROCEDURE CashLineErrorsPreparer(document_id in varchar2,
                 display_type in varchar2,
                 document in out nocopy clob,
                 document_type in out nocopy varchar2) IS
---------------------------------------------------

  l_debug_info 			VARCHAR2(200);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CashLineErrorsPreparer');

  GenerateLineErrorsClob(document_id,
                         display_type,
                         document,
                         document_type,
                         p_is_ccard => false,
                         p_is_ap    => false);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CashLineErrorsPreparer');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CashLineErrorsPreparer',
                    document_id, l_debug_info);
    raise;
END CashLineErrorsPreparer;

---------------------------------------------------
PROCEDURE CCardLineErrorsAP(document_id in varchar2,
                 display_type in varchar2,
                 document in out nocopy clob,
                 document_type in out nocopy varchar2) IS
---------------------------------------------------

  l_debug_info 			VARCHAR2(200);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CCardLineErrorsAP');

  GenerateLineErrorsClob(document_id,
                         display_type,
                         document,
                         document_type,
                         p_is_ccard => true,
                         p_is_ap    => true);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CCardLineErrorsAP');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CCardLineErrorsAP',
                    document_id, l_debug_info);
    raise;
END CCardLineErrorsAP;

---------------------------------------------------
PROCEDURE CCardLineErrorsPreparer(document_id in varchar2,
                 display_type in varchar2,
                 document in out nocopy clob,
                 document_type in out nocopy varchar2) IS
---------------------------------------------------

  l_debug_info 			VARCHAR2(200);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CCardLineErrorsPreparer');

  GenerateLineErrorsClob(document_id,
                         display_type,
                         document,
                         document_type,
                         p_is_ccard => true,
                         p_is_ap    => false);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CCardLineErrorsPreparer');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CCardLineErrorsPreparer',
                    document_id, l_debug_info);
    raise;
END CCardLineErrorsPreparer;





---------------------------------------------------
PROCEDURE ResetAPValidationAttrValues(p_item_type IN VARCHAR2, 
                                      p_item_key  IN VARCHAR2,
                                      p_actid     IN NUMBER)
---------------------------------------------------
IS
--
-- Reset the AP Validation attribute values which are not set explicitly by 
-- StartExpenseReportProcess before the returned report is resubmitted.
-- We need to clear these because we will be revisiting nodes in the process.
--

  l_textNameArr   Wf_Engine.NameTabTyp;
  l_textValArr    Wf_Engine.TextTabTyp;
  iText NUMBER :=0;

  l_report_header_id		NUMBER;
  C_WF_Version                  NUMBER          := 0;

  l_debug_info 			VARCHAR2(200);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ResetAPValidationAttrValues');

  ----------------------------------------------------------------
  l_debug_info := 'Unset Header and Setup errors';
  -----------------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'HEADER_ERRORS';
  l_textValArr(iText) := '';

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                    p_item_key,
                                                   'EXPENSE_REPORT_ID');

  ------------------------------------------------------
  l_debug_info := 'Get version of Workflow';
  ------------------------------------------------------
  C_WF_Version := GetFlowVersion(p_item_type, p_item_key);

  ------------------------------------------------------
  l_debug_info := 'Set GEN_HEADER_ERRORS Item Attribute'; 
  ------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'GEN_HEADER_ERRORS';
  l_textValArr(iText) := 'plsql:AP_WEB_EXPENSE_WF.GenerateHeaderErrors/'||p_item_type||':'||p_item_key;

  ------------------------------------------------------
  l_debug_info := 'Set CASH_LINE_ERRORS_AP Item Attribute'; 
  ------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'CASH_LINE_ERRORS_AP';
  l_textValArr(iText) := 'plsqlclob:AP_WEB_EXPENSE_WF.CashLineErrorsAP/'||p_item_type||':'||p_item_key;

  ------------------------------------------------------
  l_debug_info := 'Set CASH_LINE_ERRORS_PREPARER Item Attribute'; 
  ------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'CASH_LINE_ERRORS_PREPARER';
  l_textValArr(iText) := 'plsqlclob:AP_WEB_EXPENSE_WF.CashLineErrorsPreparer/'||p_item_type||':'||p_item_key;

  ------------------------------------------------------
  l_debug_info := 'Set CCARD_LINE_ERRORS_AP Item Attribute'; 
  ------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'CCARD_LINE_ERRORS_AP';
  l_textValArr(iText) := 'plsqlclob:AP_WEB_EXPENSE_WF.CCardLineErrorsAP/'||p_item_type||':'||p_item_key;

  ------------------------------------------------------
  l_debug_info := 'Set CCARD_LINE_ERRORS_PREPARER Item Attribute'; 
  ------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'CCARD_LINE_ERRORS_PREPARER';
  l_textValArr(iText) := 'plsqlclob:AP_WEB_EXPENSE_WF.CCardLineErrorsPreparer/'||p_item_type||':'||p_item_key;

  ----------------------------------------------------------------
  l_debug_info := 'Reset AP Validation errors';
  -----------------------------------------------------------------
  AP_WEB_DB_EXPLINE_PKG.ResetAPValidationErrors(l_report_header_id);

  ----------------------------------------------------------------
  l_debug_info := 'Unset Is Default Cost Center Used?';
  -----------------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'IS_DEFAULT_COST_CENTER_USED';
  l_textValArr(iText) := '';

  ----------------------------------------------------------------
  l_debug_info := 'Unset Is Projects Expense Report?';
  -----------------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'IS_PROJECTS_REPORT';
  l_textValArr(iText) := '';

  ----------------------------------------------------------------
  l_debug_info := 'Unset WF Administrators Note';
  -----------------------------------------------------------------
  iText := iText + 1;
  l_textNameArr(iText) := 'WF_ADMIN_NOTE';
  l_textValArr(iText) := '';

  ----------------------------------------------------------------
  l_debug_info := 'Unset EXP_ALLOCATION_ERRORS'; 
  -----------------------------------------------------------------
  IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_OIEJ_Version) THEN
    iText := iText + 1;
    l_textNameArr(iText) := 'EXP_ALLOCATION_ERRORS';
    l_textValArr(iText) := '';
  END IF;

  -----------------------------------------------------
  l_debug_info := 'Set all text Attributes';
  -----------------------------------------------------  
  WF_ENGINE.SetItemAttrTextArray(p_item_type, p_item_key, l_textNameArr, l_textValArr);


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ResetAPValidationAttrValues');

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END ResetAPValidationAttrValues;

------------------------------------------------------------------------
PROCEDURE APValidateExpenseReport(p_item_type		IN VARCHAR2,
			     	  p_item_key		IN VARCHAR2,
			     	  p_actid		IN NUMBER,
			     	  p_funmode		IN VARCHAR2,
			     	  p_result	 OUT NOCOPY VARCHAR2) IS
------------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;

  l_emp_cost_center		VARCHAR2(240);
  l_doc_cost_center		VARCHAR2(240);

  l_header_errors               VARCHAR2(2000) := NULL;
  l_other_errors                VARCHAR2(2000) := NULL;
  l_exp_alloc_errors            VARCHAR2(2000) := NULL;
  l_num_line_errors		NUMBER := 0;

  l_yes                         VARCHAR2(80);
  l_no                          VARCHAR2(80);

  l_debug_info			VARCHAR2(200);
  C_WF_Version                  NUMBER          := 0;


BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start APValidateExpenseReport');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    ----------------------------------------------------------------
    l_debug_info := 'Reset AP Validation Attributes';
    ----------------------------------------------------------------
    ResetAPValidationAttrValues(p_item_type,
                                p_item_key,
                                p_actid);

    ---------------------------------------
    l_debug_info := 'Call DoAPValidation';
    ---------------------------------------    
    DoAPValidation(p_item_type,
                   p_item_key,
                   l_report_header_id);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve HEADER_ERRORS Item Attribute';
    ------------------------------------------------------------
    l_header_errors := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'HEADER_ERRORS');
    if (l_header_errors IS NOT NULL) then
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'HEADER_ERRORS',
				l_header_errors || '<br>');
    end if;

    ------------------------------------------------------------
    l_debug_info := 'Retrieve OTHER_ERRORS Item Attribute';
    ------------------------------------------------------------
    l_other_errors := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'OTHER_ERRORS');
    if (l_other_errors IS NOT NULL) then
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'OTHER_ERRORS',
				l_other_errors || '<br>');
    end if;

    ------------------------------------------------------
    l_debug_info := 'Get version of Workflow';
    ------------------------------------------------------
    C_WF_Version := GetFlowVersion(p_item_type, p_item_key);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve EXP_ALLOCATION_ERRORS Item Attribute';
    ------------------------------------------------------------
    IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_OIEJ_Version) THEN
      l_exp_alloc_errors := WF_ENGINE.GetItemAttrText(p_item_type,
                                                      p_item_key,
                                                      'EXP_ALLOCATION_ERRORS',
    						      true);
      if (l_exp_alloc_errors IS NOT NULL) then
        WF_ENGINE.SetItemAttrText(p_item_type,
                                  p_item_key,
                                  'EXP_ALLOCATION_ERRORS',
                                  l_exp_alloc_errors );
      end if;
    END IF;

    ----------------------------------------------------------------
    l_debug_info := 'Retrieve Employee Cost Center Item Attribute';
    ----------------------------------------------------------------
    l_emp_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
                                                   p_item_key,
                                                   'EMP_COST_CENTER');
  
    ----------------------------------------------------------------
    l_debug_info := 'Retrieve Document Cost Center Item Attribute';
    ----------------------------------------------------------------
    l_doc_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
                                                   p_item_key,
                                                   'DOC_COST_CENTER');

    ----------------------------------------------------------------
    l_debug_info := 'Set IS_DEFAULT_COST_CENTER_USED';
    ----------------------------------------------------------------
    if (l_emp_cost_center = l_doc_cost_center) then

      SELECT fndl.meaning
      INTO l_yes
      FROM FND_LOOKUPS fndl
      WHERE fndl.LOOKUP_TYPE = C_YES_NO
      AND   fndl.LOOKUP_CODE = C_Y;

      WF_ENGINE.SetItemAttrText(p_item_type,
                                p_item_key,
                                'IS_DEFAULT_COST_CENTER_USED',
                                l_yes);
    else

      SELECT fndl.meaning
      INTO l_no
      FROM FND_LOOKUPS fndl
      WHERE fndl.LOOKUP_TYPE = C_YES_NO
      AND   fndl.LOOKUP_CODE = C_N;

      WF_ENGINE.SetItemAttrText(p_item_type,
                                p_item_key,
                                'IS_DEFAULT_COST_CENTER_USED',
                                l_no);
    end if;

    ----------------------------------------------------------------
    l_debug_info := 'Get number of line errors';
    -----------------------------------------------------------------
    select count(*)
    into   l_num_line_errors
    from   ap_expense_report_lines
    where  report_header_id = l_report_header_id
    and    ap_validation_error is not null;

    ----------------------------------------------------------------
    l_debug_info := 'Return Pass If No Header or Line Errors,
                     otherwise Return Fail';
    -----------------------------------------------------------------
    IF (l_header_errors IS NULL AND l_num_line_errors = 0 AND l_other_errors IS NULL) then
      p_result := 'COMPLETE:AP_PASS';
    ELSIF (l_exp_alloc_errors is not null) THEN
      p_result := 'COMPLETE:AP_FAIL_EXP_ALLOC';
    ELSE
      p_result := 'COMPLETE:AP_FAIL';
      /*
         The following item attributes are also set:
         1. Cost Center Entered = DOC_COST_CENTER
            This is already set in the WF process
         2. IS_DEFAULT_COST_CENTER_USED = 'Yes'/'No'
            This is set in APValidateExpenseReport()
         3. IS_PROJECTS_REPORT = 'Yes' if report contains Projects lines
            This is set in DoAPValidation()
      */

    END IF;   

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end APValidateExpenseReport');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'APValidateExpenseReport', 
                     p_item_type, p_item_key, to_char(0), l_debug_info || FND_MESSAGE.GET);
    raise;
END APValidateExpenseReport;

------------------------------------------------------------------------
PROCEDURE AddToWFSSError(p_error_message        IN OUT NOCOPY VARCHAR2,
			 p_new_error            IN VARCHAR2) IS
------------------------------------------------------------------------
  l_exceed_error_msg VARCHAR2(80) := 'Error message has exceeded 2000 char limit.';
BEGIN
  -- check to see if exceed error message has already been appended
  if (instrb(p_error_message, l_exceed_error_msg) = 0) then
    if ((lengthb(p_error_message) + lengthb(p_new_error) + lengthb(l_exceed_error_msg)) > 1950) then
      p_error_message := p_error_message || l_exceed_error_msg;
    else
      p_error_message := p_error_message || p_new_error;
    end if;
  end if;
EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'AddToWFSSError');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_exceed_error_msg);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;

END AddToWFSSError;

----------------------------------------------------------------------
PROCEDURE AddToHeaderErrors(p_item_type            IN  VARCHAR2,
                            p_item_key             IN  VARCHAR2,
                            p_header_error         IN  VARCHAR2) IS
----------------------------------------------------------------------

  l_header_errors	VARCHAR2(2000) := NULL;

  l_prompts			AP_WEB_UTILITIES_PKG.prompts_table;
  l_title			AK_REGIONS_VL.name%TYPE;

  l_debug_info		VARCHAR2(2000);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AddToHeaderErrors');

  ---------------------------------------------------------
  l_debug_info := 'Add to Header Errors';
  ---------------------------------------------------------
  l_header_errors := WF_ENGINE.GetItemAttrText(p_item_type,
                                               p_item_key,
                                               'HEADER_ERRORS');
  ---------------------------------------------------------
  l_debug_info := 'Check to see if error title needed';
  ---------------------------------------------------------
  if (l_header_errors IS NULL) then
    ---------------------------------------------------------
    l_debug_info := 'Add font tag';
    ---------------------------------------------------------
    l_header_errors := startOraFieldTextFont;
  else
    l_header_errors := l_header_errors || '<br>';
  end if;

  AddToWFSSError(l_header_errors, p_header_error);

  l_header_errors := l_header_errors || endOraFieldTextFont;

  WF_ENGINE.SetItemAttrText(p_item_type,
	 		    p_item_key,
			    'HEADER_ERRORS',
			    l_header_errors);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AddToHeaderErrors');

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'AddToHeaderErrors');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;

END AddToHeaderErrors;

      
----------------------------------------------------------------------
PROCEDURE HandleInvalidDistCCID(p_report_header_id IN  AP_EXPENSE_REPORT_HEADERS.report_header_id%TYPE,
                         p_report_distribution_id  IN  AP_WEB_DB_EXPDIST_PKG.expDist_REPORT_DISTRIBUTION_ID,
                         p_payment_due             IN  VARCHAR2,
                         p_exp_type_parameter_id   IN  AP_WEB_DB_EXPLINE_PKG.expLines_webParamID,
                         p_personalParameterId     IN  AP_WEB_DB_EXPLINE_PKG.expLines_webParamID,
                         p_CategoryCode            IN  AP_WEB_DB_EXPLINE_PKG.expLines_categorycode,
                         p_default_emp_segments    IN  AP_OIE_KFF_SEGMENTS_T,
                         p_dist_new_segments       IN  AP_OIE_KFF_SEGMENTS_T,
                         p_ReportLineId            IN  AP_WEB_DB_EXPLINE_PKG.expLines_report_line_id,
                         p_exp_dist_ccid           IN  AP_WEB_DB_EXPLINE_PKG.expLines_codeCombID,
                         p_chart_of_accounts_id    IN  AP_WEB_DB_AP_INT_PKG.glsob_chartOfAccountsID) IS
----------------------------------------------------------------------
  l_debug_info			VARCHAR2(1000);

  l_new_segments		AP_OIE_KFF_SEGMENTS_T;
  
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start HandleInvalidDistCCID');
  
          if (p_report_distribution_id is null) then
             if ((p_payment_due = C_CompanyPay AND p_exp_type_parameter_id = p_personalParameterId) or 
                (p_CategoryCode = C_ROUNDING))then
                 -- if dist does not exist then it adds dist and then updates
                 -- ccid and segments based on p_exp_dist_ccid
                 AP_WEB_DB_EXPDIST_PKG.updateAccountValues (
                     p_report_header_id => p_report_header_id,
                     p_report_line_id => p_ReportLineId,
                     p_report_distribution_id => p_report_distribution_id,
                     p_ccid             => p_exp_dist_ccid);                
             else
                -- When error occurs building the ccid we should update the
                -- dist table with the correct segments which caused the issue

                -----------------------------------------------------
                l_debug_info := 'Assign values to l_new_segments';
                -----------------------------------------------------
                l_new_segments := AP_OIE_KFF_SEGMENTS_T('');
                l_new_segments.extend(p_default_emp_segments.count);
                FOR i IN 1..p_default_emp_segments.count LOOP
                   l_new_segments(i) := nvl(p_dist_new_segments(i),p_default_emp_segments(i));
                END LOOP;

                -----------------------------------------------------
                l_debug_info := 'Add Dist for Line';
                -----------------------------------------------------
                AP_WEB_DB_EXPDIST_PKG.AddDistributionLine(
                  p_segments              => l_new_segments,
                  p_report_line_id        => p_ReportLineId,
                  p_chart_of_accounts_id  => p_chart_of_accounts_id);
             end if;
          end if; -- (p_report_distribution_id is null)
                    
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end HandleInvalidDistCCID');

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'HandleInvalidDistCCID');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;
END HandleInvalidDistCCID;


----------------------------------------------------------------------
PROCEDURE DoAPValidation(p_item_type            IN  VARCHAR2,
                         p_item_key             IN  VARCHAR2,
                         p_report_header_id 	IN  AP_EXPENSE_REPORT_HEADERS.report_header_id%TYPE) IS
----------------------------------------------------------------------
  l_sys_apply_advances_default	AP_WEB_DB_AP_INT_PKG.apSetUp_applyAdvDefault;
  l_sys_allow_awt_flag	      	AP_WEB_DB_AP_INT_PKG.apSetUp_allowAwtFlag;
  l_sys_default_xrate_type     	AP_WEB_DB_AP_INT_PKG.apSetUp_defaultExchRateType;
  l_sys_make_rate_mandatory    	AP_WEB_DB_AP_INT_PKG.apSetUp_makeMandatoryFlag;
  l_chart_of_accounts_id       	AP_WEB_DB_AP_INT_PKG.glsob_chartOfAccountsID;
  l_default_currency_code       AP_WEB_DB_EXPRPT_PKG.expHdr_defaultCurrCode;
  l_week_end_date	       	AP_WEB_DB_EXPRPT_PKG.expHdr_weekEndDate;
  l_exp_check_address_flag      AP_WEB_DB_HR_INT_PKG.empCurrent_checkAddrFlag;
  l_ven_allow_awt_flag	       	AP_WEB_DB_AP_INT_PKG.vendors_allowAWTFlag;
  l_ven_awt_group_id	       	AP_WEB_DB_AP_INT_PKG.vendors_awtGroupID;
  l_default_emp_ccid	       	AP_WEB_DB_HR_INT_PKG.empCurrent_defaultCodeCombID;
  l_default_emp_segments  	AP_OIE_KFF_SEGMENTS_T;
  l_exp_dist_ccid		AP_WEB_DB_EXPLINE_PKG.expLines_codeCombID;
  l_id_flex_structure_name      fnd_id_flex_structures_vl.id_flex_structure_name%TYPE;

  l_employee_ccid		AP_WEB_DB_EXPRPT_PKG.expHdr_employeeCCID;
  l_employee_id			AP_WEB_DB_EXPRPT_PKG.expHdr_employeeID;
  l_personalParameterId         AP_WEB_DB_EXPTEMPLATE_PKG.expTempl_paramID;
  l_category			AP_WEB_DB_CCARD_PKG.ccTrxn_category;
  l_default_exchange_rate	AP_WEB_DB_EXPRPT_PKG.expHdr_defaultExchRate;
  l_base_currency_code		AP_WEB_DB_AP_INT_PKG.apSetUp_baseCurrencyCode;
  l_sys_base_currency_code	AP_WEB_DB_AP_INT_PKG.apSetUp_baseCurrencyCode;
  exchange_rate_exception	EXCEPTION;
  l_available_prepays		NUMBER;
  l_payment_due			VARCHAR2(10) := C_IndividualPay;

  l_debug_info			VARCHAR2(1000);

  V_PADefaultDistCCID         AP_WEB_DB_EXPLINE_PKG.expLines_codeCombID;
  V_ConcatSegs                VARCHAR2(2000);
  V_ConcatIDs                 VARCHAR2(2000);
  V_ConcatDescrs              VARCHAR2(300);
  V_ErrMsg                    VARCHAR2(2000);--2048712
  V_ProcedureReturnCode       VARCHAR2(2000);
  V_ProcedureBillableFlag     VARCHAR2(200);
  V_PATCMsgType               VARCHAR2(10);   -- Value not used in 11.0, but used in 11.5+

  V_DefaultExchangeRateType   AP_WEB_DB_AP_INT_PKG.apSetUp_defaultExchRateType;   -- For PATC: Exchange rate type in AP
  V_BaseCurrencyCode          AP_WEB_DB_AP_INT_PKG.apSetUp_baseCurrencyCode;   -- For PATC: Functional currency
  V_ReimbCurrencyCode         VARCHAR2(15);
  V_DefaultExchangeRate       NUMBER;         -- For PATC: Exchange rate for func->reimb 
  V_AcctRawCost               NUMBER;         -- For PATC: Receipt amount in functional currency
  V_WeekEndDate               DATE;
  C_WF_Version	              NUMBER          := 0;
  l_SysInfoRec		      AP_WEB_DB_AP_INT_PKG.APSysInfoRec;

  l_error_message               VARCHAR2(2000);

  V_UserID                    NUMBER;
  V_UserName                  VARCHAR2(30);
  V_VendorID                  AP_WEB_DB_AP_INT_PKG.vendors_vendorID;
  V_IsSessionProjectEnabled   VARCHAR2(1);

  V_EmployeeID                AP_WEB_DB_EXPRPT_PKG.expHdr_employeeID;
  l_cost_center               AP_WEB_DB_EXPRPT_PKG.expHdr_flexConcat;
  V_HeaderAttributeCategory   AP_WEB_DB_EXPRPT_PKG.expHdr_attrCategory;
  V_HeaderAttribute1          AP_WEB_DB_EXPRPT_PKG.expHdr_attr1;
  V_HeaderAttribute2          AP_WEB_DB_EXPRPT_PKG.expHdr_attr2;
  V_HeaderAttribute3          AP_WEB_DB_EXPRPT_PKG.expHdr_attr3;
  V_HeaderAttribute4          AP_WEB_DB_EXPRPT_PKG.expHdr_attr4;
  V_HeaderAttribute5          AP_WEB_DB_EXPRPT_PKG.expHdr_attr5;
  V_HeaderAttribute6          AP_WEB_DB_EXPRPT_PKG.expHdr_attr6;
  V_HeaderAttribute7          AP_WEB_DB_EXPRPT_PKG.expHdr_attr7;
  V_HeaderAttribute8          AP_WEB_DB_EXPRPT_PKG.expHdr_attr8;
  V_HeaderAttribute9          AP_WEB_DB_EXPRPT_PKG.expHdr_attr9;
  V_HeaderAttribute10         AP_WEB_DB_EXPRPT_PKG.expHdr_attr10;
  V_HeaderAttribute11         AP_WEB_DB_EXPRPT_PKG.expHdr_attr11;
  V_HeaderAttribute12         AP_WEB_DB_EXPRPT_PKG.expHdr_attr12;
  V_HeaderAttribute13         AP_WEB_DB_EXPRPT_PKG.expHdr_attr13;
  V_HeaderAttribute14         AP_WEB_DB_EXPRPT_PKG.expHdr_attr14;
  V_HeaderAttribute15         AP_WEB_DB_EXPRPT_PKG.expHdr_attr15;

  ExpenseReportLinesCursor    AP_WEB_DB_EXPLINE_PKG.XpenseLineAcctCursor;
  l_dist_line_number            AP_WEB_DB_EXPLINE_PKG.expLines_distLineNum;
  l_report_distribution_id    AP_WEB_DB_EXPDIST_PKG.expDist_REPORT_DISTRIBUTION_ID;
  V_StartExpenseDate          AP_WEB_DB_EXPLINE_PKG.expLines_startExpDate;
  V_Amount                    AP_WEB_DB_EXPLINE_PKG.expLines_amount;
  V_ExpenseType               AP_EXPENSE_REPORT_PARAMS.web_friendly_prompt%TYPE;
  V_CreditCardTrxID           AP_WEB_DB_EXPLINE_PKG.expLines_crdCardTrxID;
  V_ProjectID                 AP_WEB_DB_EXPLINE_PKG.expLines_projID;
  V_TaskID                    AP_WEB_DB_EXPLINE_PKG.expLines_taskID;
  -- Grants Integration
  V_AwardID		      GMS_OIE_INT_PKG.gms_awardId;
  V_AwardSetID		      NUMBER := NULL;
  V_ExpenditureItemDate       AP_WEB_DB_EXPLINE_PKG.expLines_expendItemDate;
  V_ExpenditureType           AP_WEB_DB_EXPLINE_PKG.expLines_expendType;
  V_PAQuantity                AP_WEB_DB_EXPLINE_PKG.expLines_paQuantity;
  V_ExpenditureOrganizationID AP_WEB_DB_EXPLINE_PKG.expLines_expOrgID;
  l_exp_type_parameter_id     AP_WEB_DB_EXPLINE_PKG.expLines_webParamID;
  V_AdjustmentReason          AP_WEB_DB_EXPLINE_PKG.expLines_adjReason;
  V_CategoryCode	      AP_WEB_DB_EXPLINE_PKG.expLines_categorycode;
  V_FlexConcactenated         AP_EXPENSE_REPORT_PARAMS.flex_concactenated%TYPE;
  V_LineAttributeCategory     AP_WEB_DB_EXPLINE_PKG.expLines_attrCategory;
  V_LineAttribute1            AP_WEB_DB_EXPLINE_PKG.expLines_attr1;
  V_LineAttribute2            AP_WEB_DB_EXPLINE_PKG.expLines_attr2;
  V_LineAttribute3            AP_WEB_DB_EXPLINE_PKG.expLines_attr3;
  V_LineAttribute4            AP_WEB_DB_EXPLINE_PKG.expLines_attr4;
  V_LineAttribute5            AP_WEB_DB_EXPLINE_PKG.expLines_attr5;
  V_LineAttribute6            AP_WEB_DB_EXPLINE_PKG.expLines_attr6;
  V_LineAttribute7            AP_WEB_DB_EXPLINE_PKG.expLines_attr7;
  V_LineAttribute8            AP_WEB_DB_EXPLINE_PKG.expLines_attr8;
  V_LineAttribute9            AP_WEB_DB_EXPLINE_PKG.expLines_attr9;
  V_LineAttribute10           AP_WEB_DB_EXPLINE_PKG.expLines_attr10;
  V_LineAttribute11           AP_WEB_DB_EXPLINE_PKG.expLines_attr11;
  V_LineAttribute12           AP_WEB_DB_EXPLINE_PKG.expLines_attr12;
  V_LineAttribute13           AP_WEB_DB_EXPLINE_PKG.expLines_attr13;
  V_LineAttribute14           AP_WEB_DB_EXPLINE_PKG.expLines_attr14;
  V_LineAttribute15           AP_WEB_DB_EXPLINE_PKG.expLines_attr15;
  V_LineFlexConcat	      AP_WEB_DB_EXPLINE_PKG.expLines_LineFlexConcat;
  l_line_cost_center	      AP_WEB_DB_EXPLINE_PKG.expLines_LineFlexConcat;
  V_APValidationError         AP_WEB_DB_EXPLINE_PKG.expLines_APValidationError;
  V_ReportLineId              AP_WEB_DB_EXPLINE_PKG.expLines_report_line_id;

  l_concatenated_segments       varchar2(2000);

  l_header_error_message        VARCHAR2(2000);
  l_return_error_message        VARCHAR2(2000);
  l_return_status               VARCHAR2(30);
  l_fatal_error_occurred        BOOLEAN := false;
  l_header_error_occurred       BOOLEAN := false;
  l_line_error_occurred         BOOLEAN := false;
  l_other_error_occurred        BOOLEAN := false;
  l_add_to_line_error           BOOLEAN := false;
  l_line_error_message          VARCHAR2(2000);
  l_other_error_message         VARCHAR2(2000);
  l_is_projects_report          BOOLEAN := false;
  l_line_num                    NUMBER := 0;
  l_cash_line_num               NUMBER := 0;
  l_ccard_line_num              NUMBER := 0;
  l_yes                         VARCHAR2(80);
  l_no                          VARCHAR2(80);
  l_rounding_error_ccid		AP_WEB_DB_EXPLINE_PKG.expLines_codeCombID;
  l_card_program_id             NUMBER := 0;

  l_existing_segments		AP_OIE_KFF_SEGMENTS_T;
  l_new_segments		AP_OIE_KFF_SEGMENTS_T;
  l_dist_new_segments           AP_OIE_KFF_SEGMENTS_T;

  l_transaction_date            ap_credit_card_trxns_all.transaction_date%type;    
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start DoAPValidation');

  ---------------------------------------------------
  l_debug_info := 'Clear out potentially rejected/returned status';
  ---------------------------------------------------
  UPDATE ap_expense_report_headers erh
  SET    workflow_approved_flag = '',
         source = 'NonValidatedWebExpense'
  WHERE  report_header_id = p_report_header_id;

  --------------------------------------------------------------------
  l_debug_info := 'Retrieve values from system parameters, employees';
  --------------------------------------------------------------------
  IF (NOT AP_WEB_DB_EXPRPT_PKG.GetAccountingInfo(
         p_report_header_id,
	 l_sys_apply_advances_default,
         l_sys_allow_awt_flag,
         l_sys_default_xrate_type,
         l_sys_make_rate_mandatory,
         l_exp_check_address_flag,
 	 l_default_currency_code,
	 l_week_end_date,
	 l_cost_center,
         l_employee_id)) THEN
	NULL;
  END IF; /* GetAccountingInfo */

  ------------------------------------------------------------
  l_debug_info := 'Get Emp Acctg Info';
  ------------------------------------------------------------
  begin
    AP_WEB_ACCTG_PKG.BuildAccount(
                           p_report_header_id => null,
                           p_report_line_id => null,
                           p_employee_id => l_employee_id,
                           p_cost_center => l_cost_center,
                           p_line_cost_center => null,
                           p_exp_type_parameter_id => null,
                           p_segments => null,
                           p_ccid => null,
                           p_build_mode => AP_WEB_ACCTG_PKG.C_DEFAULT_VALIDATE,
                           p_new_segments => l_default_emp_segments,
                           p_new_ccid => l_employee_ccid,
                           p_return_error_message => l_header_error_message);
  
    -----------------------------------------------------
    l_debug_info := 'Get the Employee Chart of Accounts ID';
    -----------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.GetChartOfAccountsID(
         p_employee_id          => l_employee_id,
         p_chart_of_accounts_id => l_chart_of_accounts_id)) THEN
      NULL;
    END IF;
  
    AP_WEB_ACCTG_PKG.GetConcatenatedSegments(
        p_chart_of_accounts_id          => l_chart_of_accounts_id,
        p_segments                      => l_default_emp_segments,
        p_concatenated_segments         => l_concatenated_segments);

  exception
    when AP_WEB_OA_MAINFLOW_PKG.G_EXC_ERROR then
      l_header_error_message := FND_MESSAGE.Get;
  end;

  if (l_header_error_message is not null) then

    l_fatal_error_occurred := true;
    AddToHeaderErrors(p_item_type,
                      p_item_key,
                      l_concatenated_segments||': '||l_header_error_message);
    return;
  end if;

  ------------------------------------------------------------
  l_debug_info := 'begin preparation for Project Account Generation';
  ------------------------------------------------------------

  -- Get version of Workflow
  C_WF_Version := GetFlowVersion(p_item_type, p_item_key);

  -- Determine whether project enabled
  l_debug_info := 'Determine whether project enabled';
  V_UserID := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                          p_item_key,
                                          'EMPLOYEE_ID');

  ------------------------------------------------------------
  l_debug_info := 'Determine whether session is project enabled';
  ------------------------------------------------------------
  IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_11_0_3Version) THEN
    V_IsSessionProjectEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
                                                p_item_key,
                                                'EMPLOYEE_PROJECT_ENABLED');
  ELSE
    -- In previous versions we called 
    -- AP_WEB_PROJECT_PKG.IsSessionProjectEnabled, but that would not work
    -- without having ValidateSession called.  So, for older versions we
    -- will assume that the session is project enabled.  Since the receipts
    -- will not have any project information, the patc call will not be done.
    V_IsSessionProjectEnabled := 'Y';
  END IF; /* checking wf version */

  ------------------------------------------------------------
  l_debug_info := 'end preparation for Project Account Generation';
  ------------------------------------------------------------

  ------------------------------------------------------------------------
  l_debug_info := 'calling AP_WEB_DB_EXPLINE_PKG.GetExpDistAcctCursor';
  ------------------------------------------------------------------------
  IF (AP_WEB_DB_EXPLINE_PKG.GetExpDistAcctCursor(p_report_header_id, 
	ExpenseReportLinesCursor)) THEN

    ---------------------------------------------------------
    l_debug_info := 'Retrieve Payment Due From System Option';
    ---------------------------------------------------------
    l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

    IF (l_payment_due = C_CompanyPay) then
      ------------------------------------------------------------------------
      l_debug_info := 'calling AP_WEB_DB_EXPTEMPLATE_PKG.GetPersonalParamID';
      ------------------------------------------------------------------------
      IF (NOT AP_WEB_DB_EXPTEMPLATE_PKG.GetPersonalParamID(l_personalParameterId)) THEN
        FND_MESSAGE.SET_NAME('SQLAP','OIE_NO_PERSONAL_EXP_TYPE');
        AddToHeaderErrors(p_item_type,
                          p_item_key,
                          FND_MESSAGE.GET);
        l_header_error_occurred := true;
      END IF; /* GetPersonalParamID */

    END IF; /* C_CompanyPay */

    ------------------------------------------------------------------------
    l_debug_info := 'Calling AP_WEB_DB_AP_INT_PKG.GetRoundingErrorCCID';
    ------------------------------------------------------------------------
    IF (NOT AP_WEB_DB_AP_INT_PKG.GetRoundingErrorCCID(l_rounding_error_ccid))  THEN
      l_rounding_error_ccid   := NULL;
    END IF; /* GetRoundingErrorCCID */

    LOOP
      FETCH ExpenseReportLinesCursor INTO 
      	       l_dist_line_number,
      	       l_report_distribution_id,
               V_StartExpenseDate,
      	       V_Amount,
               V_ExpenseType,
               V_CreditCardTrxID,
      	       V_ProjectID,
      	       V_TaskID,
	       V_AwardID,
      	       V_ExpenditureItemDate,
      	       V_ExpenditureType,
      	       V_PAQuantity,
      	       V_ExpenditureOrganizationID,
      	       l_exp_type_parameter_id,
               V_AdjustmentReason,
               V_FlexConcactenated,
	       V_CategoryCode,
      	       V_LineAttributeCategory,
      	       V_LineAttribute1,   
      	       V_LineAttribute2,
      	       V_LineAttribute3,   
      	       V_LineAttribute4,
      	       V_LineAttribute5,   
      	       V_LineAttribute6,
      	       V_LineAttribute7,   
      	       V_LineAttribute8,
      	       V_LineAttribute9,   
      	       V_LineAttribute10,
      	       V_LineAttribute11,  
      	       V_LineAttribute12,
      	       V_LineAttribute13,  
      	       V_LineAttribute14,
      	       V_LineAttribute15,
	       l_line_cost_center,
               V_APValidationError,
	       V_ReportLineId;
    EXIT WHEN ExpenseReportLinesCursor%NOTFOUND;

    ------------------------------------------------------------------------
    l_debug_info := 'reset l_line_error_message';
    ------------------------------------------------------------------------
    l_line_error_message := '';
    l_add_to_line_error := false;

    ------------------------------------------------------------------------
    l_debug_info := 'set l_ccard_line_num or l_cash_line_num';
    ------------------------------------------------------------------------
    if (V_CreditCardTrxID is not null) then
      l_ccard_line_num := l_ccard_line_num + 1;
      l_line_num := l_ccard_line_num;
    else
      l_cash_line_num := l_cash_line_num + 1;
      l_line_num := l_cash_line_num;
    end if;

    ------------------------------------------------------------------------
    l_debug_info := 'begin Project Account Generation';
    ------------------------------------------------------------------------
    IF (V_IsSessionProjectEnabled = 'Y' AND V_ProjectID IS NOT NULL) THEN

      ------------------------------------------------------------------------
      l_debug_info := 'set l_is_projects_report := true';
      ------------------------------------------------------------------------
      l_is_projects_report := true;

      ------------------------------------------------------------------------
      l_debug_info := 'AP_WEB_ACCTG_PKG.BuildDistProjectAccount';
      ------------------------------------------------------------------------
      AP_WEB_ACCTG_PKG.BuildDistProjectAccount(
        p_report_header_id => p_report_header_id,
        p_report_line_id => V_ReportLineId,
        p_report_distribution_id => l_report_distribution_id,
        p_exp_type_parameter_id => l_exp_type_parameter_id,
        p_new_segments => l_dist_new_segments,
        p_new_ccid => l_exp_dist_ccid,
        p_return_error_message => l_return_error_message,
        p_return_status => l_return_status);

      if (l_return_status like '%ERROR%') then
        l_line_error_message := l_line_error_message || l_return_error_message || '<br>';
        l_add_to_line_error := true;
      end if;
	
      --------------------------------------------------------------
      l_debug_info:='Credit the Personal lines with a different ccid';
      --------------------------------------------------------------
      IF (l_payment_due = C_CompanyPay AND l_exp_type_parameter_id = l_personalParameterId) THEN

        SELECT card_program_id, transaction_date
        INTO   l_card_program_id, l_transaction_date
        FROM   ap_credit_card_trxns
        WHERE  trx_id = V_CreditCardTrxID;

        IF (NOT AP_WEB_DB_AP_INT_PKG.GetExpenseClearingCCID(p_ccid => l_exp_dist_ccid,
        	p_card_program_id => l_card_program_id,
        	p_employee_id     => l_employee_id, 
        	p_as_of_date      => l_transaction_date)) THEN
          l_exp_dist_ccid := NULL;
        END IF; /* GetExpenseClearingCCID */

        --------------------------------------------------------------
        l_debug_info:='Personal Expense Clearing CCID is NULL';
        --------------------------------------------------------------
        IF (l_exp_dist_ccid IS NULL) THEN
          l_line_error_message := l_line_error_message || 'Personal Expense Clearing CCID is NULL' || '<br>';
          l_add_to_line_error := true;
        END IF; /* l_exp_dist_ccid IS NULL */

      ELSIF (V_CategoryCode = C_ROUNDING) THEN

        --------------------------------------------
        l_debug_info := 'Rounding';
        --------------------------------------------
        l_exp_dist_ccid := l_rounding_error_ccid;
        IF (l_rounding_error_ccid IS NULL) THEN
          --------------------------------------------
          l_debug_info := 'Rounding Error CCID is NULL';
          --------------------------------------------
          FND_MESSAGE.SET_NAME('SQLAP','OIE_NO_ROUNDING_CCID');
          l_other_error_message := FND_MESSAGE.GET;
          AddToOtherErrors(p_item_type,
                              p_item_key,
                              l_concatenated_segments||': '||l_other_error_message);
	  l_other_error_occurred := true;
	END IF; /* l_rounding_error_ccid IS NULL */

      ELSE

        -- set the code combination for the line
        if (l_exp_dist_ccid is null OR l_exp_dist_ccid = -1) then
          l_line_error_message := l_line_error_message;
          l_add_to_line_error := true;
        end if; /* l_exp_dist_ccid is null */

      END IF; /* l_payment_due = C_CompanyPay AND l_exp_type_parameter_id = l_personalParameterId */

      if (l_exp_dist_ccid is null OR
          l_exp_dist_ccid = -1) then
          
         HandleInvalidDistCCID(p_report_header_id,
	                       l_report_distribution_id,
	                       l_payment_due,
	                       l_exp_type_parameter_id,
	                       l_personalParameterId,
	                       V_CategoryCode,
	                       l_default_emp_segments,
	                       l_dist_new_segments,
	                       V_ReportLineId,
	                       l_exp_dist_ccid,
                               l_chart_of_accounts_id);
      else
            /* Also update the segment values in the dist table to ensure the ccid
             and the segment values are in sync. */ 
    	    --------------------------------------------------------------
    	    l_debug_info:='Synch Account Segments with CCID'; 
    	    -- updateAccountValues calls AddDistributionLine if dist does not
    	    -- exist and then updates the ccid and segments based on l_exp_dist_ccid
    	    --------------------------------------------------------------
          AP_WEB_DB_EXPDIST_PKG.updateAccountValues (
                   p_report_header_id => p_report_header_id,
                   p_report_line_id => V_ReportLineId,
                   p_report_distribution_id => l_report_distribution_id,
                   p_ccid             => l_exp_dist_ccid);
                   
      end if; /* l_exp_dist_ccid is null */

      ------------------------------------------------------------------------
      l_debug_info := 'end Project Account Generation';
      ------------------------------------------------------------------------

    ELSE
      ------------------------------------------------------------------------
      l_debug_info := 'begin Non-Project Account Generation';
      ------------------------------------------------------------------------
      --------------------------------------------------------------
      l_debug_info:='Credit the Personal lines with a different ccid';
      --------------------------------------------------------------
      IF (l_payment_due = C_CompanyPay AND l_exp_type_parameter_id = l_personalParameterId) THEN

        SELECT card_program_id, transaction_date
        INTO   l_card_program_id, l_transaction_Date
        FROM   ap_credit_card_trxns
        WHERE  trx_id = V_CreditCardTrxID;

        IF (NOT AP_WEB_DB_AP_INT_PKG.GetExpenseClearingCCID(p_ccid => l_exp_dist_ccid,
        	p_card_program_id => l_card_program_id,
        	p_employee_id     => l_employee_id, 
        	p_as_of_date      => l_transaction_date)) THEN        
          l_exp_dist_ccid := NULL;
        END IF; /* GetExpenseClearingCCID */
 
    	--------------------------------------------------------------
    	l_debug_info:='Personal Expense Clearing CCID is NULL';
	--------------------------------------------------------------
  	IF (l_exp_dist_ccid IS NULL) THEN
          l_line_error_message := l_line_error_message || 'Personal Expense Clearing CCID is NULL' || '<br>';
          l_add_to_line_error := true;
	END IF; /* l_exp_dist_ccid IS NULL */

      ELSIF (V_CategoryCode = 'ROUNDING' ) THEN
        l_exp_dist_ccid := l_rounding_error_ccid;
        --------------------------------------------
        l_debug_info := 'Rounding Error CCID is NULL';
        --------------------------------------------
        IF ( l_rounding_error_ccid IS NULL) THEN
          FND_MESSAGE.SET_NAME('SQLAP','OIE_NO_ROUNDING_CCID');
          l_other_error_message := FND_MESSAGE.GET;
          AddToOtherErrors(p_item_type,
                              p_item_key,
                              l_concatenated_segments||': '||l_other_error_message);
	  l_other_error_occurred := true;

	END IF; /*l_rounding_error_ccid IS NULL*/

      ELSE 
        -- Removed code for 'LLA Enabled with Online Validation';
        -- i.e, Removed call to AP_WEB_DB_EXPDIST_PKG.UpdateDistCCID 
    	-- as there is no change in l_exp_dist_ccid 

        IF (l_report_distribution_id is not null) THEN -- Distribution Exist

          IF (NOT AP_WEB_DB_EXPDIST_PKG.foundCCID(l_report_distribution_id, l_exp_dist_ccid)) THEN

    	    --------------------------------------------------------------
    	    l_debug_info:='LLA Enabled without Online Validation';
    	    --------------------------------------------------------------
            --------------------------------------------------------------
            l_debug_info:='Get Distribution Segments';
            --------------------------------------------------------------
            AP_WEB_ACCTG_PKG.GetDistributionSegments(
                           p_chart_of_accounts_id => l_chart_of_accounts_id,
                           p_report_distribution_id => l_report_distribution_id,
                           p_segments => l_existing_segments);

            --------------------------------------------------------------
            l_debug_info:='Build Account';
            --------------------------------------------------------------
            AP_WEB_ACCTG_PKG.BuildAccount(
                           p_report_header_id => p_report_header_id,
                           p_report_line_id => V_ReportLineId,
                           p_employee_id => l_employee_id,
                           p_cost_center => l_cost_center,
                           p_line_cost_center => l_line_cost_center,
                           p_exp_type_parameter_id => l_exp_type_parameter_id,
                           p_segments => l_existing_segments,
                           p_ccid => null,
                           p_build_mode => AP_WEB_ACCTG_PKG.C_VALIDATE,
                           p_new_segments => l_dist_new_segments,
                           p_new_ccid => l_exp_dist_ccid,
                           p_return_error_message => l_return_error_message);

            if (l_return_error_message is not null) then
              l_line_error_message := l_line_error_message || l_return_error_message || ' ';
              l_add_to_line_error := true;
            end if;
            
          END IF; -- (Not AP_WEB_DB_EXPDIST_PKG.foundCCID) 'LLA Enabled without Online Validation';

        ELSE -- else of Distribution Exist

    	    --------------------------------------------------------------
    	    l_debug_info:='LLA Disabled';
    	    --------------------------------------------------------------
            l_existing_segments := null;
            l_new_segments := null;

            --------------------------------------------------------------
            l_debug_info:='Build Account';
            --------------------------------------------------------------
            AP_WEB_ACCTG_PKG.BuildAccount(
                           p_report_header_id => p_report_header_id,
                           p_report_line_id => V_ReportLineId,
                           p_employee_id => l_employee_id,
                           p_cost_center => l_cost_center,
                           p_line_cost_center => l_line_cost_center,
                           p_exp_type_parameter_id => l_exp_type_parameter_id,
                           p_segments => l_existing_segments,
                           p_ccid => null,
                           p_build_mode => AP_WEB_ACCTG_PKG.C_DEFAULT_VALIDATE,
                           p_new_segments => l_dist_new_segments,
                           p_new_ccid => l_exp_dist_ccid,
                           p_return_error_message => l_return_error_message);

            if (l_return_error_message is not null) then
              l_line_error_message := l_line_error_message || l_return_error_message || ' ';
              l_add_to_line_error := true;
            end if;

        END IF; /* foundDistributions */

      END IF; /* l_payment_due = C_CompanyPay AND l_exp_type_parameter_id = l_personalParameterId */


      if (l_exp_dist_ccid is null OR
          l_exp_dist_ccid = -1) then

         HandleInvalidDistCCID(p_report_header_id,
	                       l_report_distribution_id,
	                       l_payment_due,
	                       l_exp_type_parameter_id,
	                       l_personalParameterId,
	                       V_CategoryCode,
	                       l_default_emp_segments,
	                       l_dist_new_segments,
	                       V_ReportLineId,
	                       l_exp_dist_ccid,
                               l_chart_of_accounts_id);
                               
          l_line_error_message := l_line_error_message;
          l_add_to_line_error := true;

          IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_OIEJ_Version) THEN
            WF_ENGINE.SetItemAttrText(p_item_type,
                                      p_item_key,
                                      'EXP_ALLOCATION_ERRORS',
                                      'Y');
          END IF;

      else

          /* Also update the segment values in the dist table to ensure the ccid
             and the segment values are in sync. */ 
    	    --------------------------------------------------------------
    	    l_debug_info:='Synch Account Segments with CCID'; 
    	    -- updateAccountValues calls AddDistributionLine if dist does not
    	    -- exist and then updates the ccid and segments based on l_exp_dist_ccid
    	    --------------------------------------------------------------
          AP_WEB_DB_EXPDIST_PKG.updateAccountValues (
                   p_report_header_id => p_report_header_id,
                   p_report_line_id => V_ReportLineId,
                   p_report_distribution_id => l_report_distribution_id,
                   p_ccid             => l_exp_dist_ccid);
                   
      end if; /* l_exp_dist_ccid is null */

      ------------------------------------------------------------------------
      l_debug_info := 'end Non-Project Account Generation';
      ------------------------------------------------------------------------

    END IF; /* end Project and non-Project Account Generation */

    ------------------------------------------------------------------------
    l_debug_info := 'check to see if line error occurred';
    ------------------------------------------------------------------------
    if (l_add_to_line_error) then

      AP_WEB_DB_EXPLINE_PKG.UpdateAPValidationError(
                                       p_report_header_id => p_report_header_id,
                                       p_dist_line_number => l_dist_line_number,
                                       p_ap_validation_error => l_line_error_message);

      l_line_error_occurred := true;

    end if;

   END LOOP; /* ExpenseReportLinesCursor */

  END IF; /* GetExpDistAcctCursor */  

  if ExpenseReportLinesCursor%isopen then
     CLOSE ExpenseReportLinesCursor;
  end if;
    
  ----------------------------------------------------------------
  l_debug_info := 'Set Is Projects Expense Report?';
  -----------------------------------------------------------------
  if (l_is_projects_report) then

    SELECT fndl.meaning
    INTO l_yes
    FROM FND_LOOKUPS fndl
    WHERE fndl.LOOKUP_TYPE = C_YES_NO
    AND   fndl.LOOKUP_CODE = C_Y;

    WF_ENGINE.SetItemAttrText(p_item_type,
                              p_item_key,
                              'IS_PROJECTS_REPORT',
                              l_yes); 
  else
    SELECT fndl.meaning
    INTO l_no
    FROM FND_LOOKUPS fndl
    WHERE fndl.LOOKUP_TYPE = C_YES_NO
    AND   fndl.LOOKUP_CODE = C_N;

    WF_ENGINE.SetItemAttrText(p_item_type,
                            p_item_key,
                            'IS_PROJECTS_REPORT',
                            l_no); 
  end if; /* l_is_projects_report */

  ------------------------------------------------
  l_debug_info := 'Retrieve function currency';
  ------------------------------------------------
  IF (NOT AP_WEB_DB_AP_INT_PKG.GetBaseCurrInfo(l_sys_base_currency_code)) THEN
     l_sys_base_currency_code := NULL;
  END IF; /* GetBaseCurrInfo */

  ------------------------------------------------
  l_debug_info := 'Determine if EMU FIXED rate: l_sys_base_currency_code = '||l_sys_base_currency_code||' l_default_currency_code = '||l_default_currency_code;
  ------------------------------------------------
  IF (gl_currency_api.is_fixed_rate(l_sys_base_currency_code,
                                    l_default_currency_code,
                                    sysdate) = 'Y') THEN

     IF (l_sys_base_currency_code <> l_default_currency_code) THEN  --euro, bug 1289501
         l_sys_default_xrate_type := 'EMU FIXED';
     END IF; /* l_sys_base_currency_code <> l_default_currency_code */

  END IF; /* is_fixed_rate */

  IF (NOT AP_WEB_DB_AP_INT_PKG.GetBaseCurrInfo(l_base_currency_code)) THEN
	l_base_currency_code := null;
  END IF; /* GetBaseCurrInfo */

  ----------------------------------------------
  l_debug_info := 'Check for invalid Rate Type';
  ----------------------------------------------
  IF ((l_sys_default_xrate_type = 'User') AND
      (l_sys_make_rate_mandatory = 'Y')) THEN

    IF (NOT AP_WEB_DB_EXPRPT_PKG.SetDefaultExchRateType(p_report_header_id, l_sys_default_xrate_type)) THEN
	NULL;
    END IF; /* SetDefaultExchRateType */

    FND_MESSAGE.SET_NAME('SQLAP','AP_WEB_USER_EXCH_RATE_REQD');
    l_return_error_message := FND_MESSAGE.GET;
    AddToHeaderErrors(p_item_type,
                      p_item_key,
                      l_return_error_message);
    l_header_error_occurred := true;

  ELSE
    --Bug 2974741: Replace sysdate with l_week_end_date to get correct rate.
    l_default_exchange_rate := AP_UTILITIES_PKG.get_exchange_rate(l_default_currency_code, l_base_currency_code, l_sys_default_xrate_type, l_week_end_date, 'DoAPValidation');
  END IF; /* Check for invalid Rate Type */


  --------------------------------------------------------------------
  l_debug_info := 'Check to see if error occurred before proceeding';
  --------------------------------------------------------------------
  if (l_header_error_occurred OR l_line_error_occurred OR l_other_error_occurred) then
    Return;
  end if; /* l_header_error_occurred OR l_line_error_occurred */

  --------------------------------------------------------------------
  l_debug_info := 'Calculate available prepayments for this employee';
  --------------------------------------------------------------------
  IF (NOT AP_WEB_DB_AP_INT_PKG.GetAvailablePrepayments(l_employee_id,
			l_default_currency_code,
			l_available_prepays)) THEN
	l_available_prepays := NULL;
  END IF; /* GetAvailablePrepayments */

  ------------------------------------------------
  l_debug_info := 'Retrieve values from vendors';
  ------------------------------------------------
  IF (NOT AP_WEB_DB_AP_INT_PKG.GetVendorAWTSetupForExpRpt(p_report_header_id,
                l_ven_allow_awt_flag,
                l_ven_awt_group_id)) THEN

      l_ven_allow_awt_flag := NULL;
      l_ven_awt_group_id := NULL;

  END IF; /* GetVendorAWTSetupForExpRpt */

  ---------------------------------------------------
  l_debug_info := 'Update ap_expense_report_headers';
  ---------------------------------------------------
  IF (NOT AP_WEB_DB_EXPRPT_PKG.SetExpenseHeaderInfo(p_report_header_id,
				l_exp_check_address_flag,
				'WebExpense',
				'', -- clear out potentially-rejected/returned status 
			       	l_sys_apply_advances_default,
			       	l_available_prepays,
			       	l_sys_allow_awt_flag, 
			       	l_ven_allow_awt_flag,
			       	l_ven_awt_group_id,
			       	l_sys_default_xrate_type,
			       	l_week_end_date,
			       	l_default_exchange_rate,
			       	l_employee_ccid ) ) THEN
	NULL;
  END IF; /* SetExpenseHeaderInfo */

  ---------------------------------------------------
  l_debug_info := 'Update ap_expense_report_lines';
  ---------------------------------------------------
  -- 7/24: insertion of receipt_required_flag is moved to the submit package.
  IF (NOT AP_WEB_DB_EXPLINE_PKG.SetAWTGroupIDAndJustif(p_report_header_id,
					l_sys_allow_awt_flag,
					l_ven_allow_awt_flag,
					l_ven_awt_group_id)) THEN
	NULL;
  END IF; /* SetAWTGroupIDAndJustif */

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end DoAPValidation');

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'DoAPValidation');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;
END DoAPValidation;

-------------------------------------
PROCEDURE OpenExp(p1    varchar2,
		  p2	varchar2,
		  p11	varchar2) IS
-------------------------------------
l_param                 varchar2(240);
c_rowid                 varchar2(18);
l_session_id            number;
l_icx_application_id    AK_FLOW_REGION_RELATIONS.flow_application_id%TYPE := AP_WEB_INFRASTRUCTURE_PKG.GetICXApplicationId;
l_url			ICX_PARAMETERS.HOME_URL%TYPE := null;

BEGIN
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start OpenExp');

  IF AP_WEB_INFRASTRUCTURE_PKG.ValidateSession(NULL, false, false) THEN

    l_session_id := icx_sec.getID(icx_sec.PV_SESSION_ID);
    AP_WEB_INFRASTRUCTURE_PKG.ICXSetOrgContext(l_session_id, p11);

-- The following information needs to be set up through ON forms, on particular
-- Page rlations.

  IF (NOT AP_WEB_DB_UI_SETUP_PKG.GetAKPageRowID('ICX_AP_EXP_RPT_NEW_D',
					     'ICX_AP_EXP_RPT_D',
					     'ICX_AP_EXP_LINES_D',
					     'ICX_INQUIRIES',
					     l_icx_application_id,
					     c_rowid)) THEN
	NULL;
  END IF;                                          

  l_param := icx_on_utilities.buildOracleONstring
                (p_rowid => c_rowid,
                 p_primary_key => 'ICX_AP_EXP_RPT_PK',
                 p1 => icx_call.decrypt(p1),
		 p2 => icx_call.decrypt(p2));


  IF (l_session_id IS NULL) THEN
      OracleOn.IC(Y=>icx_call.encrypt2(l_param,-999));
  ELSE
      OracleOn.IC(Y=>icx_call.encrypt2(l_param,l_session_id));
  END IF;

  ELSE
    -- for bug 1661113
    select HOME_URL
    into   l_url
    from   ICX_PARAMETERS;

    FND_MESSAGE.SET_NAME('SQLAP', 'AP_WEB_NOTIF_LOGON_ERROR');
    FND_MESSAGE.SET_TOKEN('URL', l_url);
    
    htp.p('<HTML><BODY>' || FND_MESSAGE.GET || '</BODY></HTML>');

  END IF;
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end OpenExp');

EXCEPTION
  WHEN OTHERS THEN
   htp.p(SQLERRM);
END OpenExp;

------------------------------------------------------------------------------
PROCEDURE BuildManagerApprvlMessage(p_item_type	IN VARCHAR2,
				    p_item_key	IN VARCHAR2,
				    p_actid		IN NUMBER,
		       		    p_funmode		IN VARCHAR2,
		       		    p_result	 OUT NOCOPY VARCHAR2) IS
------------------------------------------------------------------------------
  l_report_header_id		NUMBER;
  l_debug_info			VARCHAR2(1000);
  l_receipts_missing_flag	VARCHAR2(1) := 'N';
  l_warning_msg			VARCHAR2(2000);
  l_violation		        VARCHAR2(1);

  /* jrautiai ADJ Fix Start */  
  l_shortpaid_flag              VARCHAR2(1) := 'N';
  /* jrautiai ADJ Fix End */
  
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start BuildManagerApprvlMessage');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						     'EXPENSE_REPORT_ID');

--chiho:1352284:
    ----------------------------------------------------------------
    l_debug_info := 'Get the receipts missing flag';
    ----------------------------------------------------------------
--chiho:1369557:
    IF ( AP_WEB_DB_EXPLINE_PKG.GetReceiptsMissingFlag(
					l_report_header_id,
					l_receipts_missing_flag) ) THEN

	IF ( l_receipts_missing_flag = 'Y' ) THEN
	
          /* jrautiai ADJ Fix Start 
           * We need to show a message indicating that this is a new report generated due to
           * employee requesting approval of shortpaid report due to missing receipts.
           * We are assuming here that the only case logic rebuilds the manager approval
           * notification while the report was created from another report is due to 
           * missing receipts.
           */
                                                           
          IF AP_WEB_DB_EXPLINE_PKG.GetShortpaidFlag(l_report_header_id, l_shortpaid_flag) THEN
            IF (l_shortpaid_flag = 'Y' ) THEN
              fnd_message.set_name('SQLAP', 'OIE_WF_APPROVAL_POLICY_NOTE');
              l_warning_msg := FND_MESSAGE.Get;
      
              WF_ENGINE.SetItemAttrText(
	  	      		      p_item_type,
	   		              p_item_key,
			              'VIOLATION_NOTE',
			              WF_ENGINE.GetItemAttrText(p_item_type,
                                                                p_item_key,
                                                                'VIOLATION_NOTE')||' '|| l_warning_msg );
            END IF;
          END IF;
          /* jrautiai ADJ Fix end */          
          
	  fnd_message.set_name('SQLAP', 'AP_WEB_EXP_APRVL_RECPTS_MISSIN');
      	  l_warning_msg := FND_MESSAGE.Get;

      	  WF_ENGINE.SetItemAttrText(
				p_item_type,
	 		        p_item_key,
			        'VIOLATION_NOTE',
			        WF_ENGINE.GetItemAttrText(p_item_type,
                                                          p_item_key,
                                                          'VIOLATION_NOTE')||' '||l_warning_msg );

	END IF;
    END IF;
        
    IF (AP_WEB_DB_EXPLINE_PKG.AnyPolicyViolation(l_report_header_id)) THEN
		fnd_message.set_name('SQLAP', 'AP_WEB_EXP_APRVL_RULES_VIOLATE');
      		l_warning_msg := FND_MESSAGE.Get;

      		WF_ENGINE.SetItemAttrText(
				p_item_type,
	 		        p_item_key,
			        'VIOLATION_NOTE',
			        WF_ENGINE.GetItemAttrText(p_item_type,
                                                          p_item_key,
                                                          'VIOLATION_NOTE')||' '||l_warning_msg );

    END IF;
   
  
  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end BuildManagerApprvlMessage');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'BuildManagerApprvlMessage', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END BuildManagerApprvlMessage;

----------------------------------------------------------------------
PROCEDURE ManagerApproved(p_item_type		IN VARCHAR2,
		   	  p_item_key		IN VARCHAR2,
		   	  p_actid		IN NUMBER,
		   	  p_funmode		IN VARCHAR2,
		   	  p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ManagerApproved');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');


    ----------------------------------------------------------------
    l_debug_info := 'Update the Expense Report as Manager Approved';
    ----------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.SetWkflApprvdFlag(l_report_header_id)) THEN  
	NULL;
    END IF;

    ----------------------------------------------------------
    l_debug_info := 'Update Receipts Status to Missing if Pending Resolution';
    ----------------------------------------------------------
    update ap_expense_report_headers
    set    receipts_status = 'MISSING'
    where  report_header_id = l_report_header_id
    and    receipts_status = 'RESOLUTN';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ManagerApproved');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ManagerApproved', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END ManagerApproved;

----------------------------------------------------------------------
PROCEDURE CheckSumMissingReceipts(p_item_type    IN VARCHAR2,
				  p_item_key     IN VARCHAR2,
				  p_actid	 IN NUMBER,
				  p_funmode	 IN VARCHAR2,
				  p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_sum_limit			NUMBER;
  l_sum_violations              NUMBER;
  l_sum_missing_receipts	NUMBER;
  l_currency			VARCHAR2(50);
  l_debug_info			VARCHAR2(200);
  l_sum_missing_display_total   VARCHAR2(50);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CheckSumMissingReceipts');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    ----------------------------------------------------
    l_debug_info := 'Retrieve Currency Item Attribute';
    ----------------------------------------------------
    l_currency := WF_ENGINE.GetItemAttrText(p_item_type,
					    p_item_key,
					    'CURRENCY');

    ---------------------------------------------------------------------------
    l_debug_info := 'Retrieve AP Receipt Minnsing Amount Limit Item Attribute';
    ---------------------------------------------------------------------------
    l_sum_limit := WF_ENGINE.GetActivityAttrNumber(p_item_type,
					           p_item_key,
						   p_actid,
					       'SUM_MISSING_RECEIPTS_LIMIT');

    -------------------------------------------------------------------------
    l_debug_info := 'Calculate Total Receipt Missing Amt for Expense Report';
    -------------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetReceiptMissingTotal(l_report_header_id,
					l_sum_missing_receipts)) THEN
         l_sum_missing_receipts := 0;
    END IF;

    -------------------------------------------------------------------------
    l_debug_info := 'Calculate Total Receipt Violations excluding missing receipt total for Expense Report';
    -------------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetReceiptViolationsTotal(l_report_header_id,
                                        l_sum_violations)) THEN
         l_sum_violations := 0;
    END IF;

    IF (nvl(l_sum_violations, 0) > 0) THEN
      WF_ENGINE.SetItemAttrText(p_item_type,
                                  p_item_key,
                                  'VIOLATIONS_TOTAL',
                                  to_char(l_sum_violations + nvl(l_sum_missing_receipts,0), FND_CURRENCY.Get_Format_Mask(l_currency,22)) || ' ' || l_currency);
    END IF;


    -----------------------------------------------------------------
    l_debug_info := 'If Report Amount is Less than AP Limit Return N
                     otherwise return Y';
    -----------------------------------------------------------------
    IF (nvl(l_sum_missing_receipts,0) <= nvl(l_sum_limit,0)) THEN

      p_result := 'COMPLETE:N';
    ELSE
      l_sum_missing_display_total := to_char(l_sum_missing_receipts, FND_CURRENCY.Get_Format_Mask(l_currency,22)) || ' ' || l_currency;

      WF_ENGINE.SetItemAttrText(p_item_type,
                                p_item_key,
                                'MISSING_RECEIPT_TOTAL',
                                l_sum_missing_display_total);

      FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_VERIFY_MISSING_NOTE');
      FND_MESSAGE.SET_TOKEN('MISSING_TOTAL',l_sum_missing_display_total);
      
      WF_ENGINE.SetItemAttrText(p_item_type,
                              	p_item_key,
                              	'VERIFY_NOTE',
                              	FND_MESSAGE.GET);



      p_result := 'COMPLETE:Y';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CheckSumMissingReceipts');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CheckSumMissingReceipts', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END CheckSumMissingReceipts;

----------------------------------------------------------------------
PROCEDURE AnyReceiptRequired(p_item_type	IN VARCHAR2,
		       	     p_item_key		IN VARCHAR2,
		       	     p_actid		IN NUMBER,
		       	     p_funmode		IN VARCHAR2,
		       	     p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_include_missing_receipts    VARCHAR2(1);
  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_num_req_receipts		NUMBER;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AnyReceiptRequired');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');



    ------------------------------------------------------------------
    l_debug_info := 'Calculate Number of Lines with Receipt Required';
    ------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumReceiptRequiredLines(
				l_report_header_id, l_num_req_receipts)) THEN
	l_num_req_receipts := 0;
    END IF;

    IF (l_num_req_receipts > 0) THEN
      ------------------------------------------------------------
      l_debug_info := 'Return Y if any line has receipt required';
      ------------------------------------------------------------
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AnyReceiptRequired');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AnyReceiptRequired', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AnyReceiptRequired;

----------------------------------------------------------------------
PROCEDURE AnyJustificationRequired(p_item_type	IN VARCHAR2,
				     p_item_key		IN VARCHAR2,
		       	     	     p_actid		IN NUMBER,
		       	     	     p_funmode		IN VARCHAR2,
		       	     	     p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_num_req_receipt		NUMBER;
  l_violation		        VARCHAR2(1);
  l_debug_info			VARCHAR2(200);
  l_mess                        Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AnyJustificationRequired');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');


    ------------------------------------------------------------------------
    l_debug_info := 'Calculate Number of Lines With Justification Required';
    ------------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumJustReqdLines(l_report_header_id,
						l_num_req_receipt)) THEN
	l_num_req_receipt := 0;
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Construction the Note';
    ------------------------------------------------------------
    IF (l_num_req_receipt > 0 ) THEN
       FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_JUST_REQUIRED_MSG');
    END IF;

    IF (AP_WEB_DB_EXPLINE_PKG.AnyPolicyViolation(l_report_header_id)) THEN
       FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_VIOLATION_MSG');
    END IF;

    IF (l_num_req_receipt > 0 ) AND  (l_violation = 'Y' ) THEN
       FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_JUST_AND_VIOLATION_MSG');
    END IF;

    
    l_mess := FND_MESSAGE.GET;
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'REVIEW_NOTE',
			      l_mess);

    ------------------------------------------------------------
    l_debug_info := 'Construction the Instruction';
    ------------------------------------------------------------
    IF (l_num_req_receipt > 0 OR l_violation = 'Y' ) THEN

     FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_REVIEW_INSTRUCTION');
     l_mess := FND_MESSAGE.GET;

      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'INSTRUCTION',
			        l_mess);


      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AnyJustificationRequired');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AnyJustificationRequired', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AnyJustificationRequired;


----------------------------------------------------------------------
PROCEDURE CreditLinesOnly(p_item_type		IN VARCHAR2,
		       	  p_item_key		IN VARCHAR2,
		       	  p_actid		IN NUMBER,
		       	  p_funmode		IN VARCHAR2,
		       	  p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		NUMBER;
  l_debug_info			VARCHAR2(200);
  l_new_expense_total		NUMBER;
BEGIN 

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CreditLinesOnly');

  IF (p_funmode = 'RUN') THEN
    ----------------------------------------------------------------
    l_debug_info := 'Retrieve New Expense Total.';
    ----------------------------------------------------------------
    l_new_expense_total := WF_ENGINE.GetItemAttrNumber(p_item_type,
						p_item_key,
						'POS_NEW_EXPENSE_TOTAL');

    IF (l_new_expense_total = 0) THEN
	p_result := 'COMPLETE:Y';
    ELSE
	p_result := 'COMPLETE:N';
    END IF;


  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CreditLinesOnly');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CreditLinesOnly',
		    p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;

END CreditLinesOnly;




/* This function is used to check if the current process is of the 'old' workflow
   which doesn't have the BLOCK activity after the AP_REVIEW_COMPLETE. This code
   should be removed after all 10.7 and 11.0.2 customers have upgraded to 11 or 11i.
*/
FUNCTION isOldProcess(p_actid	  IN NUMBER,
                      p_item_key  IN VARCHAR2) return boolean
IS
  l_resultType    WF_ACTIVITIES.result_type%TYPE;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start isOldProcess');

  select wa.result_type
  into l_resultType
  from WF_PROCESS_ACTIVITIES WPA, WF_ACTIVITIES WA, wf_items wi
  where WPA.INSTANCE_ID = p_actid
    and WPA.ACTIVITY_ITEM_TYPE = WA.ITEM_TYPE
    and WPA.ACTIVITY_NAME = WA.NAME
    and wi.begin_date >= WA.BEGIN_DATE
    and wi.begin_date < nvl(WA.END_DATE, wi.begin_date+1)
    and wi.item_type = wa.item_type
    and wi.item_key  = p_item_key;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end isOldProcess');

  --In the 'old' expense report workflow, AP_REVIEW_COMPLETE activity doesn't have result.
  if (l_resultType = '*') then
      return TRUE;
  else
      return FALSE;
  END IF;
END isOldProcess;


----------------------------------------------------------------------
PROCEDURE OldAPReviewComplete(p_item_type		IN VARCHAR2,
		       	   p_item_key		IN VARCHAR2,
		       	   p_actid		IN NUMBER,
		       	   p_funmode		IN VARCHAR2,
		       	   p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		NUMBER;
  l_ap_review_status		VARCHAR2(1);
  l_debug_info			VARCHAR2(200);
  l_wakeup_time			DATE;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start OldAPReviewComplete');

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						    p_item_key,
						    'EXPENSE_REPORT_ID');
 
  l_wakeup_time :=  (Wf_Engine.GetActivityAttrNumber(p_item_type, p_item_key, 
                     p_actid, 'TIME_INTERVAL_BETWEEN_CHECKS')/24) + sysdate;

  ----------------------------------
  l_debug_info := 'Set Org Context';
  ----------------------------------
  AP_WEB_UTILITIES_PKG.ExpenseSetOrgContext(l_report_header_id);

  -------------------------------------------------
  l_debug_info := 'Retrieve The AP Reviewed Flag';
  -------------------------------------------------
  SELECT nvl(workflow_approved_flag, 'N')
  INTO   l_ap_review_status
  FROM   ap_expense_report_headers
  WHERE  report_header_id = l_report_header_id;

  ------------------------------------------------------------------
  l_debug_info := 'Check flag to determine if AP Review Complete and
                   return Y if so, otherwise N';
  ------------------------------------------------------------------
  IF (l_ap_review_status = 'Y') THEN
    p_result := wf_engine.eng_null;
  ELSE   
    -- Set status of activity to deferred with begin_date set to wakeup_date.
    -- For Workflow 1.0 we would call:
    --   Wf_Item_Activity_Status.Update_Status(p_item_type, p_item_key, 
    --   p_actid,'DEFERRED', 'WAITING', l_wakeup_time, null);
    -- For Workflow 2.0 (update_status nolonger exists, so we would need to
    -- call create_status whose parameters changed from 1.0:
    --   Wf_Item_Activity_Status.Update_Status(p_item_type, p_item_key, 
    --   p_actid,'DEFERRED', 'WAITING', l_wakeup_time, null);
    -- Since neither call is compatible for both versions and there's no
    -- api to determine which version of workflow is installed, we needed
    -- to call the update statement directly.
    -- In the future (after Workflow 2.0 production), the Workflow team  will
    -- provide a new interface that will be compatible for both, like us
    -- returning a result of 'DEFERED:l_wakeup_time', and they will take care
    -- of running the sql statement. 

    UPDATE WF_ITEM_ACTIVITY_STATUSES
    SET    begin_date = l_wakeup_time
    WHERE  item_type = p_item_type
    AND    item_key = p_item_key
    AND    process_activity = p_actid;

    p_result := wf_engine.eng_deferred;
  END IF;


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end OldAPReviewComplete');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'OldAPReviewComplete', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END OldAPReviewComplete;


----------------------------------------------------------------------
PROCEDURE APReviewComplete(p_item_type		IN VARCHAR2,
		       	   p_item_key		IN VARCHAR2,
		       	   p_actid		IN NUMBER,
		       	   p_funmode		IN VARCHAR2,
		       	   p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_ap_review_status		AP_WEB_DB_EXPRPT_PKG.expHdr_wkflApprvdFlag;
  l_debug_info			VARCHAR2(200);

  l_WorkflowRec			AP_WEB_DB_EXPRPT_PKG.ExpWorkflowRec;
  C_WF_Version	           NUMBER      := 0;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start APReviewComplete');

  -- Do nothing in cancel mode
  IF (p_funmode = wf_engine.eng_cancel) THEN
    p_result := wf_engine.eng_null;
    return;
  end if;


  ------------------------------------------------------------
  l_debug_info := 'Check for old workflow';
  ------------------------------------------------------------
  -- Bug 1576769: Should remove this check when there is no 10.7 and 11.0.2 users
  IF isOldProcess(p_actid, p_item_key) THEN
          OldAPReviewComplete(p_item_type,
		       	      p_item_key,
		       	      p_actid,
		       	      p_funmode,
		       	      p_result);
         return;
  END IF;

  -----------------------------------------------------
  l_debug_info := 'Get Workflow Version Number';
  -----------------------------------------------------
  C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(p_item_type, p_item_key);

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						    p_item_key,
						    'EXPENSE_REPORT_ID');
   

  -------------------------------------------------
  l_debug_info := 'Retrieve The AP Reviewed Flag';
  -------------------------------------------------
  IF (AP_WEB_DB_EXPRPT_PKG.GetExpWorkflowInfo(l_report_header_id,
						l_WorkflowRec)) THEN
      l_ap_review_status := nvl(l_WorkflowRec.workflow_flag, 'N');
  END IF;

  ------------------------------------------------------------------
  l_debug_info := 'Check flag to determine if AP Review Complete and
                   return Y if so, otherwise N';
  ------------------------------------------------------------------
  IF (l_ap_review_status = 'Y' or
      l_ap_review_status = AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_REJECTED or -- already AP rejected
      l_ap_review_status = AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_REQUEST) THEN -- already AP requests more info
    -- p_result := wf_engine.eng_null;
    -- dtong changed p_result for bug # 839208
    p_result := 'COMPLETE:Y'; 
  ELSE   
    --bug 7449880: check the version and update expense_status_code 
    --for reports submitted prior to oie.g, in later releases its updated in 
    --SetStatusApproverAndDate which is just prior to AP_VERIFY_BLOCK, 

    IF (C_WF_Version < AP_WEB_EXPENSE_WF.C_OIEH_Version) THEN
       -------------------------------------------------------------------
       l_debug_info := 'Set Expense Status Code';
       -------------------------------------------------------------------
       UPDATE ap_expense_report_headers_all
       SET expense_status_code = 'MGRAPPR'
       WHERE report_header_id = l_report_header_id;
    END IF;   

    -- Set status of activity to deferred with begin_date set to wakeup_date.
    -- For Workflow 1.0 we would call:
    --   Wf_Item_Activity_Status.Update_Status(p_item_type, p_item_key, 
    --   p_actid,'DEFERRED', 'WAITING', l_wakeup_time, null);
    -- For Workflow 2.0 (update_status nolonger exists, so we would need to
    -- call create_status whose parameters changed from 1.0:
    --   Wf_Item_Activity_Status.Update_Status(p_item_type, p_item_key, 
    --   p_actid,'DEFERRED', 'WAITING', l_wakeup_time, null);
    -- Since neither call is compatible for both versions and there's no
    -- api to determine which version of workflow is installed, we needed
    -- to call the update statement directly.
    -- In the future (after Workflow 2.0 production), the Workflow team  will
    -- provide a new interface that will be compatible for both, like us
    -- returning a result of 'DEFERED:l_wakeup_time', and they will take care
    -- of running the sql statement. 
   /*
    UPDATE WF_ITEM_ACTIVITY_STATUSES
    SET    begin_date = l_wakeup_time
    WHERE  item_type = p_item_type
    AND    item_key = p_item_key
    AND    process_activity = p_actid;

    p_result := wf_engine.eng_deferred;
   */
    p_result :='COMPLETE:N';
  END IF;


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end APReviewComplete');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'APReviewComplete', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END APReviewComplete;


----------------------------------------------------------------------
PROCEDURE AnyAPAdjustments(p_item_type		IN VARCHAR2,
		       	   p_item_key		IN VARCHAR2,
		       	   p_actid		IN NUMBER,
		       	   p_funmode		IN VARCHAR2,
		       	   p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_orig_expe_report_amt	NUMBER;
  l_exp_report_amount		AP_WEB_DB_EXPRPT_PKG.expHdr_total;
  l_orig_exp_report_amt		NUMBER;
  l_expense_type		AP_WEB_DB_EXPTEMPLATE_PKG.expTempl_webFriendlyPrompt;
  l_amount			AP_WEB_DB_EXPLINE_PKG.expLines_amount;
  l_adjustment_reason		AP_WEB_DB_EXPLINE_PKG.expLines_adjReason;

  l_currency			VARCHAR2(50);
  l_adjustment_line		VARCHAR2(2000);
  l_adj_info_body		VARCHAR2(2000);
  l_debug_info			VARCHAR2(200);
  l_num_lines			INTEGER := 0;
  i				INTEGER;
  j				INTEGER;
  l_payment_due			VARCHAR2(10) := C_IndividualPay;
  l_total		        NUMBER := 0;
  l_ccard_amt			AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueCCardCompany;
  l_emp_amt			AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueEmployee;
  C_CreditLineVersion           CONSTANT NUMBER := 1;
  C_WF_Version			NUMBER          := 0;

  /* jrautiai ADJ Fix Start */
  AdjustmentsCursor 		AP_WEB_DB_EXPLINE_PKG.AdjustmentCursorType;
  adjustment_rec AP_WEB_DB_EXPLINE_PKG.AdjustmentRecordType;
  
  l_mess                  Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;
  l_crd_card_count        NUMBER := 0;
  
  l_no_receipts_ccard_amt NUMBER := 0;
  l_no_receipts_emp_amt   NUMBER := 0;
  l_policy_ccard_amt      NUMBER := 0;
  l_policy_emp_amt        NUMBER := 0;
  l_policy_shortpay_total NUMBER := 0;
  /* jrautiai ADJ Fix End */
  
  l_ExpRec			AP_WEB_DB_EXPRPT_PKG.ExpInfoRec;
  l_reimb_currency              ap_expense_report_headers_all.payment_currency_code%type;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AnyAPAdjustments');

  IF (p_funmode = 'RUN') THEN


    -----------------------------------------------------
    l_debug_info := 'Get Workflow Version Number 2';
    -----------------------------------------------------
    C_WF_Version := GetFlowVersion(p_item_type, p_item_key);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Currency Item Attribute';
    ------------------------------------------------------------
    l_currency := WF_ENGINE.GetItemAttrText(p_item_type,
					    p_item_key,
					    'CURRENCY');

    -------------------------------------------------------
    l_debug_info := 'Retrieve Orignal Expense Report Total';
    -------------------------------------------------------
    l_orig_exp_report_amt := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      	 p_item_key,
						      	 'TOTAL');

    ----------------------------------------------------
    l_debug_info := 'Retrieve Currency Item Attribute';
    ----------------------------------------------------
    l_reimb_currency := WF_ENGINE.GetItemAttrText(p_item_type,
                                                  p_item_key,
                                                  'CURRENCY');

    /* jrautiai ADJ Fix Start */						      	 
    ----------------------------------------------------------------
    l_debug_info := 'Set #FROM_ROLE to AP';
    ----------------------------------------------------------------
    SetFromRoleAP(p_item_type, p_item_key, p_actid, p_funmode, p_result);
    
    ---------------------------------------------------------
    l_debug_info := 'Retrieve Payment Due From';
    ---------------------------------------------------------
    l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumCCLinesIncluded(l_report_header_id,
    					l_crd_card_count)) THEN
	l_crd_card_count := 0;
    END IF;

    IF l_payment_due = C_BothPay AND nvl(l_crd_card_count,0) > 0 THEN
      FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_ADJ_REIMBURSEMENT_INST2');
      l_mess := FND_MESSAGE.GET;
    ELSE
      FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_ADJ_REIMBURSEMENT_INST1');
      l_mess := FND_MESSAGE.GET;
    END IF;
    
    WF_ENGINE.SetItemAttrText(p_item_type,
                              p_item_key,
                              'INSTRUCTION',
                              l_mess);
                              	
    FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_ADJUSTMENT_NOTE');
    l_mess := FND_MESSAGE.GET;

    WF_ENGINE.SetItemAttrText(p_item_type,
                              	p_item_key,
                              	'WF_NOTE',
                              	l_mess);                              	
    /* jrautiai ADJ Fix End */    

    --------------------------------------------------------
    l_debug_info := 'Retrieve Current Expense Report Total';
    --------------------------------------------------------
    IF (AP_WEB_DB_EXPRPT_PKG.GetReportInfo(l_report_header_id, l_ExpRec)) THEN
        l_exp_report_amount := l_ExpRec.total;
    ELSE
	l_exp_report_amount := 0;
    END IF;

    --------------------------------------------------------------------------
    l_debug_info := 'If Original Total and Current Total Different Then
                    Adjustment was made, return Y and retrieve adjusted lines';
    --------------------------------------------------------------------------
    -- bug 3404699:round to reimbursment currency precision
    IF (AP_UTILITIES_PKG.Ap_Round_Currency(l_orig_exp_report_amt,l_reimb_currency) <> 
	l_exp_report_amount OR AP_WEB_DB_EXPLINE_PKG.GetAdjustedLineExists(l_report_header_id)) THEN
      p_result := 'COMPLETE:Y';

      --------------------------------------------
      l_debug_info := 'Calculate Amt Due and Total';
      --------------------------------------------
      /* jrautiai ADJ Fix Start */   
      IF (NOT AP_WEB_DB_EXPLINE_PKG.CalculateAmtsDue(l_report_header_id,
                                                     l_payment_due,
    					             l_emp_amt, 
    					             l_ccard_amt,
    					             l_total)) THEN
    	  l_emp_amt:=0;
	  l_ccard_amt:=0;
	  l_total := 0;
      END IF;
      /* jrautiai ADJ Fix End */   
  
      ----------------------------------------------------------
      l_debug_info := 'Update the Headers table with the new Amt 
			  Dues and Total columns';
      ----------------------------------------------------------
      IF (NOT AP_WEB_DB_EXPRPT_PKG.SetAmtDuesAndTotal(
			  l_report_header_id,
   			  nvl(l_ccard_amt,0),
			  nvl(l_emp_amt,0),
    			  l_total)) THEN
	  NULL;
      END IF;
    
      IF (C_WF_VERSION < AP_WEB_EXPENSE_WF.C_NoMultiLineVersion) THEN
      	 ------------------------------------------
      	 l_debug_info := 'Open Adjustments Cursor';
      	 ------------------------------------------
         -- jrautiai ADJ Fix
      	 IF (AP_WEB_DB_EXPLINE_PKG.GetAdjustmentsCursor(l_report_header_id, 'ADJUSTMENT', AdjustmentsCursor)) THEN   
      	   FOR i IN 1..10 LOOP
   
      	     ------------------------------------------
      	     l_debug_info := 'Fetch Adjustments Cursor';
      	     ------------------------------------------
             -- jrautiai ADJ Fix, fetching the results into a record instead of variable.
      	     FETCH AdjustmentsCursor INTO adjustment_rec;
      	     EXIT WHEN AdjustmentsCursor%NOTFOUND;
				
      	     -----------------------------------------
      	     l_debug_info := 'Format Adjustment Line';
      	     -----------------------------------------
             -- jrautiai ADJ Fix, taking the results from a record instead of variable.
      	     l_adjustment_line := adjustment_rec.expense_type_disp || '  ' || to_char(adjustment_rec.amount,FND_CURRENCY.Get_Format_Mask(l_currency,22)) || '  ' || adjustment_rec.adjustment_reason;
     
             -----------------------------------------------------
             l_debug_info := 'Set Adjustment Line Item Attribute';
      	     -----------------------------------------------------
   	     
      	     WF_ENGINE.SetItemAttrText(p_item_type,
	   			 p_item_key,
	   			 'ADJ_LINE' || to_char(i),
      	   			 l_adjustment_line);
           	 
             l_num_lines := i;
         END LOOP;
       END IF;

       if AdjustmentsCursor%isopen then
          CLOSE AdjustmentsCursor;
       end if;

      END IF;

    IF (C_WF_VERSION >= AP_WEB_EXPENSE_WF.C_NoMultiLineVersion) THEN  
  		
      ----------------------------------------------------------
      l_debug_info := 'Set Item Attribute Line_Info_Body1';
      ---------------------------------------------------------
      WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'LINE_INFO_BODY',
			        'plsql:AP_WEB_EXPENSE_WF.generateAdjustmentInfo/'|| p_item_type || ':' || p_item_key || ':ADJUSTMENT');

    ELSE
      l_adj_info_body := '';
      ---------------------------------------------------------
      l_debug_info := 'Populating line_info_body with tokens';
      ---------------------------------------------------------
      FOR j in 1..l_num_lines LOOP

          l_adj_info_body := l_adj_info_body || '
' || '&' || 'ADJ_LINE' || to_char(j);

      END LOOP;

      ---------------------------------------------------------
      l_debug_info := 'Set Item Attribute Line_Info_Body1';
      ---------------------------------------------------------
      WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'LINE_INFO_BODY',
			        l_adj_info_body);
      IF (C_WF_Version >= C_CreditLineVersion) THEN
         ---------------------------------------------------------
        l_debug_info := 'Set Item Attribute Credit_Line_Info_Body1';
        ---------------------------------------------------------
        WF_ENGINE.SetItemAttrText(p_item_type,
	 		          p_item_key,
			          'CREDIT_LINE_INFO_BODY',
				  '');
      END IF;
    END IF;


      /* jrautiai ADJ Fix Start */   
      -----------------------------------------------------
      l_debug_info := 'Set New Adjusted Total Item Attribute';
      -----------------------------------------------------
      WF_ENGINE.SetItemAttrNumber(p_item_type,
				  p_item_key,
		                  'TOTAL',
                                  l_total);

      -----------------------------------------------------------------
      l_debug_info := 'Set New Adjusted Display_Total Item Attribute';
      -----------------------------------------------------------------
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
		                'DISPLAY_TOTAL',
                                to_char(l_total,FND_CURRENCY.Get_Format_Mask(l_currency,22)) || ' ' || l_currency);

      /* jrautiai ADJ Fix end */   

      IF (C_WF_Version >= C_CreditLineVersion) THEN
        -----------------------------------------------------
        l_debug_info := 'Set New Credit Total Item Attribute';
        -----------------------------------------------------
        WF_ENGINE.SetItemAttrNumber(p_item_type,
				  p_item_key,
		                  'NEG_CREDIT_TOTAL',
                                  0);

        -----------------------------------------------------------------
        l_debug_info := 'Set New Credit_Display_Total Item Attribute';
        -----------------------------------------------------------------
        WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
		                'NEG_CREDIT_DISPLAY_TOTAL',
                                to_char(0,FND_CURRENCY.Get_Format_Mask(l_currency,22)));


        -----------------------------------------------------
        l_debug_info := 'Set New New_Expense_Total Item Attribute';
        -----------------------------------------------------
        WF_ENGINE.SetItemAttrNumber(p_item_type,
				  p_item_key,
		                  'POS_NEW_EXPENSE_TOTAL',
                                  0);

        -----------------------------------------------------------------
        l_debug_info := 'Set New New_Expense_Display_Total Item Attribute';
        -----------------------------------------------------------------
        WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
		                'POS_NEW_EXPENSE_DISPLAY_TOTAL',
                                to_char(0,FND_CURRENCY.Get_Format_Mask(l_currency,22)));

   
	END IF;
       
    ELSE

      -------------------------------------------------
      l_debug_info := 'Return N if no adjustment made';
      -------------------------------------------------
      p_result := 'COMPLETE:N';

    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AnyAPAdjustments');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AnyAPAdjustments', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AnyAPAdjustments;

----------------------------------------------------------------------
PROCEDURE AllReqReceiptsVerified(p_item_type		IN VARCHAR2,
		       	   	 p_item_key		IN VARCHAR2,
		       	   	 p_actid		IN NUMBER,
		       	   	 p_funmode		IN VARCHAR2,
		       	   	 p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		  AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_num_req_receipt_not_verified  NUMBER;
  l_debug_info			  VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AllReqReceiptsVerified');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    ----------------------------------------------------------------------
    l_debug_info := 'Calculate Number of Lines With Receipt Required that
                     have not been verified';
    ----------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumReceiptShortpaidLines(
					l_report_header_id,
					l_num_req_receipt_not_verified)) THEN
	l_num_req_receipt_not_verified := 0;
    END IF;

    IF (l_num_req_receipt_not_verified > 0) THEN
    ----------------------------------------------------------------------
    l_debug_info := 'Return N if there exists a line with receipt required
                     and has not been verified';
    ----------------------------------------------------------------------
      p_result := 'COMPLETE:N';
    ELSE
      p_result := 'COMPLETE:Y';
    END IF;


  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AllReqReceiptsVerified');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AllReqReceiptsVerified', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AllReqReceiptsVerified;

----------------------------------------------------------------------
PROCEDURE AllPassAPApproval(p_item_type		IN VARCHAR2,
		          	    p_item_key		IN VARCHAR2,
		                p_actid			IN NUMBER,
		                p_funmode		IN VARCHAR2,
		                p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id			AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_num_req_receipt_not_verified  	NUMBER;
  l_debug_info				VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AllPassAPApproval');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');


    ----------------------------------------------------------------------
    l_debug_info := 'Calculate Number of Lines With Receipt Required that
                     have not been verified';
    ----------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumShortpaidLines(l_report_header_id,
					l_num_req_receipt_not_verified)) THEN
	l_num_req_receipt_not_verified := 0;
    END IF;

    IF (l_num_req_receipt_not_verified > 0) THEN
    ----------------------------------------------------------------------
    l_debug_info := 'Return N if there exists a line with receipt required
                     and has not been verified';
    ----------------------------------------------------------------------
      p_result := 'COMPLETE:N';
    ELSE
      p_result := 'COMPLETE:Y';
    END IF;


  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AllPassAPApproval');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AllPassAPApproval', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AllPassAPApproval;

----------------------------------------------------------------------
PROCEDURE Approved(p_item_type		IN VARCHAR2,
		   p_item_key		IN VARCHAR2,
		   p_actid		IN NUMBER,
		   p_funmode		IN VARCHAR2,
		   p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_payment_due			VARCHAR2(10) := C_IndividualPay;
  l_debug_info			VARCHAR2(200);
  C_WF_Version	           NUMBER      := 0;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start Approved');

  IF (p_funmode = 'RUN') THEN
    -----------------------------------------------------
    l_debug_info := 'Get Workflow Version Number';
    -----------------------------------------------------
    C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(p_item_type, p_item_key);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');
    
    ---------------------------------------------------------
    l_debug_info := 'Retrieve Payment Due From System Option';
    ---------------------------------------------------------
    l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

    ------------------------------------------
    l_debug_info := 'Call CustomDataTransfer';
    ------------------------------------------
    AP_WEB_EXPENSE_CUST_WF.CustomDataTransfer(p_item_type,
					      p_item_key);

    ----------------------------------------------------------------------
    l_debug_info := 'Update the Expense Report as Approved, if the expense
                     report has only been manager approved then mark it as
                     approved automatic';
    ----------------------------------------------------------------------
    --bug 7449880: check the version and update source for reports submitted
    --prior to oie.j, from oiej the source is updated at the end in 
    --SetStatusApproverAndDate, from oie.g expense_status_code is updated
    --at the end in SetStatusApproverAndDate

    IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_OIEJ_Version) THEN
       IF (NOT AP_WEB_DB_EXPRPT_PKG.SetWkflApprvdFlagAndSource(
                         l_report_header_id, NULL, NULL)) THEN
	  NULL;
       END IF;
    ELSE
       IF (NOT AP_WEB_DB_EXPRPT_PKG.SetWkflApprvdFlagAndSource(
                         l_report_header_id, NULL, 'SelfService')) THEN
	  NULL;
       END IF;
    END IF;

    IF (C_WF_Version < AP_WEB_EXPENSE_WF.C_OIEH_Version) THEN
       -------------------------------------------------------------------
       l_debug_info := 'Set Expense Status Code';
       -------------------------------------------------------------------
       UPDATE ap_expense_report_headers_all
       SET expense_status_code = 'INVOICED',
       last_update_date = SYSDATE,
       last_updated_by = Decode(Nvl(fnd_global.user_id,-1),-1,last_updated_by,fnd_global.user_id) 
       WHERE report_header_id = l_report_header_id;
    END IF;

    ----------------------------------------------------------------------
    l_debug_info := 'Update the Credit Card Trxns associated with the Expense
		     Report as Approved';
    ----------------------------------------------------------------------
    IF (l_payment_due = C_BothPay OR l_payment_due = C_CompanyPay) THEN
        IF (NOT AP_WEB_DB_CCARD_PKG.SetStatus(l_report_header_id, 'APPROVED')) THEN
	  NULL;
	END IF;
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end Approved');

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    null;
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'Approved', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END Approved;

------------------------------------------------------------------------
PROCEDURE SetShortPaidLinesInfo(p_item_type		IN VARCHAR2,
		   		p_item_key		IN VARCHAR2,
		   		p_actid			IN NUMBER,
		   		p_funmode		IN VARCHAR2,
		   		p_notification_type     IN VARCHAR2,
		   		p_result	 OUT NOCOPY VARCHAR2) IS
-------------------------------------------------------------------------
  l_exp_report_id	AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_currency		VARCHAR2(15);
  l_shortpay_line       VARCHAR2(2000);
  l_shortpay_info_body	VARCHAR2(2000) := '';
  l_num_lines		NUMBER := 0;
  i			      NUMBER;
  j			      NUMBER;
  l_debug_info		VARCHAR2(2000);

  C_CreditLineVersion           CONSTANT NUMBER := 1;
  C_WF_Version			NUMBER          := 0;

  -- jrautiai ADJ Fix, changed shortpay to refer the new cursor type.
  ShortpaidLinesCursor 		AP_WEB_DB_EXPLINE_PKG.AdjustmentCursorType;

  -- jrautiai ADJ Fix, fetching the shortpay results into a record of a common type.
  shortpay_rec AP_WEB_DB_EXPLINE_PKG.AdjustmentRecordType;


BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetShortPaidLinesInfo');

  -----------------------------------------------------
  l_debug_info := 'Get Workflow Version Number 3';
  -----------------------------------------------------
  C_WF_Version := GetFlowVersion(p_item_type, p_item_key);

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_exp_report_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						 p_item_key,
						 'EXPENSE_REPORT_ID');

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Currency Item Attribute';
  ------------------------------------------------------------
  l_currency := WF_ENGINE.GetItemAttrText(p_item_type,
					  p_item_key,
					  'CURRENCY');



  ----------------------------------
  l_debug_info := 'Check to see if the version is before 2.0.3';
  ----------------------------------
  IF (C_WF_VERSION < AP_WEB_EXPENSE_WF.C_NoMultiLineVersion) THEN
    -----------------------------------------------------
    l_debug_info := 'Clear Adjustment Line Item Attributes';
    -----------------------------------------------------
    FOR i IN 1..10 LOOP
      WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
		              'ADJ_LINE' || to_char(i),
                              '');

    END LOOP;
  END IF;

  i := 1;

  ------------------------------------------
  l_debug_info := 'Open ShortPaidLines Cursor';
  ------------------------------------------
  -- jrautiai ADJ Fix, using common cursor with adjustments.
  IF (AP_WEB_DB_EXPLINE_PKG.GetAdjustmentsCursor(l_exp_report_id, 'SHORTPAY', ShortpaidLinesCursor)) THEN

    FOR i IN 1..10 LOOP

       ------------------------------------------
       l_debug_info := 'Fetch ShortPaidLiness Cursor';
       ------------------------------------------
       -- jrautiai ADJ Fix, fetching the results into a record instead of variable.
       FETCH ShortpaidLinesCursor INTO shortpay_rec;
       EXIT WHEN ShortpaidLinesCursor%NOTFOUND;
			      
       -----------------------------------------
       l_debug_info := 'Format ShortPay Line';
       -----------------------------------------
       l_shortpay_line := shortpay_rec.expense_type_disp || '  ' || to_char(shortpay_rec.amount,FND_CURRENCY.Get_Format_Mask(l_currency,22)) || ' ' || l_currency || ' ' || shortpay_rec.adjustment_reason;
   
       -----------------------------------------------------
       l_debug_info := 'Reuse Adjustment Line Item Attribute';
       -----------------------------------------------------
       IF (C_WF_VERSION < AP_WEB_EXPENSE_WF.C_NoMultiLineVersion) THEN
    	 WF_ENGINE.SetItemAttrText(p_item_type,
				       p_item_key,
				       'ADJ_LINE' || to_char(i),
    				       l_shortpay_line);
       END IF;
       l_num_lines := i;
    
  END LOOP;
 END IF;

  if ShortpaidLinesCursor%isopen then
     CLOSE ShortpaidLinesCursor;
  end if;

  IF (C_WF_VERSION < AP_WEB_EXPENSE_WF.C_NoMultiLineVersion) THEN
    l_shortpay_info_body := '';
    ---------------------------------------------------------
    l_debug_info := 'Populating line_info_body with tokens ' || to_char(l_num_lines) || '-' || to_char(l_exp_report_id);
    ---------------------------------------------------------
    FOR j in 1..l_num_lines LOOP
      -----------------------------------------------------
      l_debug_info := 'Assigning shortpay_info_body';
      -----------------------------------------------------

      l_shortpay_info_body := l_shortpay_info_body || '
' || '&' || 'ADJ_LINE' || to_char(j);

    END LOOP;
    ---------------------------------------------------------
    l_debug_info := 'Set Item Attribute Line_Info_Body1';
    ---------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'LINE_INFO_BODY',
			        l_shortpay_info_body);   
  ELSE
    ---------------------------------------------------------
    l_debug_info := 'Set Item Attribute Line_Info_Body1';
    ---------------------------------------------------------
    -- jrautiai ADJ Fix, Need to be able to distinguish between policy violation and missing receipts notifications.
    WF_ENGINE.SetItemAttrText(p_item_type,
	 		    p_item_key,
			    'LINE_INFO_BODY',
			    'plsql:AP_WEB_EXPENSE_WF.generateAdjustmentInfo/'||p_item_type||':'||p_item_key||':'||NVL(p_notification_type,'SHORTPAY'));   
   
  END IF;

  IF (C_WF_Version >= C_CreditLineVersion AND 
	C_WF_VERSION < AP_WEB_EXPENSE_WF.C_NoMultiLineVersion) THEN
    ---------------------------------------------------------
    l_debug_info := 'Set Item Attribute Credit_Line_Info_Body1';
    ---------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'CREDIT_LINE_INFO_BODY',
			        '');
  END IF;


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetShortPaidLinesInfo');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetShortPaidLinesInfo', 
                     p_item_type, p_item_key, null, l_debug_info);
    raise;
END SetShortPaidLinesInfo;

-----------------------------------------------------------------------------
PROCEDURE MissingReceiptShortPay(p_item_type		IN VARCHAR2,
		   		 p_item_key		IN VARCHAR2,
		   		 p_actid		IN NUMBER,
		   		 p_funmode		IN VARCHAR2,
		   		 p_result	 OUT NOCOPY VARCHAR2)
-----------------------------------------------------------------------------
IS
  l_no_receipts_shortpay_id	NUMBER;
  l_debug_info			VARCHAR2(2000);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start MissingReceiptShortPay');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_no_receipts_shortpay_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						             p_item_key,
						    'NO_RECEIPTS_SHORTPAY_ID');
    IF (l_no_receipts_shortpay_id IS NOT NULL) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;   

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

    NULL;

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end MissingReceiptShortPay');

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'MissingReceiptShortPay');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;
END MissingReceiptShortPay;

-----------------------------------------------------------------------------
PROCEDURE PolicyViolationShortPay(p_item_type		IN VARCHAR2,
		   		  p_item_key		IN VARCHAR2,
		   		  p_actid		IN NUMBER,
		   		  p_funmode		IN VARCHAR2,
		   		  p_result	 OUT NOCOPY VARCHAR2)
-----------------------------------------------------------------------------
IS
  l_policy_shortpay_id		NUMBER;
  l_debug_info			VARCHAR2(2000);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start PolicyViolationShortPay');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_policy_shortpay_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						             p_item_key,
						       'POLICY_SHORTPAY_ID');
    IF (l_policy_shortpay_id IS NOT NULL) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;   

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

    NULL;

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end PolicyViolationShortPay');

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'PolicyViolationShortPay');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;
END PolicyViolationShortPay;

-----------------------------------------------------------------------------
FUNCTION GetNewShortPayDocumentNum(p_last_document_num	IN VARCHAR2) RETURN VARCHAR2 IS
  l_new_document_number		VARCHAR2(50);
  l_position			NUMBER;
  l_num				VARCHAR2(5);
  l_debug_info			VARCHAR2(2000);
-----------------------------------------------------------------------------
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetNewShortPayDocumentNum');

    -------------------------------------------------------------------
    l_debug_info := 'Check for _ in the document_number to determine if
		     the expense report has been short paid before';
    -------------------------------------------------------------------
    l_position := INSTRB(p_last_document_num, '-');

    ------------------------------------------------------------
    l_debug_info := 'If position is greater than 0 then expense report
                     has been short paid, so we need to increment the number
		     suffix at the end, otherwise the new_document_number
		     just the old with _1 appended at the end';
    ------------------------------------------------------------
    IF (l_position > 0) THEN

      l_num := to_char(to_number(substrb(p_last_document_num, l_position+1)) + 2);

      l_new_document_number := substrb(p_last_document_num,1,l_position) || l_num;
    ELSE
      l_new_document_number := p_last_document_num || '-1';
    END IF;    

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetNewShortPayDocumentNum');

    return(l_new_document_number);

END GetNewShortPayDocumentNum;

------------------------------------------------------------------------------
PROCEDURE CreateShortPayExpReport(p_orig_expense_report_id	IN AP_WEB_DB_EXPRPT_PKG.expHdr_headerID,
				  p_new_expense_report_id	IN AP_WEB_DB_EXPRPT_PKG.expHdr_headerID,
				  p_new_expense_report_num	IN AP_WEB_DB_EXPRPT_PKG.expHdr_invNum,
				  p_new_expense_report_total	IN AP_WEB_DB_EXPRPT_PKG.expHdr_total,
				  p_new_ccard_amt               IN AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueCcardCompany,
				  p_new_emp_amt                 IN AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueEmployee,
				  p_shortpay_type		IN VARCHAR2)
------------------------------------------------------------------------------
IS
  l_debug_info		VARCHAR2(2000);
  l_ExpenseRec		AP_WEB_DB_EXPRPT_PKG.XpenseInfoRec;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CreateShortPayExpReport');

    -------------------------------------------------------------------
    l_debug_info := 'Create new expense report by creating new record in 
		     ap_expense_report_headers, with same info as old 
		     expense report except new id, number and total';
    --------------------------------------------------------------------
    l_ExpenseRec.report_header_id := p_new_expense_report_id;
    l_ExpenseRec.employee_id := NULL;
    l_ExpenseRec.preparer_id := NULL;
    l_ExpenseRec.last_updated_by := NULL;
    l_ExpenseRec.vouchno := 0;
    l_ExpenseRec.total := p_new_expense_report_total;
    l_ExpenseRec.vendor_id := NULL;
    l_ExpenseRec.vendor_site_id := NULL;
    l_ExpenseRec.expense_check_address_flag := NULL;
    l_ExpenseRec.document_number := p_new_expense_report_num;
    l_ExpenseRec.last_update_login := NULL;
    l_ExpenseRec.org_id := NULL;
    l_ExpenseRec.workflow_flag := p_shortpay_type;
    l_ExpenseRec.amt_due_employee := p_new_emp_amt;
    l_ExpenseRec.amt_due_ccard := NVL(p_new_ccard_amt,0);
    l_ExpenseRec.description := NULL;
    l_ExpenseRec.bothpay_report_header_id := NULL;
    l_ExpenseRec.shortpay_parent_id := p_orig_expense_report_id;
    l_ExpenseRec.behalf_employee_id := NULL;
    l_ExpenseRec.approver_id := NULL;
    l_ExpenseRec.week_end_date := NULL;
    l_ExpenseRec.set_of_books_id := NULL;
    l_ExpenseRec.source := NULL;
    l_ExpenseRec.accts_pay_comb_id := NULL;
    l_ExpenseRec.expense_status_code := NULL;

    IF (NOT AP_WEB_DB_EXPRPT_PKG.InsertReportHeaderLikeExisting(
			p_orig_expense_report_id, l_ExpenseRec)) THEN
	NULL;
    END IF;


  IF (p_shortpay_type = 'POLICY') THEN
    --------------------------------------------------------------------
    l_debug_info := 'Insert the lines that cannot be paid into
		     ap_expense_report_lines with new report_header_id';
    --------------------------------------------------------------------
    
    IF (AP_WEB_DB_EXPLINE_PKG.AddPolicyShortPaidExpLines(p_new_expense_report_id, p_orig_expense_report_id)) THEN
	NULL;
    END IF;

      --------------------------------------------------------------------
      l_debug_info := 'Set the report header id of the CC charges that 
			are attached to the shortpaid report due to policy
			violation with the new expense report id';
      --------------------------------------------------------------------
      IF (NOT AP_WEB_DB_CCARD_PKG.SetCCPolicyShortpaidReportID(p_orig_expense_report_id, p_new_expense_report_id)) THEN
	NULL;
      END IF;

      --------------------------------------------------------------------
      l_debug_info := 'Update the report header id in the violations table
			with the new expense report id';
      --------------------------------------------------------------------
      AP_WEB_DB_VIOLATIONS_PKG.SetVioPolicyShortpaidReportID(
		p_orig_expense_report_id => p_orig_expense_report_id, 
		p_new_report_header_id	 => p_new_expense_report_id);
  ELSE

    --------------------------------------------------------------------
    l_debug_info := 'Insert the lines that cannot be paid into
		     ap_expense_report_lines with new report_header_id for 
			missing receipts shortpay';
    --------------------------------------------------------------------
    IF (AP_WEB_DB_EXPLINE_PKG.AddUnverifiedShortpaidLines(
			p_new_expense_report_id, p_orig_expense_report_id)) THEN
	NULL;
    END IF;

      --------------------------------------------------------------------
      l_debug_info := 'Set the report header id of the CC charges that 
			are attached to the shortpaid report due to missing
			receipts with the new expense report id';
      --------------------------------------------------------------------
      IF (NOT AP_WEB_DB_CCARD_PKG.SetCCReceiptShortpaidReportID(
			p_orig_expense_report_id, p_new_expense_report_id)) THEN
	NULL;
      END IF;

      --------------------------------------------------------------------
      l_debug_info := 'Update the report header id in the violations table
                        with the new expense report id';
      --------------------------------------------------------------------
      AP_WEB_DB_VIOLATIONS_PKG.SetVioReceiptShortpaidReportID(
                p_orig_expense_report_id => p_orig_expense_report_id,
                p_new_report_header_id   => p_new_expense_report_id);


  END IF;
      
  --------------------------------------------------------------------
  l_debug_info := 'Copy Notes from original report';
  --------------------------------------------------------------------
  AP_WEB_NOTES_PKG.CopyERNotes (
    p_src_report_header_id   => p_orig_expense_report_id,
    p_tgt_report_header_id   => p_new_expense_report_id
  );


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CreateShortPayExpReport');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CreateShortPayExpReport', 
                     null, to_char(p_orig_expense_report_id), null, l_debug_info);
    raise;
END CreateShortPayExpReport; 



----------------------------------------------------------------------
PROCEDURE SplitExpenseReport(p_item_type	IN VARCHAR2,
		   	     p_item_key		IN VARCHAR2,
		   	     p_actid		IN NUMBER,
		   	     p_funmode		IN VARCHAR2,
		   	     p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		  AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_num_req_receipt_not_verified  NUMBER;
  l_policy_shortpay_total	  AP_WEB_DB_EXPRPT_PKG.expHdr_total;
  l_no_receipts_shortpay_total	  AP_WEB_DB_EXPRPT_PKG.expHdr_total;
  l_policy_shortpay_id		  AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_no_receipts_shortpay_id	  AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_policy_shortpay_doc_num	  AP_WEB_DB_EXPRPT_PKG.expHdr_invNum;
  l_no_receipts_shortpay_doc_num  AP_WEB_DB_EXPRPT_PKG.expHdr_invNum;
  l_document_number		  AP_WEB_DB_EXPRPT_PKG.expHdr_invNum;
  l_payment_due			  VARCHAR2(10) := C_IndividualPay;
  l_count			  NUMBER;
  l_personal_total		  NUMBER := 0;
  l_policy_ccard_amt		  AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueCcardCompany;
  l_no_receipts_ccard_amt	  AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueCcardCompany;
  l_policy_emp_amt		  AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueEmployee;
  l_no_receipts_emp_amt	  	  AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueEmployee;
  l_ccard_amt		  	  AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueCcardCompany;
  l_emp_amt		  	  AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueEmployee;
  l_currency			  VARCHAR2(50);
  l_debug_info			  VARCHAR2(500);

  l_no_data_found_flag1		  BOOLEAN := TRUE;
  l_no_data_found_flag2		  BOOLEAN := TRUE;
  l_amtDueCCardCompany            AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueCcardCompany;
  l_amtDueEmp                     AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueEmployee;
  
  /* jrautiai ADJ Fix - Start */
  l_total                         NUMBER := 0;
  l_policy_count                  NUMBER := 0;
  l_shortpaid_count               NUMBER := 0;
  l_missing_receipt_count         NUMBER := 0;
  /* jrautiai ADJ Fix - End */
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SplitExpenseReport');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Document Number Item Attribute';
    ------------------------------------------------------------
    l_document_number := WF_ENGINE.GetItemAttrText(p_item_type,
						   p_item_key,
						   'DOCUMENT_NUMBER');

    -----------------------------------------------------
    l_debug_info := 'Retrieve Currency Item Attribute';
    -----------------------------------------------------
    l_currency := WF_ENGINE.GetItemAttrText(p_item_type,
			      		    p_item_key,
		              		    'CURRENCY');

    
    l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

    /* jrautiai ADJ Fix Start */   
    -----------------------------------------------------------------
    l_debug_info := 'Get number of lines not adhereing to policies.';
    ------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumShortpaidLines(l_report_header_id, l_shortpaid_count)) THEN 
      l_shortpaid_count := 0;
    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Get number of lines with policy shortpay.';
    ------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumPolicyShortpaidLines(l_report_header_id, l_policy_count)) THEN 
      l_policy_count := 0;
    END IF;
    /* A line can contain both scenarios, missing receipt and policy violation flag. In that case
     * the line is moved to the '-1' report created for the policy violation flag. The variable
     * l_shortpaid_count contains the number of lines with either missing receipts and / or with
     * policy violation flag. The variable l_policy_count contains lines with only the policy
     * violation flag. So the number of lines to be moved to the new missing receipt report
     * can be calculated with 'l_shortpaid_count - l_policy_count'. We are not using the function
     *  AP_WEB_DB_EXPLINE_PKG.GetNumReceiptShortpaidLines
     * since that will return all the lines with missing receipts, including ones with also policy 
     * shortpay flag set to Y, which will not be moved to the missing receipts report.
     */
    l_missing_receipt_count := l_shortpaid_count - l_policy_count;

    IF (l_policy_count > 0) THEN
    /* jrautiai ADJ Fix end */   
    
    -----------------------------------------------------------------
    l_debug_info := 'Retrieve Policy ShortPay New Expense Report Id';
    -----------------------------------------------------------------
      IF (NOT AP_WEB_DB_EXPRPT_PKG.GetNextExpReportID(l_policy_shortpay_id)) THEN
	NULL;
      END IF;
  
      l_policy_shortpay_doc_num := l_document_number || '-1';

      /* jrautiai ADJ Fix 
       * Not passing in amounts, they are calculated after the shortpaid report has been created.
       * This is because in company pay scenario the personal lines are moved with all the other
       * lines using the transaction. If the amounts are calculated prior to creating the report
       * and several personal lines exists on the original report the totals incorrectly reflect
       * all the personal amounts. */   
      CreateShortpayExpReport(l_report_header_id,
			      l_policy_shortpay_id,
			      l_policy_shortpay_doc_num,
			      0, --l_policy_shortpay_total,
                              0, --l_policy_ccard_amt,
			      0, --l_policy_emp_amt,
			      'POLICY');
			      
      /* jrautiai ADJ Fix Start 
       * recalculate the shortpaid totals after it has been created*/   
      IF (NOT AP_WEB_DB_EXPLINE_PKG.CalculateAmtsDue(l_policy_shortpay_id,
                                                     l_payment_due,
                                                     l_policy_emp_amt, 
                                                     l_policy_ccard_amt,
                                                     l_policy_shortpay_total)) THEN
        l_policy_emp_amt:=0;
        l_policy_ccard_amt:=0;
        l_policy_shortpay_total := 0;
      END IF;
      IF (NOT AP_WEB_DB_EXPRPT_PKG.SetAmtDuesAndTotal(l_policy_shortpay_id,
                                                      l_policy_ccard_amt,
                                                      l_policy_emp_amt,
                                                      l_policy_shortpay_total)) THEN
        NULL;
      END IF;
      /* jrautiai ADJ Fix End */   
    
    ------------------------------------------------------------
    l_debug_info := 'Set the New_Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
			        p_item_key,
			        'POLICY_SHORTPAY_ID',
			        l_policy_shortpay_id);

    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'POLICY_SHORTPAY_DOC_NUM',
			      l_policy_shortpay_doc_num);

    WF_ENGINE.SetItemAttrNumber(p_item_type,
			        p_item_key,
			        'POLICY_SHORTPAY_TOTAL',
			        l_policy_shortpay_total);


    END IF;

    IF (l_missing_receipt_count > 0) THEN
    -----------------------------------------------------------------
    l_debug_info := 'Retrieve Policy ShortPay New Expense Report Id';
    -----------------------------------------------------------------
      IF (NOT AP_WEB_DB_EXPRPT_PKG.GetNextExpReportID(l_no_receipts_shortpay_id)) THEN
	l_no_receipts_shortpay_id := NULL;
      END IF;

      IF (l_policy_count > 0) THEN
        l_no_receipts_shortpay_doc_num := l_document_number || '-2';
      ELSE
        l_no_receipts_shortpay_doc_num := l_document_number || '-1';
      END IF;

      /* jrautiai ADJ Fix 
       * Not passing in amounts, they are calculated after the shortpaid report has been created.
       * This is because in company pay scenario the personal lines are moved with all the other
       * lines using the transaction. If the amounts are calculated prior to creating the report
       * and several personal lines exists on the original report the totals incorrectly reflect
       * all the personal amounts. */   
      CreateShortpayExpReport(l_report_header_id,
			      l_no_receipts_shortpay_id,
			      l_no_receipts_shortpay_doc_num,
			      0,
                              0,
			      0,
			      'NO_RECEIPTS');
			      
      /* jrautiai ADJ Fix Start 
       * recalculate the shortpaid totals after it has been created*/   
      IF (NOT AP_WEB_DB_EXPLINE_PKG.CalculateAmtsDue(l_no_receipts_shortpay_id,
                                                     l_payment_due,
                                                     l_no_receipts_emp_amt, 
                                                     l_no_receipts_ccard_amt,
                                                     l_no_receipts_shortpay_total)) THEN
        l_no_receipts_emp_amt:=0;
        l_no_receipts_ccard_amt:=0;
        l_no_receipts_shortpay_total := 0;
      END IF;
      IF (NOT AP_WEB_DB_EXPRPT_PKG.SetAmtDuesAndTotal(l_no_receipts_shortpay_id,
                                                      l_no_receipts_ccard_amt,
                                                      l_no_receipts_emp_amt,
                                                      l_no_receipts_shortpay_total)) THEN
        NULL;
      END IF;
      /* jrautiai ADJ Fix End */   

      WF_ENGINE.SetItemAttrNumber(p_item_type,
			         p_item_key,
			         'NO_RECEIPTS_SHORTPAY_ID',
			         l_no_receipts_shortpay_id);

      WF_ENGINE.SetItemAttrText(p_item_type,
			        p_item_key,
			        'NO_RECEIPTS_SHORTPAY_DOC_NUM',
			        l_no_receipts_shortpay_doc_num);

      WF_ENGINE.SetItemAttrNumber(p_item_type,
			          p_item_key,
			          'NO_RECEIPTS_SHORTPAY_TOTAL',
			          l_no_receipts_shortpay_total);

    END IF;


    -----------------------------------------------------------------------
    l_debug_info := 'Handle the receipts management event MR '||to_char(l_no_receipts_shortpay_id);
    -----------------------------------------------------------------------
    IF l_no_receipts_shortpay_id IS NOT NULL THEN
      AP_WEB_RECEIPT_MANAGEMENT_UTIL.handle_event(l_no_receipts_shortpay_id,AP_WEB_RECEIPT_MANAGEMENT_UTIL.C_EVENT_MR_SHORTPAY);
    END IF;

    -----------------------------------------------------------------------
    l_debug_info := 'Handle the receipts management event PV'||to_char(l_policy_shortpay_id);
    -----------------------------------------------------------------------
    IF l_policy_shortpay_id IS NOT NULL THEN
      AP_WEB_RECEIPT_MANAGEMENT_UTIL.handle_event(l_policy_shortpay_id,AP_WEB_RECEIPT_MANAGEMENT_UTIL.C_EVENT_PV_SHORTPAY);
    END IF;
    
    -----------------------------------------------------------------------
    l_debug_info := 'Handle the receipts management event original';
    -----------------------------------------------------------------------
    AP_WEB_RECEIPT_MANAGEMENT_UTIL.handle_event(l_report_header_id,AP_WEB_RECEIPT_MANAGEMENT_UTIL.C_EVENT_SHORTPAY);

    -----------------------------------------------------------------------
    l_debug_info := 'Count the lines remaining in the original expense
			report';
    -----------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumberOfExpLines(l_report_header_id,l_count) OR l_count = 0) THEN
      -----------------------------------------
      l_debug_info := 'Delete the original expense report if everything
	  	       is getting shortpaid';
      ----------------------------------------------------------------------
      IF (NOT AP_WEB_DB_EXPRPT_PKG.DeleteExpenseReport(l_report_header_id)) THEN
	NULL;
      END IF;

    ELSE

      ----------------------------------------------------------------------
      l_debug_info := 'Update the total of the original expense report
	  	       to not include the amount of the new expense report';
      ----------------------------------------------------------------------
      /* jrautiai ADJ Fix Start */   
      IF (NOT AP_WEB_DB_EXPLINE_PKG.CalculateAmtsDue(l_report_header_id,
                                                     l_payment_due,
    					             l_amtDueEmp, 
    					             l_amtDueCCardCompany,
    					             l_total)) THEN
    	  l_amtDueEmp:=0;
	  l_amtDueCCardCompany:=0;
	  l_total := 0;
      END IF;

      IF (NOT AP_WEB_DB_EXPRPT_PKG.SetAmtDuesAndTotal(l_report_header_id,
				l_amtDueCCardCompany,
     				l_amtDueEmp,
            			l_total)) THEN
      /* jrautiai ADJ Fix End */   
	NULL;
      END IF;

    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SplitExpenseReport');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SplitExpenseReport', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SplitExpenseReport;


PROCEDURE DeleteExpReportFromAPTables(p_report_header_id	IN AP_WEB_DB_EXPRPT_PKG.expHdr_headerID) IS
  l_debug_info		VARCHAR2(200);
  l_payment_due  	VARCHAR2(10) := C_IndividualPay;
  l_item_type	VARCHAR2(100)	:= 'APEXP';
  l_item_key	VARCHAR2(100)	:= to_char(p_report_header_id);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start DeleteExpReportFromAPTables');

    ----------------------------------------------------------------
    l_debug_info := 'Retrive the Payment Due From Profile Option';
    ----------------------------------------------------------------
    l_payment_due := WF_ENGINE.GetItemAttrText(l_item_type,
					l_item_key,'PAYMENT_DUE_FROM');
 
    ---------------------------------------------------------------------
    l_debug_info := 'Update manager rejected/returned credit card transactions that 
		are deleted after a timeout';
    ---------------------------------------------------------------------
    IF (l_payment_due = C_BothPay OR l_payment_due = C_CompanyPay) THEN
	IF (NOT AP_WEB_DB_CCARD_PKG.ResetCCMgrRejectedCCLines(p_report_header_id)) THEN
	   NULL;
	END IF;
    END IF;

    -----------------------------------------------------------------------
    l_debug_info := 'Update the Credit Card interface table by setting 
	             expensed_amount to 0 and report_header_id to null';
    -----------------------------------------------------------------------
    IF (NOT AP_WEB_DB_CCARD_PKG.ResetCCLines(p_report_header_id)) THEN
        NULL;
    END IF;

    ---------------------------------------------------------------------------
    l_debug_info := 'Delete the expense lines for the given expense report id';
    ---------------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.DeleteReportLines(p_report_header_id)) THEN
	NULL;
    END IF;

    ----------------------------------------------------
    l_debug_info := 'Delete the expense report header';
    ----------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.DeleteExpenseReport(p_report_header_id)) THEN
	NULL;
    END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end DeleteExpReportFromAPTables');

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'DeleteExpReportFromAPTables');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;
END DeleteExpReportFromAPTables;

---------------------------------------------------
PROCEDURE ResetAttrValues(p_item_type IN VARCHAR2, 
                          p_item_key  IN VARCHAR2,
                          p_actid     IN NUMBER) IS
---------------------------------------------------
--
-- Reset the attribute values which are not set explicitly by 
-- StartExpenseReportProcess before the rejected/returned report is resubmitted.
-- We need to clear these because we will be revisiting nodes in the process.
--

  I            			NUMBER;
  l_debug_info 			VARCHAR2(200);
  C_WF_VERSION 			NUMBER := 0;
  -- Bug 668037
  l_override_approver_id AP_WEB_DB_EXPRPT_PKG.expHdr_overrideApprID;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ResetAttrValues');

  C_WF_VERSION  :=  GetFlowVersion(p_item_type, p_item_key);
  IF (C_WF_VERSION < AP_WEB_EXPENSE_WF.C_NoMultiLineVersion) THEN
    -----------------------------------------------------
    l_debug_info := 'Unset Adjustment Line Item Attribute';
    -----------------------------------------------------
    FOR I IN 1..C_NUM_ADJ_LINE_ATTRS LOOP
  
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'ADJ_LINE' || to_char(I),
				'');
  
    END LOOP;
  ELSE
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'LINE_INFO_BODY',
			      'plsql:AP_WEB_EXPENSE_WF.resetLineInfo/');
  END IF;

  ----------------------------------------------------------------
  l_debug_info := 'Unset error message';
  -----------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    p_item_key,
			    'ERROR_MESSAGE',
			    '');



  ----------------------------------------------------------------------
  l_debug_info := 'Unset Find Approver Count';
  ----------------------------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      p_item_key,
			      'FIND_APPROVER_COUNT',
			      0);

  ----------------------------------------------------------------------
  l_debug_info := 'Unset Forward_From Item Attributes With Approver Info';
  ----------------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    p_item_key,
			    'FORWARD_FROM_DISPLAY_NAME',
			    ''); 

  WF_ENGINE.SetItemAttrNUMBER(p_item_type,
			      p_item_key,
			      'FORWARD_FROM_ID',
			      '');

  WF_ENGINE.SetItemAttrText(p_item_type,
			    p_item_key,
			    'FORWARD_FROM_NAME',
			    '');

  IF (C_WF_VERSION < AP_WEB_EXPENSE_WF.C_NoMultiLineVersion) THEN
    ------------------------------------------------------------------------
    l_debug_info := 'Set Line_Info Item Attribute with formatted expense line';
    ---------------------------------------------------------------------------
    FOR I IN 1..200 LOOP
  
  	WF_ENGINE.SetItemAttrText(p_item_type,
  				p_item_key,
  				'LINE_INFO' || TO_CHAR(I),
  				'');
  
    END LOOP;  
    ---------------------------------------------------------
    l_debug_info := 'Unset Item Attribute Line_Info_Body1';
    ---------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
  			      p_item_key,
  			      'LINE_INFO_BODY',
  			      '');
  
  END IF;

  --------------------------------------------------------------------------
  l_debug_info := 'Reset
                   Manager_Approval_Send_Count Item Attribute and return Y';
  --------------------------------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      p_item_key,
			      'MANAGER_APPROVAL_SEND_COUNT',
			      0);

  ---------------------------------------------------------------
  l_debug_info := 'Unset Manager_Display_Name Info Item Attribute';
  ---------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    p_item_key,
			    'MANAGER_DISPLAY_NAME',
			    '');

  --------------------------------------------------------
  l_debug_info := 'Unset Manager_ID Info Item Attribute';
  --------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    p_item_key,
			    'MANAGER_ID',
			    '');

  --------------------------------------------------------
  l_debug_info := 'Unset Manager_Name Info Item Attribute';
  --------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    p_item_key,
			    'MANAGER_NAME',
			    '');


  -----------------------------------------------------------------
  l_debug_info := 'Unset Missing Receipt Total';
  -----------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    p_item_key,
			    'MISSING_RECEIPT_TOTAL',
		            '');

  ---------------------------------------------------------------
  l_debug_info := 'Reset rejection reason';
  ---------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'WF_NOTE',
			      '');

  ---------------------------------------------------------------
  l_debug_info := 'Reset violation note';
  ---------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'VIOLATION_NOTE', 
			      '');

  ---------------------------------------------------------------
  l_debug_info := 'Reset Employee violation note';
  ---------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'EMP_VIOLATION_NOTE', 
			      '');

  ---------------------------------------------------------------
  l_debug_info := 'Reset violation total';
  ---------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'VIOLATIONS_TOTAL', 
			      ''); 

  --Bug 4425821: Uptake AME parallel approvers
  ---------------------------------------------------------------
  l_debug_info := 'Reset AME Approver Response';
  ---------------------------------------------------------------
  IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_R120_Version) THEN
    WF_ENGINE.SetItemAttrText(p_item_type,
  			    p_item_key,
 			    'AME_APPROVER_RESPONSE',
			    '');
    WF_ENGINE.SetItemAttrText(p_item_type,
  			    p_item_key,
 			    'AME_REJECTED_CHILD_ITEM_KEY',
			    '');
    begin
     WF_ENGINE.SetItemAttrText(p_item_type,
  			    p_item_key,
 			    'AME_APPROVED_CHILD_ITEM_KEY',
			    '');
    exception
     when others then
      if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
        null;
      else
        raise;
      end if;
   end;
  END IF;
                                 
    --
    -- Bug 668037
    -- Reset approver attributes
    --
        IF (NOT AP_WEB_DB_EXPRPT_PKG.GetOverrideApproverID(to_number(p_item_key), l_override_approver_id)) THEN
            l_override_approver_id := NULL;
        END IF;

        IF (l_override_approver_id IS NOT NULL) THEN
            AP_WEB_EXPENSE_WF.SetPersonAs(l_override_approver_id,
                                          p_item_type,
                                          p_item_key,
                                          'APPROVER');
        ELSE
            --------------------------------------------------------
            l_debug_info := 'Set Approver_ID Info Item Attribute';
            --------------------------------------------------------
            WF_ENGINE.SetItemAttrText(p_item_type,
                                      p_item_key,
                                      'APPROVER_ID',
                                      null);

            --------------------------------------------------------
            l_debug_info := 'Set Approver_Name Info Item Attribute';
            --------------------------------------------------------
            WF_ENGINE.SetItemAttrText(p_item_type,
                                      p_item_key,
                                      'APPROVER_NAME',
                                      '');

            ----------------------------------------------------------------
            l_debug_info := 'Set Approver_Display_Name Info Item Attribute';
            ----------------------------------------------------------------
            WF_ENGINE.SetItemAttrText(p_item_type,
                                      p_item_key,
                                      'APPROVER_DISPLAY_NAME',
                                      '');
        END IF;

  ----------------------------------------------------------------
  l_debug_info := 'Reset AP Validation Attributes';
  ----------------------------------------------------------------
  ResetAPValidationAttrValues(p_item_type,
                              p_item_key,
                              p_actid);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ResetAttrValues');

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END ResetAttrValues;

/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      ResetCCardTxns                                                        |
 |                                                                            |
 | DESCRIPTION                                                                |
 |      Private procedure for resetting credit card transactions              |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |      p_report_header_id      NUMBER    -- Expense Report Header ID         |
 | RETURNS                                                                    |
 |     none                                                                   |
 *----------------------------------------------------------------------------*/
 
PROCEDURE ResetCCardTxns (
   p_report_header_id   IN AP_WEB_DB_EXPLINE_PKG.expLines_headerID,
   p_item_type          IN VARCHAR2,
   p_item_key           IN VARCHAR2)
IS
   l_payment_due        VARCHAR2(50) := C_IndividualPay;
   l_debug_info         VARCHAR2(200);
BEGIN
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF',
     'start ResetCCardTxns');
 
  l_payment_due     := WF_ENGINE.GetItemAttrText(p_item_type, p_item_key,
                                                'PAYMENT_DUE_FROM');

  l_debug_info := 'Update for Credit Card Integration';
  IF (l_payment_due = C_CompanyPay) THEN
       IF (NOT AP_WEB_DB_EXPLINE_PKG.DeletePersonalLines(p_report_header_id))
         THEN
          NULL;
       END IF;
  END IF;

  /* Bug 2356968. When an expense report contains a Personal CC txn, and if
     the approver rejects that Expense Report upon submission, the following
     call to  ResetMgrRejectPersonalTrxns will remove the Personal CC txn
     from the expense report, whereby it becomes part of the common queue again
     allowing other users to use the same CC txn on other expense reports. Hence
     commenting the call because the expense report should maintian its original
     data on rejected reports.
  l_debug_info := 'Update for Credit Card Integration Bothpay';
  IF (l_payment_due = C_CompanyPay OR
      l_payment_due = AP_WEB_EXPENSE_WF.C_BothPay) THEN
        IF (NOT AP_WEB_DB_CCARD_PKG.ResetMgrRejectPersonalTrxns(
                                        p_report_header_id)) THEN
           NULL;
        END IF;
  END IF;
  */

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF',
     'end ResetCCardTxns');
 
EXCEPTION
  WHEN OTHERS THEN
      ROLLBACK;
      APP_EXCEPTION.RAISE_EXCEPTION;
END ResetCCardTxns;

PROCEDURE AMEAbortRequestApprovals(
	p_rep_header_id IN AP_WEB_DB_EXPLINE_PKG.expLines_headerID,
	p_withdraw IN VARCHAR2 DEFAULT 'N')
IS
  l_debug_info         VARCHAR2(200);
  l_wf_active          BOOLEAN := FALSE;
  l_wf_exist           BOOLEAN := FALSE;
  l_end_date           wf_items.end_date%TYPE;
  l_childItemKeySeq    NUMBER;
  l_childItemKey       varchar2(30);
  l_itemkey            varchar2(30);
  l_itemtype           varchar2(30);
  l_AmeRejectedChildItemKey       varchar2(30);
  l_AmeApprovedChildItemKey       varchar2(30);
  l_ap_reject_return              varchar2(1);
  l_ap_review_status		  AP_WEB_DB_EXPRPT_PKG.expHdr_wkflApprvdFlag;
  l_WorkflowRec			  AP_WEB_DB_EXPRPT_PKG.ExpWorkflowRec;
BEGIN

  l_itemtype := 'APEXP';
  l_itemkey     := to_char(p_rep_header_id);

  ---------------------------------------------
  l_debug_info := 'Start AMEAbortRequestApprovals';
  ---------------------------------------------
  l_childItemKeySeq := WF_ENGINE.GetItemAttrNumber(l_itemtype,
						   l_itemkey,
						   'AME_CHILD_ITEM_KEY_SEQ');

  l_AmeRejectedChildItemKey := WF_ENGINE.GetItemAttrText(l_itemtype,
						   l_itemkey,
						   'AME_REJECTED_CHILD_ITEM_KEY');

  -- bug 6686996
  begin
    l_AmeApprovedChildItemKey := WF_ENGINE.GetItemAttrText(l_itemtype,
						   l_itemkey,
						   'AME_APPROVED_CHILD_ITEM_KEY');
  exception
    when others then
      if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
        l_AmeApprovedChildItemKey := null;
      else
        raise;
      end if;
  end;

  -------------------------------------------------
  l_debug_info := 'Retrieve The AP Reviewed Flag';
  -------------------------------------------------
  IF (AP_WEB_DB_EXPRPT_PKG.GetExpWorkflowInfo(to_number(l_itemkey),
						l_WorkflowRec)) THEN
      l_ap_review_status := nvl(l_WorkflowRec.workflow_flag, 'N');
  END IF;

  l_ap_reject_return := 'N';
  IF (l_ap_review_status = AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_REJECTED or -- already AP rejected
      l_ap_review_status = AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_REQUEST) THEN -- already AP requests more info
    l_ap_reject_return := 'Y'; 
  END IF;
  if (l_childItemKeySeq >= 1) then

   FOR i in 1 .. l_childItemKeySeq LOOP
    l_childItemKey := l_itemkey || '-' || to_char(i);
    l_end_date := null;
    l_wf_active := FALSE;
    l_wf_exist  := FALSE;

    ---------------------------------------------------------------------------
    l_debug_info := 'l_childItemKey :' || l_childItemKey;
    l_debug_info := 'l_AmeRejectedChildItemKey: ' || l_AmeRejectedChildItemKey;
    ---------------------------------------------------------------------------

    if ((((l_AmeRejectedChildItemKey is null) or (l_childItemKey <> l_AmeRejectedChildItemKey)) and
        ((l_ap_reject_return = 'N') or 
         (l_ap_reject_return = 'Y' and (l_AmeApprovedChildItemKey is null or l_childItemKey <> l_AmeApprovedChildItemKey))) ) or
	 (p_withdraw = 'Y'))
    then

     begin
      select   end_date
      into     l_end_date
      from     wf_items
      where    item_type = l_itemtype
      and      item_key  = l_childItemKey;

      if l_end_date is NULL then
         l_wf_active := TRUE;
      else
         l_wf_active := FALSE;
      end if;
      l_wf_exist  := TRUE;
     exception
      when no_data_found then
        l_wf_active := FALSE;
        l_wf_exist  := FALSE;
     end;

     if l_wf_exist then

      if l_wf_active then
         --------------------------------------------------------
         l_debug_info := 'Abort Child Process' || l_childItemKey;
         --------------------------------------------------------
         wf_engine.AbortProcess (itemtype => l_itemtype,
                                itemkey  => l_childItemKey,
                                cascade  => TRUE);
      end if;

      ---------------------------------------------------------
      l_debug_info := 'Purge child workflow' || l_childItemKey;
      ---------------------------------------------------------
      wf_purge.Items(itemtype => l_itemtype,
                    itemkey  => l_childItemKey);

      wf_purge.TotalPerm(itemtype => l_itemtype,
                         itemkey  => l_childItemKey,
                         runtimeonly => TRUE);

      ---------------------------------------------------------------
      l_debug_info := 'After Purge child workflow' || l_childItemKey;
      ---------------------------------------------------------------

     end if;
    end if;

   END LOOP;

  end if;
END AMEAbortRequestApprovals;

----------------------------------------------------------------------
PROCEDURE SetRejectStatusAndResetAttr(p_item_type      IN VARCHAR2,
                          p_item_key       IN VARCHAR2,
                          p_actid          IN NUMBER,
                          p_funmode        IN VARCHAR2,
                          p_result         OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info                     VARCHAR2(200);   
  l_report_header_id		   AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_payment_due			   VARCHAR2(10) := C_IndividualPay;
  l_AMEEnabled                     VARCHAR2(1);
  l_No                     VARCHAR2(1) := 'N';
  C_WF_Version	           NUMBER      := 0;
  l_n_resp_id			    NUMBER;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetRejectStatusAndResetAttr');

  IF (p_funmode = 'RUN') THEN  

    -----------------------------------------------------
    l_debug_info := 'Get Workflow Version Number';
    -----------------------------------------------------
    C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(p_item_type, p_item_key);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

    ------------------------------------------------------------
    l_debug_info := 'Set reject status in report header';
    ------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.SetWkflApprvdFlagAndSource(l_report_header_id,
				AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_REJECTED, 
				'NonValidatedWebExpense')) THEN
	NULL;
    END IF;

    /* This is required for AME integration with Expenses in 11i
	In 11, this procedure is only a stub */
    /*
    AP_WEB_WRAPPER_PKG.SetRejectStatusInAME(p_item_key,
					    p_item_type);*/

    -- Bug 3560082 - Comment the call to SetRejectStatusInAME and add the call
    -- AME_API.clearAllApprovals
    l_AMEEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
					       p_item_key,
					       'AME_ENABLED');
    IF (l_AMEEnabled = 'Y') THEN
       --Bug 4425821: Uptake AME parallel approvers
       IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_R120_Version) THEN
          ---------------------------------------------------------------------------
          l_debug_info := 'Call AMEAbortRequestApprovals' || to_char(l_report_header_id);
          ---------------------------------------------------------------------------
          AMEAbortRequestApprovals(l_report_header_id); 
       END IF;

       -----------------------------------------------------------------
       l_debug_info := 'Call clearAllApprovals' || to_char(p_item_key) ;
       -----------------------------------------------------------------
       AME_API2.clearAllApprovals(applicationIdIn => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                                 transactionIdIn => p_item_key, 
  			         transactionTypeIn => p_item_type);                        

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Call AP_WEB_AUDIT_QUEUE_UTILS.remove_from_queue';
    -----------------------------------------------------------------
    AP_WEB_AUDIT_QUEUE_UTILS.remove_from_queue(l_report_header_id);

    ----------------------------------------------------------
    l_debug_info := 'Clearing out lines in AP_AUD_AUDIT_REASONS';
    ----------------------------------------------------------
    -- Bug 4394168
      AP_WEB_AUDIT_UTILS.clear_audit_reason_codes(l_report_header_id);

     ------------------------------------------------------------
    l_debug_info := 'call reset credit card transactions';
    ------------------------------------------------------------
    ResetCCardTxns(l_report_header_id, p_item_type, p_item_key);

    -- 4001778/3654956 : reset the Apply Advances 
    --5060928: reset the Apply Advnaces only if OIE:Enable Advances = "Payables"

    begin

    l_n_resp_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'RESPONSIBILITY_ID');

     exception
  	when others then
  	   if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
  	       null;
  	   else
  	       raise;
  	  end if;
     end;
    
    IF FND_PROFILE.VALUE_SPECIFIC('OIE_ENABLE_ADVANCES',NULL,l_n_resp_id,200) = 'PAYABLES' THEN

	    AP_WEB_DB_EXPLINE_PKG.resetApplyAdvances(l_report_header_id);
    END IF;


    /* Bug 4019412 */
    AP_WEB_DB_EXPLINE_PKG.resetAPflags(l_report_header_id);

    ------------------------------------------------------------
    l_debug_info := 'Set which process to start from';
    ------------------------------------------------------------
    -- Indicate which process to start from 
    -- (skip ServerValidate, Manager Approval)
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'START_FROM_PROCESS',
			      C_START_FROM_SERVER_VALIDATION);

    -- Reset the attributes which will not be set by code to initialize a
    -- process
    ----------------------------------------------------------
    l_debug_info := 'Reset attribute';
    ----------------------------------------------------------
    ResetAttrValues(p_item_type, p_item_key, p_actid);
  
    ----------------------------------------------------------
    l_debug_info := 'Reset Receipt Verified Flag to N';
    ----------------------------------------------------------
    -- Bug 4094871
    begin
      update ap_expense_report_lines
      set    receipt_verified_flag = l_No
      where  report_header_id = l_report_header_id;
    exception
      when others then null;
    end;

    -----------------------------------------------
    l_debug_info := 'Raise Receipts Aborted Event';
    -----------------------------------------------
    AP_WEB_RECEIPTS_WF.RaiseAbortedEvent(l_report_header_id);

    -----------------------------------------------------
    l_debug_info := 'After Raise Receipts Aborted Event';
    -----------------------------------------------------
    p_result := 'COMPLETE:Y';
  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetRejectStatusAndResetAttr');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetRejectStatusAndResetAttr',

                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    RAISE;

END SetRejectStatusAndResetAttr;

----------------------------------------------------------------------
PROCEDURE DeleteExpenseReport(p_item_type	IN VARCHAR2,
		   	      p_item_key	IN VARCHAR2,
		   	      p_actid		IN NUMBER,
		   	      p_funmode		IN VARCHAR2,
		   	      p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start DeleteExpenseReport');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    DeleteExpReportFromAPTables(l_report_header_id);
    
    AP_WEB_DB_VIOLATIONS_PKG.deleteViolationEntry(l_report_header_id);

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end DeleteExpenseReport');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'DeleteExpenseReport', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END DeleteExpenseReport;

----------------------------------------------------------------
PROCEDURE StartAPApprvlSubProcess(p_item_type	IN VARCHAR2,
		   	      	  p_item_key	IN VARCHAR2,
		   	      	  p_actid	IN NUMBER,
		   	      	  p_funmode	IN VARCHAR2,
		   	      	  p_result OUT NOCOPY VARCHAR2) IS
-----------------------------------------------------------------
  l_item_key			VARCHAR2(100);
  l_preparer_id			NUMBER;
  l_preparer_name		wf_users.name%type;
  l_preparer_display_name	wf_users.display_name%type;
  l_employee_id                 NUMBER;
  l_employee_name               wf_users.name%type;
  l_employee_display_name       wf_users.display_name%type;
  l_report_header_id		NUMBER;
  l_document_number		VARCHAR2(50);
  l_emp_cost_center		VARCHAR2(240);
  l_doc_cost_center		VARCHAR2(240);
  l_total			NUMBER;
  l_payment_due			VARCHAR2(10) := C_IndividualPay;
  l_currency			VARCHAR2(25);
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start StartAPApprvlSubProcess');

  ------------------------------------------------------------
  l_debug_info := 'Retrieve New Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						    p_item_key,
						    'NEW_EXPENSE_REPORT_ID');

  --------------------------------------------------------------
  l_debug_info := 'Retrieve New Document Number Item Attribute';
  ---------------------------------------------------------------
  l_document_number := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'NEW_DOCUMENT_NUMBER');


  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Employee Cost Center Item Attribute';
  ----------------------------------------------------------------
  l_emp_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'EMP_COST_CENTER');

  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Document Cost Center Item Attribute';
  ----------------------------------------------------------------
  l_doc_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'DOC_COST_CENTER');

  -----------------------------------------------------
  l_debug_info := 'Retrieve New Total Item Attribute';
  -----------------------------------------------------
  l_total := WF_ENGINE.GetItemAttrNumber(p_item_type,
					 p_item_key,
					 'NEW_TOTAL');

  -----------------------------------------------------
  l_debug_info := 'Retrieve Currency Item Attribute';
  -----------------------------------------------------
  l_currency := WF_ENGINE.GetItemAttrText(p_item_type,
			      		  p_item_key,
		              		  'CURRENCY');

  --------------------------------
  l_debug_info := 'Set item key';
  --------------------------------
  l_item_key := to_char(l_report_header_id);


  -------------------------------------------------------
  l_debug_info := 'Retrieve Preparer_ID Item Attribute';
  -------------------------------------------------------
  l_preparer_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					       p_item_key,
					       'PREPARER_ID');

  -------------------------------------------------------
  l_debug_info := 'Retrieve Employee_ID Item Attribute';
  -------------------------------------------------------
  l_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'EMPLOYEE_ID'); 

  -------------------------------------------------------
  l_debug_info := 'Retrieve CC Payment Due From Item Attribute';
  -------------------------------------------------------
  l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,
                                               p_item_key,
                                               'PAYMENT_DUE_FROM'); 

  -------------------------------------------------
  l_debug_info := 'Create AP Approval Subprocess';
  -------------------------------------------------
  WF_ENGINE.CreateProcess(p_item_type,
			  l_item_key,
			  'AP_EXPENSE_REPORT_PROCESS');

  --------------------------------------------------------
  l_debug_info := 'Set Expense_Report_ID Item Attribute';
  --------------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'EXPENSE_REPORT_ID',
			      l_report_header_id);

  ------------------------------------------------------
  l_debug_info := 'Set Document_Number Item Attribute';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'DOCUMENT_NUMBER',
			    l_document_number);

  ----------------------------------------------------------
  l_debug_info := 'Get Preparer Name Info For Preparer_Id';
  ----------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
			   l_preparer_id,
			   l_preparer_name,
			   l_preparer_display_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_ID',
			    l_preparer_id);

  ----------------------------------------------------------
  l_debug_info := 'Set Preparer Name Info Item Attributes';
  ----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_NAME',
			    l_preparer_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_DISPLAY_NAME',
			    l_preparer_display_name);

  ----------------------------------------------------------
  l_debug_info := 'Get Employee Name Info For Employee_Id';
  ----------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
                           l_employee_id,
                           l_employee_name,
                           l_employee_display_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_ID',
                            l_employee_id);              

  ----------------------------------------------------------
  l_debug_info := 'Set Employee Name Info Item Attributes';
  ----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_NAME',
                            l_employee_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_DISPLAY_NAME',
                            l_employee_display_name);
                                                               
  -------------------------------------------------
  l_debug_info := 'Set Total Item Attribute';
  -------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'TOTAL',
			      l_total);

  -----------------------------------------------------------------
  l_debug_info := 'Set New Adjusted Display_Total Item Attribute';
  -----------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
		            'DISPLAY_TOTAL',
                            to_char(l_total,FND_CURRENCY.Get_Format_Mask(l_currency,22)) || ' ' || l_currency);

  ----------------------------------------------
  l_debug_info := 'Set Currency Item Attribute';
  -----------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
		            'CURRENCY',
			    l_currency);


  -----------------------------------------------------------
  l_debug_info := 'Set Document Cost Center Item Attribute';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'DOC_COST_CENTER',
			    l_doc_cost_center);

  -----------------------------------------------------------
  l_debug_info := 'Set Employee Cost Center Item Attribute';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'EMP_COST_CENTER',
			    l_emp_cost_center);

  --------------------------------------------------------------
  l_debug_info := 'Set CC Payment Due From Item Attribute';
  --------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                              l_item_key,
                              'PAYMENT_DUE_FROM',
                              l_payment_due);      

  -----------------------------------------------------------
  l_debug_info := 'Skip server validation and manager approval';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'START_FROM_PROCESS',
			    C_START_FROM_AP_APPROVAL);

  -------------------------------------------------
  l_debug_info := 'Start AP Approval Sub Process';
  -------------------------------------------------
  WF_ENGINE.StartProcess(p_item_type,
			 l_item_key);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end StartAPApprvlSubProcess');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'StartAPApprvlSubProcess', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END StartAPApprvlSubProcess;

----------------------------------------------------------------------
PROCEDURE StartFromAPApproval(p_item_type	IN VARCHAR2,
		   	      p_item_key	IN VARCHAR2,
		   	      p_actid		IN NUMBER,
		   	      p_funmode		IN VARCHAR2,
		   	      p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_debug_info			VARCHAR2(200);
  l_No                     VARCHAR2(1) := 'N';
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start StartFromAPApproval');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieve New_Expense_Report_ID Item Attribute';
    ----------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						    p_item_key,
						    'EXPENSE_REPORT_ID');


    --------------------------------------------------------------
    l_debug_info := 'Update all expense lines as receipt missing';
    --------------------------------------------------------------
    -- Bug 884248
    IF (NOT AP_WEB_DB_EXPRPT_PKG.SetWkflApprvdFlag2(l_report_header_id)) THEN
	NULL;
    END IF;

    ----------------------------------------------------------
    l_debug_info := 'Update Receipts Status to Required if Pending Resolution';
    ----------------------------------------------------------
    update ap_expense_report_headers
    set    receipts_status = 'REQUIRED'
    where  report_header_id = l_report_header_id
    and    receipts_status = 'RESOLUTN';

    ----------------------------------------------------------
    l_debug_info := 'Reset Receipt Missing Flag';
    ----------------------------------------------------------
    -- Bug 4075372
    update ap_expense_report_lines
    set    receipt_missing_flag = l_No
    where  report_header_id = l_report_header_id;

    ------------------------------------------------------------
    l_debug_info := 'Set which process to start from';
    ------------------------------------------------------------
    -- Indicate which process to start from 
    -- (skip ServerValidate, Manager Approval)
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'START_FROM_PROCESS',
			      C_START_FROM_AP_APPROVAL);
    
  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end StartFromAPApproval');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'StartFromAPApproval', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END StartFromAPApproval;

----------------------------------------------------------------------
PROCEDURE StartFromManagerApproval(p_item_type	IN VARCHAR2,
		   	           p_item_key	IN VARCHAR2,
		   	           p_actid	IN NUMBER,
		   	           p_funmode	IN VARCHAR2,
		   	           p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start StartFromManagerApproval');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieve New_Expense_Report_ID Item Attribute';
    ----------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						    p_item_key,
						    'EXPENSE_REPORT_ID');


    --------------------------------------------------------------
    l_debug_info := 'Update all expense lines as receipt missing';
    --------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPLINE_PKG.SetReceiptMissing(l_report_header_id,	
					'Y')) THEN
	NULL;
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Set which process to start from';
    ------------------------------------------------------------
    -- Indicate which process to start from 
    -- (skip ServerValidate, Manager Approval)
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'START_FROM_PROCESS',
			      C_START_FROM_MANAGER_APPROVAL);

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end StartFromManagerApproval');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'StartFromManagerApproval', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END StartFromManagerApproval;


----------------------------------------------------------------------
PROCEDURE CheckIfShortPaid(p_item_type	IN VARCHAR2,
		   	         p_item_key	IN VARCHAR2,
		   	         p_actid		IN NUMBER,
		   	         p_funmode	IN VARCHAR2,
		   	         p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_orig_expense_report_num	VARCHAR2(50);
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CheckIfShortPaid');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieve ShortPay_Flag Item Attribute';
    ----------------------------------------------------------------
    l_orig_expense_report_num := WF_ENGINE.GetItemAttrText(p_item_type,
						      p_item_key,
						      'ORIG_EXPENSE_REPORT_NUM');

    IF (l_orig_expense_report_num IS NOT NULL) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CheckIfShortPaid');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CheckIfShortPaid', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END CheckIfShortPaid;



-----------------------------------------------------------------------------
PROCEDURE BuildBothpayExpReport(p_item_type	IN VARCHAR2,
				p_item_key	IN VARCHAR2,
				p_actid		IN NUMBER,
		       		p_funmode	IN VARCHAR2,
		       		p_result OUT NOCOPY VARCHAR2)
------------------------------------------------------------------------------
IS
  l_report_header_id        AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_total	            AP_WEB_DB_EXPRPT_PKG.expHdr_total := NULL;
  l_new_report_id    	    AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_document_number         AP_WEB_DB_EXPRPT_PKG.expHdr_invNum;
  l_description	            AP_WEB_DB_EXPRPT_PKG.expHdr_description := NULL;
  l_vendor_id 	            AP_WEB_DB_CCARD_PKG.cardProgs_vendorID := NULL;
  l_vendor_site_id          AP_WEB_DB_CCARD_PKG.cardProgs_vendorSiteID := NULL;
  l_ccard_amt	            AP_WEB_DB_EXPRPT_PKG.expHdr_amtDueCcardCompany := 0;
  l_XpenseRec		    AP_WEB_DB_EXPRPT_PKG.XpenseInfoRec;
  l_accts_pay_comb_id	    AP_WEB_DB_EXPRPT_PKG.expHdr_acctsPayCodeCombID := NULL;
  l_debug_info		    VARCHAR2(2000);
  l_ccard_exists	    BOOLEAN := TRUE;
  l_report_submitted_date   DATE;
  l_org_id                  NUMBER;
  l_holds_setup             VARCHAR2(2);
  l_expense_status_code     VARCHAR2(30)    := NULL;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start BuildBothpayExpReport');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						     'EXPENSE_REPORT_ID');
 
    -------------------------------------------------------------------------
    l_debug_info := 'Retrieve and create new Document Number Item Attribute';
    -------------------------------------------------------------------------
    l_document_number := WF_ENGINE.GetItemAttrText(p_item_type,
    						 p_item_key,
    						 'DOCUMENT_NUMBER') || '.1';


    -----------------------------------------------------------------
    l_debug_info := 'Retrieve Credit Card New Expense Report Id';
    -----------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.GetNextExpReportID(l_new_report_id) ) THEN
	l_new_report_id := NULL;
    END IF;
    
    
    -------------------------------------------------------------------
    l_debug_info := 'Obtain the card number and the full name and the
    		vendor information for the new expense report';
    --------------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.GetExpReportInfo(l_report_header_id,
    	 			l_description, l_ccard_amt, l_total)) THEN
  	   l_description := NULL;
	   l_total := 0;
	   l_ccard_amt := 0;
           l_ccard_exists := FALSE;
     END IF;  
 
     -------------------------------------------------------------------
     l_debug_info := 'Obtain the Vendor ID item attribute';
     --------------------------------------------------------------------
      l_vendor_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						 p_item_key,
						 'VENDOR_ID');
  
 
     -------------------------------------------------------------------
     l_debug_info := 'Obtain the Vendor Site ID item attribute';
     --------------------------------------------------------------------
     l_vendor_site_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						     p_item_key,
						     'VENDOR_SITE_ID');

  /* Bug2610233 : Replacing l_ccard_amt check with l_ccard_exists check.
     IF (l_ccard_amt <> 0) THEN */

     IF (l_ccard_exists = TRUE) THEN
      	----------------------------------------------------------------------
      	l_debug_info := 'Get the accts pay code combination id from vendors';
      	----------------------------------------------------------------------
	IF (NOT AP_WEB_DB_AP_INT_PKG.GetVendorSitesCodeCombID(l_vendor_site_id,
							   l_accts_pay_comb_id) OR
	    l_accts_pay_comb_id = NULL) THEN
	   IF (NOT AP_WEB_DB_AP_INT_PKG.GetVendorCodeCombID(l_vendor_id,
							   l_accts_pay_comb_id)) THEN
	   	l_accts_pay_comb_id := NULL;
	   END IF;
	END IF;

 
  /* Bug2610233 : Replacing l_ccard_amt check with l_ccard_exists check.
        IF (l_total - l_ccard_amt <> 0) THEN
  */
           -------------------------------------------------------------------
           l_debug_info := 'Create new expense report by creating new record in 
		     ap_expense_report_headers, with same info as old 
		     expense report except new id, doc number, total, 
                     bothpay parent id, paid on behalf employee id, description,
		     and amt due ccard company';
           --------------------------------------------------------------------
  	   l_XpenseRec.report_header_id	:= l_new_report_id;
  	   l_XpenseRec.document_number	:= l_document_number;
  	   l_XpenseRec.employee_id 	:= -1;   --will become NULL	
  	   l_XpenseRec.org_id		:= NULL;
  	   l_XpenseRec.vouchno		:= 0;
  	   l_XpenseRec.total		:= -1;
  	   l_XpenseRec.vendor_id	:= l_vendor_id;		
  	   l_XpenseRec.vendor_site_id	:= l_vendor_site_id;	
  	   l_XpenseRec.amt_due_employee	:= 0;
  	   l_XpenseRec.amt_due_ccard	:= NULL;		
  	   l_XpenseRec.description 	:= l_description;  		
  	   l_XpenseRec.preparer_id	:= NULL; 			
  	   l_XpenseRec.last_update_login:= NULL; 	
  	   l_XpenseRec.last_updated_by	:= NULL; 		
  	   l_XpenseRec.workflow_flag	:= NULL; 		
  	   l_XpenseRec.expense_check_address_flag := NULL;	
  	   l_XpenseRec.bothpay_report_header_id   := l_report_header_id;
  	   l_XpenseRec.shortpay_parent_id := NULL;
  	   l_XpenseRec.behalf_employee_id := -1;	
  	   l_XpenseRec.approver_id	:= NULL;		
  	   l_XpenseRec.week_end_date	:= NULL;		
  	   l_XpenseRec.set_of_books_id	:= NULL;	
  	   l_XpenseRec.source           := 'Both Pay';
	   l_XpenseRec.accts_pay_comb_id := l_accts_pay_comb_id;		

           ----------------------------------------------------------
           l_debug_info := 'Get Expense Report date';
           ----------------------------------------------------------
           select report_submitted_date
           into   l_report_submitted_date
           from   ap_expense_report_headers
           where  report_header_id = l_report_header_id;

           ------------------------------------------------------------
           l_debug_info := 'Retrieve ORG_ID Item Attribute';
           ------------------------------------------------------------
           l_org_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                   p_item_key,
                                                   'ORG_ID');


           l_holds_setup := AP_WEB_HOLDS_WF.IsHoldsRuleSetup(l_org_id,
                                                         l_report_submitted_date);

           IF (l_holds_setup = 'Y') THEN
               l_expense_status_code := AP_WEB_RECEIPTS_WF.C_PENDING_HOLDS;
           ELSE
               l_expense_status_code := 'INVOICED';
           END IF;

           l_XpenseRec.expense_status_code := l_expense_status_code;

	   IF (NOT AP_WEB_DB_EXPRPT_PKG.InsertReportHeaderLikeExisting(    
      					l_report_header_id, l_XpenseRec)) THEN
		NULL;
	   END IF;

           ------------------------------------------------------------------
           l_debug_info := 'Insert the lines for the credit card company into 
	   	         ap_expense_report_lines with new report_header_id';
    	   ------------------------------------------------------------------
    	   IF (NOT AP_WEB_DB_EXPLINE_PKG.AddCCReportLines(l_report_header_id, 
				l_new_report_id)) THEN
	   	NULL;
	   END IF; 

      	-----------------------------------------------------------------------
      	l_debug_info := 'Set the Bothpay Document Number Item Attribute with
			the new expense report document number';
      	-----------------------------------------------------------------------
        WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'BOTHPAY_DOC_NUM',
				l_document_number);

        --------------------------------------------------------------------
        l_debug_info := 'Copy Notes from original report';
        --------------------------------------------------------------------
        AP_WEB_NOTES_PKG.CopyERNotes (
          p_src_report_header_id   => l_report_header_id,
          p_tgt_report_header_id   => l_new_report_id
        );

   END IF;
    
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end BuildBothpayExpReport');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'BuildBothpayReport', 
                     null, to_char(l_report_header_id) || ' ' || to_char(l_new_report_id), to_char(p_actid), l_debug_info);
    raise;
END BuildBothpayExpReport;


----------------------------------------------------------------------
PROCEDURE CheckIfBothpay(p_item_type	IN VARCHAR2,
		   	   p_item_key	IN VARCHAR2,
		   	   p_actid	IN NUMBER,
		   	   p_funmode	IN VARCHAR2,
		   	   p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_payment			VARCHAR2(10);
  l_debug_info			VARCHAR2(200);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CheckIfBothpay');

  IF (p_funmode = 'RUN') THEN


    ----------------------------------------------------------------
    l_debug_info := 'Retrieve Profile Option Payment Due From';
    ----------------------------------------------------------------
    l_payment :=  WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

    IF (l_payment = C_BothPay) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CheckIfBothpay');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CheckIfBothpay', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END CheckIfBothpay;

----------------------------------------------------------------------
PROCEDURE FindVendor(p_item_type IN VARCHAR2,
		     p_item_key	 IN VARCHAR2,
		     p_actid	 IN NUMBER,
		     p_funmode	 IN VARCHAR2,
		     p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info			VARCHAR2(200);
  l_vendor_id			AP_WEB_DB_CCARD_PKG.cardProgs_vendorID;
  l_vendor_site_id 		AP_WEB_DB_CCARD_PKG.cardProgs_vendorID;
  l_report_header_id 		AP_WEB_DB_CCARD_PKG.ccTrxn_headerID;
  l_crd_card_count 		NUMBER := 0;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start FindVendor');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						     'EXPENSE_REPORT_ID');

    ----------------------------------------------------------------
    l_debug_info := 'Retrieve Vendor IDs from the table';
    ------------------------------------------------------------
    IF (NOT AP_WEB_DB_CCARD_PKG.GetVendorIDs(l_report_header_id, l_vendor_id,
	      			l_vendor_site_id)) THEN
  	   l_vendor_id := NULL;
	   l_vendor_site_id := NULL;
    END IF;  
	 
    ----------------------------------------------------------------
    l_debug_info := 'Set the Vendor ID Attribute';
    ----------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
				p_item_key,
				'VENDOR_ID',
				l_vendor_id);
    
   ----------------------------------------------------------------
   l_debug_info := 'Set the Vendor Site ID Attribute';
   ----------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
				p_item_key,
				'VENDOR_SITE_ID',
				l_vendor_site_id);
    IF (NOT AP_WEB_DB_EXPLINE_PKG.GetNumCCLinesIncluded(l_report_header_id,
    					l_crd_card_count)) THEN
	l_crd_card_count := 0;
    END IF;

    IF ( (l_vendor_id IS NULL OR l_vendor_site_id IS NULL)
	AND nvl(l_crd_card_count,0) >0 ) THEN
      ----------------------------------------------------------------
      l_debug_info := 'Get the FND message for this missing vendor';
      ----------------------------------------------------------------
      FND_MESSAGE.Set_Name('SQLAP','AP_WEB_CCARD_NO_VENDOR_INFO');

      ----------------------------------------------------------------
      l_debug_info := 'Set the Error Message Attribute';
      ----------------------------------------------------------------
      WF_ENGINE.SetItemAttrText(p_item_type,
			        p_item_key,
			        'ERROR_MESSAGE',
			        FND_MESSAGE.Get);
      p_result := 'COMPLETE:N';
    ELSE
      p_result := 'COMPLETE:Y';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end FindVendor');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'FindVendor', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END FindVendor;


----------------------------------------------------------------------
PROCEDURE CheckIfSplit(p_item_type	IN VARCHAR2,
		   	   p_item_key	IN VARCHAR2,
		   	   p_actid	IN NUMBER,
		   	   p_funmode	IN VARCHAR2,
		   	   p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_doc_num			VARCHAR2(50);
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CheckIfSplit');

  IF (p_funmode = 'RUN') THEN

   /* Bug 4096880 : The Bothpay split notification should not be
    *               sent from OIE.J onwards. Hence, hard-code the
    *               return value as 'N'.
    */
    
    p_result := 'COMPLETE:N';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CheckIfSplit');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CheckIfSplit', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END CheckIfSplit;

----------------------------------------------------------------
PROCEDURE StartPolicyShortPayProcess(p_item_type IN VARCHAR2,
		   	      	     p_item_key	 IN VARCHAR2,
		   	      	     p_actid	 IN NUMBER,
		   	      	     p_funmode	 IN VARCHAR2,
		   	      	     p_result	 OUT NOCOPY VARCHAR2) IS
-----------------------------------------------------------------
  l_item_type   VARCHAR2(100)   := 'APEXP';             -- Bug 996020
  l_item_key			VARCHAR2(100);
  l_preparer_id			NUMBER;
  l_preparer_name		wf_users.name%type;
  l_preparer_display_name	wf_users.display_name%type;
  l_employee_id                 NUMBER;
  l_employee_name               wf_users.name%type;
  l_employee_display_name       wf_users.display_name%type;
  l_orig_expense_report_num	VARCHAR2(50);
  l_report_header_id		NUMBER;
  l_document_number		VARCHAR2(50);
  l_emp_cost_center		VARCHAR2(240);
  l_doc_cost_center		VARCHAR2(240);
  l_total			NUMBER;
  l_credit_total		NUMBER;
  l_new_exp_total		NUMBER;
  l_currency			VARCHAR2(25);
  l_url				VARCHAR2(1000);
  l_debug_info			VARCHAR2(200);
  l_payment_due			VARCHAR2(10) := C_IndividualPay;

  l_purpose            		VARCHAR2(2400);
  l_approver_id			NUMBER; 
  l_approver_name		wf_users.name%type;
  l_approver_display_name  	wf_users.display_name%type;
  l_submit_from_oie		VARCHAR2(1);

  C_CreditLineVersion           CONSTANT NUMBER := 1;
  C_WF_Version			NUMBER          := 0;

  -- for bug 1652106
  l_n_org_id			NUMBER;
  l_n_user_id 			Number;
  l_n_resp_id 			Number;
  l_n_resp_appl_id 		Number;

  -- for bug 2069362
  l_AMEEnabled			VARCHAR2(1);

  -- jrautiai ADJ Fix
  l_mess Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start StartPolicyShortPayProcess');

  -----------------------------------------------------
  l_debug_info := 'Get Workflow Version Number 4';
  -----------------------------------------------------
  C_WF_Version := GetFlowVersion(p_item_type, p_item_key);

  ----------------------------------
  l_debug_info := 'Set Org Context';
  ----------------------------------
  -- for bug 1652106
  begin 

      l_n_org_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					        p_item_key,
					        'ORG_ID');
  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    -- ORG_ID item attribute doesn't exist, need to add it
	    wf_engine.AddItemAttr(p_item_type, p_item_key, 'ORG_ID');
	    -- get the org_id from header for old reports
	    IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(
				to_number(p_item_key),
				l_n_org_id) <> TRUE ) THEN
	    	l_n_org_id := NULL;
	    END IF;
	    WF_ENGINE.SetItemAttrNumber(p_item_type,
			    p_item_key,
			    'ORG_ID',
			    l_n_org_id);		
	  else
	    raise;
	  end if;

  end;


  ----------------------------------
  l_debug_info := 'Get User ID';
  ----------------------------------
  begin 
    l_n_user_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
  					       p_item_key,
  					       'USER_ID');
    l_n_resp_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
  	 				       p_item_key,
  					       'RESPONSIBILITY_ID');
    l_n_resp_appl_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
  				      		    p_item_key,
  						    'APPLICATION_ID');
  exception
  	when others then
  	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
  	    null;
  	  else
  	    raise;
  	  end if;
  end;

  ------------------------------------------------------------
  l_debug_info := 'Retrieve New Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						    p_item_key,
						    'POLICY_SHORTPAY_ID');

  --------------------------------------------------------------
  l_debug_info := 'Retrieve New Document Number Item Attribute';
  ---------------------------------------------------------------
  l_document_number := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'POLICY_SHORTPAY_DOC_NUM');

  --------------------------------------------------------------
  l_debug_info := 'Retrieve New Document Number Item Attribute';
  ---------------------------------------------------------------
  l_orig_expense_report_num := WF_ENGINE.GetItemAttrText(p_item_type,
						 			p_item_key,
						 			'DOCUMENT_NUMBER');


  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Employee Cost Center Item Attribute';
  ----------------------------------------------------------------
  l_emp_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'EMP_COST_CENTER');

  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Payment Due From Item Attribute';
  ----------------------------------------------------------------
  l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');


  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Document Cost Center Item Attribute';
  ----------------------------------------------------------------
  l_doc_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'DOC_COST_CENTER');

  -----------------------------------------------------
  l_debug_info := 'Retrieve New Total Item Attribute';
  -----------------------------------------------------
  l_total := WF_ENGINE.GetItemAttrNumber(p_item_type,
					 p_item_key,
					 'POLICY_SHORTPAY_TOTAL');

  l_new_exp_total := l_total;
  l_credit_total  := 0;

  -----------------------------------------------------
  l_debug_info := 'Retrieve Currency Item Attribute';
  -----------------------------------------------------
  l_currency := WF_ENGINE.GetItemAttrText(p_item_type,
			      		  p_item_key,
		              		  'CURRENCY');

  --------------------------------
  l_debug_info := 'Set item key';
  --------------------------------
  l_item_key := to_char(l_report_header_id);


  -------------------------------------------------------
  l_debug_info := 'Retrieve Preparer_ID Item Attribute';
  -------------------------------------------------------
  l_preparer_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					       p_item_key,
					       'PREPARER_ID');

  -------------------------------------------------------
  l_debug_info := 'Retrieve Employee_ID Item Attribute';
  -------------------------------------------------------
  l_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'EMPLOYEE_ID'); 

  ----------------------------------
  l_debug_info := 'Get AME_ENABLED';
  ----------------------------------
  l_AMEEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
  						 p_item_key,
  						 'AME_ENABLED');

  ----------------------------------
  l_debug_info := 'Get PURPOSE';
  ----------------------------------
  l_purpose := WF_ENGINE.GetItemAttrText(p_item_type,
  					 p_item_key,
  					 'PURPOSE');

  ------------------------------------------------------------
  l_debug_info := 'Get Approver Info';
  ------------------------------------------------------------
  l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'APPROVER_ID');

  l_approver_name := WF_ENGINE.GetItemAttrText(p_item_type,
                                               p_item_key,
                                               'APPROVER_NAME');

  l_approver_display_name := WF_ENGINE.GetItemAttrText(p_item_type,
                                                       p_item_key,
                                                       'APPROVER_DISPLAY_NAME');

  ----------------------------------
  l_debug_info := 'Get SUBMIT_FROM_OIE';
  ----------------------------------
  l_submit_from_oie := WF_ENGINE.GetItemAttrText(p_item_type,
  					 p_item_key,
  					 'SUBMIT_FROM_OIE');

  -------------------------------------------------
  l_debug_info := 'Create Policy Violation Shortpay Subprocess';
  -------------------------------------------------
  WF_ENGINE.CreateProcess(p_item_type,
			  l_item_key,
			  'POLICY_VIOLATION_PROCESS');

 /* Bug 2351528. Need to set the user_key for easier query */
    WF_ENGINE.SetItemUserKey(l_item_type,
                             l_item_key,
                             l_document_number);
                             
    ----------------------------------------------------
    l_debug_info := 'Set SUBMIT_FROM_OIE Item Attribute';
    ----------------------------------------------------
    WF_ENGINE.SetItemAttrText(l_item_type,
                             	l_item_key,
                              	'SUBMIT_FROM_OIE',
                             	l_submit_from_oie);

    ------------------------------------------------------
    l_debug_info := 'Set PURPOSE Item Attribute';
    ------------------------------------------------------
    WF_ENGINE.SetItemAttrText(l_item_type,
                              l_item_key,
                              'PURPOSE',
                              l_purpose);

    ------------------------------------------------------
    l_debug_info := 'Set Approver Info';
    ------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(l_item_type,
                                l_item_key,
                                'APPROVER_ID',
                                l_approver_id);

    WF_ENGINE.SetItemAttrText(l_item_type,
                              l_item_key,
                              'APPROVER_NAME',
                              l_approver_name);

    WF_ENGINE.SetItemAttrText(l_item_type,
                              l_item_key,
                              'APPROVER_DISPLAY_NAME',
                              l_approver_display_name);


    -- Bug 996020
    ------------------------------------------------------
    l_debug_info := 'Set LINE_TABLE Item Attribute';
    ------------------------------------------------------
    WF_ENGINE.SetItemAttrText(l_item_type,
                              l_item_key,
                              'LINE_TABLE',
                  'plsqlclob:AP_WEB_EXPENSE_WF.generateExpClobLines/'||l_item_type||':'||l_item_key);

     ------------------------------------------------------
    l_debug_info := 'Set EMP_LINE_TABLE Item Attribute';
    ------------------------------------------------------
    WF_ENGINE.SetItemAttrText(l_item_type,
                              l_item_key,
                              'EMP_LINE_TABLE',
                  'plsqlclob:AP_WEB_EXPENSE_WF.generateExpClobLines/'||l_item_type||':'||l_item_key || ':'|| C_EMP);

 --------------------------------------------------------
  l_debug_info := 'Set Expense_Report_ID Item Attribute';
  --------------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'EXPENSE_REPORT_ID',
			      l_report_header_id);

  ------------------------------------------------------
  l_debug_info := 'Set Document_Number Item Attribute';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'DOCUMENT_NUMBER',
			    l_document_number);

  ------------------------------------------------------
  l_debug_info := 'Set Document_Number Item Attribute';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'ORIG_EXPENSE_REPORT_NUM',
			    l_orig_expense_report_num);

  ----------------------------------------------------------
  l_debug_info := 'Get Preparer Name Info For Preparer_Id';
  ----------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
			   l_preparer_id,
			   l_preparer_name,
			   l_preparer_display_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_ID',
			    l_preparer_id);

  ----------------------------------------------------------
  l_debug_info := 'Set Preparer Name Info Item Attributes';
  ----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_NAME',
			    l_preparer_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_DISPLAY_NAME',
			    l_preparer_display_name);

  ----------------------------------------------------------
  l_debug_info := 'Set the Owner of Workflow Process.';
  ----------------------------------------------------------
  WF_ENGINE.SetItemOwner(p_item_type, l_item_key, l_preparer_name);

  ----------------------------------------------------------
  l_debug_info := 'Get Employee Name Info For Employee_Id';
  ----------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
                           l_employee_id,
                           l_employee_name,
                           l_employee_display_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_ID',
                            l_employee_id);              

  ----------------------------------------------------------
  l_debug_info := 'Set Employee Name Info Item Attributes';
  ----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_NAME',
                            l_employee_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_DISPLAY_NAME',
                            l_employee_display_name);
                                                               
  -------------------------------------------------
  l_debug_info := 'Set Total Item Attribute';
  -------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'TOTAL',
			      l_total);

  -----------------------------------------------------------------
  l_debug_info := 'Set New Adjusted Display_Total Item Attribute';
  -----------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
		            'DISPLAY_TOTAL',
                            to_char(l_total,FND_CURRENCY.Get_Format_Mask(l_currency,22)) || ' ' || l_currency);




  ---------------------------------------------------------------------------
  l_debug_info := 'Set Attribute value for Credit Total and New Expense Total';
  ---------------------------------------------------------------------------

  IF (C_WF_Version >= C_CreditLineVersion) THEN
    
     WF_ENGINE.SetItemAttrNumber(p_item_type,
				 l_item_key,
				 'POS_NEW_EXPENSE_TOTAL',
			         l_new_exp_total); 
     WF_ENGINE.SetItemAttrText(p_item_type,
 			       l_item_key,
		               'POS_NEW_EXPENSE_DISPLAY_TOTAL',
                               to_char(l_new_exp_total, FND_CURRENCY.Get_Format_Mask(l_currency,22)));

     WF_ENGINE.SetItemAttrNumber(p_item_type,
				 l_item_key,
			         'NEG_CREDIT_TOTAL',
			         l_credit_total); 
     WF_ENGINE.SetItemAttrText(p_item_type,
 			       l_item_key,
		               'NEG_CREDIT_DISPLAY_TOTAL',
                               to_char(l_credit_total, FND_CURRENCY.Get_Format_Mask(l_currency,22)));

     

  END IF;

  ----------------------------------------------
  l_debug_info := 'Set Currency Item Attribute';
  -----------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
		            'CURRENCY',
			    l_currency);


  -----------------------------------------------------------
  l_debug_info := 'Set Document Cost Center Item Attribute';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'DOC_COST_CENTER',
			    l_doc_cost_center);

  -----------------------------------------------------------
  l_debug_info := 'Set Employee Cost Center Item Attribute';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'EMP_COST_CENTER',
			    l_emp_cost_center);

  --------------------------------------------------------------
  l_debug_info := 'Set CC Payment Due From Item Attribute';
  --------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                              l_item_key,
                              'PAYMENT_DUE_FROM',
                              l_payment_due);      

  --------------------------------------------------------
  l_debug_info := 'Call JumpIntoFunction to retrieve URL';
  --------------------------------------------------------
  AP_WEB_INFRASTRUCTURE_PKG.JumpIntoFunction(l_report_header_id,
					'EXPENSE REPORT',
					l_url);

  -----------------------------------------------------
  l_debug_info := 'Set EXPENSE DETAILS Item Attribute';
  -----------------------------------------------------

  -- Be sure to clear these values.  If we are resubmitting, we don't want 
  -- the values from the previous process traversal to hang around.
  WF_ENGINE.SetItemAttrText(p_item_type,
			     l_item_key,
			     'EXPENSE_DETAILS',
			     l_url);

  -----------------------------------------------------
  l_debug_info := 'Set Org ID Item Attribute';
  -----------------------------------------------------
  begin 
     WF_ENGINE.SetItemAttrNumber(p_item_type,
			     l_item_key,
			     'ORG_ID',
			     l_n_org_id);
  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    -- ORG_ID item attribute doesn't exist, need to add it
	    wf_engine.AddItemAttr(p_item_type, l_item_key, 'ORG_ID');
	    -- get the org_id from header for old reports
	    WF_ENGINE.SetItemAttrNumber(p_item_type,
			    l_item_key,
			    'ORG_ID',
			    l_n_org_id);
	  else
	    raise;
	  end if;
  end;


  begin

    --------------------------------------------------------------
    l_debug_info := 'Set User_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	l_item_key,
                              	'USER_ID',
                              	l_n_user_id);


    --------------------------------------------------------------
    l_debug_info := 'Set Resp_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	l_item_key,
                              	'RESPONSIBILITY_ID',
                              	l_n_resp_id);

    --------------------------------------------------------------
    l_debug_info := 'Set Resp_Appl_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	l_item_key,
                              	'APPLICATION_ID',
                              	l_n_resp_appl_id);

  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
  end;

    --------------------------------------------------------------
    l_debug_info := 'Set AME_ENABLED value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
                              	l_item_key,
                              	'AME_ENABLED',
				l_AMEEnabled);

  /* jrautiai ADJ Fix Start */
  ----------------------------------------------------------------
  l_debug_info := 'Set #FROM_ROLE to AP';
  ----------------------------------------------------------------
  SetFromRoleAP(p_item_type, l_item_key, p_actid, p_funmode, p_result);
    
  FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_POLICY_NC_NOTE');
  
  FND_MESSAGE.Set_Token('ORIG_REPORT_NUMBER', l_orig_expense_report_num);
  l_mess := FND_MESSAGE.GET;

  ----------------------------------------------------------------
  l_debug_info := 'Set Policy Non-Compliance note';
  ----------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'WF_NOTE',
                            l_mess);

  /* jrautiai ADJ Fix End */

  -------------------------------------------------
  l_debug_info := 'Start Policy Violation Shortpay Process';
  -------------------------------------------------
  WF_ENGINE.StartProcess(p_item_type,
			 l_item_key);
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end StartPolicyShortPayProcess');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'StartPolicyShortPayProcess', 
                     p_item_type, l_item_key, to_char(p_actid), l_debug_info);
    raise;
END StartPolicyShortPayProcess;

----------------------------------------------------------------
PROCEDURE StartNoReceiptsShortPayProcess(p_item_type 	 IN VARCHAR2,
		   	      	        p_item_key	 IN VARCHAR2,
		   	      	        p_actid	 	 IN NUMBER,
		   	      	        p_funmode	 IN VARCHAR2,
		   	      	        p_result	 OUT NOCOPY VARCHAR2) IS
-----------------------------------------------------------------
  l_item_type   VARCHAR2(100)   := 'APEXP';             -- Bug 996020

  l_item_key			VARCHAR2(100);
  l_preparer_id			NUMBER;
  l_preparer_name		wf_users.name%type;
  l_preparer_display_name	wf_users.display_name%type;
  l_employee_id                 NUMBER;
  l_employee_name               wf_users.name%type;
  l_employee_display_name       wf_users.display_name%type;
  l_report_header_id		NUMBER;
  l_document_number		VARCHAR2(50);
  l_orig_expense_report_num	VARCHAR2(50);
  l_emp_cost_center		VARCHAR2(240);
  l_doc_cost_center		VARCHAR2(240);
  l_override_approver_id	AP_WEB_DB_EXPRPT_PKG.expHdr_overrideApprID;
  l_approver_name		wf_users.name%type;
  l_approver_display_name	wf_users.display_name%type;
  l_total			NUMBER;
  l_credit_total		NUMBER;
  l_new_exp_total		NUMBER;
  l_currency			VARCHAR2(25);
  l_url				VARCHAR2(1000);
  l_debug_info			VARCHAR2(200);
  V_IsSessionProjectEnabled     VARCHAR2(1);
  l_payment_due			VARCHAR2(10) := C_IndividualPay;

  l_purpose			VARCHAR2(2400);
  l_approver_id			NUMBER; 
  l_submit_from_oie		VARCHAR2(1);

  C_CreditLineVersion           CONSTANT NUMBER := 1;
  C_WF_Version			NUMBER          := 0;

  -- for bug 1652106
  l_n_org_id			NUMBER;
  l_n_user_id 			Number;
  l_n_resp_id 			Number;
  l_n_resp_appl_id 		Number;

  -- for bug 2069362
  l_AMEEnabled			VARCHAR2(1);
  
  -- jrautiai ADJ Fix
  l_mess Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start StartNoReceiptsShortPayProcess');

  -----------------------------------------------------
  l_debug_info := 'Get Workflow Version Number 5';
  -----------------------------------------------------
  C_WF_Version := GetFlowVersion(p_item_type, p_item_key);

  ------------------------------------------------------------
  l_debug_info := 'Retrieve New Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						    p_item_key,
						    'NO_RECEIPTS_SHORTPAY_ID');

  --------------------------------------------------------------
  l_debug_info := 'Retrieve New Document Number Item Attribute';
  ---------------------------------------------------------------
  l_document_number := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'NO_RECEIPTS_SHORTPAY_DOC_NUM');

  --------------------------------------------------------------
  l_debug_info := 'Retrieve New Document Number Item Attribute';
  ---------------------------------------------------------------
  l_orig_expense_report_num := WF_ENGINE.GetItemAttrText(p_item_type,
						 			p_item_key,
						 			'DOCUMENT_NUMBER');

  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Employee Cost Center Item Attribute';
  ----------------------------------------------------------------
  l_emp_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'EMP_COST_CENTER');

  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Document Cost Center Item Attribute';
  ----------------------------------------------------------------
  l_doc_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'DOC_COST_CENTER');

  -----------------------------------------------------
  l_debug_info := 'Retrieve New Total Item Attribute';
  -----------------------------------------------------
  l_total := WF_ENGINE.GetItemAttrNumber(p_item_type,
					 p_item_key,
					 'NO_RECEIPTS_SHORTPAY_TOTAL');

  l_new_exp_total := l_total;
  l_credit_total  := 0;

  -----------------------------------------------------
  l_debug_info := 'Retrieve Currency Item Attribute';
  -----------------------------------------------------
  l_currency := WF_ENGINE.GetItemAttrText(p_item_type,
			      		  p_item_key,
		              		  'CURRENCY');

  --------------------------------
  l_debug_info := 'Set item key';
  --------------------------------
  l_item_key := to_char(l_report_header_id);


  -------------------------------------------------------
  l_debug_info := 'Retrieve Preparer_ID Item Attribute';
  -------------------------------------------------------
  l_preparer_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					       p_item_key,
					       'PREPARER_ID');

  -------------------------------------------------------
  l_debug_info := 'Retrieve Employee_ID Item Attribute';
  -------------------------------------------------------
  l_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'EMPLOYEE_ID'); 

  ---------------------------------------------------------
  l_debug_info := 'Retrieve Payment Due From System Option';
  ---------------------------------------------------------
  l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

  ------------------------------------------------------------
  l_debug_info := 'Determine whether session is project enabled';
  ------------------------------------------------------------
  IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_11_0_3Version) THEN
    V_IsSessionProjectEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
                                                p_item_key,
                                                'EMPLOYEE_PROJECT_ENABLED');

  ELSE
    -- In previous versions we called 
    -- AP_WEB_PROJECT_PKG.IsSessionProjectEnabled, but that would not work
    -- without having ValidateSession called.  So, for older versions we
    -- will assume that the session is project enabled.  Since the receipts
    -- will not have any project information, the patc call will not be done.
    V_IsSessionProjectEnabled := 'Y';
  END IF;


  ----------------------------------
  l_debug_info := 'Set Org Context';
  ----------------------------------
  -- for bug 1652106
  begin 

      l_n_org_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					        p_item_key,
					        'ORG_ID');
  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    -- ORG_ID item attribute doesn't exist, need to add it
	    wf_engine.AddItemAttr(p_item_type, p_item_key, 'ORG_ID');
	    -- get the org_id from header for old reports
	    IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(
				to_number(p_item_key),
				l_n_org_id) <> TRUE ) THEN
	    	l_n_org_id := NULL;
	    END IF;
	    WF_ENGINE.SetItemAttrText(p_item_type,
			    p_item_key,
			    'ORG_ID',
			    l_n_org_id);
	  else
	    raise;
	  end if;

  end;

  ----------------------------------
  l_debug_info := 'Get User ID';
  ----------------------------------
  begin 
     l_n_user_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
  						 p_item_key,
  						 'USER_ID');
     l_n_resp_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
  						 p_item_key,
  						 'RESPONSIBILITY_ID');
     l_n_resp_appl_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
  				      		    p_item_key,
  						    'APPLICATION_ID');
  exception
  	when others then
  	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
  	    null;
  	  else
  	    raise;
  	  end if;
  end;

  ----------------------------------
  l_debug_info := 'Get AME_ENABLED';
  ----------------------------------
  l_AMEEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
  						 p_item_key,
  						 'AME_ENABLED');

  ----------------------------------
  l_debug_info := 'Get PURPOSE';
  ----------------------------------
  l_purpose := WF_ENGINE.GetItemAttrText(p_item_type,
                                         p_item_key,
                                         'PURPOSE');

  ------------------------------------------------------------
  l_debug_info := 'Get Approver Info';
  ------------------------------------------------------------
  l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'APPROVER_ID');

  l_approver_name := WF_ENGINE.GetItemAttrText(p_item_type,
                                               p_item_key,
                                               'APPROVER_NAME');

  l_approver_display_name := WF_ENGINE.GetItemAttrText(p_item_type,
                                                       p_item_key,
                                                       'APPROVER_DISPLAY_NAME');

  ----------------------------------
  l_debug_info := 'Get SUBMIT_FROM_OIE';
  ----------------------------------
  l_submit_from_oie := WF_ENGINE.GetItemAttrText(p_item_type,
  					 p_item_key,
  					 'SUBMIT_FROM_OIE');

  -------------------------------------------------
  l_debug_info := 'Create Missing Receipts Shortpay Subprocess';
  -------------------------------------------------
  WF_ENGINE.CreateProcess(p_item_type,
			  l_item_key,
			  'NO_RECEIPTS_SHORTPAY_PROCESS');

 /* Bug 2351528. Need to set the user_key for easier query */
    WF_ENGINE.SetItemUserKey(l_item_type,
                             l_item_key,
                             l_document_number);
                             
  ----------------------------------------------------
  l_debug_info := 'Set SUBMIT_FROM_OIE Item Attribute';
  ----------------------------------------------------
  WF_ENGINE.SetItemAttrText(l_item_type,
                            l_item_key,
                            'SUBMIT_FROM_OIE',
                            l_submit_from_oie);

  ------------------------------------------------------
  l_debug_info := 'Set PURPOSE Item Attribute';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrText(l_item_type,
                            l_item_key,
                            'PURPOSE',
                 	    l_purpose);

  ------------------------------------------------------
  l_debug_info := 'Set Approver Info';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(l_item_type,
                              l_item_key,
                              'APPROVER_ID',
                              l_approver_id);

  WF_ENGINE.SetItemAttrText(l_item_type,
                            l_item_key,
                            'APPROVER_NAME',
                            l_approver_name);

  WF_ENGINE.SetItemAttrText(l_item_type,
                            l_item_key,
                            'APPROVER_DISPLAY_NAME',
                            l_approver_display_name);

  -- Bug 996020
  ------------------------------------------------------
  l_debug_info := 'Set LINE_TABLE Item Attribute';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrText(l_item_type,
                              l_item_key,
                              'LINE_TABLE',
                  'plsqlclob:AP_WEB_EXPENSE_WF.generateExpClobLines/'||l_item_type||':'||l_item_key);

  ------------------------------------------------------
  l_debug_info := 'Set EMP_LINE_TABLE Item Attribute';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrText(l_item_type,
                              l_item_key,
                              'EMP_LINE_TABLE',
                  'plsqlclob:AP_WEB_EXPENSE_WF.generateExpClobLines/'||l_item_type||':'||l_item_key || ':'||C_EMP);

  --------------------------------------------------------
  l_debug_info := 'Set Expense_Report_ID Item Attribute';
  --------------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'EXPENSE_REPORT_ID',
			      l_report_header_id);

  ------------------------------------------------------
  l_debug_info := 'Set Document_Number Item Attribute';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'DOCUMENT_NUMBER',
			    l_document_number);

 ------------------------------------------------------
  l_debug_info := 'Set Document_Number Item Attribute';
  ------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'ORIG_EXPENSE_REPORT_NUM',
			    l_orig_expense_report_num);

  ----------------------------------------------------------
  l_debug_info := 'Get Preparer Name Info For Preparer_Id';
  ----------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
			   l_preparer_id,
			   l_preparer_name,
			   l_preparer_display_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_ID',
			    l_preparer_id);

  ----------------------------------------------------------
  l_debug_info := 'Set Preparer Name Info Item Attributes';
  ----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_NAME',
			    l_preparer_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_DISPLAY_NAME',
			    l_preparer_display_name);

  ----------------------------------------------------------
  l_debug_info := 'Set the Owner of Workflow Process.';
  ----------------------------------------------------------
  WF_ENGINE.SetItemOwner(p_item_type, l_item_key, l_preparer_name);

  ----------------------------------------------------------
  l_debug_info := 'Get Employee Name Info For Employee_Id';
  ----------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
                           l_employee_id,
                           l_employee_name,
                           l_employee_display_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_ID',
                            l_employee_id);              

  ----------------------------------------------------------
  l_debug_info := 'Set Employee Name Info Item Attributes';
  ----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_NAME',
                            l_employee_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_DISPLAY_NAME',
                            l_employee_display_name);
                                                               
  -------------------------------------------------
  l_debug_info := 'Set Total Item Attribute';
  -------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'TOTAL',
			      l_total);

  -----------------------------------------------------------------
  l_debug_info := 'Set New Adjusted Display_Total Item Attribute';
  -----------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
		            'DISPLAY_TOTAL',
                            to_char(l_total,FND_CURRENCY.Get_Format_Mask(l_currency,22)) || ' ' || l_currency);

  --------------------------------------------------------------
  l_debug_info := 'Set CC Payment Due From Item Attribute';
  --------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                              l_item_key,
                              'PAYMENT_DUE_FROM',
                              l_payment_due);      

  ---------------------------------------------------------------------------
  l_debug_info := 'Set Attribute value for Credit Total and New Expense Total';
  ---------------------------------------------------------------------------

  IF (C_WF_Version >= C_CreditLineVersion) THEN

     WF_ENGINE.SetItemAttrNumber(p_item_type,
				 l_item_key,
				 'POS_NEW_EXPENSE_TOTAL',
			         l_new_exp_total); 
     WF_ENGINE.SetItemAttrText(p_item_type,
 			       l_item_key,
		               'POS_NEW_EXPENSE_DISPLAY_TOTAL',
                               to_char(l_new_exp_total, FND_CURRENCY.Get_Format_Mask(l_currency,22)));

     WF_ENGINE.SetItemAttrNumber(p_item_type,
				 l_item_key,
			         'NEG_CREDIT_TOTAL',
			         l_credit_total); 
     WF_ENGINE.SetItemAttrText(p_item_type,
 			       l_item_key,
		               'NEG_CREDIT_DISPLAY_TOTAL',
                               to_char(l_credit_total, FND_CURRENCY.Get_Format_Mask(l_currency,22)));
    
  END IF;

  ---------------------------------------------------------------------------
  l_debug_info := 'Set whether employee is project enabled';
  ---------------------------------------------------------------------------
  IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_11_0_3Version) THEN

     WF_ENGINE.SetItemAttrText(p_item_type,
 			       l_item_key,
		               'EMPLOYEE_PROJECT_ENABLED',
                               V_IsSessionProjectEnabled);
  END IF;


  ----------------------------------------------
  l_debug_info := 'Set Currency Item Attribute';
  -----------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
		            'CURRENCY',
			    l_currency);


  -----------------------------------------------------------
  l_debug_info := 'Set Document Cost Center Item Attribute';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'DOC_COST_CENTER',
			    l_doc_cost_center);

  -----------------------------------------------------------
  l_debug_info := 'Set Employee Cost Center Item Attribute';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'EMP_COST_CENTER',
			    l_emp_cost_center);

  --------------------------------------------------------
  l_debug_info := 'Call JumpIntoFunction to retrieve URL';
  --------------------------------------------------------
  AP_WEB_INFRASTRUCTURE_PKG.JumpIntoFunction(l_report_header_id,
					'EXPENSE REPORT',
					l_url);

  -----------------------------------------------------
  l_debug_info := 'Set EXPENSE DETAILS Item Attribute';
  -----------------------------------------------------

  -- Be sure to clear these values.  If we are resubmitting, we don't want 
  -- the values from the previous process traversal to hang around.
  WF_ENGINE.SetItemAttrText(p_item_type,
			     l_item_key,
			     'EXPENSE_DETAILS',
			     l_url);


  IF (AP_WEB_DB_EXPRPT_PKG.GetOverrideApproverID(to_number(l_item_key), 
			l_override_approver_id)) THEN

    WF_DIRECTORY.GetUserName('PER',
			     l_override_approver_id,
			     l_approver_name,
			     l_approver_display_name);

    WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'APPROVER_ID',
			      l_override_approver_id);

    WF_ENGINE.SetItemAttrText(p_item_type,
			      l_item_key,
			      'APPROVER_NAME',
			      l_approver_name);

    WF_ENGINE.SetItemAttrText(p_item_type,
			      l_item_key,
			      'APPROVER_DISPLAY_NAME',
			      l_approver_display_name);

  END IF;

  -----------------------------------------------------
  l_debug_info := 'Set Org ID Item Attribute';
  -----------------------------------------------------
  begin 
     WF_ENGINE.SetItemAttrNumber(p_item_type,
			     l_item_key,
			     'ORG_ID',
			     l_n_org_id);
  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    -- ORG_ID item attribute doesn't exist, need to add it
	    wf_engine.AddItemAttr(p_item_type, l_item_key, 'ORG_ID');
	    -- get the org_id from header for old reports
	    WF_ENGINE.SetItemAttrNumber(p_item_type,
			    l_item_key,
			    'ORG_ID',
			    l_n_org_id);
	  else
	    raise;
	  end if;
  end;

  begin

    --------------------------------------------------------------
    l_debug_info := 'Set User_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	l_item_key,
                              	'USER_ID',
                              	l_n_user_id);


    --------------------------------------------------------------
    l_debug_info := 'Set Resp_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	l_item_key,
                              	'RESPONSIBILITY_ID',
                              	l_n_resp_id);

    --------------------------------------------------------------
    l_debug_info := 'Set Resp_Appl_ID value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	l_item_key,
                              	'APPLICATION_ID',
                              	l_n_resp_appl_id);

  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
  end;

    --------------------------------------------------------------
    l_debug_info := 'Set AME_ENABLED value ';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
                              	l_item_key,
                              	'AME_ENABLED',
				l_AMEEnabled);

  /* jrautiai ADJ Fix Start */
  
  ----------------------------------------------------------------
  l_debug_info := 'Set #FROM_ROLE to AP';
  ----------------------------------------------------------------
  SetFromRoleAP(p_item_type, l_item_key, p_actid, p_funmode, p_result);
  
  FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_POLICY_MR_NOTE');
  
  FND_MESSAGE.Set_Token('ORIG_REPORT_NUMBER', l_orig_expense_report_num);
  l_mess := FND_MESSAGE.GET;

  ----------------------------------------------------------------
  l_debug_info := 'Set Missing receipts note';
  ----------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'WF_NOTE',
                            l_mess);

  /* jrautiai ADJ Fix End */

  -------------------------------------------------------
  l_debug_info := 'Start No Receipts Short Pay Process';
  -------------------------------------------------------
  WF_ENGINE.StartProcess(p_item_type,
			 l_item_key);


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end StartNoReceiptsShortPayProcess');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'StartNoReceiptsShortPayProcess', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END StartNoReceiptsShortPayProcess;

---------------------------------------------------------------------
PROCEDURE StartManagerApprvlSubProcess(p_item_type	IN VARCHAR2,
		   	      	       p_item_key	IN VARCHAR2,
		   	      	       p_actid		IN NUMBER,
		   	      	       p_funmode	IN VARCHAR2,
		   	      	       p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------------------
  l_item_key			VARCHAR2(100);
  l_preparer_id			NUMBER;
  l_preparer_name		wf_users.name%type;
  l_preparer_display_name	wf_users.display_name%type;
  l_employee_id                 NUMBER;
  l_employee_name               wf_users.name%type;
  l_employee_display_name       wf_users.display_name%type;
  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_document_number		VARCHAR2(50);
  l_total			NUMBER;
  l_emp_cost_center		VARCHAR2(240);
  l_doc_cost_center		VARCHAR2(240);
  l_currency			VARCHAR2(50);
  l_week_end_date               DATE;
  l_debug_info			VARCHAR2(200);
  l_payment_due			VARCHAR2(10) := C_IndividualPay;

  C_WF_VERSION                  NUMBER;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start StartManagerApprvlSubProcess');

  ----------------------------------------------------------------
  l_debug_info := 'Get the version of the workflow currently using';
  ----------------------------------------------------------------
  C_WF_VERSION := GetFlowVersion(p_item_type, p_item_key);

  ----------------------------------------------------------------
  l_debug_info := 'Retrieve New_Expense_Report_ID Item Attribute';
  ----------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						    p_item_key,
						    'NEW_EXPENSE_REPORT_ID');


  --------------------------------------------------------------
  l_debug_info := 'Update all expense lines as receipt missing';
  --------------------------------------------------------------
  IF (NOT AP_WEB_DB_EXPLINE_PKG.SetReceiptMissing(l_report_header_id,	
  					'Y')) THEN
      NULL;
  END IF;

  --------------------------------------------------------------
  l_debug_info := 'Retrieve New_Document_Number Item Attribute';
  --------------------------------------------------------------
  l_document_number := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'NEW_DOCUMENT_NUMBER');

  -----------------------------------------------------
  l_debug_info := 'Retrieve New_Total Item Attribute';
  -----------------------------------------------------
  l_total := WF_ENGINE.GetItemAttrNumber(p_item_type,
					 p_item_key,
					 'NEW_TOTAL');

  -----------------------------------------------------
  l_debug_info := 'Retrieve Currency Item Attribute';
  -----------------------------------------------------
  l_currency := WF_ENGINE.GetItemAttrText(p_item_type,
			      		  p_item_key,
		              		  'CURRENCY');

  --------------------------------
  l_debug_info := 'Set Item Key';
  --------------------------------
  l_item_key := to_char(l_report_header_id);

  -------------------------------------------------------
  l_debug_info := 'Retrieve Preparer_Id Item Attribute';
  -------------------------------------------------------
  l_preparer_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					       p_item_key,
					       'PREPARER_ID');

  -------------------------------------------------------
  l_debug_info := 'Retrieve Employee_Id Item Attribute';
  -------------------------------------------------------
  l_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'EMPLOYEE_ID');

  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Employee Cost Center Item Attribute';
  ----------------------------------------------------------------
  l_emp_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'EMP_COST_CENTER');

  ----------------------------------------------------------------
  l_debug_info := 'Retrieve Document Cost Center Item Attribute';
  ----------------------------------------------------------------
  l_doc_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'DOC_COST_CENTER');

  ---------------------------------------------------------
  l_debug_info := 'Retrieve Payment Due From System Option';
  ---------------------------------------------------------
  l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

  -----------------------------------------
  l_debug_info := 'Retrieve Week End Date';
  -----------------------------------------
  IF (C_WF_Version >= C_ProjectIntegrationVersion) THEN

    l_week_end_date := WF_ENGINE.GetItemAttrDate(p_item_type,
 	  				         p_item_key,
					         'WEEK_END_DATE');

  END IF;

  ------------------------------------------------------------
  l_debug_info := 'Create Approval Subprocess';
  ------------------------------------------------------------
  WF_ENGINE.CreateProcess(p_item_type,
			  l_item_key,
			  'AP_EXPENSE_REPORT_PROCESS');

  --------------------------------------------------------
  l_debug_info := 'Set Expense_Report_ID Item Attribute';
  --------------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'EXPENSE_REPORT_ID',
			      l_report_header_id);

  ----------------------------------------------------------
  l_debug_info := 'Set Document_Number Item Attribute';
  ----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			      l_item_key,
			      'DOCUMENT_NUMBER',
			      l_document_number);

  --------------------------------------------------------------------
  l_debug_info := 'Retrieve Preparer_Name Info for given preparer_id';
  --------------------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
			   l_preparer_id,
			   l_preparer_name,
			   l_preparer_display_name);

  --------------------------------------------------
  l_debug_info := 'Set Preparer_ID Item Attribute';
  --------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_ID',
			    l_preparer_id);  

  ---------------------------------------------------------
  l_debug_info := 'Set Preparer_Name Info Item Attributes';
  ---------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'PREPARER_NAME',
			    l_preparer_name);

  WF_ENGINE.SetItemAttrText(p_item_type,
			      l_item_key,
			      'PREPARER_DISPLAY_NAME',
			      l_preparer_display_name);

  --------------------------------------------------------------------
  l_debug_info := 'Retrieve Employee_Name Info for given Employee_id';
  --------------------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
                           l_employee_id,
                           l_employee_name,
                           l_employee_display_name);

  --------------------------------------------------
  l_debug_info := 'Set Employee_ID Item Attribute';
  --------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_ID',
                            l_employee_id);

  ---------------------------------------------------------
  l_debug_info := 'Set Employee_Name Info Item Attributes';
  ---------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                            l_item_key,
                            'EMPLOYEE_NAME',
                            l_employee_name);                  

  WF_ENGINE.SetItemAttrText(p_item_type,
                              l_item_key,
                              'EMPLOYEE_DISPLAY_NAME',
                              l_employee_display_name);
                                                            
  ------------------------------------------------------------
  l_debug_info := 'Set Total Item Attribute';
  ------------------------------------------------------------
  WF_ENGINE.SetItemAttrNumber(p_item_type,
			      l_item_key,
			      'TOTAL',
			      l_total);


  -----------------------------------------------------------------
  l_debug_info := 'Set New Adjusted Display_Total Item Attribute';
  -----------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
		            'DISPLAY_TOTAL',
                            to_char(l_total,FND_CURRENCY.Get_Format_Mask(l_currency,22)) || ' ' || l_currency);

  ----------------------------------------------
  l_debug_info := 'Set Currency Item Attribute';
  -----------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
		            'CURRENCY',
                            l_currency);


  -----------------------------------------------------------
  l_debug_info := 'Set Document Cost Center Item Attribute';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'DOC_COST_CENTER',
			    l_doc_cost_center);

  -----------------------------------------------------------
  l_debug_info := 'Set Employee Cost Center Item Attribute';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'EMP_COST_CENTER',
			    l_emp_cost_center);

  --------------------------------------------------------------
  l_debug_info := 'Set CC Payment Due From Item Attribute';
  --------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                              l_item_key,
                              'PAYMENT_DUE_FROM',
                              l_payment_due);      

  IF (C_WF_Version >= C_ProjectIntegrationVersion) THEN

    -------------------------------------------------
    l_debug_info := 'Set Week End Date used in determining PA auto approval';
    -------------------------------------------------
    WF_ENGINE.SetItemAttrDate(p_item_type,
			      l_item_key,
			      'WEEK_END_DATE',
			      l_week_end_date);

  END IF;

  -----------------------------------------------------------
  l_debug_info := 'Skip server validation';
  -----------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
			    l_item_key,
			    'START_FROM_PROCESS',
			    C_START_FROM_MANAGER_APPROVAL);

  ------------------------------------------------------
  l_debug_info := 'Start Manager Approval Sub Process';
  ------------------------------------------------------
  WF_ENGINE.StartProcess(p_item_type,
			 l_item_key);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end StartManagerApprvlSubProcess');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'StartManagerApprvlSubProcess', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END StartManagerApprvlSubProcess;

-------------------------------------------------------
PROCEDURE GetManager(p_employee_id 	IN  HR_EMPLOYEES_CURRENT_V.employee_id%TYPE,
                     p_manager_id OUT NOCOPY HR_EMPLOYEES_CURRENT_V.employee_id%TYPE) IS
-------------------------------------------------------
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetManager');

  -------------------------------------------------------
  l_debug_info := 'Trying to retrieve employee manager';
  -------------------------------------------------------
  IF (NOT AP_WEB_DB_HR_INT_PKG.GetSupervisorID(p_employee_id, p_manager_id)) THEN
    p_manager_id := NULL;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetManager');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GetManager', 
                     null, null, null, l_debug_info);
    raise;
END GetManager;

--------------------------------------------------------
PROCEDURE SetPersonAs(p_manager_id 	IN NUMBER,
                      p_item_type	IN VARCHAR2,
		      p_item_key	IN VARCHAR2,
		      p_manager_target	IN VARCHAR2) IS
--------------------------------------------------------
  l_manager_name		wf_users.name%type;
  l_manager_display_name	wf_users.display_name%type;
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetPersonAs');

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Manager_Name Info for Manager_Id';
  ------------------------------------------------------------
  WF_DIRECTORY.GetUserName('PER',
			   p_manager_id,
			   l_manager_name,
			   l_manager_display_name);

  IF (p_manager_target = 'MANAGER') THEN 

    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'MANAGER_ID',
			      p_manager_id);

    --------------------------------------------------------
    l_debug_info := 'Set Manager_Name Info Item Attribute';
    --------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'MANAGER_NAME',
			      l_manager_name);

    ---------------------------------------------------------------
    l_debug_info := 'Set Manager_Display_Name Info Item Attribute';
    ---------------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'MANAGER_DISPLAY_NAME',
			      l_manager_display_name); 

  ELSE

    --------------------------------------------------------
    l_debug_info := 'Set Approver_ID Info Item Attribute';
    --------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'APPROVER_ID',
			      p_manager_id);

    --------------------------------------------------------
    l_debug_info := 'Set Approver_Name Info Item Attribute';
    --------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'APPROVER_NAME',
			      l_manager_name);

    ----------------------------------------------------------------
    l_debug_info := 'Set Approver_Display_Name Info Item Attribute';
    ----------------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'APPROVER_DISPLAY_NAME',
			      l_manager_display_name); 

    ----------------------------------------------------------------
    l_debug_info := 'Retrieving EXPENSE_REPORT_ID Item Attribute';
    ----------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

   /* Bug 3566496: Need to update expense_current_approver_id since that
    * is used to display the approver in the Track expenses page.
    */

    UPDATE ap_expense_report_headers_all 
    SET    expense_current_approver_id = p_manager_id
    WHERE  report_header_id = l_report_header_id;

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetPersonAs');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetPersonAs', 
                     p_item_type, p_item_key, null, l_debug_info);
    raise;
END SetPersonAs;

-- 3257576 added new parameters p_error_message, p_instructions, 
-- p_special_instr
---------------------------------------------------------------------------
PROCEDURE GetFinalApprover(p_employee_id		IN NUMBER,
                           p_override_approver_id	IN NUMBER,
		      	   p_emp_cost_center		IN VARCHAR2,
		      	   p_doc_cost_center		IN VARCHAR2,
		      	   p_approval_amount		IN NUMBER,
                           p_item_key			IN VARCHAR2,
			   p_item_type			IN VARCHAR2,
		      	   p_final_approver_id	 OUT NOCOPY NUMBER,
		      	   p_error_message	 OUT NOCOPY VARCHAR2,
                           p_instructions        OUT NOCOPY VARCHAR2,
                           p_special_instr       OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------------------------
  l_approver_id			NUMBER;
  l_approver_id_out             NUMBER; -- Bug 2718416
  l_debug_info			VARCHAR2(200);
  TYPE   l_ManagerIDList        IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  l_manager_id                  l_ManagerIDList;
  l_counter                     NUMBER := 1;
  -- 3257576
  l_approver_status          per_assignment_status_types.per_system_status%type;
  l_approver_name            per_people_x.full_name%type;
  l_approver_name_out        per_people_x.full_name%type;
  l_employee_name            per_people_x.full_name%type;

  l_last_approver_id         NUMBER;
  l_last_approver_name       per_workforce_x.full_name%TYPE;
  l_emp_info_rec             AP_WEB_DB_HR_INT_PKG.EmployeeInfoRec;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetFinalApprover');

  IF (p_override_approver_id IS NULL) THEN

    -- bug 3257576
    GetManagerInfoAndCheckStatus( p_employee_id,
                           l_employee_name, 
                           l_approver_id,
                           l_approver_name,
                           l_approver_status,
                           p_error_message,
                           p_instructions,
                           p_special_instr);

    IF (p_error_message IS NOT NULL) THEN
       p_final_approver_id := NULL;
    END IF;

  ELSE

    l_approver_id := p_override_approver_id;

  END IF;     

  -- 3257576
  IF ((l_approver_id IS NOT NULL) AND (p_error_message IS NULL)) THEN

  /*Bug 2492342 Setting the value of the 1st Manager */
  l_manager_id(l_counter) := l_approver_id;

  LOOP

    l_counter := l_counter + 1;

    IF (AP_WEB_EXPENSE_CUST_WF.HasAuthority(l_approver_id,
                                            p_doc_cost_center,
					    p_approval_amount,
					    p_item_key,
					    p_item_type)) THEN
      p_final_approver_id := l_approver_id;
      return;
    END IF;

    -- bug 3257576
    GetManagerInfoAndCheckStatus(
                           l_approver_id,
                           l_approver_name,
                           l_approver_id_out,
                           l_approver_name_out,
                           l_approver_status,
                           p_error_message,
                           p_instructions,
                           p_special_instr);

    IF (p_error_message IS NOT NULL) THEN
       p_final_approver_id := NULL;
       return;
    END IF;

    -- Bug 2718416 - do not pass in same variable as IN and OUT parameter
    l_approver_id := l_approver_id_out;
    l_approver_name := l_approver_name_out;

    IF (l_approver_id = p_employee_id) THEN
      ---------------------------------------------
      l_debug_info := 'Loop in Approval Hierarchy';
      ---------------------------------------------
      -- 3257576
      FND_MESSAGE.Set_Name('SQLAP', 'AP_WEB_APRVL_HIERARCHY_LOOP');
      p_error_message := FND_MESSAGE.Get;
      FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR6');
      p_instructions := FND_MESSAGE.Get;
      FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_SPL_INSTR');
      p_special_instr := FND_MESSAGE.Get;
      return;
    END IF;

    /*Bug 2492342 : Adding the manager to the table and checking whether
                  this manager has been come across before. If so, there
                  is a loop in the hierarchy.*/

    l_manager_id(l_counter) := l_approver_id;

    FOR i in 1..(l_counter -1) LOOP

        IF l_approver_id = l_manager_id(i) THEN
           ---------------------------------------------
           l_debug_info := 'Loop in Approval Hierarchy';
           ---------------------------------------------
           -- 3257576
           FND_MESSAGE.Set_Name('SQLAP', 'AP_WEB_APRVL_HIERARCHY_LOOP');
           p_error_message := FND_MESSAGE.Get;
           FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR6');
           p_instructions := FND_MESSAGE.Get;
           FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_SPL_INSTR');
           p_special_instr := FND_MESSAGE.Get;
           return;
        END IF;

    END LOOP;


  END LOOP;

  END IF; -- l_approver_id is not null and p_error_message is null
  
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetFinalApprover');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GetFinalApprover', 
                     p_item_type, null, null, l_debug_info);
    raise;
END GetFinalApprover;

----------------------------------------------------------------------
PROCEDURE GetPreparerManager(p_item_type	IN VARCHAR2,
		     	     p_item_key		IN VARCHAR2,
		     	     p_actid		IN NUMBER,
		     	     p_funmode		IN VARCHAR2,
		     	     p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_preparer_id			NUMBER;
  l_manager_id			NUMBER;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetPreparerManager');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------
    l_debug_info := 'Retrieve Employee_ID Item Attribute';
    ------------------------------------------------------
    l_preparer_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					         p_item_key,
					         'PREPARER_ID');


    ---------------------------------------------
    l_debug_info := 'Call Get Manager Procedure';
    ----------------------------------------------
    GetManager(l_preparer_id,
               l_manager_id);

    IF (l_manager_id IS NULL) THEN
      l_debug_info := 'Manager not found for employee_id ' || to_char(l_preparer_id);
    END IF;

    SetPersonAs(l_manager_id,
                p_item_type,
                p_item_key,
                'MANAGER');  

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetPreparerManager');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GetPreparerManager', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END GetPreparerManager;

----------------------------------------------------------------------
PROCEDURE GetApproverManager(p_item_type	IN VARCHAR2,
		     	     p_item_key		IN VARCHAR2,
		     	     p_actid		IN NUMBER,
		     	     p_funmode		IN VARCHAR2,
		     	     p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_approver_id			NUMBER;
  l_manager_id			NUMBER;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetApproverManager');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------
    l_debug_info := 'Retrieve Approve_ID Item Attribute';
    ------------------------------------------------------
    l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					         p_item_key,
					         'APPROVER_ID');

    ---------------------------------------------
    l_debug_info := 'Call Get Manager Procedure';
    ----------------------------------------------
    GetManager(l_approver_id,
               l_manager_id);

    SetPersonAs(l_manager_id,
                p_item_type,
	        p_item_key,
                'APPROVER');

   /* 
      SetForwardInfoInAME is called to forward the approval to the approver's
      manager when the approver doesn't response and got time-out
   */
   AP_WEB_WRAPPER_PKG.SetForwardInfoInAME(p_item_key,
                                          p_item_type);

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetApproverManager');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GetApproverManager', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END GetApproverManager;

----------------------------------------------------------------------
PROCEDURE ApproverProvided(p_item_type	IN VARCHAR2,
		     	   p_item_key	IN VARCHAR2,
		     	   p_actid	IN NUMBER,
		     	   p_funmode	IN VARCHAR2,
		     	   p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_approver_id			NUMBER;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ApproverProvided');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------
    l_debug_info := 'Retrieve Approve_ID Item Attribute';
    ------------------------------------------------------
    l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					         p_item_key,
					         'APPROVER_ID');

    ---------------------------------------------------------------------------
    l_debug_info := 'If l_approver_id is not null return Y otherwise return N';
    ---------------------------------------------------------------------------
    IF (l_approver_id IS NOT NULL) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ApproverProvided');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ApproverProvided', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END ApproverProvided;

----------------------------------------------------------------------
PROCEDURE SameCostCenters(p_item_type	IN VARCHAR2,
		     	  p_item_key	IN VARCHAR2,
		     	  p_actid	IN NUMBER,
		     	  p_funmode	IN VARCHAR2,
		     	  p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_emp_cost_center		VARCHAR2(240);
  l_report_cost_center		VARCHAR2(240);
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SameCostCenters');

  IF (p_funmode = 'RUN') THEN

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Employee Cost Center Item Attribute';
    ---------------------------------------------------------------
    l_emp_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
					           p_item_key,
					           'EMP_COST_CENTER');

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Document Cost Center Item Attribute';
    ---------------------------------------------------------------
    l_report_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						      p_item_key,
						      'DOC_COST_CENTER');

    --------------------------------------------------------------------
    l_debug_info := 'If Employee and Document Cost Centers are the same
		     return Y otherwise return N';
    --------------------------------------------------------------------
    IF (l_emp_cost_center = l_report_cost_center) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SameCostCenters');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SameCostCenters', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SameCostCenters;

----------------------------------------------------------------------
PROCEDURE SetApproverEqualManager(p_item_type	IN VARCHAR2,
		     	  	     p_item_key		IN VARCHAR2,
		     	  	     p_actid		IN NUMBER,
		     	  	     p_funmode		IN VARCHAR2,
		     	  	     p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_manager_id			NUMBER;
  l_manager_name		wf_users.name%type;
  l_manager_display_name  	wf_users.display_name%type;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetApproverEqualManager');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------
    l_debug_info := 'Retrieve Manager_ID Item Attribute';
    -------------------------------------------------------
    l_manager_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					        p_item_key,
					        'MANAGER_ID');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Manager_Name Info Item Attributes';
    ------------------------------------------------------------
    l_manager_name := WF_ENGINE.GetItemAttrText(p_item_type,
					        p_item_key,
					        'MANAGER_NAME');

    l_manager_display_name := WF_ENGINE.GetItemAttrText(p_item_type,
					        	p_item_key,
					                'MANAGER_DISPLAY_NAME');

    ----------------------------------------------------------------------
    l_debug_info := 'Set Approver Info Item Attributes with Manager Info';
    ----------------------------------------------------------------------
    WF_ENGINE.SetItemAttrNUMBER(p_item_type,
			        p_item_key,
			        'APPROVER_ID',
			        l_manager_id);

    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'APPROVER_NAME',
			      l_manager_name);

    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'APPROVER_DISPLAY_NAME',
			      l_manager_display_name); 

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetApproverEqualManager');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetApproverEqualManager', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SetApproverEqualManager;

----------------------------------------------------------------------
PROCEDURE RecordForwardFromInfo(p_item_type	IN VARCHAR2,
		     	  	     p_item_key		IN VARCHAR2,
		     	  	     p_actid		IN NUMBER,
		     	  	     p_funmode		IN VARCHAR2,
		     	  	     p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_approver_id			NUMBER; 
  l_approver_name		wf_users.name%type;
  l_approver_display_name  	wf_users.display_name%type;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start RecordForwardFromInfo');

  IF (p_funmode in ('RUN', 'TRANSFER')) THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Approver_Info Item Attributes';
    ------------------------------------------------------------
    l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					         p_item_key,
					         'APPROVER_ID');

    l_approver_name := WF_ENGINE.GetItemAttrText(p_item_type,
					        p_item_key,
					        'APPROVER_NAME');

    l_approver_display_name := WF_ENGINE.GetItemAttrText(p_item_type,
					        	p_item_key,
					        'APPROVER_DISPLAY_NAME');

    ----------------------------------------------------------------------
    l_debug_info := 'Set Forward_From Item Attributes With Approver Info';
    ----------------------------------------------------------------------
    WF_ENGINE.SetItemAttrNUMBER(p_item_type,
			        p_item_key,
			        'FORWARD_FROM_ID',
			        l_approver_id);

    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'FORWARD_FROM_NAME',
			      l_approver_name);

    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'FORWARD_FROM_DISPLAY_NAME',
			      l_approver_display_name); 

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end RecordForwardFromInfo');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'RecordForwardFromInfo', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END RecordForwardFromInfo;

----------------------------------------------------------------------
PROCEDURE ManagerNotEqualToApprover(p_item_type		IN VARCHAR2,
		     	  	    p_item_key		IN VARCHAR2,
		     	  	    p_actid		IN NUMBER,
		     	  	    p_funmode		IN VARCHAR2,
		     	  	    p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_approver_id			NUMBER;
  l_manager_id			NUMBER;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ManagerNotEqualToApprover');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------
    l_debug_info := 'Retrieve Approver_ID Item Attribute';
    ------------------------------------------------------
    l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					         p_item_key,
					         'APPROVER_ID');

    ------------------------------------------------------
    l_debug_info := 'Retrieve Approve_ID Item Attribute';
    ------------------------------------------------------
    l_manager_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
					         p_item_key,
					         'MANAGER_ID');

    IF (l_approver_id <> l_manager_id) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ManagerNotEqualToApprover');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ManagerNotEqualToApprover', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END ManagerNotEqualToApprover;

----------------------------------------------------------------------
PROCEDURE NotifyPreparer(p_item_type		IN VARCHAR2,
		     	  p_item_key		IN VARCHAR2,
		     	  p_actid		IN NUMBER,
		     	  p_funmode		IN VARCHAR2,
		     	  p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_approver_id			NUMBER;
  l_manager_id			NUMBER;
  l_count			NUMBER;
  l_limit			NUMBER;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start NotifyPreparer');

  IF (p_funmode = 'RUN') THEN

    -----------------------------------------------------------------------
    l_debug_info := 'Retrieve Manager_Approval_Send_Count Item Attribute';
    -----------------------------------------------------------------------
    l_count := WF_ENGINE.GetItemAttrNumber(p_item_type,
					   p_item_key,
					   'MANAGER_APPROVAL_SEND_COUNT');

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Manager_Send_Limit Item Attribute';
    ---------------------------------------------------------------
    l_limit := WF_ENGINE.GetActivityAttrNumber(p_item_type,
					       p_item_key,
					       p_actid,
					   'MANAGER_SEND_LIMIT');

    -----------------------------------------------------------------------
    l_debug_info := 'Increment Manager_Approval_Send_Count Item Attribute';
    -----------------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
				p_item_key,
				'MANAGER_APPROVAL_SEND_COUNT',
				l_count+1);


    IF (l_count+1 >= l_limit) THEN

      ---------------------------------------------------------------
      l_debug_info := 'Send_count at least equals limit, clear
                       Manager_Approval_Send_Count Item Attribute 
		       and return Y';
      ---------------------------------------------------------------
      WF_ENGINE.SetItemAttrNumber(p_item_type,
				  p_item_key,
			 	  'MANAGER_APPROVAL_SEND_COUNT',
				  0);

      p_result := 'COMPLETE:Y';

    ELSE

      p_result := 'COMPLETE:N';

    END IF;
    
  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end NotifyPreparer');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'NotifyPreparer', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END NotifyPreparer;

/*----------------------------------------------------------------------------*
 | Procedure                                                                  
 |      AMEEnabled                                                            
 |                                                                            
 | DESCRIPTION                                                                
 |      This procedure is used by workflow to determine whether AME is        
 |	enabled or not							
 |									      
 | PARAMETERS                                                                 
 |                                                                            
 | RETURNS                                                                    
 |     none                                                                               
 *----------------------------------------------------------------------------*/
---------------------------------------------------------
PROCEDURE AMEEnabled(p_item_type	IN VARCHAR2,
		     	p_item_key	IN VARCHAR2,
		     	p_actid		IN NUMBER,
		     	p_funmode	IN VARCHAR2,
		     	p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------
  l_find_approver_count		NUMBER;
  l_debug_info			VARCHAR2(200);  
  l_AMEEnabled			VARCHAR2(1);
  l_bAMEProfileDefined		BOOLEAN;
  l_nRespId 			Number;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AMEEnabled');

  IF (p_funmode = 'RUN') THEN

    BEGIN
      ------------------------------------------------------------
      l_debug_info := 'Get responsibility id';
      ------------------------------------------------------------
      l_nRespId := WF_ENGINE.GetItemAttrNumber(p_item_type,
  	 				       p_item_key,
  					       'RESPONSIBILITY_ID');

    EXCEPTION
	WHEN OTHERS THEN
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
    END;

    ----------------------------------------------------
    l_debug_info := 'Retrieve profile option AME Enabled';
    ----------------------------------------------------
    FND_PROFILE.GET_SPECIFIC('AME_INSTALLED_FLAG', null, l_nRespId, 200, l_AMEEnabled, l_bAMEProfileDefined);

    if l_bAMEProfileDefined then
      -----------------------------------------------
      -- for bug 3344280, check the profile option value if it's defined
      -----------------------------------------------
      if (NVL(l_AMEEnabled,'N') = 'Y') then
        p_result := 'COMPLETE:Y';
      else
	p_result := 'COMPLETE:N';
      end if;
    else
      ---------------------------------------------------
      -- return no if AME Installed profile option is not defined
      ---------------------------------------------------
      p_result := 'COMPLETE:N';
    end if;

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AMEEnabled');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AMEEnabled', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AMEEnabled;

---------------------------------------------------------
PROCEDURE FirstApprover(p_item_type	IN VARCHAR2,
		     	p_item_key	IN VARCHAR2,
		     	p_actid		IN NUMBER,
		     	p_funmode	IN VARCHAR2,
		     	p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------
  l_find_approver_count		NUMBER;
  l_debug_info			VARCHAR2(200);  
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start FirstApprover');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieving Find_Approver_Count Item Attribute';
    ----------------------------------------------------------------
    l_find_approver_count := WF_ENGINE.GetItemAttrNumber(p_item_type,
						         p_item_key,
						       'FIND_APPROVER_COUNT');

    IF (l_find_approver_count = 1) THEN
      -----------------------------------------------
      -- return yes when find_approver_count equals 1
      -----------------------------------------------
      p_result := 'COMPLETE:Y';
    ELSE
      ---------------------------------------------------
      -- return no if find_approver_count doesn't equal 1
      ---------------------------------------------------
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end FirstApprover');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'FirstApprover', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END FirstApprover;

---------------------------------------------------------
PROCEDURE ApprovalForwarded(p_item_type	IN VARCHAR2,
		     	    p_item_key	IN VARCHAR2,
		     	    p_actid	IN NUMBER,
		     	    p_funmode	IN VARCHAR2,
		     	    p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------
  l_forward_from_id		NUMBER;
  l_debug_info			VARCHAR2(200);  
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ApprovalForwarded');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieving FORWARD_FROM_ID Item Attribute';
    ----------------------------------------------------------------
    l_forward_from_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						     p_item_key,
						     'FORWARD_FROM_ID');

    IF (l_forward_from_id IS NOT NULL) THEN
      -----------------------------------------------
      -- return yes when forward_from_id is not null
      -----------------------------------------------
      p_result := 'COMPLETE:Y';
    ELSE
      ----------------------------------------
      -- return no if forward_from_id is null
      ----------------------------------------
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ApprovalForwarded');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ApprovalForwarded', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END ApprovalForwarded;

---------------------------------------------------------
PROCEDURE ResetEmpCostCenter(p_item_type IN VARCHAR2,
		     	     p_item_key	 IN VARCHAR2,
		     	     p_actid	 IN NUMBER,
		     	     p_funmode	 IN VARCHAR2,
		     	     p_result	 OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------
  l_preparer_id				NUMBER;
  l_emp_name				wf_users.name%type;
  l_emp_num				VARCHAR2(30);
  l_emp_cost_center			VARCHAR2(240);
  l_debug_info				VARCHAR2(200);  
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ResetEmpCostCenter');

  IF (p_funmode = 'RUN') THEN

    -------------------------------------------------------------
    l_debug_info := 'Retrieving Emp_Cost_Center Item Attribute';
    -------------------------------------------------------------
    l_emp_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						   p_item_key,
						   'EMP_COST_CENTER');

    ---------------------------------------------------------
    l_debug_info := 'Retrieving Preparer_Id Item Attribute';
    ---------------------------------------------------------
    l_preparer_id := WF_ENGINE.GetItemAttrText(p_item_type,
						p_item_key,
						'PREPARER_ID');


    IF (l_emp_cost_center IS NULL) THEN

      ---------------------------------------------------------------
      l_debug_info := 'Get the Employee Cost Center Associated With 
                       Preparer_Id';
      ---------------------------------------------------------------
      AP_WEB_UTILITIES_PKG.GetEmployeeInfo(l_emp_name,
				           l_emp_num,
				           l_emp_cost_center,
				           l_preparer_id);

      -------------------------------------------------------------
      l_debug_info := 'Set Emp_Cost_Center Item Attribute';
      -------------------------------------------------------------
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'EMP_COST_CENTER',
				l_emp_cost_center);

    END IF;
      

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ResetEmpCostCenter');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ResetEmpCostCenter', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END ResetEmpCostCenter;

---------------------------------------------------------
PROCEDURE PayablesReviewed(p_item_type	IN VARCHAR2,
		     	   p_item_key	IN VARCHAR2,
		     	   p_actid	IN NUMBER,
		     	   p_funmode	IN VARCHAR2,
		     	   p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_WorkflowRec			AP_WEB_DB_EXPRPT_PKG.ExpWorkflowRec;
  l_debug_info			VARCHAR2(200);  
  l_rejection_reason		Wf_Item_Attribute_Values.TEXT_VALUE%TYPE := NULL;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start PayablesReviewed');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieving EXPENSE_REPORT_ID Item Attribute';
    ----------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    ----------------------------------------------------------------
    l_debug_info := 'Set Rejection Reason to No reason provided if it is null';
    ----------------------------------------------------------------
    l_rejection_reason := WF_ENGINE.GetItemAttrText(p_item_type, 
						      p_item_key, 
						      'WF_NOTE');

    IF (l_rejection_reason IS NULL OR 
	replace(l_rejection_reason, ' ', '') = '') THEN
      FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_REASON_PROVIDED');
      WF_ENGINE.SetItemAttrText(p_item_type,
			        p_item_key,
			        'WF_NOTE',
			        FND_MESSAGE.Get);

    END IF;

    

    IF (NOT AP_WEB_DB_EXPRPT_PKG.GetExpWorkflowInfo(l_report_header_id, 
					l_WorkflowRec)) THEN
	l_WorkflowRec.workflow_flag := NULL;
    END IF;

    IF (l_WorkflowRec.workflow_flag = 'P') THEN
      ---------------------------------------------------------
      -- return yes when workflow_approved_flag is equal to 'P'
      ---------------------------------------------------------
      p_result := 'COMPLETE:Y';
    ELSE
      ----------------------------------------------------------
      -- return no if workflow_approved_flag is not equal to 'P'
      ----------------------------------------------------------
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end PayablesReviewed');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'PayablesReviewed', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END PayablesReviewed;

----------------------------------------------------------------------
PROCEDURE EmployeeEqualsToPreparer(p_item_type   IN VARCHAR2,
                          	   p_item_key    IN VARCHAR2,
                          	   p_actid       IN NUMBER,
                          	   p_funmode     IN VARCHAR2,
                          	   p_result      OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_employee_id		NUMBER(15);
  l_preparer_id         NUMBER(15);
  l_debug_info          VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start EmployeeEqualsToPreparer');

  IF (p_funmode = 'RUN') THEN

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Employee Id Item Attribute';
    ---------------------------------------------------------------
    l_employee_id := WF_ENGINE.GetItemAttrText(p_item_type,
                                               p_item_key,
                                               'EMPLOYEE_ID');

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Preparer Id Item Attribute'; 
    ---------------------------------------------------------------
    l_preparer_id := WF_ENGINE.GetItemAttrText(p_item_type,
                                               p_item_key,
                                               'PREPARER_ID');

    --------------------------------------------------------------------
    l_debug_info := 'If Employee Id and Preparer Id are the same
                     return Y otherwise return N';
    --------------------------------------------------------------------
    IF (l_employee_id = l_preparer_id) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end EmployeeEqualsToPreparer');

EXCEPTION
  WHEN OTHERS THEN               
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'EmployeeEqualsToPreparer',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END EmployeeEqualsToPreparer; 

----------------------------------------------------------------------
PROCEDURE EmployeeApprovalRequired(p_item_type      IN VARCHAR2,
                                   p_item_key       IN VARCHAR2,
                                   p_actid          IN NUMBER,
                                   p_funmode        IN VARCHAR2,
                                   p_result         OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_emp_method 				VARCHAR2(20);
  l_debug_info                  	VARCHAR2(200);   
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start EmployeeApprovalRequired');

  IF (p_funmode = 'RUN') THEN  

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Find_Approver_Method Activity Attribute';
    -------------------------------------------------------------------
    l_emp_method := WF_ENGINE.GetActivityAttrText(p_item_type,
                                                  p_item_key,
                                                  p_actid,
                                           'EMPLOYEE_APPROVAL_REQUIRED_MET');
  
    IF (l_emp_method = 'Y') THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end EmployeeApprovalRequired');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'EmployeeApprovalRequired',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END EmployeeApprovalRequired;  

---------------------------------------------------------
PROCEDURE DetermineStartFromProcess(p_item_type	IN VARCHAR2,
		     	   p_item_key	IN VARCHAR2,
		     	   p_actid	IN NUMBER,
		     	   p_funmode	IN VARCHAR2,
		     	   p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------

--
-- Determines from which process to start the workflow: server validation,
-- manager approval, or ap approval.
--

  l_start_from_process		VARCHAR2(40);
  l_workflow_approved_flag	VARCHAR2(1);
  l_debug_info			VARCHAR2(200);  
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start DetermineStartFromProcess');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieving Start From Process Item Attribute';
    ----------------------------------------------------------------
    l_start_from_process := WF_ENGINE.GetItemAttrText(p_item_type,
						    p_item_key,
						    'START_FROM_PROCESS');
    p_result := 'COMPLETE:' || l_start_from_process;
    IF l_start_from_process IS NULL THEN 
      p_result := 'COMPLETE:' || C_START_FROM_SERVER_VALIDATION;
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end DetermineStartFromProcess');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'DetermineStartFromProcess', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    RAISE;

END DetermineStartFromProcess;

---------------------------------------------------------
PROCEDURE SetEmployeeAsApprover(p_item_type	IN VARCHAR2,
		       	  p_item_key	IN VARCHAR2,
		     	  p_actid	IN NUMBER,
		     	  p_funmode	IN VARCHAR2,
		     	  p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------

--
-- For the third-party expense report submission, if the employee
-- (not the submitter) rejects the report we must set the approver
-- info to the employee so that the notification sent to the 
-- submitter will contain the appropriate rejector name.  The approver
-- info is used to determine the actual report approver not the 
-- employee in the third party case.
--

  V_employee_id            NUMBER;
  V_employee_name          wf_users.name%type;
  V_employee_display_name  wf_users.display_name%type;
  l_debug_info             VARCHAR2(200);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetEmployeeAsApprover');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------
    l_debug_info := 'Get WF Employee_ID Item Attribute';
    ------------------------------------------------------
    V_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                p_item_key,
                                'EMPLOYEE_ID');
                                                 
    V_employee_name := WF_ENGINE.GetItemAttrText(p_item_type,
                                p_item_key,
                                'EMPLOYEE_NAME');
                                
                                                 
    V_employee_display_name := WF_ENGINE.GetItemAttrText(p_item_type,
                                p_item_key,
                                'EMPLOYEE_DISPLAY_NAME');
                                

    --------------------------------------------------------------
    l_debug_info := 'Set WF Preparer_Display_Name Item Attribute';
    --------------------------------------------------------------
    WF_ENGINE.SetItemAttrNumber(p_item_type,
  			      p_item_key,
  			      'APPROVER_ID',
  			      V_employee_id);
  
    WF_ENGINE.SetItemAttrText(p_item_type,
  			      p_item_key,
  			      'APPROVER_NAME',
  			      V_employee_name);
  
    WF_ENGINE.SetItemAttrText(p_item_type,
  			      p_item_key,
  			      'APPROVER_DISPLAY_NAME',
  			      V_employee_display_name);
  

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetEmployeeAsApprover');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetEmployeeAsApprover', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    RAISE;
  
END SetEmployeeAsApprover;

----------------------------------------------------------------------
PROCEDURE DeleteShortPayExpReport(p_item_type	IN VARCHAR2,
		   	      	  p_item_key	IN VARCHAR2,
		   	      	  p_actid	IN NUMBER,
		   	      	  p_funmode	IN VARCHAR2,
		   	      	  p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start DeleteShortPayExpReport');

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieve New_Expense_Report_ID Item Attribute';
    ----------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'NEW_EXPENSE_REPORT_ID');

    DeleteExpReportFromAPTables(l_report_header_id);

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end DeleteShortPayExpReport');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'DeleteShortPayExpReport', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END DeleteShortPayExpReport;

---------------------------------------------------------
PROCEDURE RequireProofOfPayment(p_item_type	IN VARCHAR2,
		       	  	p_item_key	IN VARCHAR2,
		     	  	p_actid		IN NUMBER,
		     	  	p_funmode	IN VARCHAR2,
		     	  	p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------
  l_require_proof_of_payment VARCHAR2(1);
  l_report_header_id	     AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_debug_info              VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start RequireProofOfPayment');

  IF (p_funmode = 'RUN') THEN

    ---------------------------------------------------------------------------
    l_debug_info := 'Retrieve Include_Missing_Receipts Activity Attribute';
    ---------------------------------------------------------------------------
    l_require_proof_of_payment := WF_ENGINE.GetActivityAttrText(p_item_type,
					           p_item_key,
						   p_actid,
					       'ALWAYS_REQ_PROOF_OF_PAYMENT');

    IF (l_require_proof_of_payment = 'N') THEN

      ----------------------------------------------------------------
      l_debug_info := 'Retrieving EXPENSE_REPORT_ID Item Attribute';
      ----------------------------------------------------------------
      l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						        p_item_key,
						        'EXPENSE_REPORT_ID');

    
      IF (NOT AP_WEB_DB_EXPLINE_PKG.SetReceiptRequired(l_report_header_id, 'N')) THEN
	NULL;
      END IF;

    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end RequireProofOfPayment');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'RequireProofOfPayment', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    RAISE;
  
END RequireProofOfPayment;

/*
Written by: 
  Quan Le
Purpose: 
  To generate the value for LINE_TABLE document attribute of Expense Workflow. This procedure follows
predefined API.   See Workflow API documentation for more informfation.
Input: 
  See Workflow API documentation.
Output:
    See Workflow API documentation.
Input Output:
    See Workflow API documentation.
Assumption: 
  document_id is assumed to have the following format:
  <item_key>:<item_id>
Date:
  1/4/99 
*/

PROCEDURE GenerateExpLines(document_id		IN VARCHAR2,
				display_type	IN VARCHAR2,
				document	IN OUT NOCOPY VARCHAR2,
				document_type	IN OUT NOCOPY VARCHAR2) IS

  l_document_max 	        NUMBER := 25000; -- 27721 fails
  l_debug_info                  VARCHAR2(1000);
  l_message                     Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;
  l_temp_clob                   CLOB;
  l_colon                       NUMBER;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GenerateExpLines');

  WF_NOTIFICATION.NewClob(l_temp_clob,document);
  GenerateExpClobLines(document_id,
		   display_type,
		   l_temp_clob,
		   document_type);
  dbms_lob.read(l_temp_clob,l_document_max,1,document);

  if (dbms_lob.getlength(l_temp_clob) > l_document_max) then

        l_colon  := instr(document, tr_end,-1);
        document := substr(document,1,l_colon+4);
        document := document || table_end || indent_end;

        FND_MESSAGE.SET_NAME('SQLAP','AP_WEB_EXP_UNABLE_TO_SHOWLINES');
        l_message := FND_MESSAGE.GET; 
        document := document || table_start;
        document := document || tr_start || '&' || 'nbsp;' || tr_end;
        document := document || tr_start || '&' || 'nbsp;' || tr_end;
        document := document || tr_start || td_start || l_message || td_end || tr_end;
        document := document || table_end || indent_end;

  end if;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GenerateExpLines');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GenerateExpLines', 
                    document_id, l_debug_info);
    raise;
END GenerateExpLines;


/*
Written by: 
  Quan Le
Purpose: 
  To generate the value for  document attribute of Expense Workflow. This procedure follows
predefined API.   See Workflow API documentation for more informfation. Currently this procedure
is used for PURPOSE attribute only.
Input: 
  See Workflow API documentation.
Output:
    See Workflow API documentation.
Input Output:
    See Workflow API documentation.
Assumption: 
  document_id is assumed to have the following format:
  <item_key>:<item_id>:<item attribute>
Date:
  1/4/99 
*/
PROCEDURE GenerateDocumentAttributeValue(document_id	IN VARCHAR2,
				display_type	IN VARCHAR2,
				document	IN OUT NOCOPY VARCHAR2,
				document_type	IN OUT NOCOPY VARCHAR2) IS
  l_colon    NUMBER;
  l_colon2    NUMBER;
  l_itemtype VARCHAR2(7);
  l_itemkey  VARCHAR2(15);
  l_attribute VARCHAR2(30);
  l_debug_info                  VARCHAR2(1000);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GenerateDocumentAttributeValue');

   document := '';

  l_debug_info := 'Decode document_id';

  l_colon    := instrb(document_id, ':');
  l_colon2   := instrb(document_id, ':', l_colon+1);  
  l_itemtype := substrb(document_id, 1, l_colon - 1);
  l_itemkey  := substrb(document_id, l_colon  + 1, l_colon2 - l_colon -1);
  l_attribute   := substrb(document_id, l_colon2 + 1);

  if (display_type = 'text/plain') then
      if (l_attribute = 'PURPOSE') then
          document := WF_ENGINE.GetItemAttrText(l_itemtype,
						      l_itemkey,
						     'PURPOSE');
      end if;
  else  -- html
      if (l_attribute = 'PURPOSE') then
          document := '<B>' || WF_ENGINE.GetItemAttrText(l_itemtype, l_itemkey, 'PURPOSE') || '</B>';
      end if;
  end if;
  document_type := display_type;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GenerateDocumentAttributeValue');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GenerateDocumentAttributeValue', 
                    document_id, l_debug_info);
    raise;
END  GenerateDocumentAttributeValue;



/**
 * jrautiai ADJ Fix Removed shortpay and adjustment specific logic form elsewhere, so instead here 
 *                  we are dealing with both cases using common logic.
 */
PROCEDURE BuildAdjustmentInfoLine(p_display_type        IN VARCHAR2,
                                  adjustment_rec        IN AP_WEB_DB_EXPLINE_PKG.AdjustmentRecordType,
                                  p_adjustment_type     IN VARCHAR2,
                                  p_currency            IN VARCHAR2,
                                  p_adjustment_line     IN OUT NOCOPY VARCHAR2) IS

l_debug_info              VARCHAR2(1000);
l_item_type               VARCHAR2(30);
l_report_header_id	  NUMBER;
l_adjustment_line   	  VARCHAR2(2000);

BEGIN
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start BuildAdjustmentInfoLine');

  IF p_adjustment_type = 'ADJUSTMENT' THEN
    ------------------------------------------------------------------
    l_debug_info := 'Format Adjustment Line with amount' || adjustment_rec.amount;
    ------------------------------------------------------------------
    IF (p_display_type = 'text/plain') THEN
       l_adjustment_line := adjustment_rec.expense_type_disp || '  ' || adjustment_rec.amount || '  ' || adjustment_rec.adjustment_reason;
       p_adjustment_line := p_adjustment_line || '
  '  ||  l_adjustment_line;
    ELSE -- HTML type
      p_adjustment_line := p_adjustment_line || tr_start;
      -- 'Receipt Date'
      p_adjustment_line := p_adjustment_line || td_text || adjustment_rec.start_expense_date || td_end;
      -- 'Expense Type'
      p_adjustment_line := p_adjustment_line || td_text || adjustment_rec.expense_type_disp || td_end;
      -- 'Original Amount'
      p_adjustment_line := p_adjustment_line || td_number || 
                             NVL(to_char(adjustment_rec.submitted_amount, FND_CURRENCY.Get_Format_Mask(p_currency,22)), '&' || 'nbsp;') || td_end;
      -- 'Adjustment'
      p_adjustment_line := p_adjustment_line || td_number || 
                             NVL(to_char(adjustment_rec.adjusted_amount, FND_CURRENCY.Get_Format_Mask(p_currency,22)), '&' || 'nbsp;') || td_end;
      -- 'New Amount'
      p_adjustment_line := p_adjustment_line || td_number || to_char(adjustment_rec.amount, FND_CURRENCY.Get_Format_Mask(p_currency,22)) || td_end;
      -- 'Credit Card Expense'
      p_adjustment_line := p_adjustment_line || td_text || NVL(adjustment_rec.credit_card_expense_disp, '&' || 'nbsp;') || td_end;
      -- 'Justification'
      p_adjustment_line := p_adjustment_line || td_text || nvl(WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.justification), '&' || 'nbsp;') || td_end;
      -- 'Instructions'
      p_adjustment_line := p_adjustment_line || td_text;
      if (adjustment_rec.adjustment_reason_code_disp is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason_code_disp) ||'<br>';
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      if (adjustment_rec.adjustment_reason_description is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason_description) ||'<br>';
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      if (adjustment_rec.adjustment_reason is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason);
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      p_adjustment_line := p_adjustment_line || td_end;
      p_adjustment_line := p_adjustment_line || tr_end;
    END IF;
  ELSIF p_adjustment_type = 'AUDIT' THEN
    IF (p_display_type = 'text/plain') THEN
       l_adjustment_line := adjustment_rec.expense_type_disp || '  ' || adjustment_rec.amount || '  ' || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason);
       p_adjustment_line := p_adjustment_line || '
  '  ||  l_adjustment_line;
    ELSE -- HTML type
      p_adjustment_line := p_adjustment_line || tr_start;
      -- 'Receipt Date'
      p_adjustment_line := p_adjustment_line || td_text || adjustment_rec.start_expense_date || td_end;
      -- 'Expense Type'
      p_adjustment_line := p_adjustment_line || td_text || adjustment_rec.expense_type_disp || td_end;
      -- 'Amount'
      p_adjustment_line := p_adjustment_line || td_number || 
                             NVL(to_char(adjustment_rec.amount, FND_CURRENCY.Get_Format_Mask(p_currency,22)), '&' || 'nbsp;') || td_end;
      -- 'Justification'
      p_adjustment_line := p_adjustment_line || td_text || nvl(WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.justification), '&' || 'nbsp;') || td_end;
      -- 'Instructions'
      p_adjustment_line := p_adjustment_line || td_text;
      if (adjustment_rec.adjustment_reason_code_disp is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason_code_disp) ||'<br>';
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      if (adjustment_rec.adjustment_reason_description is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason_description) ||'<br>';
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      if (adjustment_rec.adjustment_reason is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason);
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      p_adjustment_line := p_adjustment_line || td_end;
      p_adjustment_line := p_adjustment_line || tr_end;
    END IF;
  ELSE
    IF (p_display_type = 'text/plain') THEN
       l_adjustment_line := adjustment_rec.expense_type_disp || '  ' || adjustment_rec.amount || '  ' || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason);
       p_adjustment_line := p_adjustment_line || '
  '  ||  l_adjustment_line;
    ELSE -- HTML type
      p_adjustment_line := p_adjustment_line || tr_start;
      -- 'Receipt Date'
      p_adjustment_line := p_adjustment_line || td_text || adjustment_rec.start_expense_date || td_end;
      -- 'Expense Type'
      p_adjustment_line := p_adjustment_line || td_text || adjustment_rec.expense_type_disp || td_end;
      -- 'Amount'
      p_adjustment_line := p_adjustment_line || td_number || 
                             NVL(to_char(adjustment_rec.amount, FND_CURRENCY.Get_Format_Mask(p_currency,22)), '&' || 'nbsp;') || td_end;
      -- 'Itemized Expense'
      p_adjustment_line := p_adjustment_line || td_text || NVL(adjustment_rec.itemized_expense_disp, '&' || 'nbsp;') || td_end;
      -- 'Justification'
      p_adjustment_line := p_adjustment_line || td_text || nvl(WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.justification), '&' || 'nbsp;') || td_end;
      -- 'Instructions'
      p_adjustment_line := p_adjustment_line || td_text;
      if (adjustment_rec.adjustment_reason_code_disp is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason_code_disp) ||'<br>';
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      if (adjustment_rec.adjustment_reason_description is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason_description) ||'<br>';
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      if (adjustment_rec.adjustment_reason is not null) then
        p_adjustment_line := p_adjustment_line || WF_NOTIFICATION.SubstituteSpecialChars(adjustment_rec.adjustment_reason);
      else
        p_adjustment_line := p_adjustment_line || '&'||'nbsp;';
      end if;
      p_adjustment_line := p_adjustment_line || td_end;
      p_adjustment_line := p_adjustment_line || tr_end;
    END IF;
  END IF; -- p_adjustment_type = 'ADJUSTMENT'

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end BuildAdjustmentInfoLine');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'BuildAdjustmentInfoLine', 
                    '', l_debug_info);
    raise;
END  BuildAdjustmentInfoLine;


PROCEDURE GenerateAdjustmentInfo(document_id          IN VARCHAR2,
			   display_type		IN VARCHAR2,
			   document	        IN OUT NOCOPY VARCHAR2,
			   document_type	IN OUT NOCOPY VARCHAR2) IS

 l_document_max            NUMBER:=25000;
 l_debug_info              VARCHAR2(1000);
 l_message                VARCHAR2(2000);
 l_temp_clob               CLOB;
 l_colon                  NUMBER;--namrata
 BEGIN
 WF_NOTIFICATION.NewClob(l_temp_clob,document);
 	         
 GenerateAdjustmentInfoClob(document_id,
                         display_type,
                         l_temp_clob,
                         document_type);
 	 
 dbms_lob.read(l_temp_clob,l_document_max,1,document);
 	 
 if (dbms_lob.getlength(l_temp_clob) > l_document_max) then
 	 
         l_colon  := instr(document, '</tr>',-1);
         document := substr(document,1,l_colon+4);
         document := document || '</table><br>';
 
         FND_MESSAGE.SET_NAME('SQLAP','AP_WEB_EXP_UNABLE_TO_SHOWLINES');
         l_message := FND_MESSAGE.GET;
         document := document || '<table>';
         document := document || '<tr>`&nbsp;</tr>';
         document := document || '<tr>`&nbsp;</tr>';
         document := document || '<tr><td>' || l_message || '</td></tr>';
         document := document || '</table>';
 
 
 end if;
 AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GenerateAdjustmentInfo');
 
 EXCEPTION
   WHEN OTHERS THEN  
     Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GenerateAdjustmentInfo',
                     document_id, l_debug_info);
     raise;
 END GenerateAdjustmentInfo; --NAMRATA


PROCEDURE GenerateAdjustmentInfoClob(document_id          IN VARCHAR2,
                            display_type                IN VARCHAR2,
                            document                IN OUT NOCOPY CLOB,
                            document_type        IN OUT NOCOPY VARCHAR2) IS
 	 
l_document                long;--namrata
l_document_max            NUMBER:=25000;

l_debug_info              VARCHAR2(1000);
l_item_type               VARCHAR2(30);
l_report_header_id	  AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
l_adjustment_line	  VARCHAR2(2000);
l_adj_info_body		  VARCHAR2(2000);
l_itemtype 		  VARCHAR2(7);
l_itemkey  		  VARCHAR2(30);
l_currency  		  VARCHAR2(50);
l_colon    		  NUMBER;

 -- Bug 3336259: CC SP and ADJ Fix

l_adj_code   		  VARCHAR2(100) := 'ADJUSTMENT';  --default is Adjustments
l_prompts		  AP_WEB_UTILITIES_PKG.prompts_table;
l_title			  AK_REGIONS_VL.name%TYPE;

-- Bug 3336259: CC SP and ADJ Fix, changed to refer the new cursor type.
  AdjustmentsCursor 		AP_WEB_DB_EXPLINE_PKG.AdjustmentCursorType;

  -- Bug 3336259: CC SP and ADJ Fix, fetching the results into a record of a common type.
  adjustment_rec AP_WEB_DB_EXPLINE_PKG.AdjustmentRecordType;

  l_colspan               NUMBER :=0;
  l_total_adjustment      NUMBER :=0;
  l_total_amount          NUMBER :=0;
  l_total_disp            NUMBER :=0;

  l_n_org_id 		  Number; 
BEGIN
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GenerateAdjustmentInfo');

    ------------------------------------------------------------
    l_debug_info := 'Decode document_id';
    ------------------------------------------------------------  
    l_colon    := instrb(document_id, ':');

    ------------------------------------------------------------------------------
    l_debug_info := ' First index: ' || to_char(l_colon);
    ------------------------------------------------------------------------------
    l_itemtype := substrb(document_id, 1, l_colon - 1);
    l_itemkey  := substrb(document_id, l_colon  + 1);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Adjustment Code';
    ------------------------------------------------------------  
    l_colon    := instrb(l_itemkey, ':');
    ------------------------------------------------------------------------------
    l_debug_info := 'Second index: ' || to_char(l_colon);
    ------------------------------------------------------------------------------
    l_adj_code  := substrb(l_itemkey, l_colon  + 1);
    l_itemkey := substrb(l_itemkey, 1, l_colon - 1);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(l_itemtype,
						      l_itemkey,
						     'EXPENSE_REPORT_ID');

    ----------------------------------------------------
    l_debug_info := 'Retrieve Currency Item Attribute';
    ----------------------------------------------------
    l_currency := WF_ENGINE.GetItemAttrText(l_itemtype,
				            l_itemkey,
					    'CURRENCY');

    --------------------------------------------
    l_debug_info := 'Get Org Id';
    --------------------------------------------
    begin

      l_n_org_id := WF_ENGINE.GetItemAttrNumber(l_itemtype,
					      l_itemkey,
					      'ORG_ID');
    exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    -- ORG_ID item attribute doesn't exist, need to add it
	    WF_ENGINE.AddItemAttr(l_itemtype, l_itemkey, 'ORG_ID');
      	    IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(
				to_number(l_itemkey),
				l_n_org_id) <> TRUE ) THEN
	       l_n_org_id := NULL;
      	    END IF;

    	    WF_ENGINE.SetItemAttrNumber(l_itemtype,
                              	l_itemkey,
                              	'ORG_ID',
                              	l_n_org_ID);
	  else
	    raise;
	  end if;

    end;

    if (l_n_org_id is not null) then
      fnd_client_info.set_org_context(l_n_org_id);
    else
      -- Report was submitted before org_id being added, hence org_id
      -- item attributes hasn't been set yet. Need to get it from
      -- report header
      IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(
				to_number(l_itemkey),
				l_n_org_id) <> TRUE ) THEN
	 l_n_org_id := NULL;
      END IF;

      IF (l_n_org_id is not null) then
        fnd_client_info.set_org_context(l_n_org_id);
      END IF;

    end if;

 
    IF (display_type = 'text/plain') THEN
 	 l_document := '';
    ELSE  -- HTML 
     ----------------------------------
  	 l_debug_info := 'Get prompts';
     ----------------------------------
  	 AP_WEB_DISC_PKG.getPrompts(200,'AP_WEB_WF_LINETABLE',l_title,l_prompts);
  	 
        /**
         * Bug 3336259: CC SP and ADJ Fix start
         * set the table header depending whether we are building adjustment, policy violation or missing receipts table
         */ 
         IF (l_adj_code = 'ADJUSTMENT') THEN
           l_document := '<b>' || l_prompts(16) || '</b><br>';
         ELSE
           IF (l_adj_code = 'POLICY') THEN
            l_document := '<b>' || l_prompts(17) || '</b><br>';
           ELSE -- missing receipts
             l_document := '<b>' || l_prompts(18) || '</b><br>';
           END IF;
         END IF;
        /**
         * Bug 3336259: CC SP and ADJ Fix end
         */ 
         
 	  l_document := l_document || '<table bgcolor='||table_bgcolor||' width='||table_width||' border='||table_border||' cellpadding='||table_cellpadding||' cellspacing='||table_cellspacing||'>';

 	  l_document := l_document || '<tr bgcolor='||th_bgcolor||'>';
        /**
         * Bug 3336259: CC SP and ADJ Fix start
         * set the table column headers depending whether we are building adjustment or shortpay table
         */ 
         IF (l_adj_code = 'ADJUSTMENT') THEN
           -- 'Receipt Date'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(4) || '</b></td>';
           -- 'Expense Type'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(5) || '</b></td>';
           -- 'Original Amount (REIMBURSEMENT_CURRENCY)'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(19) || ' ('||l_currency||')' || '</b></td>';
           -- 'Adjustment  (REIMBURSEMENT_CURRENCY)'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(20) || ' ('||l_currency||')' || '</b></td>';
           -- 'New Amount (REIMBURSEMENT_CURRENCY)'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(21) || ' ('||l_currency||')' || '</b></td>';
           -- 'Credit Card Expense'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(22) || '</b></td>';
           -- 'Adjustment Reason'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(23) || '</b></td>';
           -- 'Adjustment Comments'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(11) || '</b></td></tr>';
         ELSE
           -- 'Receipt Date'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(4) || '</b></td>';
           -- 'Expense Type'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(5) || '</b></td>';
           -- 'Amount (REIMBURSEMENT_CURRENCY)'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(9) || ' ('||l_currency||')' || '</b></td>';
           -- 'Itemized Expense'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(24) || '</b></td>';
           -- 'Adjustment Reason'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(25) || '</b></td>';
           -- 'Adjustment Comments'
           l_document := l_document || '<td align="left"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(26) || '</b></td></tr>';
         END IF;
        /**
         * Bug 3336259: CC SP and ADJ Fix end
         */ 
    END IF;

     ------------------------------------------
    l_debug_info := 'Read Adjustments Cursor';
    ------------------------------------------
    
/**
 * Bug 3336259: CC SP and ADJ Fix Start - Removed shortpay and adjustment specific logic, instead we are using the same
 *                          logic for both in GetAdjustmentsCursor and BuildAdjustmentInfoLine.
 */
    IF (AP_WEB_DB_EXPLINE_PKG.GetAdjustmentsCursor(l_report_header_id, l_adj_code, AdjustmentsCursor)) THEN
      LOOP
        FETCH AdjustmentsCursor INTO adjustment_rec;
        EXIT  WHEN AdjustmentsCursor%NOTFOUND;
        BuildAdjustmentInfoLine(display_type,
				adjustment_rec,
				l_adj_code,
				l_currency,
				l_document);--namrata

	IF lengthb(l_document)>=l_document_max THEN
 	              WF_NOTIFICATION.WriteToClob(document,l_document);
 	              l_document:='';--namrata
 	END IF;


        l_total_adjustment := l_total_adjustment + adjustment_rec.adjusted_amount;
        l_total_amount     := l_total_amount + adjustment_rec.amount;
      END LOOP;

         CLOSE AdjustmentsCursor;

    END IF;
    
/**
 * Bug 3336259: CC SP and ADJ Fix end
 */

    IF (display_type = 'text/html') THEN
/**
 * Bug 3336259: CC SP and ADJ Fix Start
 */
      --------------------------------------------
      l_debug_info := 'Generate Total Row';
      --------------------------------------------
      l_document := l_document || '<tr bgcolor='||th_bgcolor||'>';   

      IF l_adj_code = 'ADJUSTMENT' THEN
        l_document := l_document || '<td colspan=3 align="right"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(12) || '</b></td>';
        l_document := l_document || '<td bgcolor='||td_bgcolor||' align="left"><font color='||td_fontcolor||' face='||td_fontface||'>'|| LPAD(to_char(l_total_adjustment, FND_CURRENCY.Get_Format_Mask(l_currency,22)),14) || '</td>';
	l_document := l_document || '<td colspan=4 align="right"><font color='||th_fontcolor||' face='||th_fontface||'></td>';
      ELSE
        l_document := l_document || '<td colspan=2 align="right"><font color='||th_fontcolor||' face='||th_fontface||'><b>' || l_prompts(12) || '</b></td>';
        l_document := l_document || '<td bgcolor='||td_bgcolor||' align="left"><font color='||td_fontcolor||' face='||td_fontface||'>'|| LPAD(to_char(l_total_amount, FND_CURRENCY.Get_Format_Mask(l_currency,22)),14) || '</td>';
        l_document := l_document || '<td colspan=3 align="right"><font color='||th_fontcolor||' face='||th_fontface||'></td>';
      END IF;

      l_document := l_document || '</tr>';
      l_document := l_document || '</table><br>';
/**
  * Bug 3336259: CC SP and ADJ Fix end
 */
    END IF;

    IF l_document is not null THEN
 	        WF_NOTIFICATION.WriteToClob(document,l_document);
 	     END IF;

    document_type := display_type;

   AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GenerateAdjustmentInfoClob');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GenerateAdjustmentInfoClob', 
                    document_id, l_debug_info);
    raise;
END  GenerateAdjustmentInfoClob;

PROCEDURE ResetLineInfo(document_id	IN VARCHAR2,
			display_type	IN VARCHAR2,
			document	IN OUT NOCOPY VARCHAR2,
			document_type	IN OUT NOCOPY VARCHAR2) IS
  l_debug_info                  VARCHAR2(1000);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ResetLineInfo');

  ------------------------------------------------------------------
  l_debug_info := 'Reset Line Info Body';
  ------------------------------------------------------------------
  
  document := '';
  document_type := display_type;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ResetLineInfo');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ResetLineInfo', 
                    document_id, l_debug_info);
    raise;
END  ResetLineInfo;

----------------------------------------------------------------------
PROCEDURE CallbackFunction(	p_s_item_type      IN VARCHAR2,
                          	p_s_item_key       IN VARCHAR2,
                          	p_n_actid          IN NUMBER,
                          	p_s_command        IN VARCHAR2,
                          	p_s_result         OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_n_org_id 			Number;
  l_n_user_id 			Number;
  l_n_resp_id 			Number;
  l_n_resp_appl_id 		Number;
  l_current_org_id              Number;
  l_current_user_id             Number;
  l_current_resp_id             Number;
  l_current_resp_appl_id        Number;


BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CallbackFunction');

  begin 
  
    l_n_org_id := WF_ENGINE.GetItemAttrNumber(p_s_item_type,
  					        p_s_item_key,
  					        'ORG_ID');
  exception
  	when others then
  	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
  	    -- ORG_ID item attribute doesn't exist, need to add it
  	    wf_engine.AddItemAttr(p_s_item_type, p_s_item_key, 'ORG_ID');
  	    -- get the org_id from header for old reports
  	    IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(
  				to_number(p_s_item_key),
  				l_n_org_id) <> TRUE ) THEN
  	    	l_n_org_id := NULL;
  	    END IF;
	    WF_ENGINE.SetItemAttrNumber(p_s_item_type,
  					p_s_item_key,
  					'ORG_ID',
					l_n_org_id);
  	  else
  	    raise;
  	  end if;
  
  end;

  begin 
    l_n_user_id := WF_ENGINE.GetItemAttrNumber(p_s_item_type,
                                               p_s_item_key,
                                               'USER_ID');

    l_n_resp_id := WF_ENGINE.GetItemAttrNumber(p_s_item_type,
                                               p_s_item_key,
                                               'RESPONSIBILITY_ID');

    l_n_resp_appl_id := WF_ENGINE.GetItemAttrNumber(p_s_item_type,
                                                    p_s_item_key,
                                                    'APPLICATION_ID');
    exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
    end;


  IF (p_s_command = 'SET_CTX') THEN
      
      -- Set the context
      FND_GLOBAL.APPS_INITIALIZE(  USER_ID => l_n_user_id,
				 RESP_ID => l_n_resp_id,
				 RESP_APPL_ID => l_n_resp_appl_id
				 );

    -- Set Org context
    -- Needs to be after FND_GLOBAL.APPS_INITIALIZE because 
    -- user_id, resp_id, and appl_id may be null because 
    -- the attributes don't exist or because they are not set
    if (l_n_org_id is not null) then
      fnd_client_info.set_org_context(l_n_org_id);
    end if;

  ELSIF (p_s_command = 'TEST_CTX') THEN

     /* Bug 4319321 : Need to check the values of user_id, resp_id
      * and resp_appl_id as well.
      */
     l_current_user_id       := TO_NUMBER(FND_PROFILE.VALUE('USER_ID'));
     l_current_resp_id       := TO_NUMBER(FND_PROFILE.VALUE('RESP_ID'));
     l_current_resp_appl_id  := TO_NUMBER(FND_PROFILE.VALUE('RESP_APPL_ID'));
     l_current_org_id        := TO_NUMBER(rtrim(substrb(USERENV('CLIENT_INFO'), 1, 10)));

     IF l_n_user_id IS NULL
       OR l_n_resp_id IS NULL
       OR l_n_resp_appl_id IS NULL THEN
        /* This condition should not occur. But if it does, do not reset the context*/
         p_s_result := 'TRUE'; 
     ELSIF l_current_user_id IS NULL
       OR l_current_resp_id IS NULL
       OR l_current_resp_appl_id IS NULL THEN
        /* Context is not set as yet. It will be set in SET_CTX mode call */
         p_s_result := 'NOTSET'; 
     ELSIF l_n_user_id=l_current_user_id
       AND l_n_resp_id=l_current_resp_id
       AND l_n_resp_appl_id=l_current_resp_appl_id THEN
         IF l_n_org_id <> l_current_org_id THEN
           /* Context is incorrect. Need to set it correctly in SET_CTX mode */
	   /* Bug 9663017: When the org context is not correct, the selector function should return FALSE */
-------------------
-- start modification by SR:3-4896814351 change 'FALSE' to 'NOTSET'
-------------------
--         p_s_result := 'FALSE'; -- 5563083:change 'FALSE' to 'NOTEST'
           p_s_result := 'NOTSET'; 
-------------------
-- end modification by SR:3-4896814351  change 'FALSE' to 'NOTSET'
-------------------           
         ELSE
           /* will come here if either of l_org_id or l_current_org_id is null or both are equal 
            * l_org_id or l_current_org_id is NULL means single org environment
            */
           p_s_result := 'TRUE';
         END IF;
     ELSE
-------------------
-- start modification by SR:3-4896814351  change 'FALSE' to 'NOTSET'
-------------------
--         p_s_result := 'FALSE'; -- 5563083:change 'FALSE' to 'NOTEST'
           p_s_result := 'NOTSET'; 
-------------------
-- end modification by SR:3-4896814351  change 'FALSE' to 'NOTSET'
-------------------           
      END IF;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CallbackFunction');

END CallbackFunction;

----------------------------------------------------------------------
PROCEDURE IsPreparerToAuditorTransferred(
                                p_item_type      IN VARCHAR2,
                                p_item_key       IN VARCHAR2,
                                p_actid          IN NUMBER,
                                p_funmode        IN VARCHAR2,
                                p_result         OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info         VARCHAR2(1000);

  l_notificationID     NUMBER;

  l_report_header_id    AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_entered_by          NUMBER := fnd_global.user_id;
  l_role_info_tbl       wf_directory.wf_local_roles_tbl_type;

  l_orig_language_code  ap_expense_params.note_language_code%type := null;
  l_orig_language       fnd_languages.nls_language%type := null;
  l_new_language_code   ap_expense_params.note_language_code%type := null;
  l_new_language        fnd_languages.nls_language%type := null;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start IsPreparerToAuditorTransferred');

  if (p_funmode in ('QUESTION', 'ANSWER')) then

    -------------------------------------------------------------------
    l_debug_info := 'Need to generate Note based on language setup';
    -------------------------------------------------------------------
    
    -------------------------------------------------------------------
    l_debug_info := 'Save original language';
    -------------------------------------------------------------------
    l_orig_language_code := userenv('LANG');
    select nls_language
    into   l_orig_language
    from   fnd_languages
    where  language_code = l_orig_language_code;

    -------------------------------------------------------------------
    l_debug_info := 'Check AP_EXPENSE_PARAMS.NOTE_LANGUAGE_CODE';
    -------------------------------------------------------------------
    begin
      select note_language_code
      into   l_new_language_code
      from   ap_expense_params;

      exception
        when no_data_found then
          null;
    end;

    -------------------------------------------------------------------
    l_debug_info := 'Else use instance base language';
    -------------------------------------------------------------------
    if (l_new_language_code is null) then
      select language_code
      into   l_new_language_code
      from   fnd_languages
      where  installed_flag in ('B');
    end if;

    -------------------------------------------------------------------
    l_debug_info := 'Set nls context to new language';
    -------------------------------------------------------------------
    select nls_language
    into   l_new_language
    from   fnd_languages
    where  language_code = l_new_language_code;

    fnd_global.set_nls_context(p_nls_language => l_new_language);

    -----------------------------------------
    l_debug_info := 'Get the Notification ID';
    -----------------------------------------
    l_notificationID := wf_engine.context_nid;

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                      p_item_key,
                                                      'EXPENSE_REPORT_ID');

    -----------------------------------------
    l_debug_info := 'Get the User Id';
    -----------------------------------------
    begin

      WF_DIRECTORY.GetRoleInfo2(wf_engine.context_user, l_role_info_tbl);
      AP_WEB_OA_MAINFLOW_PKG.GetUserId(l_role_info_tbl(1).orig_system_id, l_entered_by);

      exception
        when no_data_found then
          null;
    end;

    ------------------------------------------------------------
    l_debug_info := 'store the Request More Info question/answer as a note';
    ------------------------------------------------------------
    AP_WEB_NOTES_PKG.CreateERPrepToAudNote (
      p_report_header_id       => l_report_header_id,
      p_note                   => wf_core.translate(p_funmode)||'
'||wf_engine.context_user_comment,
      p_lang                   => l_new_language_code,
      p_entered_by             => l_entered_by
    );

    -------------------------------------------------------------------
    l_debug_info := 'Restore nls context to original language';
    -------------------------------------------------------------------
    fnd_global.set_nls_context(p_nls_language => l_orig_language);

  end if ;

  EXCEPTION
    WHEN OTHERS THEN
      Wf_Core.Context('AP_WEB_EXPENSE_WF', 'IsPreparerToAuditorTransferred',
                     p_item_type, p_item_key, to_char(0), l_debug_info);
      RAISE;

END IsPreparerToAuditorTransferred;

----------------------------------------------------------------------
PROCEDURE IsApprovalRequestTransferred(
                                p_item_type      IN VARCHAR2,
                                p_item_key       IN VARCHAR2,
                                p_actid          IN NUMBER,
                                p_funmode        IN VARCHAR2,
                                p_result         OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  l_debug_info         VARCHAR2(1000);

  l_notificationID     NUMBER;
  l_TransferNotificationID     NUMBER;
  l_TransferToID       NUMBER;
  l_Transferee         wf_users.name%type;
  l_TransferToName     wf_users.name%type;
  l_preparer_id        NUMBER;
  l_preparer_name      wf_users.name%type;
  l_preparer_display_name      wf_users.display_name%type;
  l_employee_id        NUMBER;
  l_AMEEnabled	       VARCHAR2(1);
  l_AmeMasterItemKey  VARCHAR2(30);
  l_forwarder          AME_UTIL.approverRecord2 default ame_util.emptyApproverRecord2;
  l_forwardee          AME_UTIL.approverRecord2 default ame_util.emptyApproverRecord2;
  l_notificationIn        ame_util2.notificationRecord default ame_util2.emptyNotificationRecord;
  l_approver_id	       NUMBER;
  l_approver_name      varchar2(240);
  l_approverResponse              varchar2(80); 
  l_approvalStatusIn      varchar2(20); 

  l_report_header_id	AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_entered_by 		NUMBER := fnd_global.user_id;
  l_role_info_tbl	wf_directory.wf_local_roles_tbl_type;

  l_orig_language_code	ap_expense_params.note_language_code%type := null;
  l_orig_language	fnd_languages.nls_language%type := null;
  l_new_language_code	ap_expense_params.note_language_code%type := null;
  l_new_language	fnd_languages.nls_language%type := null;

  C_WF_Version		NUMBER := 0;

  l_itemkey            wf_items.item_key%TYPE;
  l_approvalProcessCompleteYNOut  varchar2(1);
  l_nextApproversOut              ame_util.approversTable2;
  l_ApproverAuthority	varchar2(10);
  l_oldApproversOut     ame_util.approversTable2;
  -- Bug: 7463317
  l_approvers 		ame_util.approversTable2;
  l_approvalProcessCompleteYN varchar2(20) := ame_util.booleanFalse;

  CURSOR c_person_id IS
    SELECT orig_system_id
    FROM   wf_roles
    WHERE  orig_system = 'PER'
    AND    name = l_TransferToName;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start IsApprovalRequestTransferred');

  -- Bug 8278999(sodash) Used the AME API AME_API6.updateApprovalStatus so that the comments of one approver is visible to other approvers 
  IF(p_funmode = 'RESPOND') THEN 
        l_AMEEnabled := WF_ENGINE.GetItemAttrText(p_item_type, 
                                                p_item_key, 
                                                'AME_ENABLED'); 
 
       l_notificationID := wf_engine.context_nid; 
       
      IF(nvl(l_AMEEnabled,'N')='Y') THEN 
        l_AmeMasterItemKey := WF_ENGINE.GetItemAttrText(p_item_type, 
                                       p_item_key, 
                                       'AME_MASTER_ITEM_KEY'); 
        l_approver_name := WF_ENGINE.GetItemAttrText(p_item_type, 
                                             p_item_key, 
                                            'APPROVER_NAME'); 
        l_forwarder.name := l_approver_name; 
        l_approverResponse := WF_NOTIFICATION.GetAttrText(l_notificationID,'RESULT'); 
        -- Bug 9011191 l_approverResponse is set to null in case of timeouts.
          IF (l_approverResponse = 'APPROVED') THEN 
             l_approvalStatusIn := AME_UTIL.approvedStatus; 
          ELSIF (l_approverResponse = 'REJECTED') THEN 
             l_approvalStatusIn := AME_UTIL.rejectStatus; 
          ELSIF (l_approverResponse = 'NO_RESPONSE' OR l_approverResponse IS NULL) THEN 
             l_approvalStatusIn := AME_UTIL.noResponseStatus; 
          ELSIF (l_approverResponse = 'FYI') THEN 
             l_approvalStatusIn := AME_UTIL.notifiedStatus; 
          END IF; 
 
          l_forwarder.approval_status := l_approvalStatusIn; 
          l_notificationIn.notification_id := l_notificationID; 
          l_notificationIn.user_comments := wf_engine.context_user_comment; 
           
        AME_API6.updateApprovalStatus(applicationIdIn    => AP_WEB_DB_UTIL_PKG.GetApplicationID, 
                              transactionTypeIn  => p_item_type, 
                              transactionIdIn    => l_AmeMasterItemKey, 
                              approverIn => l_forwarder, 
                              notificationIn => l_notificationIn, 
                              forwardeeIn => l_forwardee); 
      END IF; 
    END IF;   

  if (p_funmode in ('QUESTION', 'ANSWER')) then

    -------------------------------------------------------------------
    l_debug_info := 'Need to generate Note based on language setup';
    -------------------------------------------------------------------
    
    -------------------------------------------------------------------
    l_debug_info := 'Save original language';
    -------------------------------------------------------------------
    l_orig_language_code := userenv('LANG');
    select nls_language
    into   l_orig_language
    from   fnd_languages
    where  language_code = l_orig_language_code;

    -------------------------------------------------------------------
    l_debug_info := 'Check AP_EXPENSE_PARAMS.NOTE_LANGUAGE_CODE';
    -------------------------------------------------------------------
    begin
      select note_language_code
      into   l_new_language_code
      from   ap_expense_params;

      exception
        when no_data_found then
          null;
    end;

    -------------------------------------------------------------------
    l_debug_info := 'Else use instance base language';
    -------------------------------------------------------------------
    if (l_new_language_code is null) then
      select language_code
      into   l_new_language_code
      from   fnd_languages
      where  installed_flag in ('B');
    end if;

    -------------------------------------------------------------------
    l_debug_info := 'Set nls context to new language';
    -------------------------------------------------------------------
    select nls_language
    into   l_new_language
    from   fnd_languages
    where  language_code = l_new_language_code;

    fnd_global.set_nls_context(p_nls_language => l_new_language);

    -----------------------------------------
    l_debug_info := 'Get the Notification ID'; 
    -----------------------------------------
    l_notificationID := wf_engine.context_nid;

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                      p_item_key,
                                                      'EXPENSE_REPORT_ID');

    -----------------------------------------
    l_debug_info := 'Get the User Id'; 
    -----------------------------------------
    begin

      WF_DIRECTORY.GetRoleInfo2(wf_engine.context_user, l_role_info_tbl);
      AP_WEB_OA_MAINFLOW_PKG.GetUserId(l_role_info_tbl(1).orig_system_id, l_entered_by);

      exception
        when no_data_found then
          null;
    end;

    ------------------------------------------------------------
    l_debug_info := 'store the Request More Info question/answer as a note';
    ------------------------------------------------------------
    AP_WEB_NOTES_PKG.CreateERPrepToAudNote (
      p_report_header_id       => l_report_header_id,
      p_note                   => wf_core.translate(p_funmode)||'
'||wf_engine.context_user_comment,
      p_lang                   => l_new_language_code,
      p_entered_by             => l_entered_by
    );

    -------------------------------------------------------------------
    l_debug_info := 'Restore nls context to original language';
    -------------------------------------------------------------------
    fnd_global.set_nls_context(p_nls_language => l_orig_language);

  elsif (p_funmode in ('TRANSFER','FORWARD')) then
    -----------------------------------------
    l_debug_info := 'Get the Notification ID'; 
    -----------------------------------------
    l_notificationID := wf_engine.context_nid;

    -----------------------------------------
    l_debug_info := 'Get information on the transfer to'; 
    -----------------------------------------
    -- wf_engine.context_text = new responder
    l_Transferee := wf_engine.context_text;

    -----------------------------------------
    l_debug_info := 'check for transferee received through email/web';
    -----------------------------------------
    IF (substrb(l_Transferee,1,6) = 'email:') THEN
        l_TransferToName := substrb(l_Transferee,7);
    ELSE
        -- response received through web or form
        l_TransferToName := l_Transferee;
    END IF;

    -----------------------------------------
    l_debug_info := 'Get the transferee id'; 
    -----------------------------------------
    OPEN c_person_id;
      FETCH c_person_id into l_TransferToID;
      IF c_person_id%NOTFOUND THEN
        p_result := wf_engine.eng_completed||':'||wf_engine.eng_null;
      	Wf_Core.Raise(wf_core.translate('NO_ROLE_FOUND'));
      	RETURN;
      ELSE
        IF l_TransferToID IS NULL THEN
          p_result := wf_engine.eng_completed||':'||wf_engine.eng_null;
          Wf_Core.Raise(wf_core.translate('PERSON_ID_NULL'));
          RETURN;
      	END IF;
      END IF;
      CLOSE c_person_id;

    IF (l_TransferToID IS NOT NULL) THEN
      ----------------------------------
      l_debug_info := 'Get AME_ENABLED';
      ----------------------------------
      l_AMEEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
  					        p_item_key,
  					        'AME_ENABLED');

      IF (l_AMEEnabled = 'Y') THEN

        C_WF_VERSION  :=  GetFlowVersion(p_item_type, p_item_key);
        IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_R120_Version) THEN
          l_itemkey := WF_ENGINE.GetItemAttrText(p_item_type,
 					       p_item_key,
					       'AME_MASTER_ITEM_KEY');
        ELSE
          l_itemkey := p_item_key;
        END IF;

        -- For bug 3062917, if AME is enabled and the approval is forwarded,
        -- need to set approval status to ame_util.forwardStatus so the 
        -- current approver doesn't have to approve again later.

        ----------------------------------------------------------------
        l_debug_info := 'Retrieving APPROVER_ID Item Attribute';
        ----------------------------------------------------------------
        l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						     p_item_key,
						     'APPROVER_ID');

        ------------------------------------------------------
        l_debug_info := 'Retrieve Approver_ID Item Attribute';
        -------------------------------------------------------
        l_approver_name := WF_ENGINE.GetItemAttrText(p_item_type,
  						     p_item_key,
						    'APPROVER_NAME');

        ------------------------------------------------------
        -- Bug 7119347
        l_debug_info := 'Retrieve ApproverAuthority Item Attribute';
        -------------------------------------------------------
        begin
          l_ApproverAuthority := WF_ENGINE.GetItemAttrText(p_item_type,
  						     p_item_key,
						    'AME_APPROVER_AUTHORITY');
        exception
	  when others then
	    if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	         ame_api3.getOldApprovers(
       	               applicationIdIn   => AP_WEB_DB_UTIL_PKG.GetApplicationID,
	               transactionTypeIn => 'APEXP',
	               transactionIdIn   => l_itemkey,
	               oldApproversOut   => l_oldApproversOut);

                 FOR i IN 1 .. l_oldApproversOut.count LOOP
                   if l_oldApproversOut(i).orig_system_id = l_approver_id then
                      l_ApproverAuthority := l_oldApproversOut(i).authority;
                      exit;
                   end if;
                 END LOOP;
  	    else
	      raise;
	    end if;
        end;


        /*
        l_forwarder.user_id := null;
        l_forwarder.person_id := l_approver_id;
        l_forwarder.approval_status := ame_util.forwardStatus;
        l_forwarder.authority := ame_util.authorityApprover;

        l_forwardee.user_id := null; 
        l_forwardee.person_id := l_TransferToID;
        l_forwardee.api_insertion := ame_util.apiAuthorityInsertion;
        l_forwardee.authority := ame_util.authorityApprover;
        l_forwardee.approval_status := null;


        AME_API.updateApprovalStatus(applicationIdIn => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                                  transactionIdIn     => p_item_key,
				  approverIn          => l_forwarder,
                                  forwardeeIn         => l_forwardee,
                                  transactionTypeIn   => p_item_type);
        */

        /*l_forwarder.name := l_approver_name;
        l_forwarder.approval_status := ame_util.forwardStatus;
        l_forwarder.authority := nvl(l_ApproverAuthority,ame_util.authorityApprover);*/

        -- Bug: 7463317
        ame_api2.getAllApprovers7
	   (applicationIdIn                => AP_WEB_DB_UTIL_PKG.GetApplicationID
	   ,transactionTypeIn              => 'APEXP'
	   ,transactionIdIn                => l_itemkey
	   ,approvalProcessCompleteYNOut   => l_approvalProcessCompleteYN 
	   ,approversOut                   => l_approvers);

        -- Bug: 7463317, find the forwarder record. Exit from the loop when found
        FOR i IN 1 .. l_approvers.count LOOP
           if l_approvers(i).orig_system_id = l_approver_id then
              l_forwarder := l_approvers(i);
              -- Bug: 7463317, set the approval status to forwarded so that AME does not wait for
              -- the approval from the forwarder when vacation rules are set.
	      l_forwarder.approval_status := ame_util.forwardStatus;
              exit;
           end if;
        END LOOP;

        l_forwardee.name := l_TransferToName;
        l_forwardee.authority := nvl(l_ApproverAuthority,ame_util.authorityApprover);

        -- Bug: 7463317, change the if condition according to the suggestions by AME
	if (l_forwarder.authority = ame_util.authorityApprover and
	  l_forwarder.api_insertion <>  ame_util.apiInsertion) then
          l_forwardee.api_insertion := ame_util.apiAuthorityInsertion;
        else
          l_forwardee.api_insertion := ame_util.apiInsertion;
        end if;
        l_forwardee.approval_status := null;

	l_notificationIn.notification_id := l_notificationID;
        l_notificationIn.user_comments := wf_engine.context_user_comment;

        -- Bug 8278999(sodash) Used the AME API AME_API6.updateApprovalStatus so that the comments of one approver is visible to other approvers when the notification is transferred or forwarded
	AME_API6.updateApprovalStatus(applicationIdIn    => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                              	    transactionTypeIn  => p_item_type,   
                               	    transactionIdIn    => l_itemkey,  
                                    approverIn => l_forwarder,
				    notificationIn => l_notificationIn,
                                    forwardeeIn => l_forwardee);
	/*AME_API2.updateApprovalStatus(applicationIdIn    => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                              	    transactionTypeIn  => p_item_type,   
                               	    transactionIdIn    => l_itemkey,  
                                    approverIn => l_forwarder,
                                    forwardeeIn => l_forwardee); */

        -- 5135505: After re-assign the status of forwardee is null
        -- calling getNextApprover[n] will return forwardee and set the status to notified.
        begin                                    
           AME_API2.getNextApprovers4(applicationIdIn   => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                              transactionTypeIn => p_item_type,
	                      transactionIdIn   => l_itemkey,
                              approvalProcessCompleteYNOut => l_approvalProcessCompleteYNOut,
			      nextApproversOut   => l_nextApproversOut);        
	exception
	  when others then
	    null;
	end;

      END IF;    
    END IF;


    if (p_funmode in ('TRANSFER') OR (l_AMEEnabled = 'Y')) then
    
	    -----------------------------------------
	    l_debug_info := 'set the transferring Approver info to the Transferor';
	    -----------------------------------------
	    WF_ENGINE.SetItemAttrText(p_item_type,
				      p_item_key,
				      'TRANSFER_APPROVER_DISPLAY_NAME',
				      WF_ENGINE.GetItemAttrText(p_item_type,
								p_item_key,
								'APPROVER_DISPLAY_NAME'));

	    -----------------------------------------------------------
	    l_debug_info := 'Record the forward from info';
	    -----------------------------------------------------------
	    if (l_AMEEnabled = 'Y') then
	      RecordForwardFromInfo(p_item_type, p_item_key, p_actid, 'TRANSFER', p_result);
	    else
	      RecordForwardFromInfo(p_item_type, p_item_key, p_actid, p_funmode, p_result);
	    end if;

	    -----------------------------------------
	    l_debug_info := 'set the current Approver info to the Transferee';
	    -----------------------------------------
	    SetPersonAs(l_TransferToID,
			p_item_type,
			p_item_key,
			'APPROVER');

	    -------------------------------------------------------
	    l_debug_info := 'Retrieve Preparer_ID Item Attribute';
	    -------------------------------------------------------
	    l_preparer_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
							 p_item_key,
							 'PREPARER_ID');

	    -------------------------------------------------------
	    l_debug_info := 'Retrieve Employee_ID Item Attribute';
	    -------------------------------------------------------
	    l_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
 	                                                 p_item_key,
 	                                                 'EMPLOYEE_ID');

	    --Bug 2742114:raise exception when preparer id and trasferee is same.

	    IF l_preparer_id = l_TransferToID THEN
	      FND_MESSAGE.SET_NAME('SQLAP','OIE_TRANSFEREE_CANTBE_PREPARER');
	      app_exception.raise_exception;
	    ELSIF ((l_preparer_id <> l_employee_id) and (l_employee_id = l_TransferToID)) THEN
	      FND_MESSAGE.SET_NAME('SQLAP','OIE_TRANSFEREE_CANTBE_EMPLOYEE');
	      app_exception.raise_exception;
	    END IF;


	    ----------------------------------------------------------
	    l_debug_info := 'Get Preparer Name Info For Preparer_Id';
	    ----------------------------------------------------------
	    WF_DIRECTORY.GetUserName('PER',
				     l_preparer_id,
				     l_preparer_name,
				     l_preparer_display_name);

	    /* Bug 3545282 : Set the #FROM_ROLE */
	    -----------------------------------------------------------
	    l_debug_info := 'Set the FromRole to the previous approver';
	    -----------------------------------------------------------

	    SetFromRoleForwardFrom(p_item_type, p_item_key, p_actid, p_funmode, p_result);

	    -----------------------------------------
	    l_debug_info := 'send notification Notify Preparer About Approval Request Transfer';
	    -----------------------------------------
	    l_TransferNotificationID := WF_NOTIFICATION.SEND(
				 role         => l_preparer_name,
				 msg_type     => 'APEXP',
				 msg_name     => 'OIE_PREPARER_TRANSFER',
				 due_date     => null,
				 callback     => 'WF_ENGINE.CB',
				 context      => p_item_type||':'||p_item_key||':'||to_char(p_actid),
				 send_comment => null,
				 priority     => null);

	    if (l_TransferNotificationID is not null) then
	      -----------------------------------------
	      l_debug_info := 'set the notification attributes';
	      -----------------------------------------
	      WF_NOTIFICATION.SetAttrText(l_TransferNotificationID,
					  'DOCUMENT_NUMBER',
					  WF_ENGINE.GetItemAttrText(p_item_type,
								    p_item_key,
								    'DOCUMENT_NUMBER'));

	      WF_NOTIFICATION.SetAttrText(l_TransferNotificationID,
					  '#HDR_DISPLAY_TOTAL',
					  WF_ENGINE.GetItemAttrText(p_item_type,
								    p_item_key,
								    'DISPLAY_TOTAL'));

	    end if;

    end if;  

  end if;


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end IsApprovalRequestTransferred');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'IsApprovalRequestTransferred',
                     p_item_type, p_item_key, to_char(0), l_debug_info);
    RAISE;

END IsApprovalRequestTransferred;

----------------------------------------------------------------------
PROCEDURE CheckWFAdminNote(
                                p_item_type      IN VARCHAR2,
                                p_item_key       IN VARCHAR2,
                                p_actid          IN NUMBER,
                                p_funmode        IN VARCHAR2,
                                p_result         OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  l_debug_info         VARCHAR2(1000);

  l_notificationID     NUMBER;
  l_WFAdminNote        VARCHAR2(240) := NULL;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CheckWFAdminNote');

  if (p_funmode = 'RESPOND') then
    -----------------------------------------
    l_debug_info := 'Get the Notification ID'; 
    -----------------------------------------
    l_notificationID := wf_engine.context_nid;

    -----------------------------------------
    l_debug_info := 'Get WF Admin Note'; 
    -----------------------------------------
    l_WFAdminNote := WF_NOTIFICATION.GetAttrText(l_notificationID,
					         'WF_ADMIN_NOTE');

    /* Bug 2798344: The following code does got fire to raise a sql
       exception.  However, it appears to be a bug than a desired feature. 
    IF (l_WFAdminNote IS NULL OR replace(l_WFAdminNote, ' ', '') = '') THEN
      l_debug_info := 'Please provide specific instructions in the Note field.'; 
      Wf_Core.Raise('ICX_ALL_FIELDS_REQUIRED');
    end if;
    */
  end if;


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CheckWFAdminNote');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CheckWFAdminNote',
                     p_item_type, p_item_key, to_char(0), l_debug_info);
    RAISE;

END CheckWFAdminNote;

----------------------------------------------------------------------
PROCEDURE SetReturnStatusAndResetAttr(p_item_type      IN VARCHAR2,
                          p_item_key       IN VARCHAR2,
                          p_actid          IN NUMBER,
                          p_funmode        IN VARCHAR2,
                          p_result         OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info                     VARCHAR2(200);   
  l_report_header_id		   AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_payment_due			   VARCHAR2(10) := C_IndividualPay;
  l_No                     VARCHAR2(1) := 'N';
  l_AMEEnabled             VARCHAR2(1);
  C_WF_Version		   NUMBER := 0;
  l_n_resp_id		   NUMBER;	
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetReturnStatusAndResetAttr');

  IF (p_funmode = 'RUN') THEN  

    -----------------------------------------------------
    l_debug_info := 'Get Workflow Version Number';
    -----------------------------------------------------
    C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(p_item_type, p_item_key);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    l_AMEEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
					       p_item_key,
					       'AME_ENABLED');
    IF (l_AMEEnabled = 'Y') THEN

       --Bug 4425821: Uptake AME parallel approvers
       IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_R120_Version) THEN
          --------------------------------------------
          l_debug_info := 'Call AMEAbortRequestApprovals';
          --------------------------------------------
          AMEAbortRequestApprovals(l_report_header_id);
       END IF;

       -----------------------------------------
       l_debug_info := 'Call clearAllApprovals';
       -----------------------------------------
       AME_API2.clearAllApprovals(applicationIdIn => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                                 transactionIdIn => p_item_key, 
  			         transactionTypeIn => p_item_type);
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Set Returned status in report header';
    ------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.SetWkflApprvdFlagAndSource(l_report_header_id,
				AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_RETURNED, 
				'NonValidatedWebExpense')) THEN
	NULL;
    END IF;

    --AP_WEB_DB_VIOLATIONS_PKG.deleteViolationEntry(l_report_header_id);
    AP_WEB_AUDIT_QUEUE_UTILS.remove_from_queue(l_report_header_id);

    ----------------------------------------------------------
    l_debug_info := 'Clearing out lines in AP_AUD_AUDIT_REASONS';
    ----------------------------------------------------------
    -- Bug 4394168
      AP_WEB_AUDIT_UTILS.clear_audit_reason_codes(l_report_header_id);


    l_payment_due := WF_ENGINE.GetItemAttrText(p_item_type,p_item_key,'PAYMENT_DUE_FROM');

    IF (l_payment_due = C_CompanyPay) THEN
       IF (NOT AP_WEB_DB_EXPLINE_PKG.DeletePersonalLines(l_report_header_id)) THEN
	  NULL;
	END IF;
    END IF;

    /* Bug 6502501: cc trxns are detached from expense report when an
       expense report is returned. 
    IF (l_payment_due = C_CompanyPay OR l_payment_due = C_BothPay) THEN
        IF (NOT AP_WEB_DB_CCARD_PKG.ResetMgrRejectPersonalTrxns(
					l_report_header_id)) THEN
	   NULL;
	END IF;
    END IF;
    */

    -- 4001778/3654956 : reset the Apply Advances 
    --5060928: reset the Apply Advnaces only if OIE:Enable Advances = "Payables"
  
    begin

    l_n_resp_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'RESPONSIBILITY_ID');

     exception
  	when others then
  	   if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
  	       null;
  	   else
  	       raise;
  	  end if;
     end;
    
    IF FND_PROFILE.VALUE_SPECIFIC('OIE_ENABLE_ADVANCES',NULL,l_n_resp_id,200) = 'PAYABLES' THEN

	    AP_WEB_DB_EXPLINE_PKG.resetApplyAdvances(l_report_header_id);
    END IF;

    /* Bug 4019412 */
    AP_WEB_DB_EXPLINE_PKG.resetAPflags(l_report_header_id);
    ------------------------------------------------------------
    l_debug_info := 'Set which process to start from';
    ------------------------------------------------------------
    -- Indicate which process to start from 
    -- (skip ServerValidate, Manager Approval)
    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'START_FROM_PROCESS',
			      C_START_FROM_SERVER_VALIDATION);

    -- Reset the attributes which will not be set by code to initialize a
    -- process
    ------------------------------------------------------------
    l_debug_info := 'Reset attribute';
    ------------------------------------------------------------
    ResetAttrValues(p_item_type, p_item_key, p_actid);

    ----------------------------------------------------------
    l_debug_info := 'Reset Receipt Verified Flag to N';
    ----------------------------------------------------------
    -- Bug 4094871
    begin
      update ap_expense_report_lines
      set    receipt_verified_flag = l_No
      where  report_header_id = l_report_header_id;
    exception
      when others then null;
    end;

    ------------------------------------------------------------
    l_debug_info := 'Raise Receipts Aborted Event';
    ------------------------------------------------------------
    AP_WEB_RECEIPTS_WF.RaiseAbortedEvent(l_report_header_id);
    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetReturnStatusAndResetAttr');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetReturnStatusAndResetAttr',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    RAISE;

END SetReturnStatusAndResetAttr;

----------------------------------------------------------------------
PROCEDURE SetFromRoleBeforeApproval(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info                  VARCHAR2(200);
  l_find_approver_count         NUMBER;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetFromRoleBeforeApproval');

  IF (p_funmode = 'RUN') THEN
    ----------------------------------------------------------------
    l_debug_info := 'Retrieving Find_Approver_Count Item Attribute';
    ----------------------------------------------------------------
    l_find_approver_count := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                         p_item_key,
                                                         'FIND_APPROVER_COUNT');

    IF (l_find_approver_count = 1) THEN
      ----------------------------------------------------------------
      l_debug_info := 'Set #FROM_ROLE to Preparer';
      ----------------------------------------------------------------
      SetFromRoleEmployee(p_item_type, p_item_key, p_actid, p_funmode, p_result);
    ELSE
      ----------------------------------------------------------------
      l_debug_info := 'Set #FROM_ROLE to Forward From';
      ----------------------------------------------------------------
      SetFromRoleForwardFrom(p_item_type, p_item_key, p_actid, p_funmode, p_result);
    END IF;

    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetFromRoleBeforeApproval');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetFromRoleBeforeApproval',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SetFromRoleBeforeApproval;

----------------------------------------------------------------------
PROCEDURE SetFromRolePreparer(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info                  VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetFromRolePreparer');

  IF (p_funmode = 'RUN') THEN
    ----------------------------------------------------------------
    l_debug_info := 'Set #FROM_ROLE to Preparer';
    ----------------------------------------------------------------
    SetFromRole(p_item_type, 
            p_item_key, 
            p_actid, 
            WF_ENGINE.GetItemAttrText(p_item_type, 
                                      p_item_key, 
                                      'PREPARER_NAME'), 
            'SetFromRolePreparer' 
            ); 

    /*
    WF_ENGINE.SetItemAttrText(p_item_type,
                              p_item_key,
                              '#FROM_ROLE',
                              WF_ENGINE.GetItemAttrText(p_item_type,
                                                        p_item_key,
                                                        'PREPARER_NAME'));
    */
    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetFromRolePreparer');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetFromRolePreparer',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SetFromRolePreparer;

----------------------------------------------------------------------
PROCEDURE SetFromRoleEmployee(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info                  VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetFromRoleEmployee');

  IF (p_funmode = 'RUN') THEN
    ----------------------------------------------------------------
    l_debug_info := 'Set #FROM_ROLE to Employee';
    ----------------------------------------------------------------
    SetFromRole(p_item_type, 
            p_item_key, 
            p_actid, 
            WF_ENGINE.GetItemAttrText(p_item_type, 
                                      p_item_key, 
                                      'EMPLOYEE_NAME'), 
            'SetFromRoleEmployee' 
            ); 

    /*
    WF_ENGINE.SetItemAttrText(p_item_type, 
                              p_item_key, 
                              '#FROM_ROLE',
                              WF_ENGINE.GetItemAttrText(p_item_type,
                                                        p_item_key,
                                                        'EMPLOYEE_NAME'));
    */
    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetFromRoleEmployee');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetFromRoleEmployee',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SetFromRoleEmployee;

----------------------------------------------------------------------
PROCEDURE SetFromRoleForwardFrom(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info                  VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetFromRoleForwardFrom');

  IF (p_funmode in ('RUN', 'TRANSFER')) THEN
    ----------------------------------------------------------------
    l_debug_info := 'Set #FROM_ROLE to Forward From';
    ----------------------------------------------------------------
    SetFromRole(p_item_type, 
            p_item_key, 
            p_actid, 
            WF_ENGINE.GetItemAttrText(p_item_type, 
                                      p_item_key, 
                                      'FORWARD_FROM_NAME'), 
            'SetFromRoleForwardFrom' 
            ); 

    /*
    WF_ENGINE.SetItemAttrText(p_item_type, 
                              p_item_key, 
                              '#FROM_ROLE',
                              WF_ENGINE.GetItemAttrText(p_item_type,
                                                        p_item_key,
                                                        'FORWARD_FROM_NAME'));
    */
    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetFromRoleForwardFrom');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetFromRoleForwardFrom',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SetFromRoleForwardFrom;

----------------------------------------------------------------------
PROCEDURE SetFromRoleApprover(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info                  VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetFromRoleApprover');

  IF (p_funmode = 'RUN') THEN
    ----------------------------------------------------------------
    l_debug_info := 'Set #FROM_ROLE to Approver';
    ----------------------------------------------------------------
    SetFromRole(p_item_type, 
            p_item_key, 
            p_actid, 
            WF_ENGINE.GetItemAttrText(p_item_type, 
                                      p_item_key, 
                                      'APPROVER_NAME'), 
            'SetFromRoleApprover' 
            ); 

    /*
    WF_ENGINE.SetItemAttrText(p_item_type, 
                              p_item_key, 
                              '#FROM_ROLE',
                              WF_ENGINE.GetItemAttrText(p_item_type,
                                                        p_item_key,
                                                        'APPROVER_NAME'));
    */
    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetFromRoleApprover');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetFromRoleApprover',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SetFromRoleApprover;

----------------------------------------------------------------------
PROCEDURE SetStatusApproverAndDate(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_current_approver_id		NUMBER		:= NULL;
  l_expense_status_code         VARCHAR2(30)    := NULL;
  l_date_reset                  VARCHAR2(30)    := NULL;

  fixable_exception		EXCEPTION;
  l_error_message		VARCHAR2(2000);
  l_debug_info			VARCHAR2(200);
  l_source                      VARCHAR2(25)     := NULL;
  l_holds_setup                 VARCHAR2(2);
  l_report_submitted_date       DATE;
  l_org_id                      NUMBER;
  l_report_header_id            NUMBER;

BEGIN

  IF (p_funmode = 'RUN') THEN

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Expense Status Code Activity Attribute';
    -------------------------------------------------------------------
    l_expense_status_code := WF_ENGINE.GetActivityAttrText(p_item_type,
							    p_item_key,
                                                            p_actid,   
						     'EXPENSE_STATUS_CODE');

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Current Approver ID Activity Attribute';
    -------------------------------------------------------------------
    l_current_approver_id := WF_ENGINE.GetActivityAttrNumber(p_item_type,
							    p_item_key,
                                                            p_actid,   
						     'CURRENT_APPROVER_ID');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve ORG_ID Item Attribute';
    ------------------------------------------------------------
    l_org_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                            p_item_key,
                                            'ORG_ID');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                      p_item_key,
                                                      'EXPENSE_REPORT_ID');

    ----------------------------------------------------------
    l_debug_info := 'Get Expense Report data';
    ----------------------------------------------------------
    select report_submitted_date
    into   l_report_submitted_date
    from   ap_expense_report_headers
    where  report_header_id = l_report_header_id;

    IF (l_expense_status_code = 'INVOICED') THEN

       l_source := 'SelfService';

       l_holds_setup := AP_WEB_HOLDS_WF.IsHoldsRuleSetup(l_org_id,
                                                         l_report_submitted_date);
     
       IF (l_holds_setup = 'Y') THEN
          l_expense_status_code := AP_WEB_RECEIPTS_WF.C_PENDING_HOLDS;
       END IF;

    END IF;

    --Bug 4425821: Uptake AME parallel approvers
    -- replaced p_item_key with the l_report_header_id
    -------------------------------------------------------------------
    l_debug_info := 'Set Expense Status Code and Current Approver ID';
    -------------------------------------------------------------------
    UPDATE ap_expense_report_headers_all
    SET expense_status_code = l_expense_status_code,
        expense_current_approver_id = l_current_approver_id,
        expense_last_status_date=sysdate,
        source = nvl(l_source, source),
        last_updated_by = Decode(Nvl(fnd_global.user_id,-1),-1,last_updated_by,fnd_global.user_id) 
    WHERE report_header_id = l_report_header_id;

    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION
  WHEN fixable_exception THEN
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'ERROR_MESSAGE',
				l_error_message);

      p_result := 'COMPLETE:N';    
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetStatusApproverAndDate', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SetStatusApproverAndDate;

---------------------------------------------------------
PROCEDURE ZeroFindApproverCount(p_item_type	IN VARCHAR2,
		     	p_item_key	IN VARCHAR2,
		     	p_actid		IN NUMBER,
		     	p_funmode	IN VARCHAR2,
		     	p_result OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------
  l_find_approver_count		NUMBER;
  l_debug_info			VARCHAR2(200);  
BEGIN

  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Retrieving Find_Approver_Count Item Attribute';
    ----------------------------------------------------------------
    l_find_approver_count := WF_ENGINE.GetItemAttrNumber(p_item_type,
						         p_item_key,
						       'FIND_APPROVER_COUNT');

    IF (l_find_approver_count = 0) THEN
      -----------------------------------------------
      -- return yes when find_approver_count equals 0
      -----------------------------------------------
      p_result := 'COMPLETE:Y';
    ELSE
      ---------------------------------------------------
      -- return no if find_approver_count doesn't equal 0
      ---------------------------------------------------
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN

    p_result := 'COMPLETE';

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ZeroFindApproverCount', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END ZeroFindApproverCount;

/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      WithdrawExpenseRep                                                    |
 |                                                                            |
 | DESCRIPTION                                                                |
 |      Withdraw the expense report from workflow approval                    |
 |         bug1552747
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |      p_employee_id           NUMBER    -- Expense Report Header ID         |
 | RETURNS                                                                    |
 |     none                                                                   |
 *----------------------------------------------------------------------------*/
 
PROCEDURE WithdrawExpenseRep(
   p_rep_header_id IN AP_EXPENSE_REPORT_LINES.report_header_id%TYPE)
IS
  l_itemkey            wf_items.item_key%TYPE;
  l_itemtype           wf_items.item_type%TYPE := 'APEXP';
  l_document_number    AP_WEB_DB_EXPRPT_PKG.expHdr_invNum;
  l_doc_cctr           VARCHAR2(2000);
  l_preparer_name      VARCHAR2(2000);
  l_employee_name      VARCHAR2(2000);
  l_purpose            VARCHAR2(2400);
  l_payable_admin      wf_notifications.recipient_role%TYPE;
  l_currency           VARCHAR2(50);
  l_total              VARCHAR2(200);
  l_payment_due        VARCHAR2(100);
  l_nid                wf_notifications.notification_id%TYPE;
  l_debug_info         VARCHAR2(200);
  l_wf_active          BOOLEAN := FALSE;
  l_wf_exist           BOOLEAN := FALSE;
  l_end_date           wf_items.end_date%TYPE;
  l_AMEEnabled         VARCHAR2(1);
  l_receipts_status    VARCHAR2(30);

  l_entered_by          NUMBER := fnd_global.user_id;
  l_note		varchar2(2000);
  l_message_name	fnd_new_messages.message_name%type := 'OIE_WITHDRAWN_NOTE';
    
  l_orig_language_code  ap_expense_params.note_language_code%type := null;
  l_orig_language       fnd_languages.nls_language%type := null;
  l_new_language_code   ap_expense_params.note_language_code%type := null;
  l_new_language        fnd_languages.nls_language%type := null;

  l_No                     VARCHAR2(1) := 'N';
  C_WF_Version		NUMBER          := 0;  
  l_n_resp_id           NUMBER;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF',
     'start WF WithdrawExpenseRep');

  l_itemkey         := to_char(p_rep_header_id);
  begin
    select   end_date
    into     l_end_date
    from     wf_items
    where    item_type = l_itemtype
    and      item_key  = l_itemkey;

       if l_end_date is NULL then
          l_wf_active := TRUE;
       else
          l_wf_active := FALSE;
       end if;
       l_wf_exist  := TRUE;
  exception
     when no_data_found then
        l_wf_active := FALSE;
        l_wf_exist  := FALSE;
  end;

  -----------------------------------------------------
  l_debug_info := 'Get Workflow Version Number';
  -----------------------------------------------------
  C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(l_itemtype, l_itemkey);

  if l_wf_exist then
     l_debug_info := 'Get Attribute values';
     l_preparer_name   := WF_ENGINE.GetItemAttrText(
                             itemtype => l_itemtype,
                             itemkey  => l_itemkey,
                             aname    => 'PREPARER_DISPLAY_NAME');
     l_employee_name   := WF_ENGINE.GetItemAttrText(
                             itemtype => l_itemtype,
                             itemkey  => l_itemkey,
                             aname    => 'EMPLOYEE_DISPLAY_NAME');
     l_document_number := WF_ENGINE.GetItemAttrText(
                             itemtype => l_itemtype,
                             itemkey  => l_itemkey,
                             aname    => 'DOCUMENT_NUMBER');
     l_payable_admin   := WF_ENGINE.GetItemAttrText(
                             itemtype => l_itemtype,
                             itemkey  => l_itemkey,
                             aname    => 'PAYABLES');
     l_total           := WF_ENGINE.GetItemAttrText(
                             itemtype => l_itemtype,
                             itemkey  => l_itemkey,
                             aname    => 'DISPLAY_TOTAL');
     l_currency        := WF_ENGINE.GetItemAttrText(
                             itemtype => l_itemtype,
                             itemkey  => l_itemkey,
                             aname    => 'CURRENCY');
     l_doc_cctr        := WF_ENGINE.GetItemAttrText(
                             itemtype => l_itemtype,
                             itemkey  => l_itemkey,
                             aname    => 'DOC_COST_CENTER');
     l_purpose         := WF_ENGINE.GetItemAttrText(
                             itemtype => l_itemtype,
                             itemkey  => l_itemkey,
                             aname    => 'PURPOSE');

  end if;

  l_debug_info := 'Update AME as if rejected';
  -- Bug 3560082 - Comment the call to SetRejectStatusInAME and add the call
  -- AME_API.clearAllApprovals
  l_AMEEnabled := WF_ENGINE.GetItemAttrText(l_itemtype,
					    l_itemkey,
					    'AME_ENABLED');
  if (l_AMEEnabled = 'Y') then
     --Bug 4425821: Uptake AME parallel approvers
     if (C_WF_Version >= AP_WEB_EXPENSE_WF.C_R120_Version) then
        --------------------------------------------
        l_debug_info := 'Call AMEAbortRequestApprovals';
        --------------------------------------------
        AMEAbortRequestApprovals(p_rep_header_id, 'Y');
     end if;

     -----------------------------------------
     l_debug_info := 'Call clearAllApprovals';
     -----------------------------------------
     AME_API2.clearAllApprovals(applicationIdIn => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                               transactionIdIn => l_itemkey, 
  			       transactionTypeIn => l_itemtype);                        
  end if;

  l_debug_info := 'Set withdraw status in report header';
  IF (NOT AP_WEB_DB_EXPRPT_PKG.SetWkflApprvdFlagAndSource(p_rep_header_id,
             AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_WITHDRAW,
             'NonValidatedWebExpense')) THEN
    NULL;
  END IF;

  AP_WEB_DB_EXPLINE_PKG.resetAPflags(p_rep_header_id);

  -- 4001778/3654956
  --5060928: reset the Apply Advnaces only if OIE:Enable Advances = "Payables"

    begin

    l_n_resp_id := WF_ENGINE.GetItemAttrNumber(l_itemtype,
                                               l_itemkey,
                                               'RESPONSIBILITY_ID');

     exception
  	when others then
  	   if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
  	       null;
  	   else
  	       raise;
  	  end if;
     end;
    
    IF FND_PROFILE.VALUE_SPECIFIC('OIE_ENABLE_ADVANCES',NULL,l_n_resp_id,200) = 'PAYABLES' THEN

	    AP_WEB_DB_EXPLINE_PKG.resetApplyAdvances(p_rep_header_id);
    END IF;

  --AP_WEB_DB_VIOLATIONS_PKG.deleteViolationEntry(p_rep_header_id);
  AP_WEB_AUDIT_QUEUE_UTILS.remove_from_queue(p_rep_header_id);

  ----------------------------------------------------------
  l_debug_info := 'Reset Report Submitted Date to null And Expense Status Code to WITHDRAWN';
  ----------------------------------------------------------
  -- Bug 4070441
  begin
    update ap_expense_report_headers
    set    report_submitted_date = null,
           expense_status_code = AP_WEB_OA_ACTIVE_PKG.C_WITHDRAWN
    where  report_header_id = p_rep_header_id;
  exception
    when others then null;
  end;

  ----------------------------------------------------------
  l_debug_info := 'Reset Receipt Verified Flag to N';
  ----------------------------------------------------------
  -- Bug 4094871
  begin
    update ap_expense_report_lines
    set    receipt_verified_flag = l_No
    where  report_header_id = p_rep_header_id;
  exception
    when others then null;
  end;
  ----------------------------------------------------------
  l_debug_info := 'Clearing out lines in AP_AUD_AUDIT_REASONS';
  ----------------------------------------------------------
  -- Bug 4394168
   AP_WEB_AUDIT_UTILS.clear_audit_reason_codes(p_rep_header_id);

  if l_wf_exist then
     l_debug_info := 'call reset credit card transactions 2';
     ResetCCardTxns(p_rep_header_id, l_itemtype, l_itemkey);

     if l_wf_active then
        l_debug_info := 'Workflow Abort Process';
        wf_engine.AbortProcess (itemtype => l_itemtype,
                                itemkey  => l_itemkey,
                                cascade  => TRUE);
     end if;

     l_debug_info := 'Purge workflow';
     wf_purge.Items(itemtype => l_itemtype,
                    itemkey  => l_itemkey);

     /* Bug 3772025 : Calling wf_purge.TotalPerm to purge workflow with persistence type
                 as 'Permanent'.
     */

     wf_purge.TotalPerm(itemtype => l_itemtype,
                        itemkey  => l_itemkey,
                        runtimeonly => TRUE);

     /*  Calling the WF_NOTIFICATION.SEND API first before setting the
         necessary WF_NOTIFICATION.SetAttr* API's is standard as directed
         by workflow Development team.  The actual sending of the notification
         will not happen until the COMMIT statement is issued.
     */ 
     -- Bug# 8937579 one-off for 5941554 - When there is no valid role set for PAYABLES attribute,
     -- return null to avoid overdue receipts notification for withdrawn reports
     begin
     l_debug_info := 'Sending FYI notification to Payable';
     l_nid := WF_NOTIFICATION.SEND(
                 role     => l_payable_admin,
                 msg_type => l_itemtype,
                 msg_name => 'OIE_WITHDRAW_WARNING');

     l_debug_info := 'Setting Notification Attributes';
     if l_nid is not null then
        WF_NOTIFICATION.SetAttrText(
           nid    => l_nid,
           aname  => 'DOCUMENT_NUMBER',
           avalue => l_document_number);
        WF_NOTIFICATION.SetAttrText(
           nid    => l_nid,
           aname  => '#HDR_EMPLOYEE_DISPLAY_NAME',
           avalue => l_employee_name);
        WF_NOTIFICATION.SetAttrText(
           nid    => l_nid,
           aname  => '#HDR_DISPLAY_TOTAL',
           avalue => l_total);
        WF_NOTIFICATION.SetAttrText(
           nid    => l_nid,
           aname  => '#HDR_DOC_COST_CENTER',
           avalue => l_doc_cctr);
        WF_NOTIFICATION.SetAttrText(
           nid    => l_nid,
           aname  => '#HDR_PURPOSE',
           avalue => l_purpose);
        -- Fix bug#2587575
        WF_NOTIFICATION.Denormalize_Notification(
           nid    => l_nid);
     end if;
     exception
      when others then
       null;
     end;
  end if;

    -------------------------------------------------------------------
    l_debug_info := 'Save original language';
    -------------------------------------------------------------------
    l_orig_language_code := userenv('LANG');
    select nls_language
    into   l_orig_language
    from   fnd_languages 
    where  language_code = l_orig_language_code;

    -------------------------------------------------------------------
    l_debug_info := 'Check AP_EXPENSE_PARAMS.NOTE_LANGUAGE_CODE';
    -------------------------------------------------------------------
    begin
      select note_language_code
      into   l_new_language_code
      from   ap_expense_params;

      exception
        when no_data_found then
          null;
    end;

    -------------------------------------------------------------------
    l_debug_info := 'Else use instance base language';
    -------------------------------------------------------------------
    if (l_new_language_code is null) then
      select language_code
      into   l_new_language_code
      from   fnd_languages
      where  installed_flag in ('B');
    end if;

    -------------------------------------------------------------------
    l_debug_info := 'Set nls context to new language';
    -------------------------------------------------------------------
    select nls_language
    into   l_new_language
    from   fnd_languages
    where  language_code = l_new_language_code;

    fnd_global.set_nls_context(p_nls_language => l_new_language);

    begin
      -------------------------------------------------------------------
      -- fnd_global.set_nls_context() seems to work for WF but not FND_MESSAGES
      -------------------------------------------------------------------
      select message_text
      into   l_note
      from   fnd_new_messages
      where  application_id = 200
      and    message_name = l_message_name
      and    language_code = l_new_language_code;

      exception
        when no_data_found then
          FND_MESSAGE.SET_NAME('SQLAP', l_message_name);
          l_note := FND_MESSAGE.GET;
    end;

    ------------------------------------------------------------
    l_debug_info := 'store the withdrawn note';
    ------------------------------------------------------------
    AP_WEB_NOTES_PKG.CreateERPrepToAudNote (
      p_report_header_id       => p_rep_header_id,
      p_note                   => l_note,
      p_lang                   => l_new_language_code
    );

    -------------------------------------------------------------------
    l_debug_info := 'Restore nls context to original language';
    -------------------------------------------------------------------
    fnd_global.set_nls_context(p_nls_language => l_orig_language);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF',
     'end WF WithdrawExpenseRep');
  COMMIT;

  ------------------------------------------------------------
  l_debug_info := 'Raise Receipts Aborted Event';
  ------------------------------------------------------------
  AP_WEB_RECEIPTS_WF.RaiseAbortedEvent(p_rep_header_id);

  COMMIT;


EXCEPTION
  WHEN OTHERS THEN
      ROLLBACK;
      APP_EXCEPTION.RAISE_EXCEPTION;
END WithdrawExpenseRep;


PROCEDURE GenerateExpClobLines(document_id		IN VARCHAR2,
				display_type	IN VARCHAR2,
				document	IN OUT NOCOPY CLOB,
				document_type	IN OUT NOCOPY VARCHAR2) IS

  l_colon    NUMBER;
  l_itemtype VARCHAR2(7);
  l_itemkey  VARCHAR2(25);

  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_receipt_missing_flag	AP_WEB_DB_EXPLINE_PKG.expLines_receiptMissingFlag;
  l_start_date			AP_WEB_DB_EXPLINE_PKG.expLines_startExpDate;
  l_days			VARCHAR2(4);
  l_daily_amt			AP_WEB_DB_EXPLINE_PKG.expLines_dailyAmount;
  l_receipt_curr		AP_WEB_DB_EXPLINE_PKG.expLines_receiptCurrCode;
  l_receipt_rate		VARCHAR2(5);
  l_receipt_amt			VARCHAR2(10);
  l_total_amt			AP_WEB_DB_EXPLINE_PKG.expLines_amount;
  l_expense_report_total_amt	AP_WEB_DB_EXPLINE_PKG.expLines_amount;
  l_cc_personal_total_amt	AP_WEB_DB_EXPLINE_PKG.expLines_amount;
  l_justification		AP_WEB_DB_EXPLINE_PKG.expLines_justification;
  l_expense_type		AP_WEB_DB_EXPTEMPLATE_PKG.expTempl_webFriendlyPrompt;
  l_project_number              PA_PROJECTS.segment1%TYPE;
  l_task_number                 AP_WEB_DB_PA_INT_PKG.tasks_taskNum;
  l_award_number		GMS_OIE_INT_PKG.gms_awardNum;
  l_credit_card_trx_id		AP_WEB_DB_EXPLINE_PKG.expLines_crdCardTrxID;
  l_distribution_line_number	AP_WEB_DB_EXPLINE_PKG.expLines_distLineNum;
  l_line_number			NUMBER := 0;
  l_primary_number		NUMBER := 1;
  l_line_display		VARCHAR2(5);
  l_counter			NUMBER := 1;
  l_violation_type		AP_LOOKUP_CODES.DISPLAYED_FIELD%TYPE;
  l_employee_project_enabled    VARCHAR2(1);
  -- Grants Integration
  l_grants_enabled		VARCHAR2(1) := 'N';
  l_project_string              VARCHAR2(100);
  l_line_info			VARCHAR2(2000);
  l_num_lines 	                NUMBER := 0;
  l_num_cc_lines 	        NUMBER := 0;
  l_num_personal_lines 	        NUMBER := 0;
  l_num_cash_lines 	        NUMBER := 0;
  l_table_loop_counter 	        NUMBER := 0;
  l_document_max 	        NUMBER := 25000; -- 27721 fails
  l_is_cc_table 	        BOOLEAN;
  l_currency			VARCHAR2(50);
  l_colspan			NUMBER := 0;

  l_prompts			AP_WEB_UTILITIES_PKG.prompts_table;
  l_title			AK_REGIONS_VL.name%TYPE;
  l_debug_info                  VARCHAR2(1000);

  XpenseLinesCursor 		AP_WEB_DB_EXPLINE_PKG.DisplayXpenseLinesCursor;
  PersonalLinesCursor 		AP_WEB_DB_EXPLINE_PKG.DisplayXpenseLinesCursor;

--Bug 2944363
  BothPayPersonalLinesCursor    AP_WEB_DB_EXPLINE_PKG.DisplayXpenseLinesCursor;  


  l_n_org_id Number;

  l_show_message                VARCHAR2(1) := 'N';
  l_message                     VARCHAR2(2000);
  l_rules_violated              VARCHAR2(1) := 'N';
  l_last_dist_number		AP_WEB_DB_EXPLINE_PKG.expLines_distLineNum
  := -1;

  l_document			long;

  l_flex_concatenated		AP_EXPENSE_REPORT_LINES.flex_concatenated%TYPE;
  l_line_accounting_enabled	VARCHAR2(30);
  l_line_accounting_defined	BOOLEAN;
  l_policy_violation_value      VARCHAR2(50);
  l_policy_violation_defined    BOOLEAN;
  l_n_resp_id 			Number;
  l_mrate_adjusted_flag		AP_EXPENSE_REPORT_LINES.mileage_rate_adjusted_flag%TYPE;
  l_mileage_note		VARCHAR2(2000);
  l_notification_type		VARCHAR2(10);
  l_print_violation		VARCHAR2(1) := 'N';
  l_merchant_name               AP_EXPENSE_REPORT_LINES.merchant_name%TYPE;
  l_co_merchant_count           NUMBER;

  l_num_both_personal_lines     NUMBER := 0; --Bug 2944363
  l_payment                     VARCHAR2(10);--Bug 2944363
  l_cc_trxn_date                VARCHAR2(50);--Bug 2944363
  l_cc_expensed_amt             AP_WEB_DB_EXPLINE_PKG.expLines_amount;--Bug 2944363
  l_cc_curr_code                VARCHAR2(20); --Bug 2944363
  l_cc_merchant_name            AP_CREDIT_CARD_TRXNS_ALL.merchant_name1%TYPE;--Bug 2944363  
  l_payment_due_from            VARCHAR2(10) := 'INDIVIDUAL';

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GenerateExpClobLines');

  ------------------------------------------------------------
  l_debug_info := 'Decode document_id';
  ------------------------------------------------------------
  l_colon    := instrb(document_id, ':');
  l_debug_info := ' First index: ' || to_char(l_colon);
  l_itemtype := substrb(document_id, 1, l_colon - 1);
  l_itemkey  := substrb(document_id, l_colon  + 1);
  l_colon    := instrb(l_itemkey, ':');

  ------------------------------------------------------------
  l_debug_info := 'Second index: ' || to_char(l_colon);
  ------------------------------------------------------------
  IF (l_colon > 0) THEN
    l_notification_type  := substrb(l_itemkey, l_colon  + 1);
    l_itemkey := substrb(l_itemkey, 1, l_colon - 1);
  ELSE
    l_notification_type := C_OTHER;
  END IF;

  ------------------------------------------------------------
  l_debug_info := 'Get prompts';
  ------------------------------------------------------------
  AP_WEB_DISC_PKG.getPrompts(200,'AP_WEB_WF_LINETABLE',l_title,l_prompts);

  ------------------------------------------------------------
  l_debug_info := 'Check Projects enabled';
  ------------------------------------------------------------
  l_employee_project_enabled := WF_ENGINE.GetItemAttrText(l_itemtype,
                                                          l_itemkey,
                                                          'EMPLOYEE_PROJECT_ENABLED');

  ------------------------------------------------------------
  l_debug_info := 'Check Grants enabled';
  ------------------------------------------------------------
  begin
  l_grants_enabled := WF_ENGINE.GetItemAttrText(l_itemtype,
                                                          l_itemkey,
                                                          'GRANTS_ENABLED');

  ------------------------------------------------------------
  l_debug_info := 'Get responsibility id';
  ------------------------------------------------------------
  l_n_resp_id := WF_ENGINE.GetItemAttrNumber(l_itemtype,
  	 				       l_itemkey,
  					       'RESPONSIBILITY_ID');

  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
  end;
 
  ------------------------------------------------------------
  l_debug_info := 'Check line level accounting enabled';
  ------------------------------------------------------------
  FND_PROFILE.get_specific('OIE_ENABLE_LINE_LEVEL_ACCOUNTING', null,
  l_n_resp_id, 200, l_line_accounting_enabled, l_line_accounting_defined);


   if l_line_accounting_defined then
     l_line_accounting_enabled := NVL(l_line_accounting_enabled,'N');
   else
     l_line_accounting_enabled := 'N';
   end if;

   ------------------------------------------------------------
  l_debug_info := 'Get policy profile option'; 
  ------------------------------------------------------------
  FND_PROFILE.get_specific('AP_WEB_POLICY_VIOLATION_SUBMIT', null,
    l_n_resp_id, 200, l_policy_violation_value, l_policy_violation_defined);

  if l_policy_violation_defined then
    l_policy_violation_value := NVL(l_policy_violation_value, C_ALLOW_NO_WARNINGS);
  else
    l_policy_violation_value := C_ALLOW_NO_WARNINGS;
  end if;

 ------------------------------------------------------------
  l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(l_itemtype,
				      l_itemkey,
				     'EXPENSE_REPORT_ID');

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Currency Item Attribute';
  ------------------------------------------------------------
  l_currency := WF_ENGINE.GetItemAttrText(l_itemtype,
			    l_itemkey,
			    'CURRENCY');

  ------------------------------------------------------------
  l_debug_info := 'Retrieve MILEAGE NOTE Item Attribute';
  ------------------------------------------------------------
  begin
  l_mileage_note := WF_ENGINE.GetItemAttrText(l_itemtype,
			    l_itemkey,
			    'MILEAGE_NOTE');
  exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
  end;

  --------------------------------------------
  l_debug_info := 'Get Org Id';
  --------------------------------------------
  begin

    l_n_org_id := WF_ENGINE.GetItemAttrNumber(l_itemtype,
			      l_itemkey,
			      'ORG_ID');
    exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    -- ORG_ID item attribute doesn't exist, need to add it
	    WF_ENGINE.AddItemAttr(l_itemtype, l_itemkey, 'ORG_ID');
      	    IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(
				to_number(l_itemkey),
				l_n_org_id) <> TRUE ) THEN
	       l_n_org_id := NULL;
      	    END IF;

    	    WF_ENGINE.SetItemAttrNumber(l_itemtype,
                              	l_itemkey,
                              	'ORG_ID',
                              	l_n_org_ID);
	  else
	    raise;
	  end if;

  end;

  if (l_n_org_id is not null) then
    fnd_client_info.set_org_context(l_n_org_id);
  else
    -- Report was submitted before org_id being added, hence org_id
    -- item attributes hasn't been set yet. Need to get it from
    -- report header
    IF (AP_WEB_DB_EXPRPT_PKG.GetOrgIdByReportHeaderId(to_number(l_itemkey), l_n_org_id) <> TRUE ) THEN
      l_n_org_id := NULL;
    END IF;

    IF (l_n_org_id is not null) then
      fnd_client_info.set_org_context(l_n_org_id);
    END IF;

  end if; -- l_n_org_id 

  --------------------------------------------
  l_debug_info := 'get Number of ExpLines';
  --------------------------------------------
  if (AP_WEB_DB_EXPLINE_PKG.GetNumberOfExpLines(l_report_header_id, l_num_lines)) then null; end if;

  if (l_num_lines = 0) then

    /*Bug 2944363: Dont raise SHORTPAID error if the expense report
                   does not have any lines. raise it conditionally because
                   an ER in BOTHPAY having only personal CC trx will
                   also not have any lines.
    */
    --AMMISHRA - Both Pay Personal Only Lines project.
    if (AP_WEB_DB_EXPLINE_PKG.GetNoOfBothPayPersonalLines(l_report_header_id,l_num_both_personal_lines)) then null; end if;

    ----------------------------------------------------------------
    l_debug_info := 'Retrieve Profile Option Payment Due From';
    ----------------------------------------------------------------

    IF (NOT AP_WEB_DB_EXPRPT_PKG.getPaymentDueFromReport(to_number(l_itemkey),l_payment)) THEN
        l_debug_info := 'Could not set workflow attribute Payment_Due_From';
    END IF;

    IF (l_payment = 'BOTH' and l_num_both_personal_lines > 0) THEN
      NULL;
    ELSE
      FND_MESSAGE.SET_NAME('SQLAP','AP_WEB_EXP_REPORT_SHORTPAID');
      WF_NOTIFICATION.WriteToClob(document,fnd_message.get);
      document_type := display_type;
      return;
    END IF;
    --Bug 2944363 End here.  

  end if;

  l_document := '';
  if (display_type = 'text/plain') then
    l_num_lines :=  0;
    --------------------------------------------
    l_debug_info := 'Generate Table Header';
    --------------------------------------------

    --------------------------------------------
    l_debug_info := 'Open Expense Lines Cursor';
    --------------------------------------------
    IF (AP_WEB_DB_EXPLINE_PKG.GetDisplayXpenseLinesCursor(l_report_header_id, XpenseLinesCursor)) THEN

    LOOP

      --------------------------------------------
      l_debug_info := 'Fetch Expense Lines Cursor';
      --------------------------------------------
      FETCH XpenseLinesCursor INTO l_receipt_missing_flag,
                           l_start_date,
                           l_days,
                           l_daily_amt,
                           l_receipt_curr,
                           l_receipt_rate,
                           l_receipt_amt,
                           l_total_amt,
                           l_justification,
                           l_expense_type,
                           l_project_number,
                           l_task_number,
                           l_credit_card_trx_id,
                           l_distribution_line_number,
			   l_award_number,
			   l_violation_type,
			   l_merchant_name;

      EXIT WHEN XpenseLinesCursor%NOTFOUND;

      l_num_lines :=  l_num_lines + 1;

      -------------------------------------------------------------------
      l_debug_info := 'Check if Receipt missing, print * next to line and set boolean flag';
      -------------------------------------------------------------------
      IF (l_receipt_missing_flag = 'Y') THEN
         l_line_info := ' * ';
      ELSE
         l_line_info := '   ';
      END IF;

      --------------------------------------------
      l_debug_info := 'Format Expense Line Info';
      --------------------------------------------
      l_project_string := '';
      IF (l_project_number IS NOT NULL) THEN
	 l_project_string := l_project_number || ' ' || l_task_number;
 	 if (l_grants_enabled = 'Y') then
           l_project_string := l_project_string || ' ' || l_award_number;
	 end if;
      END IF;
      l_line_info := '(' || to_char(l_num_lines) || ')' || l_line_info || ' '|| l_start_date
                             || l_expense_type || ' ' || l_project_string
                             || ' ' || LPAD(to_char(l_total_amt, FND_CURRENCY.Get_Format_Mask(l_currency,22)),14);
      -- set a new line
      l_document := l_document || '
';
      l_document := l_document || l_line_info;
      -- set a new line
      l_document := l_document || '
';
      l_document := l_document || '----> ' || l_justification;
      l_line_info := '';

    END LOOP; -- GetDisplayXpenseLinesCursor 

    END IF; -- GetDisplayXpenseLinesCursor 

    if XpenseLinesCursor%isopen then /*Bug 3422298 */
       close XpenseLinesCursor;
    end if;

  else  -- text/html

    --------------------------------------------
    l_debug_info := 'get Number of Cash/Credit Card lines';
    --------------------------------------------
    if (AP_WEB_DB_EXPLINE_PKG.GetNumCCLinesIncluded(l_report_header_id, l_num_cc_lines)) then null; end if; 
    l_num_cash_lines := l_num_lines - l_num_cc_lines;


    --------------------------------------------
    l_debug_info := 'get Number of Cash/Credit Card lines';
    --------------------------------------------
    if (AP_WEB_DB_EXPLINE_PKG.GetNumCashLinesWOMerch(l_report_header_id, l_co_merchant_count)) then null; end if; 

    --------------------------------------------
    l_debug_info := 'loop thru Cash/Credit Card lines';
    --------------------------------------------
    for l_table_loop_counter in 1..2 
    loop

      IF lengthb(l_document) >= l_document_max THEN
         -- Appends l_document to end of document (CLOB object)
	 WF_NOTIFICATION.WriteToClob(document,l_document);
	 l_document := '';
         --l_show_message := 'Y';
         --exit;
      END IF;

      l_expense_report_total_amt := 0;
      l_num_lines :=  0;
      l_line_number :=  0;
      l_primary_number :=  1;
      l_counter :=  1;

      if (l_table_loop_counter = 1) then
        l_is_cc_table := true;
      else
        l_is_cc_table := false;
      end if;

      --------------------------------------------
      l_debug_info := 'Traverse selected lines';
      --------------------------------------------
      if ((l_is_cc_table AND l_num_cc_lines > 0) OR
          (NOT l_is_cc_table AND l_num_cash_lines > 0)) then

        --------------------------------------------
        l_debug_info := 'Generate Table Header';
        --------------------------------------------
        if l_is_cc_table then
          l_document := l_document || indent_start || table_title_start || l_prompts(1) || table_title_end;
        else
          l_document := l_document || indent_start || table_title_start || l_prompts(2) || table_title_end;
        end if;

        l_document := l_document || table_start;

        l_document := l_document || tr_start;


        IF (AP_WEB_DB_EXPLINE_PKG.AnyPolicyViolation(l_report_header_id)) THEN
          l_rules_violated := 'Y';
        END IF;
    
        /* If the profile option is set to APPROVER_ONLY
	(ALLOW_NO_WARNINGS), do not show any violations to the employee
	notifications.  */
        IF (l_rules_violated = 'Y' ) THEN
          IF ((l_policy_violation_value = C_ALLOW_NO_WARNINGS) AND
              (l_notification_type <> C_EMP)) OR
              (l_policy_violation_value <> C_ALLOW_NO_WARNINGS) THEN
                l_print_violation := 'Y';
	        l_document := l_document || th_text || '&' || 'nbsp;' || td_end;
          END IF;
	END IF;


        -- display Line Number
        l_document := l_document || th_select || l_prompts(13) || td_end;


        IF (l_rules_violated = 'Y' ) THEN
          IF ((l_policy_violation_value = C_ALLOW_NO_WARNINGS) AND
              (l_notification_type <> C_EMP)) OR
              (l_policy_violation_value <> C_ALLOW_NO_WARNINGS) THEN
              l_document := l_document || th_text || l_prompts(14) || td_end;
          END IF;
	END IF;

        -- display Date
        l_document := l_document || th_text || l_prompts(4) || td_end;
        -- display Expense Type
        l_document := l_document || th_text || l_prompts(5) || td_end;
        -- display Merchant Name
        if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
           l_document := l_document || th_text || l_prompts(27) || td_end;
        end if;
        if (l_employee_project_enabled = 'Y') then
          -- display Project/Task only when Projects enabled
          l_document := l_document || th_text || l_prompts(6) || td_end;
          l_document := l_document || th_text || l_prompts(7) || td_end;
	  -- Grants Integration
	  if (l_grants_enabled = 'Y') then
	    l_document := l_document || th_text || l_prompts(8) || td_end;
	  end if;
        end if;
        -- display Amount
        l_document := l_document || th_number || l_prompts(9) || td_end;
        -- display Justification
        l_document := l_document || th_text || l_prompts(10) || td_end;

        if (l_line_accounting_enabled = 'Y') then
          l_document := l_document || th_text || l_prompts(15) || td_end;
        end if;
        l_document := l_document || tr_end;

        --------------------------------------------
        l_debug_info := 'Open Expense Lines Cursor';
        --------------------------------------------
        IF (AP_WEB_DB_EXPLINE_PKG.GetDisplayXpenseLinesCursor(l_report_header_id, l_is_cc_table, XpenseLinesCursor)) THEN

        LOOP

          --------------------------------------------
          l_debug_info := 'Fetch Expense Lines Cursor';
          --------------------------------------------
          FETCH XpenseLinesCursor INTO l_receipt_missing_flag,
			       l_start_date,
			       l_days,
			       l_daily_amt,
			       l_receipt_curr,
			       l_receipt_rate,
			       l_receipt_amt,
                               l_total_amt,
			       l_justification,
			       l_expense_type,
                               l_project_number,
                               l_task_number,
                               l_credit_card_trx_id,
                               l_distribution_line_number,
			       l_award_number,
			       l_violation_type,
			       l_merchant_name,
			       l_flex_concatenated,
			       l_mrate_adjusted_flag;

          EXIT WHEN XpenseLinesCursor%NOTFOUND;
     
          IF lengthb(l_document) >= l_document_max THEN
             -- Appends l_document to end of document (CLOB object)
	     WF_NOTIFICATION.WriteToClob(document,l_document);
	     l_document := '';
             --l_show_message := 'Y';
             --exit;
          END IF;
    
          IF ((l_notification_type = C_EMP) AND
              (l_policy_violation_value = C_ALLOW_NO_WARNINGS) AND
 	      (l_distribution_line_number = l_last_dist_number)) THEN
              null;
          ELSE
            l_num_lines :=  l_num_lines + 1;
            l_document := l_document || tr_start;
            ------------------------------------------------------------
            l_debug_info := 'If policy violated, indicate with a gif';
            ------------------------------------------------------------
            IF (l_rules_violated = 'Y' ) THEN
              IF ((l_policy_violation_value = C_ALLOW_NO_WARNINGS) AND
                  (l_notification_type <> C_EMP)) OR
		  (l_policy_violation_value <> C_ALLOW_NO_WARNINGS) THEN
                IF (l_violation_type is not null ) THEN
                  l_document := l_document || td_text || '**' || td_end;
                  -- Bug 2750863: With WF mailer limitation, images can't be
                  --   displayed on email notifications. Therefore, taking the
                  --   image out from the following until the WF issue has been
                  --   addressed. 
                  --face='||td_fontface||'><img src="/OA_MEDIA/warningicon_status.gif">'||td_end;
                ELSE
                  l_document := l_document || td_text || '&' || 'nbsp;' || td_end;
                END IF;
              END IF;
            END IF;

            IF l_mileage_note is not null THEN
              IF  (l_mrate_adjusted_flag is not null) THEN
                  l_line_info := '* ';
              ELSE
                  l_line_info := '&' || 'nbsp;' || '&' || 'nbsp;';
              END IF;

            ELSE
              ------------------------------------------------------------
              l_debug_info := 'If Any Receipts Missing Then Print Warning';
              ------------------------------------------------------------
              IF (l_receipt_missing_flag = 'Y') THEN
                  l_line_info := '* ';
              ELSE
                  l_line_info := '&' || 'nbsp;' || '&' || 'nbsp;';
              END IF;
            END IF;
  
  	    IF (l_distribution_line_number <> l_last_dist_number) THEN
 
              -- display Line Number
              l_document := l_document || td_select;
              --l_line_numbr := l_line_number + 1;
              l_line_display := l_primary_number;
              l_primary_number := l_primary_number + 1;
	      l_counter := l_counter + 1;
	      l_document := l_document || l_line_info || ' ' || l_line_display || ' ' || td_end;
	    ELSE
              -- display Line Number
              l_document := l_document || td_select;
  	      l_document := l_document || l_line_info  || td_end;

	    END IF;

            ------------------------------------------------------------
            l_debug_info := 'If policy violated, show the violation type';
            ------------------------------------------------------------
            IF (l_rules_violated = 'Y' ) THEN
              IF ((l_policy_violation_value = C_ALLOW_NO_WARNINGS) AND
                  (l_notification_type <> C_EMP)) OR
		  (l_policy_violation_value <> C_ALLOW_NO_WARNINGS) THEN
                IF (l_violation_type is not null ) THEN
                  l_document := l_document || td_text || nvl(l_violation_type, '&' || 'nbsp;') || td_end;
                ELSE
               l_document := l_document || td_text || '&' || 'nbsp;' || td_end;
                END IF;
              END IF;
            END IF;
 
	    IF (l_distribution_line_number <> l_last_dist_number) THEN
              -- display Date
              l_document := l_document || td_text;
              l_document := l_document  || l_start_date || td_end;
              -- display Expense Type
              l_document := l_document || td_text || l_expense_type || td_end;
              -- display Merchant Name
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
                 l_document := l_document || td_text || WF_NOTIFICATION.SubstituteSpecialChars(l_merchant_name) || td_end;
              end if;

              if (l_employee_project_enabled = 'Y') then
                -- display Project/Task only when Projects enabled
                l_document := l_document || td_text || nvl(l_project_number, '&' || 'nbsp;') || td_end;
                l_document := l_document || td_text || nvl(l_task_number, '&' || 'nbsp;') || td_end;
	       if (l_grants_enabled = 'Y') then
	       l_document := l_document || td_text || nvl(l_award_number, '&' || 'nbsp;') || td_end;
	       end if;
              end if;
 
              -- display Amount
              l_document := l_document || td_number || LPAD(to_char(l_total_amt, FND_CURRENCY.Get_Format_Mask(l_currency,22)),14) || td_end;

              -- display Justification
              l_document := l_document || td_text || nvl(WF_NOTIFICATION.SubstituteSpecialChars(l_justification), '&' || 'nbsp;') || td_end;

              if (l_line_accounting_enabled = 'Y') then
                l_document := l_document || td_text || nvl(l_flex_concatenated, '&' || 'nbsp;') || td_end;
	      end if;

            ELSE 
              l_document := l_document || td_text || '&' || 'nbsp;' || td_end;
              l_document := l_document || td_text || '&' || 'nbsp;' || td_end;

              -- display Merchant Name
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
                 l_document := l_document || td_text || WF_NOTIFICATION.SubstituteSpecialChars(l_merchant_name) || td_end;
              end if;

              if (l_employee_project_enabled = 'Y') then
                -- display Project/Task only when Projects enabled
                l_document := l_document || td_text || '&' || 'nbsp;' || td_end;
                l_document := l_document || td_text || '&' || 'nbsp;' || td_end;
	        if (l_grants_enabled = 'Y') then
	          l_document := l_document || td_text || '&' || 'nbsp;' || td_end;
	        end if;
              end if;


              -- display Amount
              l_document := l_document || td_number || '&' || 'nbsp;'|| td_end;

              -- display Justification
              l_document := l_document || td_text || '&' || 'nbsp;' || td_end;

              if (l_line_accounting_enabled = 'Y') then
                l_document := l_document || td_text || '&' || 'nbsp;' || td_end;
	      end if;

	    END IF;



            l_document := l_document || tr_end;
  
  	    IF (l_distribution_line_number <> l_last_dist_number) THEN
              l_expense_report_total_amt := l_expense_report_total_amt + l_total_amt;
	    END IF;
          
          END IF; 

	  l_last_dist_number := l_distribution_line_number;
        END LOOP; -- GetDisplayXpenseLinesCursor 
  
        END IF; -- GetDisplayXpenseLinesCursor 

        if XpenseLinesCursor%isopen then
           close XpenseLinesCursor;
        end if;

        --------------------------------------------
        l_debug_info := 'Generate Total Row';
        --------------------------------------------
        l_document := l_document || tr_start;
        if (l_employee_project_enabled = 'Y') then
	  if (l_grants_enabled = 'Y') and (l_print_violation = 'Y') then	
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
	         l_colspan := 9;
              else
	         l_colspan := 8;
              end if; 
	  elsif (l_grants_enabled = 'Y') and (l_print_violation = 'N') then
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
	         l_colspan := 7;
              else
	         l_colspan := 6;
              end if; 
	  elsif (l_grants_enabled = 'N') and (l_print_violation = 'Y') then
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
	         l_colspan := 8;
              else
	         l_colspan := 7;
              end if; 
	  elsif (l_grants_enabled = 'N') and (l_print_violation = 'N') then
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
	         l_colspan := 6;
              else
	         l_colspan := 5;
              end if; 
          end if;
        else
	  if (l_grants_enabled = 'Y') and (l_print_violation = 'Y') then	
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
	         l_colspan := 7;
              else
	         l_colspan := 6;
              end if; 
	  elsif (l_grants_enabled = 'Y') and (l_print_violation = 'N') then
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
	         l_colspan := 4;
              else
	         l_colspan := 3;
              end if; 
	  elsif (l_grants_enabled = 'N') and (l_print_violation = 'Y') then
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
	         l_colspan := 6;
              else
	         l_colspan := 5;
              end if; 
	  elsif (l_grants_enabled = 'N') and (l_print_violation = 'N') then
              if ((l_is_cc_table) or (NOT l_is_cc_table and l_co_merchant_count > 0)) then
	         l_colspan := 4;
              else
	         l_colspan := 3;
              end if; 
          end if;
        end if;
        -- display Total
        l_document := l_document || '<td colspan=' || l_colspan || 
        ' style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;background-color:#cccc99;color:#336699;vertical-align:bottom;text-align:right}">' || 
        l_prompts(12) || td_end;
        
        l_document := l_document || td_number || LPAD(to_char(l_expense_report_total_amt, FND_CURRENCY.Get_Format_Mask(l_currency,22)),14) || td_end;
        l_document := l_document || th_number || '&' || 'nbsp;' || td_end;

	if (l_line_accounting_enabled = 'Y') then
	  l_document := l_document || th_number || '&' || 'nbsp;' || td_end;
	end if;
        l_document := l_document || tr_end;
        l_document := l_document || table_end || indent_end;

      end if; -- traverse selected lines 

    end loop; -- l_table_loop_counter 


    --------------------------------------------
    l_debug_info := 'Display Company Pay Corporate Credit Card Personal Expenses';
    --------------------------------------------

    --------------------------------------------
    l_debug_info := 'Check to see if Company Pay scenario';
    --------------------------------------------
    begin
    l_payment_due_from := WF_ENGINE.GetItemAttrText(l_itemtype,l_itemkey,'PAYMENT_DUE_FROM');
    exception
	when others then
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
    end;    
    if (l_show_message = 'N' AND C_CompanyPay = l_payment_due_from) then

        --------------------------------------------
        l_debug_info := 'get Number of Personal Credit Card lines';
        --------------------------------------------
        if (AP_WEB_DB_EXPLINE_PKG.GetNumberOfPersonalLines(l_report_header_id, l_num_personal_lines)) then null; end if; 

        if (l_num_personal_lines > 0) then

          --------------------------------------------
          l_debug_info := 'Generate Table Header';
          --------------------------------------------
          l_document := l_document || indent_start || table_title_start || l_prompts(3) || table_title_end;
  
          l_document := l_document || table_start;
  
          l_document := l_document || tr_start;
          -- display Date
          l_document := l_document || th_text || l_prompts(4) || td_end;

          -- display Merchant
          --Bug 2942773: Add Merchant Name to personal Expenses Table.
          l_document := l_document || th_text || l_prompts(27) || td_end;
          -- display Amount
          l_document := l_document || th_number || l_prompts(9) || td_end;
          l_document := l_document || tr_end;

          --------------------------------------------
          l_debug_info := 'Open Personal Lines Cursor';
          --------------------------------------------
          IF (AP_WEB_DB_EXPLINE_PKG.GetDisplayPersonalLinesCursor(l_report_header_id, PersonalLinesCursor)) THEN
  
          l_num_lines := 0;
          l_cc_personal_total_amt := 0;
          LOOP

            --------------------------------------------
            l_debug_info := 'Fetch Personal Lines Cursor';
            --------------------------------------------
            FETCH PersonalLinesCursor INTO l_receipt_missing_flag,
			         l_start_date,
			         l_days,
			         l_daily_amt,
			         l_receipt_curr,
			         l_receipt_rate,
			         l_receipt_amt,
                                 l_total_amt,
			         l_justification,
			         l_expense_type,
                                 l_project_number,
                                 l_task_number,
                                 l_credit_card_trx_id,
                                 l_distribution_line_number,
                                 l_merchant_name;  --Bug 29427743.
            EXIT WHEN PersonalLinesCursor%NOTFOUND;
       
            IF lengthb(l_document) >= l_document_max THEN
               -- Appends l_document to end of document (CLOB object)
	       WF_NOTIFICATION.WriteToClob(document,l_document);
	       l_document := '';
               --l_show_message := 'Y';
               --exit;
            END IF;
    
	    l_total_amt := -(l_total_amt) ;	-- Bug 2824304. Reversing the sign of Personal Expenses since they are negated and stored in database.
            l_num_lines :=  l_num_lines + 1;
    
-- Bug 2824304: Removed use of abs function for displaying Personal Expenses Amount and the Total.

            l_document := l_document || tr_start;

            -- display Date
            l_document := l_document || td_text || l_start_date || td_end;

            -- display Merchant
--Bug 2942773: Add Merchant name value to personal expense table.
            l_document := l_document || td_text || WF_NOTIFICATION.SubstituteSpecialChars(l_merchant_name) || td_end;
            -- display Amount
            l_document := l_document || td_number || LPAD(to_char(l_total_amt, FND_CURRENCY.Get_Format_Mask(l_currency,22)),14) || td_end;
            l_document := l_document || tr_end;
    
            l_cc_personal_total_amt := l_cc_personal_total_amt + l_total_amt;
  
          END LOOP; -- GetDisplayPersonalLinesCursor 
  
          END IF; -- GetDisplayPersonalLinesCursor 

          if PersonalLinesCursor%isopen then
             close PersonalLinesCursor;
          end if; 
          --------------------------------------------
          l_debug_info := 'Generate Total Row';
          --------------------------------------------
          l_document := l_document || tr_start;
--Bug 2942773: Add colspans to Total AMount so that it will appear under Amount

            -- display Total
          l_document := l_document || '<td colspan=2 style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;background-color:#cccc99;color:#336699;vertical-align:bottom;text-align:right}">' || l_prompts(12) || td_end;

          l_document := l_document || td_number || LPAD(to_char(l_cc_personal_total_amt, FND_CURRENCY.Get_Format_Mask(l_currency,22)),14)  || td_end;
          l_document := l_document || tr_end;
          l_document := l_document || table_end || indent_end;

      end if; -- l_num_personal_lines > 0 

    end if; -- Display Company Pay Corporate Credit Card Personal Expenses 

/*Bug 2944363: Added code to show the table for personal expenses in Both Pay.*/

--AMMISHRA - Both Pay Personal Only Lines project.

    --------------------------------------------
    l_debug_info := 'Check to see if Both Pay scenario';
    --------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.getPaymentDueFromReport(l_report_header_id,l_payment)) THEN
      l_debug_info := 'Could not set workflow attribute Payment_Due_From';
    END IF;
    if (l_show_message = 'N' AND C_BothPay = l_payment) then
        --------------------------------------------
        l_debug_info := 'get Number of Personal Credit Card lines Both Pay';
        --------------------------------------------
        if (AP_WEB_DB_EXPLINE_PKG.GetNoOfBothPayPersonalLines(l_report_header_id, l_num_personal_lines)) then null; end if;
        if (l_num_personal_lines > 0) then

          --------------------------------------------
          l_debug_info := 'Generate Table Header';
          --------------------------------------------
          l_document := l_document || indent_start || table_title_start || l_prompts(3) || table_title_end;

          l_document := l_document || table_start;

          l_document := l_document || tr_start;

          -- display Date
          l_document := l_document || th_text || l_prompts(4) || td_end;

          -- display Merchant
          l_document := l_document || th_text || l_prompts(27) || td_end;

          -- display Amount
          l_document := l_document || th_number || l_prompts(9) || td_end;

          l_document := l_document || tr_end;

          ------------------End Of Table Header------------------
          --------------------------------------------
          l_debug_info := 'Open BothPay Personal Lines Cursor';
          --------------------------------------------
          IF (AP_WEB_DB_EXPLINE_PKG.GetBothPayPersonalLinesCursor(l_report_header_id, BothPayPersonalLinesCursor)) THEN

            l_num_lines := 0;
            l_cc_personal_total_amt := 0;
          LOOP

            --------------------------------------------
            l_debug_info := 'Fetch Personal Lines Cursor';
            --------------------------------------------
            FETCH BothPayPersonalLinesCursor INTO
                                 l_cc_trxn_date,
                                 l_cc_expensed_amt,
                                 l_cc_curr_code,
                                 l_cc_merchant_name;
            EXIT WHEN BothPayPersonalLinesCursor%NOTFOUND;
            IF lengthb(l_document) >= l_document_max THEN
               -- Appends l_document to end of document (CLOB object)
               WF_NOTIFICATION.WriteToClob(document,l_document);
               l_document := '';
               --l_show_message := 'Y';
               --exit;
            END IF;
            l_num_lines :=  l_num_lines + 1;

            l_document := l_document || tr_start;
            -- display Date
            l_document := l_document || td_text || l_cc_trxn_date || td_end;
            -- display Merchant
            l_document := l_document || td_text || WF_NOTIFICATION.SubstituteSpecialChars(l_cc_merchant_name) || td_end;
            -- display Amount
            l_document := l_document || td_number || LPAD(to_char(l_cc_expensed_amt, FND_CURRENCY.Get_Format_Mask(l_cc_curr_code,22)),14) || td_end;
            l_document := l_document || tr_end;

            l_cc_personal_total_amt := l_cc_personal_total_amt + to_number(l_cc_expensed_amt);

          END LOOP; -- GetDisplayPersonalLinesCursor

          END IF; -- GetDisplayPersonalLinesCursor

          if BothPayPersonalLinesCursor%isopen then
             close BothPayPersonalLinesCursor;
          end if;

          --------------------------------------------
          l_debug_info := 'Generate Total Row';
          --------------------------------------------
          l_document := l_document || tr_start;
          -- display Total
          l_document := l_document || '<td colspan=2 style="{font-family:Arial,Helvetica,Geneva,sans-serif;font-size:10pt;font-weight:bold;background-color:#cccc99;color:#336699;vertical-align:bottom;text-align:right}">' || l_prompts(12) || td_end;
          l_document := l_document || td_number || LPAD(to_char(l_cc_personal_total_amt, FND_CURRENCY.Get_Format_Mask(l_cc_curr_code,22)),14) || td_end;
          l_document := l_document || tr_end;
          l_document := l_document || table_end || indent_end;

      end if; -- l_num_personal_lines > 0

    end if; -- Display Both Pay Corporate Credit Card Personal Expenses

--2944363:End of Both pay Personal Table.          

    --------------------------------------------
    l_debug_info := 'Unable to show more lines';
    --------------------------------------------
    IF l_show_message = 'Y' THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_WEB_EXP_UNABLE_TO_SHOWLINES');
      FND_MESSAGE.SET_TOKEN('NO_OF_LINES',to_char(l_num_lines));
      l_message := FND_MESSAGE.GET; 
      l_document := l_document || table_start;
      l_document := l_document || tr_start || '&' || 'nbsp;' || tr_end;
      l_document := l_document || tr_start || '&' || 'nbsp;' || tr_end;
      l_document := l_document || tr_start || td_start || l_message || td_end || tr_end;
      l_document := l_document || table_end || indent_end;
    END IF;

  end if; -- text/plain vs text/html 

   /* Bug 3561386 : Should add l_document to the clob only if it is 
    *        not null.
   */
  IF  l_document is not null then
      WF_NOTIFICATION.WriteToClob(document,l_document);
  END IF;

  document_type := display_type;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GenerateExpClobLines');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GenerateExpClobLines', 
                    document_id, l_debug_info);
    raise;
END GenerateExpClobLines;

-------------------------------------------------------------------------------
PROCEDURE determineMileageAdjusted(p_item_type  IN VARCHAR2,
			          p_item_key   IN VARCHAR2,
				  p_actid      IN NUMBER,
				  p_funmode    IN VARCHAR2,
				  p_result     OUT NOCOPY VARCHAR2) IS 
-------------------------------------------------------------------------------
  l_debug_info	     VARCHAR2(200);
  l_report_header_id AP_WEB_DB_EXPLINE_PKG.expLines_HeaderID;
  l_modified_count   NUMBER :=0;
  l_new_count	     NUMBER :=0;
  l_mess             Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;
  
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start determineMileageAdjusted');

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                      p_item_key,
                                                      'EXPENSE_REPORT_ID');



    ------------------------------------------------------------
    l_debug_info := 'Construct Mileage Note';
    ------------------------------------------------------------
    SELECT count(*)
    INTO   l_modified_count
    FROM   ap_expense_report_lines xl
    WHERE  xl.report_header_id = l_report_header_id
    AND	   xl.mileage_rate_adjusted_flag = AP_WEB_DB_EXPLINE_PKG.C_Modified;

    /* If the system adjusted the mileage rate by adding new lines
       and changing the rate in the same report, the notes on the
       notification will only display the modified message. Only 
       one notification will be send to the preparer and AP.  */
    IF (l_modified_count > 0) THEN
      FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_MRATE_MODIFIED_NOTE');    
    ELSE
      SELECT count(*)
      INTO   l_new_count
      FROM   ap_expense_report_lines xl
      WHERE  xl.report_header_id = l_report_header_id
      AND    (xl.mileage_rate_adjusted_flag = AP_WEB_DB_EXPLINE_PKG.C_New
           OR xl.mileage_rate_adjusted_flag = AP_WEB_DB_EXPLINE_PKG.C_Split);

      IF (l_new_count > 0 ) THEN
         FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_MRATE_SPLIT_NOTE');    
      END IF;
    END IF;

    l_mess := FND_MESSAGE.GET;

    WF_ENGINE.SetItemAttrText(p_item_type,
			      p_item_key,
			      'MILEAGE_NOTE',
			      l_mess);

    IF (l_modified_count > 0 OR l_new_count > 0 ) THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;
    

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end determineMileageAdjusted');

EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('determineMileageAdjusted');
    APP_EXCEPTION.RAISE_EXCEPTION;
END determineMileageAdjusted;



---------------------------------------------------------
PROCEDURE getScheduleLineArray(
		p_report_header_id		IN NUMBER,
		p_distribution_line_number	IN NUMBER,
		p_employee_id			IN NUMBER,
		p_cumulative_mileage		IN NUMBER,
		p_schedule_line_array	 OUT NOCOPY AP_WEB_DB_SCHLINE_PKG.Schedule_Line_Array) IS
---------------------------------------------------------
  l_vehicle_category_code AP_WEB_DB_EXPLINE_PKG.expLines_vehicle_category_code;
  l_vehicle_type	AP_WEB_DB_EXPLINE_PKG.expLines_vehicle_type;
  l_fuel_type		AP_WEB_DB_EXPLINE_PKG.expLines_fuel_type;
  l_trip_distance	AP_WEB_DB_EXPLINE_PKG.expLines_trip_distance;
  l_distance_unit_code	AP_WEB_DB_EXPLINE_PKG.expLines_distance_unit_code;
  l_currency_code	AP_WEB_DB_EXPLINE_PKG.expLines_currCode;
  l_start_expense_date	AP_WEB_DB_EXPLINE_PKG.expLines_startExpDate;
  l_end_expense_date	AP_WEB_DB_EXPLINE_PKG.expLines_endExpDate;
  l_web_parameter_iD	AP_WEB_DB_EXPLINE_PKG.expLines_webParamID;
  l_policy_id		AP_EXPENSE_REPORT_PARAMS.COMPANY_POLICY_ID%TYPE;
  l_distance_uom	AP_POL_HEADERS.DISTANCE_UOM%TYPE;
  l_employee_role_flag	AP_POL_HEADERS.EMPLOYEE_ROLE_FLAG%TYPE;
  l_distance_thresholds_flag	AP_POL_HEADERS.DISTANCE_THRESHOLDS_FLAG%TYPE;
  l_debug_info          VARCHAR2(200);
  l_cumulative_mileage	AP_WEB_EMPLOYEE_INFO.NUMERIC_VALUE%TYPE := nvl(p_cumulative_mileage,0);
  l_currency_preference	AP_POL_HEADERS.CURRENCY_PREFERENCE%TYPE;
  bDistanceWithinRange		BOOLEAN := FALSE;
  bDistanceThresholdCrossed	BOOLEAN := FALSE;
  bFoundSingleRate		BOOLEAN := FALSE;
  l_schedule_line_array		AP_WEB_DB_SCHLINE_PKG.Schedule_Line_Array;
  l_orig_cum_mileage		AP_WEB_EMPLOYEE_INFO.VALUE_TYPE%TYPE;
  i			NUMBER := 1;
  j			NUMBER := 1;
  l_ou_distance_field	AP_POL_CAT_OPTIONS.DISTANCE_FIELD%TYPE;
  l_threshold_tolerance	NUMBER := 0;

  c_schedule_line_cursor AP_WEB_DB_SCHLINE_PKG.ScheduleLinesCursor;
  
BEGIN
  --------------------------------------------------
  l_debug_info := 'Retrieving info from the Database';
  --------------------------------------------------

  SELECT XL.VEHICLE_CATEGORY_CODE,
	 XL.VEHICLE_TYPE,
	 XL.FUEL_TYPE,
	 nvl(XL.TRIP_DISTANCE,0),
	 XL.DISTANCE_UNIT_CODE,
	 XL.CURRENCY_CODE,
	 XL.START_EXPENSE_DATE,
	 XL.END_EXPENSE_DATE,
	 XL.WEB_PARAMETER_ID,
	 XP.COMPANY_POLICY_ID,
         SH.CURRENCY_PREFERENCE
  INTO   l_vehicle_category_code,
	 l_vehicle_type,
	 l_fuel_type,
	 l_trip_distance,
	 l_distance_unit_code,
	 l_currency_code,
	 l_start_expense_date,
	 l_end_expense_date,
	 l_web_parameter_id,
	 l_policy_id,
	 l_currency_preference
  FROM   ap_expense_report_lines XL,
         AP_EXPENSE_REPORT_HEADERS XH,
	 AP_EXPENSE_REPORT_PARAMS XP,
	 AP_POL_HEADERS SH
  WHERE  XH.report_header_id = p_report_header_id
   AND   XH.report_header_id = XL.report_header_id
   AND	 XL.distribution_line_number = p_distribution_line_number
   AND   (XP.WEB_ENABLED_FLAG   = 'Y'
         OR    XH.EXPENSE_REPORT_ID = XP.EXPENSE_REPORT_ID)
   AND   XL.web_parameter_id = XP.parameter_id
   AND	 XP.company_policy_id = SH.policy_id;

  --------------------------------------------------
  l_debug_info := 'Retrieving info from the ap_pol_headers';
  --------------------------------------------------
  SELECT AH.DISTANCE_UOM,
	 AH.DISTANCE_THRESHOLDS_FLAG,
	 AH.EMPLOYEE_ROLE_FLAG
  INTO   l_distance_uom,
	 l_distance_thresholds_flag,
	 l_employee_role_flag
  FROM   AP_POL_HEADERS AH
  WHERE  AH.POLICY_ID = l_policy_id;

  IF (l_distance_thresholds_flag is not null) THEN
    IF ((l_distance_uom = C_KILOMETERS) AND (l_distance_unit_code = C_MILES)) THEN
          l_trip_distance := l_trip_distance * MILES_TO_KILOMETERS;
    ELSIF ((l_distance_uom = C_MILES) AND (l_distance_unit_code = C_KILOMETERS)) THEN
          l_cumulative_mileage := round((l_cumulative_mileage * KILOMETERS_TO_MILES),1);
          l_trip_distance := l_trip_distance * KILOMETERS_TO_MILES;
    ELSIF ((l_distance_uom = C_SWMILES) AND (l_distance_unit_code = C_KILOMETERS)) THEN
          l_cumulative_mileage := round((l_cumulative_mileage * KILOMETERS_TO_SWMILES),1);
          l_trip_distance := l_trip_distance * KILOMETERS_TO_SWMILES;
    ELSIF ((l_distance_uom = C_SWMILES) AND (l_distance_unit_code = C_MILES)) THEN
          l_cumulative_mileage := round((l_cumulative_mileage * MILES_TO_SWMILES),1);
          l_trip_distance := l_trip_distance * MILES_TO_SWMILES;
    ELSIF ((l_distance_uom = C_KILOMETERS) AND (l_distance_unit_code = C_SWMILES)) then
          l_trip_distance := l_trip_distance * SWMILES_TO_KILOMETERS;
    ELSIF ((l_distance_uom = C_MILES) AND (l_distance_unit_code = C_SWMILES)) THEN
          l_cumulative_mileage := round((l_cumulative_mileage * SWMILES_TO_MILES),1);
          l_trip_distance := l_trip_distance * SWMILES_TO_MILES;
    ELSIF ((l_distance_uom = C_MILES) AND (l_distance_unit_code = C_MILES)) THEN
          l_cumulative_mileage := round((l_cumulative_mileage * KILOMETERS_TO_MILES),1); 
    ELSIF ((l_distance_uom = C_SWMILES) AND (l_distance_unit_code = C_SWMILES)) THEN
          l_cumulative_mileage := round((l_cumulative_mileage * KILOMETERS_TO_SWMILES),1); 
    END IF;
  END IF;

  
  --------------------------------------------------
  l_debug_info := 'Retrieving schedule line from the ap_pol_lines';
  --------------------------------------------------
  l_orig_cum_mileage   := l_cumulative_mileage;
  l_cumulative_mileage := l_cumulative_mileage + l_trip_distance;

  IF (  AP_WEB_DB_SCHLINE_PKG.GetScheduleLinesCursor(l_policy_id, 
					l_vehicle_category_code,
					l_vehicle_type,
					l_fuel_type,
					l_currency_code,
					p_employee_id,
					l_start_expense_date,
					c_schedule_line_cursor)) THEN

    LOOP
      FETCH c_schedule_line_cursor INTO
	l_schedule_line_array(i).range_high,
	l_schedule_line_array(i).range_low,
	l_schedule_line_array(i).start_date,
	l_schedule_line_array(i).end_date,
	l_schedule_line_array(i).rate,
	l_schedule_line_array(i).rate_per_passenger;
      EXIT WHEN c_schedule_line_cursor%NOTFOUND;

    --------------------------------------------------
    l_debug_info := 'Determine whether distance threshold crossed';
    --------------------------------------------------
    -- Bug 8813146 - Threshold tolerance is used when daily_distance is used or distance_uom's used are different
    Begin
	    SELECT DISTANCE_FIELD 
	    INTO   l_ou_distance_field 
	    FROM   AP_POL_CAT_OPTIONS 
	    WHERE  category_code = 'MILEAGE';
    exception
        when no_data_found then
	    l_ou_distance_field := C_DISTANCE_FIELD;
    end;

    IF ( C_DISTANCE_FIELD = l_ou_distance_field OR l_distance_unit_code <> l_distance_uom) THEN
	IF (l_distance_unit_code <> C_KILOMETERS) THEN
		l_threshold_tolerance := C_THRESHOLD_TOLERANCE;
	END IF;
    END IF;

    IF (l_distance_thresholds_flag is not null) THEN
     IF (l_cumulative_mileage > l_schedule_line_array(i).range_low AND l_orig_cum_mileage <
           nvl(l_schedule_line_array(i).range_high,l_orig_cum_mileage + 1)) THEN
      IF (l_cumulative_mileage > nvl(l_schedule_line_array(i).range_high + l_threshold_tolerance, l_cumulative_mileage)) THEN
        bDistanceThresholdCrossed := TRUE;
      ELSE
        bDistanceThresholdCrossed := FALSE;
      END IF;

      p_schedule_line_array(j) := l_schedule_line_array(i);
      IF (bDistanceThresholdCrossed = FALSE) THEN	
        EXIT;
      END IF;

      j := j+1;
     END IF;
    END IF;
  
    
    i := i+1;
  END LOOP;
  
END IF;

EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('getScheduleLineArray',
                                    l_debug_info);
    APP_EXCEPTION.RAISE_EXCEPTION;
END  getScheduleLineArray;


-------------------------------------------------------------------------------
PROCEDURE updateCumulativeMileage( 
	p_cumulative_mileage	IN AP_WEB_EMPLOYEE_INFO.NUMERIC_VALUE%TYPE,
	p_period_id		IN AP_WEB_EMPLOYEE_INFO.PERIOD_ID%TYPE,
	p_employee_id		IN AP_WEB_EMPLOYEE_INFO.EMPLOYEE_ID%TYPE)  IS
-------------------------------------------------------------------------------
  l_count NUMBER := 0;
BEGIN

  SELECT count(*) 
  INTO	 l_count
  FROM	 ap_web_employee_info_all
  WHERE	 value_type = 'CUM_REIMB_DISTANCE'
  AND	 period_id = p_period_id
  AND	 employee_id = p_employee_id;

  IF (l_count > 0 ) THEN
    UPDATE ap_web_employee_info_all
    SET	   numeric_value = p_cumulative_mileage,
           last_update_date = sysdate,
           last_updated_by = p_employee_id
    WHERE  value_type = 'CUM_REIMB_DISTANCE'
    AND	   period_id = p_period_id
    AND	   employee_id = p_employee_id;
  ELSE
    INSERT INTO ap_web_employee_info_all
	  (EMPLOYEE_ID,			 
	   VALUE_TYPE,				  
	   NUMERIC_VALUE,					  
	   PERIOD_ID,				  
	   CREATION_DATE,				  
	   CREATED_BY,				  
	   LAST_UPDATE_DATE,			  
	   LAST_UPDATED_BY)			  
    VALUES(p_employee_id,
	   'CUM_REIMB_DISTANCE',
	   p_cumulative_mileage,
	   p_period_id,
	   sysdate,
	   p_employee_id,
	   sysdate,
	   p_employee_id);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('updateCumulativeMileage');
    APP_EXCEPTION.RAISE_EXCEPTION;
END updateCumulativeMileage;


FUNCTION getAddonMileageRatesSum(p_report_header_id IN NUMBER,
                                 p_dist_line_number IN NUMBER)
RETURN NUMBER IS
l_addon_rate_sum NUMBER := 0.0;
BEGIN
  -- Bug: 7378079, one-off for 7330731.
  select nvl(sum(mileage_rate),0)
  into l_addon_rate_sum
  from oie_addon_mileage_rates
  where report_line_id = (select report_line_id
                          from ap_expense_report_lines
                          where report_header_id = p_report_header_id
                          and distribution_line_number = p_dist_line_number
                          and rownum = 1);
  return l_addon_rate_sum;
EXCEPTION when others then
  return l_addon_rate_sum;
END getAddonMileageRatesSum;

-------------------------------------------------------------------------------
FUNCTION getRate( 
	p_sh_distance_uom	   IN AP_POL_HEADERS.distance_uom%TYPE,
	p_sh_currency_code	   IN AP_POL_HEADERS.currency_code%TYPE,
	p_mileage_line		   IN AP_WEB_DB_EXPLINE_PKG.Mileage_Line_Rec,
	p_schedule_line		   IN AP_WEB_DB_SCHLINE_PKG.Schedule_Line_Rec)
RETURN NUMBER IS
-------------------------------------------------------------------------------
  l_debug_info		VARCHAR2(200);
  l_conversion_type	VARCHAR2(30);
  l_converted_amount	NUMBER := 1;
  l_denominator		NUMBER := 1;
  l_numerator		NUMBER := 1;
  l_rate		NUMBER;

  l_get_ap_system_params        boolean;
  l_base_curr_code              AP_WEB_DB_AP_INT_PKG.apSetup_baseCurrencyCode;
  l_set_of_books_id             AP_WEB_DB_AP_INT_PKG.apSetup_setOfBooksID;
  l_expense_report_id           AP_WEB_DB_AP_INT_PKG.apSetup_expenseReportID;
  l_tax_calc_flag               AP_WEB_DB_AP_INT_PKG.apSetUp_autoTaxCalcFlag;
  l_tax_calc_override           AP_WEB_DB_AP_INT_PKG.apSetUp_autoTaxCalcOverride;
  l_amt_inc_tax_override        AP_WEB_DB_AP_INT_PKG.apSetUp_amtInclTaxOverride;
  
BEGIN
  
  -- Need to convert to reimbursement currency if different
  IF (p_sh_currency_code <> p_mileage_line.reimbursement_currency_code) THEN

    ------------------------------------------------------
    l_debug_info := 'Get the rate type';
    ------------------------------------------------------
    l_get_ap_system_params := AP_WEB_DB_AP_INT_PKG.get_ap_system_params(
                                            p_base_curr_code => l_base_curr_code,
                                            p_set_of_books_id => l_set_of_books_id,
                                            p_expense_report_id => l_expense_report_id,
                                            p_default_exch_rate_type => l_conversion_type,
                                            p_tax_calc_flag => l_tax_calc_flag,
                                            p_tax_calc_override => l_tax_calc_override,
                                            p_amt_inc_tax_override =>l_amt_inc_tax_override);



    gl_currency_api.convert_closest_amount(
      x_from_currency	=> p_sh_currency_code,
      x_to_currency	=> p_mileage_line.reimbursement_currency_code,
      x_conversion_date => p_mileage_line.start_date, 
      x_conversion_type => l_conversion_type, 
      x_user_rate	=> 1, 
      x_amount	        => 1, 
      x_max_roll_days	=> 0,
      x_converted_amount=> l_converted_amount,
      x_denominator	=> l_denominator, 
      x_numerator	=> l_numerator, 
      x_rate		=> l_rate);
    l_rate := p_schedule_line.rate * l_rate;
  ELSE
    l_rate := p_schedule_line.rate;
  END IF;

  ------------------------------------------------------
  l_debug_info := 'Convert rate to the corresponding UOM';
  ------------------------------------------------------
  IF (p_sh_distance_uom <> p_mileage_line.distance_unit_code) THEN

    IF ((p_sh_distance_uom = C_KILOMETERS) AND (p_mileage_line.distance_unit_code = C_MILES)) THEN
      l_rate := round( p_schedule_line.rate * MILES_TO_KILOMETERS, 6);
    ELSIF ((p_sh_distance_uom = C_MILES) AND (p_mileage_line.distance_unit_code = C_KILOMETERS)) THEN
      l_rate := round( p_schedule_line.rate * KILOMETERS_TO_MILES, 6);
    ELSIF ((p_sh_distance_uom = C_SWMILES) AND (p_mileage_line.distance_unit_code = C_KILOMETERS)) THEN
      l_rate := round( p_schedule_line.rate * KILOMETERS_TO_SWMILES, 6);
    ELSIF ((p_sh_distance_uom = C_SWMILES) AND (p_mileage_line.distance_unit_code = C_MILES)) THEN
      l_rate := round( p_schedule_line.rate * MILES_TO_SWMILES, 6);
    ELSIF ((p_sh_distance_uom = C_MILES) AND (p_mileage_line.distance_unit_code = C_SWMILES)) THEN
      l_rate := round( p_schedule_line.rate * SWMILES_TO_MILES, 6);
    ELSIF ((p_sh_distance_uom = C_KILOMETERS) AND (p_mileage_line.distance_unit_code = C_SWMILES)) THEN
      l_rate := round( p_schedule_line.rate * SWMILES_TO_KILOMETERS, 6);
    END IF;

  END IF;

  return l_rate;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    return 0;
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('getRate');
    APP_EXCEPTION.RAISE_EXCEPTION;
    return 0;
END getRate;


-------------------------------------------------------------------------------
PROCEDURE copyMileageArray( 
	p_from_array		IN AP_WEB_DB_EXPLINE_PKG.Mileage_Line_Array,
	p_to_array	 OUT NOCOPY AP_WEB_DB_EXPLINE_PKG.Mileage_Line_Array) IS
-------------------------------------------------------------------------------
  l_debug_info	     VARCHAR2(200);

BEGIN
  -- Start w/ defaulting the orig_dist_line_number to new_orig_dist_line_number
  FOR i IN 1..p_from_array.COUNT LOOP
    p_to_array(i).orig_dist_line_number := p_from_array(i).orig_dist_line_number;
    p_to_array(i).new_dist_line_number := p_from_array(i).orig_dist_line_number;
    p_to_array(i).report_header_id := p_from_array(i).report_header_id;
    p_to_array(i).start_date := p_from_array(i).start_date;
    p_to_array(i).end_date := p_from_array(i).end_date;
    p_to_array(i).number_of_days := p_from_array(i).number_of_days;
    p_to_array(i).policy_id := p_from_array(i).policy_id;
    p_to_array(i).avg_mileage_rate := p_from_array(i).avg_mileage_rate;
    p_to_array(i).trip_distance := p_from_array(i).trip_distance;
    p_to_array(i).daily_distance := p_from_array(i).daily_distance; 
    p_to_array(i).distance_unit_code := p_from_array(i).distance_unit_code;
    p_to_array(i).amount := p_from_array(i).amount;

  END LOOP;


EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('copyMileageArray');
    APP_EXCEPTION.RAISE_EXCEPTION;
END copyMileageArray;


-------------------------------------------------------------------------------
PROCEDURE addToMileageArray( 
	p_index			IN NUMBER,
	p_new_dist_number	IN AP_EXPENSE_REPORT_LINES.distribution_line_number%TYPE,
	p_trip_dist		IN AP_EXPENSE_REPORT_LINES.TRIP_DISTANCE%TYPE,
	p_daily_distance	IN AP_EXPENSE_REPORT_LINES.DAILY_DISTANCE%TYPE,
	p_rate			IN AP_EXPENSE_REPORT_LINES.avg_mileage_rate%TYPE,
	p_report_header_id	IN AP_EXPENSE_REPORT_LINES.report_header_id%TYPE,
	p_from_index		IN AP_EXPENSE_REPORT_LINES.distribution_line_number%TYPE,
	p_mileage_line_array	IN OUT NOCOPY AP_WEB_DB_EXPLINE_PKG.Mileage_Line_Array) IS
-------------------------------------------------------------------------------
  l_debug_info	     VARCHAR2(200);

BEGIN

    p_mileage_line_array(p_index).orig_dist_line_number := p_new_dist_number;
    p_mileage_line_array(p_index).new_dist_line_number := p_new_dist_number;
    p_mileage_line_array(p_index).report_header_id := p_report_header_id;
    p_mileage_line_array(p_index).start_date := p_mileage_line_array(p_from_index).start_date;
    p_mileage_line_array(p_index).end_date := p_mileage_line_array(p_from_index).end_date;
    p_mileage_line_array(p_index).number_of_days := p_mileage_line_array(p_from_index).number_of_days;
    p_mileage_line_array(p_index).policy_id := p_mileage_line_array(p_from_index).policy_id;
    p_mileage_line_array(p_index).avg_mileage_rate := p_rate;
    p_mileage_line_array(p_index).trip_distance := p_trip_dist;
    p_mileage_line_array(p_index).daily_distance := p_daily_distance;
    p_mileage_line_array(p_index).distance_unit_code := p_mileage_line_array(p_from_index).distance_unit_code;
    p_mileage_line_array(p_index).amount := p_rate * p_trip_dist;
    p_mileage_line_array(p_index).daily_amount := p_rate * p_trip_dist / p_mileage_line_array(p_from_index).number_of_days;
    p_mileage_line_array(p_index).copy_From :=  p_mileage_line_array(p_from_index).orig_dist_line_number;
    p_mileage_line_array(p_index).status := AP_WEB_DB_EXPLINE_PKG.C_New;

EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('addToMileageArray');
    APP_EXCEPTION.RAISE_EXCEPTION;
END addToMileageArray;

-------------------------------------------------------------------------------
PROCEDURE updateNewDistNumber( 
	p_index			IN NUMBER,
	p_last_index		IN NUMBER,
	p_added_total		IN NUMBER,
	p_mileage_line_array	IN OUT NOCOPY AP_WEB_DB_EXPLINE_PKG.Mileage_Line_Array)IS
-------------------------------------------------------------------------------
  l_debug_info	     VARCHAR2(200);
  i		     NUMBER;
BEGIN

 If (p_last_index > p_index) THEN
  FOR i IN p_index..p_last_index LOOP
    p_mileage_line_array(i).new_dist_line_number :=
        p_mileage_line_array(i).new_dist_line_number + p_added_total;

    -- Only the status of existing lines will be updated to M(odifed)
    -- All new lines will keep the N(ew) status to ensure they will 
    -- be added to the database later.

    IF (p_mileage_line_array(i).status <> 'N') THEN
      p_mileage_line_array(i).status := 'M';
    END IF;
  END LOOP;

 END IF;

EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('updateNewDistNumber');
    APP_EXCEPTION.RAISE_EXCEPTION;
END updateNewDistNumber;

--------------------------------------------------------------------------------
PROCEDURE processCrossThreshold( 
	p_ml_index		   IN NUMBER,
	p_sh_distance_uom	   IN AP_POL_HEADERS.DISTANCE_UOM%TYPE,
	p_sh_currency_code	   IN AP_POL_HEADERS.CURRENCY_CODE%TYPE,
	p_schedule_line_array	   IN AP_WEB_DB_SCHLINE_PKG.Schedule_Line_Array,
	p_mileage_line_array_count IN OUT NOCOPY NUMBER,
	p_cumulative_mileage	   IN OUT NOCOPY AP_WEB_EMPLOYEE_INFO.NUMERIC_VALUE%TYPE,
	p_mileage_line_array	   IN OUT NOCOPY AP_WEB_DB_EXPLINE_PKG.Mileage_Line_Array)IS
--------------------------------------------------------------------------------
  l_cumulative_mileage NUMBER := p_cumulative_mileage;
  l_ml_trip_distance   NUMBER := p_mileage_line_array(p_ml_index).trip_distance;
  l_over_amount	       NUMBER;
  l_cum_distance       NUMBER;
  l_over_threshold_distance NUMBER := 0;
  l_range_high		    NUMBER;
  l_range_low		    NUMBER;
  l_next_dist_number	    NUMBER;
  l_range_size		    NUMBER;
  l_daily_distance	    NUMBER;
  l_updated_trip_dist	    NUMBER;
  l_new_rate		    NUMBER := 0;
  l_insert_index	    NUMBER := p_mileage_line_array_count + 1;
  l_added_total		    NUMBER := 0;
  l_sl_array_count	    NUMBER := 0;
  l_debug_info		    VARCHAR2(200);
  l_ou_distance_field	AP_POL_CAT_OPTIONS.DISTANCE_FIELD%TYPE;
  l_threshold_tolerance	NUMBER := 0;


BEGIN

  ------------------------------------------------------
  l_debug_info := 'Convert to the appropriate UOM';
  ------------------------------------------------------      

  IF (p_mileage_line_array(p_ml_index).distance_unit_code = C_MILES) THEN
     l_cum_distance := round(((l_cumulative_mileage * KILOMETERS_TO_MILES) + p_mileage_line_array(p_ml_index).trip_distance), 1);
  ELSIF (p_mileage_line_array(p_ml_index).distance_unit_code = C_SWMILES) THEN
     l_cum_distance := round(((l_cumulative_mileage * KILOMETERS_TO_SWMILES) + p_mileage_line_array(p_ml_index).trip_distance), 1);
  ELSE
    l_cum_distance := l_cumulative_mileage + p_mileage_line_array(p_ml_index).trip_distance;
  END IF;

  --------------------------------------------
  l_debug_info := 'assign p_cumulative_mileage';
  --------------------------------------------
  IF (p_mileage_line_array(p_ml_index).distance_unit_code = C_MILES) THEN
    p_cumulative_mileage := round((l_cum_distance * MILES_TO_KILOMETERS),1);    
  ELSIF (p_mileage_line_array(p_ml_index).distance_unit_code = C_SWMILES) THEN
    p_cumulative_mileage := round((l_cum_distance * SWMILES_TO_KILOMETERS),1);
  ELSE 
    p_cumulative_mileage := l_cum_distance;
  END IF;

  l_sl_array_count := p_schedule_line_array.COUNT;

  FOR i IN 1..l_sl_array_count LOOP
    l_range_high := p_schedule_line_array(i).range_high;
    l_range_low  := p_schedule_line_array(i).range_low;

    IF ((p_mileage_line_array(p_ml_index).distance_unit_code = C_MILES) AND (p_sh_distance_uom = C_KILOMETERS)) THEN
        l_range_high := p_schedule_line_array(i).range_high * KILOMETERS_TO_MILES;
     	l_range_low  := p_schedule_line_array(i).range_low * KILOMETERS_TO_MILES;
    ELSIF ((p_mileage_line_array(p_ml_index).distance_unit_code = C_KILOMETERS) AND (p_sh_distance_uom = C_MILES)) THEN    	
        l_range_high := p_schedule_line_array(i).range_high * MILES_TO_KILOMETERS;
     	l_range_low  := p_schedule_line_array(i).range_low * MILES_TO_KILOMETERS;
    ELSIF ((p_mileage_line_array(p_ml_index).distance_unit_code = C_KILOMETERS) AND (p_sh_distance_uom = C_SWMILES)) THEN    	
        l_range_high := p_schedule_line_array(i).range_high * SWMILES_TO_KILOMETERS;
     	l_range_low  := p_schedule_line_array(i).range_low * SWMILES_TO_KILOMETERS;
    ELSIF ((p_mileage_line_array(p_ml_index).distance_unit_code = C_MILES) AND (p_sh_distance_uom = C_SWMILES)) THEN    	
        l_range_high := p_schedule_line_array(i).range_high * SWMILES_TO_MILES;
     	l_range_low  := p_schedule_line_array(i).range_low * SWMILES_TO_MILES;
    ELSIF ((p_mileage_line_array(p_ml_index).distance_unit_code = C_SWMILES) AND (p_sh_distance_uom = C_MILES)) THEN    	
        l_range_high := p_schedule_line_array(i).range_high * MILES_TO_SWMILES;
     	l_range_low  := p_schedule_line_array(i).range_low * MILES_TO_SWMILES;
    ELSIF ((p_mileage_line_array(p_ml_index).distance_unit_code = C_SWMILES) AND (p_sh_distance_uom = C_KILOMETERS)) THEN    	
        l_range_high := p_schedule_line_array(i).range_high * KILOMETERS_TO_SWMILES;
     	l_range_low  := p_schedule_line_array(i).range_low * KILOMETERS_TO_SWMILES;     	
    END IF;	
    
    -- Bug 8813146 - Threshold tolerance is used when daily_distance is used or distance_uom's used are different
    Begin
	    SELECT DISTANCE_FIELD 
	    INTO   l_ou_distance_field 
	    FROM   AP_POL_CAT_OPTIONS 
	    WHERE  category_code = 'MILEAGE';
    exception
        when no_data_found then
	    l_ou_distance_field := C_DISTANCE_FIELD;
    end;

    IF ( C_DISTANCE_FIELD = l_ou_distance_field OR p_mileage_line_array(p_ml_index).distance_unit_code <> p_sh_distance_uom) THEN
	IF (p_mileage_line_array(p_ml_index).distance_unit_code <> C_KILOMETERS) THEN
		l_threshold_tolerance := C_THRESHOLD_TOLERANCE;
	END IF;
    END IF;

    IF (i = 1) THEN
      -------------------------------------------
      l_debug_info := 'is distance within range';
      ------------------------------------------- 
      l_over_threshold_distance := l_cum_distance - nvl(l_range_high, l_cum_distance);

      --Bug 5844609
      --Line shouldn't be split if over threshold distance is greater than or equal to trip distance.

      IF (round(l_over_threshold_distance) <= 0 OR
      (round(p_mileage_line_array(p_ml_index).trip_distance - l_over_threshold_distance)) <= 0)  THEN        	 
	
        RETURN;

      END IF;

      IF (l_over_threshold_distance > l_threshold_tolerance) THEN

          IF (round(p_mileage_line_array(p_ml_index).trip_distance  -
                    l_over_threshold_distance)) > 0 THEN

              p_mileage_line_array(p_ml_index).trip_distance :=
                          (round(p_mileage_line_array(p_ml_index).trip_distance  -
                          l_over_threshold_distance));
          END IF;

        p_mileage_line_array(p_ml_index).daily_distance := 
          round(p_mileage_line_array(p_ml_index).trip_distance /
	  p_mileage_line_array(p_ml_index).number_of_days);

      ELSE

        p_mileage_line_array(p_ml_index).daily_distance := 
          round(p_mileage_line_array(p_ml_index).trip_distance /
	  p_mileage_line_array(p_ml_index).number_of_days);
  
      END IF;
      -------------------------------------------
      l_debug_info := 'Modify the original line';
      -------------------------------------------      
      l_new_rate := getRate(
		      p_sh_distance_uom       => p_sh_distance_uom, 
		      p_sh_currency_code      => p_sh_currency_code,
                      p_mileage_line	      => p_mileage_line_array(p_ml_index),     
		      p_schedule_line         => p_schedule_line_array(1));

          /* Bug 3975334 : Rate per passenger logic needs to be added.
                           rate_per_passenger will be 0 if the schedule
                           does not have passengers_flag as 'Y'.
          */

           l_new_rate := l_new_rate + nvl((p_schedule_line_array(1).rate_per_passenger *
                                      p_mileage_line_array(p_ml_index).number_people),0)+
                                      getAddonMileageRatesSum(p_mileage_line_array(p_ml_index).report_header_id,
                                      p_mileage_line_array(p_ml_index).orig_dist_line_number );

      p_mileage_line_array(p_ml_index).avg_mileage_rate := l_new_rate;      
      p_mileage_line_array(p_ml_index).amount := 
        l_new_rate * p_mileage_line_array(p_ml_index).trip_distance;
      p_mileage_line_array(p_ml_index).receipt_currency_amount := 
        p_mileage_line_array(p_ml_index).amount;
      p_mileage_line_array(p_ml_index).daily_amount := 
        l_new_rate * p_mileage_line_array(p_ml_index).trip_distance / p_mileage_line_array(p_ml_index).number_of_days;
      p_mileage_line_array(p_ml_index).new_dist_line_number := 
	    p_mileage_line_array(p_ml_index).orig_dist_line_number;
      p_mileage_line_array(p_ml_index).status := AP_WEB_DB_EXPLINE_PKG.C_Split;

      l_over_threshold_distance := l_cum_distance - nvl(l_range_high, l_cum_distance);

    ELSE 

      /* When a threshold is crossed, the original line will be modified.  At
         the same time, the system will add new lines to the lines table.  
         The first row of the scheduleLineArray is used to modified the
         original line.  We will need to loop through the rest of the array
         to decide how many new rows will be added. */    
   
      IF (l_over_threshold_distance > l_threshold_tolerance ) THEN

        --------------------------------------------
        l_debug_info := 'Creat a new receipt line';
        -------------------------------------------- 

        SELECT max(distribution_line_number) + 1
        INTO   l_next_dist_number
        FROM   AP_EXPENSE_REPORT_LINES
        WHERE  report_header_id = p_mileage_line_array(p_ml_index).report_header_id;
     
        --------------------------------------------
        l_debug_info := 'Find the trip distance';
        -------------------------------------------- 
        IF (l_over_threshold_distance >= l_range_high - l_range_low) THEN
	  l_updated_trip_dist := l_range_high - l_range_low;
        else
          l_updated_trip_dist := l_over_threshold_distance;
        end if;
 
        l_daily_distance := l_updated_trip_dist / p_mileage_line_array(p_ml_index).number_of_days;
      
        /* The rate from the schedule line array is the rate stored in 
	   ap_pol_headers.  The unit of measure will be according to 
	   ap_pol_headers.  However, when calculating the rate for the 
	   lines, we need to get convert the rate according to the UOM
	   in ap_expense_report_lines.  -Akita */
      l_new_rate := getRate(
		      p_sh_distance_uom       => p_sh_distance_uom, 
		      p_sh_currency_code      => p_sh_currency_code,
                      p_mileage_line	      => p_mileage_line_array(p_ml_index),     
		      p_schedule_line         => p_schedule_line_array(i));

          /* Bug 3975334 : Rate per passenger logic needs to be added.
                           rate_per_passenger will be 0 if the schedule
                           does not have passengers_flag as 'Y'.
          */

           l_new_rate := l_new_rate + nvl((p_schedule_line_array(i).rate_per_passenger *
                                      p_mileage_line_array(p_ml_index).number_people),0)+
                                      getAddonMileageRatesSum(p_mileage_line_array(p_ml_index).report_header_id,
                                      p_mileage_line_array(p_ml_index).orig_dist_line_number );
        addToMileageArray(l_insert_index,
			l_next_dist_number,
			round(l_updated_trip_dist),
			round(l_daily_distance),
			l_new_rate,
			p_mileage_line_array(p_ml_index).report_header_id,
			p_ml_index,
			p_mileage_line_array);

        p_mileage_line_array_count := l_insert_index ; 

	l_added_total := l_added_total + 1;

        l_over_threshold_distance := l_cum_distance - nvl(l_range_high, l_cum_distance);
      END IF; -- l_over_threshold_distance > 0
		          
    END IF; -- i = 1

  END LOOP;

  --------------------------------------------
  l_debug_info := 'Reorder l_mileage_array';
  --------------------------------------------
  /* Using the original count of the array to ensure the new distribution 
     number assigned to the new rows will not be modified again in 
     updateNewDistNumber. -Akita */
  updateNewDistNumber(p_ml_index + 1,
		   l_sl_array_count,
		   l_added_total,
		   p_mileage_line_array);


EXCEPTION
  WHEN NO_DATA_FOUND THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('No Data found: processCrossThreshold');
    APP_EXCEPTION.RAISE_EXCEPTION;
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('processCrossThreshold');
    APP_EXCEPTION.RAISE_EXCEPTION;
END processCrossThreshold;

-------------------------------------------------------------------------------
PROCEDURE ProcessMileageLines(p_item_type 	IN VARCHAR2,
			     p_item_key		IN VARCHAR2,
			     p_actid		IN NUMBER,
			     p_funmode		IN VARCHAR2,
			     p_result	 OUT NOCOPY VARCHAR2) IS
-------------------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_ml_start_date		DATE;
  l_ml_end_date			DATE;
  l_ml_numberOfDays		NUMBER;
  l_ml_distribution_line_number	AP_WEB_DB_EXPLINE_PKG.expLines_distLineNum;
  l_ml_policy_id		AP_POL_HEADERS.policy_id%TYPE;
  l_cumulative_mileage		AP_WEB_EMPLOYEE_INFO.NUMERIC_VALUE%TYPE;
  l_period_id			AP_WEB_EMPLOYEE_INFO.PERIOD_ID%TYPE;
  l_debug_info			VARCHAR2(200);
  C_WF_VERSION			NUMBER := 0;	
  l_new_rate			NUMBER := 0;
  l_ml_avg_mileage_rate		AP_WEB_DB_EXPLINE_PKG.expLines_avg_mileage_rate;
  l_ml_distance_unit_code	AP_WEB_DB_EXPLINE_PKG.expLines_distance_unit_code;
  l_ml_trip_distance		AP_WEB_DB_EXPLINE_PKG.expLines_trip_distance;
  c_expense_lines_cursor	AP_WEB_DB_EXPLINE_PKG.ExpLinesCursor;
  l_employee_id			NUMBER;
  l_schedule_line_array		AP_WEB_DB_SCHLINE_PKG.Schedule_Line_Array;
  l_temp			NUMBER;
  l_sh_distance_uom		AP_POL_HEADERS.distance_uom%TYPE;
  l_sh_currency_code		AP_POL_HEADERS.currency_code%TYPE;
  l_index			NUMBER := 0;
  l_lines_created		NUMBER := 0;
  l_temp_mileage_line_array	AP_WEB_DB_EXPLINE_PKG.Mileage_Line_Array;
  l_mileage_line_array		AP_WEB_DB_EXPLINE_PKG.Mileage_Line_Array;
  l_mileage_array_count		NUMBER;
  i				NUMBER;
  j				NUMBER := 1;
  l_orig_distance_travel	NUMBER;
  l_rate                        NUMBER;

  l_base_precision		NUMBER;
  l_ext_precision		NUMBER;
  l_base_min_acct_unit		NUMBER;
  l_total                       NUMBER;
  l_total_dsp                   VARCHAR2(50);
  l_bHeaderUpdated		BOOLEAN := FALSE;
  l_reimb_curr			AP_WEB_DB_EXPRPT_PKG.expHdr_payemntCurrCode;
  l_over_threshold_distance NUMBER := 0;
  l_sh_distance_thresholds_flag VARCHAR2(1);

  l_report_header_info   	AP_WEB_DFLEX_PKG.ExpReportHeaderRec;
  l_custom_array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  l_mileage_line		AP_WEB_DFLEX_PKG.ExpReportLineRec;
  l_addon_rates                 OIE_ADDON_RATES_T;
  Custom1_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom2_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom3_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom4_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom5_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom6_Array 		    AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom7_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom8_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom9_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom10_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom11_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom12_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom13_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom14_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom15_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  k number;
  cursor getAddonRates(l_report_line_id NUMBER) is select addon_rate_type
  from oie_addon_mileage_rates
  where report_line_id = l_report_line_id;
  l_client_extension_enabled VARCHAR2(1);
  l_temp_array     OIE_PDM_NUMBER_T;  -- bug 5358186 
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ProcessMileageLines');

  -----------------------------------------------------
  l_debug_info := 'Get Workflow Version Number 5';
  -----------------------------------------------------
  C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(p_item_type, p_item_key);

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
				      p_item_key,
				     'EXPENSE_REPORT_ID'); 
  -------------------------------------------------------
  l_debug_info := 'Retrieve Employee_ID Item Attribute';
  -------------------------------------------------------
  l_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                               p_item_key,
                                               'EMPLOYEE_ID'); 


  --------------------------------------------
  l_debug_info := 'Open Expense Lines Cursor';
  --------------------------------------------
  IF (AP_WEB_DB_EXPLINE_PKG.GetExpMileageLinesCursor(l_report_header_id, c_expense_lines_cursor)) THEN		    
                  						
    LOOP
      --------------------------------------------
       l_debug_info := 'Fetch Mileage Lines Cursor';
      --------------------------------------------
      FETCH c_expense_lines_cursor INTO 
			   l_temp_mileage_line_array(j).start_date,
			   l_temp_mileage_line_array(j).end_date,
			   l_temp_mileage_line_array(j).number_of_days,
                           l_temp_mileage_line_array(j).orig_dist_line_number, 
			   l_temp_mileage_line_array(j).policy_id,
			   l_temp_mileage_line_array(j).avg_mileage_rate,
			   l_temp_mileage_line_array(j).distance_unit_code,
			   l_temp_mileage_line_array(j).trip_distance,
			   l_temp_mileage_line_array(j).daily_distance,
			   l_temp_mileage_line_array(j).category_code,
			   l_temp_mileage_line_array(j).reimbursement_currency_code,
                           l_temp_mileage_line_array(j).amount,
                           l_temp_mileage_line_array(j).number_people,
                           l_temp_mileage_line_array(j).web_parameter_id,
                           l_temp_mileage_line_array(j).rate_per_passenger,
                           l_temp_mileage_line_array(j).attribute1,
                           l_temp_mileage_line_array(j).attribute2 ,
                           l_temp_mileage_line_array(j).attribute3 ,
                           l_temp_mileage_line_array(j).attribute4 ,
                           l_temp_mileage_line_array(j).attribute5 ,
                           l_temp_mileage_line_array(j).attribute6 ,
                           l_temp_mileage_line_array(j).attribute7 ,
                           l_temp_mileage_line_array(j).attribute8 ,
                           l_temp_mileage_line_array(j).attribute9 ,
                           l_temp_mileage_line_array(j).attribute10 ,
                           l_temp_mileage_line_array(j).attribute11 ,
                           l_temp_mileage_line_array(j).attribute12 ,
                           l_temp_mileage_line_array(j).attribute13 ,
                           l_temp_mileage_line_array(j).attribute14 ,
                           l_temp_mileage_line_array(j).attribute15 ,
                           l_temp_mileage_line_array(j).report_line_id ;
      EXIT WHEN c_expense_lines_cursor%NOTFOUND;
      l_temp_mileage_line_array(j).report_header_id := l_report_header_id;
      l_temp_mileage_line_array(j).new_dist_line_number := l_temp_mileage_line_array(j).orig_dist_line_number;
      j := j+1;
    END LOOP;
  END IF;
  
  l_mileage_array_count := c_expense_lines_cursor%ROWCOUNT;

  IF (l_mileage_array_count > 0 ) THEN 
    FOR j IN 1..l_mileage_array_count LOOP
      l_mileage_line_array(j).start_date := l_temp_mileage_line_array(j).start_date;
      l_mileage_line_array(j).end_date := l_temp_mileage_line_array(j).end_date;
      l_mileage_line_array(j).number_of_days:= l_temp_mileage_line_array(j).number_of_days;
      l_mileage_line_array(j).orig_dist_line_number:= l_temp_mileage_line_array(j).orig_dist_line_number; 
      l_mileage_line_array(j).policy_id:= l_temp_mileage_line_array(j).policy_id;
      l_mileage_line_array(j).avg_mileage_rate:= l_temp_mileage_line_array(j).avg_mileage_rate;
      l_mileage_line_array(j).distance_unit_code:= l_temp_mileage_line_array(j).distance_unit_code;
      l_mileage_line_array(j).trip_distance:= l_temp_mileage_line_array(j).trip_distance;
      l_mileage_line_array(j).category_code:= l_temp_mileage_line_array(j).category_code;
      l_mileage_line_array(j).reimbursement_currency_code := l_temp_mileage_line_array(j).reimbursement_currency_code;
      l_mileage_line_array(j).amount := l_temp_mileage_line_array(j).amount;
      l_mileage_line_array(j).report_header_id := l_temp_mileage_line_array(j).report_header_id;
      l_mileage_line_array(j).new_dist_line_number := l_temp_mileage_line_array(j).new_dist_line_number;
      l_mileage_line_array(j).number_people := l_temp_mileage_line_array(j).number_people;
      l_mileage_line_array(j).web_parameter_id := l_temp_mileage_line_array(j).web_parameter_id;
      l_mileage_line_array(j).rate_per_passenger := l_temp_mileage_line_array(j).rate_per_passenger;
      l_mileage_line_array(j).attribute1 := l_temp_mileage_line_array(j).attribute1;
      l_mileage_line_array(j).attribute2 := l_temp_mileage_line_array(j).attribute2;
      l_mileage_line_array(j).attribute3 := l_temp_mileage_line_array(j).attribute3;
      l_mileage_line_array(j).attribute4 := l_temp_mileage_line_array(j).attribute4;
      l_mileage_line_array(j).attribute5 := l_temp_mileage_line_array(j).attribute5;
      l_mileage_line_array(j).attribute6 := l_temp_mileage_line_array(j).attribute6;
      l_mileage_line_array(j).attribute7 := l_temp_mileage_line_array(j).attribute7;
      l_mileage_line_array(j).attribute8 := l_temp_mileage_line_array(j).attribute8;
      l_mileage_line_array(j).attribute9 := l_temp_mileage_line_array(j).attribute9;
      l_mileage_line_array(j).attribute10 := l_temp_mileage_line_array(j).attribute10;
      l_mileage_line_array(j).attribute11 := l_temp_mileage_line_array(j).attribute11;
      l_mileage_line_array(j).attribute12 := l_temp_mileage_line_array(j).attribute12;
      l_mileage_line_array(j).attribute13 := l_temp_mileage_line_array(j).attribute13;
      l_mileage_line_array(j).attribute14 := l_temp_mileage_line_array(j).attribute14;
      l_mileage_line_array(j).attribute15 := l_temp_mileage_line_array(j).attribute15;
      l_mileage_line_array(j).report_line_id := l_temp_mileage_line_array(j).report_line_id;
    END loop;

    FOR i IN 1..l_mileage_array_count LOOP
      --------------------------------------------
      l_debug_info := 'Start processing the mileage line';
      --------------------------------------------    
      IF (l_mileage_line_array(i).category_code = 'MILEAGE') THEN
 
        --------------------------------------------
        l_debug_info := 'Get distance UOM from schedule header';
        --------------------------------------------      
        AP_WEB_DB_SCHLINE_PKG.getSchHeaderInfo(
	  p_policy_id	   => l_mileage_line_array(i).policy_id,
	  p_sh_distance_uom  => l_sh_distance_uom,
	  p_sh_currency_code => l_sh_currency_code,
          p_sh_distance_thresholds_flag => l_sh_distance_thresholds_flag);

      IF (l_sh_distance_thresholds_flag = 'P') THEN    
          AP_WEB_DB_USER_PREF_PKG.getCumulativeMileage(l_mileage_line_array(i).policy_id, 
				     l_mileage_line_array(i).start_date,
				     l_mileage_line_array(i).end_date,
				     l_employee_id,
				     l_cumulative_mileage,
				     l_period_id);
      ELSIF (l_sh_distance_thresholds_flag = 'T') THEN
      			l_cumulative_mileage := 0.0;	
                l_period_id := 0;
      END IF;

        --------------------------------------------
        l_debug_info := 'Call getScheduleLine';
        --------------------------------------------      
        getScheduleLineArray(l_report_header_id,
		l_mileage_line_array(i).orig_dist_line_number,
		l_employee_id,
		l_cumulative_mileage,
		l_schedule_line_array);

        l_orig_distance_travel := l_mileage_line_array(i).trip_distance; 

	IF (l_schedule_line_array.COUNT > 1) THEN

	  processCrossThreshold(
		p_ml_index		   => i,
		p_sh_distance_uom	   => l_sh_distance_uom,
		p_sh_currency_code	   => l_sh_currency_code,
		p_schedule_line_array	   => l_schedule_line_array,
		p_mileage_line_array_count => l_mileage_array_count,
		p_cumulative_mileage	   => l_cumulative_mileage,
		p_mileage_line_array	   => l_mileage_line_array);

	ELSIF (l_schedule_line_array.COUNT = 1 ) THEN
	  -------------------------------------------  
          l_debug_info := 'is distance within range';
          -------------------------------------------
          IF l_over_threshold_distance > 1 THEN
            l_mileage_line_array(i).trip_distance :=
              round(l_mileage_line_array(i).trip_distance  -
              l_over_threshold_distance);

            l_mileage_line_array(i).daily_distance :=
              round(l_mileage_line_array(i).trip_distance /
              l_mileage_line_array(i).number_of_days);

          ELSE

            l_mileage_line_array(i).daily_distance :=
              round(l_mileage_line_array(i).trip_distance /
              l_mileage_line_array(i).number_of_days);
 
          END IF;

          /*  To determine whether the entire trip distance has met another
           * threshold, we compare the reimbursement amount to find it out.
           * By doing this, we can avoid the precision error especially
           * there is no limit on the precision of a rate when defining a
           * schedule.
           */

          l_rate := l_schedule_line_array(1).rate;

          IF (l_sh_distance_uom <> l_mileage_line_array(i).distance_unit_code) THEN
            IF ((l_sh_distance_uom = C_KILOMETERS) AND (l_mileage_line_array(i).distance_unit_code = C_MILES )) THEN
              l_rate := round(l_schedule_line_array(1).rate * MILES_TO_KILOMETERS, 6);
            ELSIF ((l_sh_distance_uom = C_MILES) AND (l_mileage_line_array(i).distance_unit_code = C_KILOMETERS)) THEN
              l_rate := round(l_schedule_line_array(1).rate * KILOMETERS_TO_MILES, 6);
            ELSIF ((l_sh_distance_uom = C_SWMILES) AND (l_mileage_line_array(i).distance_unit_code = C_KILOMETERS)) THEN
              l_rate := round(l_schedule_line_array(1).rate * KILOMETERS_TO_SWMILES, 6);
            ELSIF ((l_sh_distance_uom = C_KILOMETERS) AND (l_mileage_line_array(i).distance_unit_code = C_SWMILES)) THEN
              l_rate := round(l_schedule_line_array(1).rate * SWMILES_TO_KILOMETERS, 6);
            ELSIF ((l_sh_distance_uom = C_MILES) AND (l_mileage_line_array(i).distance_unit_code = C_SWMILES)) THEN
              l_rate := round(l_schedule_line_array(1).rate * SWMILES_TO_MILES, 6);
            ELSIF ((l_sh_distance_uom = C_SWMILES) AND (l_mileage_line_array(i).distance_unit_code = C_MILES)) THEN
              l_rate := round(l_schedule_line_array(1).rate * MILES_TO_SWMILES, 6);
            END IF;
          END IF;

          /* Bug 3975334 : Rate per passenger logic needs to be added.
                           rate_per_passenger will be 0 if the schedule
                           does not have passengers_flag as 'Y'.
             Bug 6448540 : Add getAddonMileageRatesSum
          */
           l_rate := l_rate + nvl((l_schedule_line_array(1).rate_per_passenger *
                                l_mileage_line_array(i).number_people),0)+
                                getAddonMileageRatesSum(l_mileage_line_array(i).report_header_id,
                                l_mileage_line_array(i).orig_dist_line_number);


          FND_CURRENCY.GET_INFO( 
             l_mileage_line_array(i).reimbursement_currency_code,
             l_base_precision ,
             l_ext_precision ,
             l_base_min_acct_unit);
          
          IF (round(l_rate * l_mileage_line_array(i).trip_distance,l_base_precision) <> l_mileage_line_array(i).amount) THEN
	    -- update reimbursable amount (Rate)

	    l_new_rate := getRate(
			  p_sh_distance_uom       => l_sh_distance_uom,  
			  p_sh_currency_code	  => l_sh_currency_code,
			  p_mileage_line	  => l_mileage_line_array(i),
			  p_schedule_line	  => l_schedule_line_array(1));

          /* Bug 3975334 : Rate per passenger logic needs to be added.
                           rate_per_passenger will be 0 if the schedule
                           does not have passengers_flag as 'Y'.
          */

           l_new_rate := l_new_rate + nvl((l_schedule_line_array(1).rate_per_passenger *
                                      l_mileage_line_array(i).number_people),0)+
                                      getAddonMileageRatesSum(l_mileage_line_array(i).report_header_id,
                                      l_mileage_line_array(i).orig_dist_line_number);

     /* Bug 3732690 : In ProcessMileageLines rounding the amount before calling
                      updateExpenseMileageLines.
     */
 
	    l_mileage_line_array(i).amount := 
                AP_UTILITIES_PKG.AP_ROUND_CURRENCY(
	                   l_new_rate * l_mileage_line_array(i).trip_distance,
                           l_mileage_line_array(i).reimbursement_currency_code);

	    l_mileage_line_array(i).receipt_currency_amount :=
                                 l_mileage_line_array(i).amount;

	    l_mileage_line_array(i).daily_amount := 
                AP_UTILITIES_PKG.AP_ROUND_CURRENCY(
	                l_new_rate * l_mileage_line_array(i).trip_distance /
	                             l_mileage_line_array(i).number_of_days,
                        l_mileage_line_array(i).reimbursement_currency_code);

	    l_mileage_line_array(i).avg_mileage_rate := l_new_rate;

            l_mileage_line_array(i).new_dist_line_number := 
	      l_mileage_line_array(i).orig_dist_line_number;
  
	    l_mileage_line_array(i).status := AP_WEB_DB_EXPLINE_PKG.C_Modified;


	  END IF;	

          IF (l_mileage_line_array(i).distance_unit_code = C_MILES) THEN
               l_cumulative_mileage := round(((l_orig_distance_travel * MILES_TO_KILOMETERS) + l_cumulative_mileage),1);
          ELSIF (l_mileage_line_array(i).distance_unit_code = C_SWMILES) THEN
               l_cumulative_mileage := round(((l_orig_distance_travel * SWMILES_TO_KILOMETERS) + l_cumulative_mileage),1);
          ELSE
	       l_cumulative_mileage := l_orig_distance_travel  + l_cumulative_mileage;
          END IF;

        END IF;


        IF (l_sh_distance_thresholds_flag = 'P') THEN 	
              updateCumulativeMileage(l_cumulative_mileage,
			      l_period_id,
			      l_employee_id);

        END IF;				
	BEGIN
	        SELECT CALCULATE_AMOUNT_FLAG
        	INTO l_client_extension_enabled
        	FROM ap_expense_report_params
        	WHERE parameter_id = l_mileage_line_array(i).web_parameter_id;
	EXCEPTION WHEN OTHERS THEN
		l_client_extension_enabled := 'N';
	END;
	IF (l_client_extension_enabled = 'Y') THEN
	    -- Bug: 7140256 one-off for 6476888, NO_DATA_FOUND, wrong index used.
	    Custom1_Array(1).value := l_mileage_line_array(i).attribute1;
	    Custom1_Array(2).value := l_mileage_line_array(i).attribute2;
   	    Custom1_Array(3).value := l_mileage_line_array(i).attribute3;	
	    Custom1_Array(4).value := l_mileage_line_array(i).attribute4;
	    Custom1_Array(5).value := l_mileage_line_array(i).attribute5;
	    Custom1_Array(6).value := l_mileage_line_array(i).attribute6;
	    Custom1_Array(7).value := l_mileage_line_array(i).attribute7;
	    Custom1_Array(8).value := l_mileage_line_array(i).attribute8;
	    Custom1_Array(9).value := l_mileage_line_array(i).attribute9;
	    Custom1_Array(10).value := l_mileage_line_array(i).attribute10;
	    Custom1_Array(11).value := l_mileage_line_array(i).attribute11;
	    Custom1_Array(12).value := l_mileage_line_array(i).attribute12;
	    Custom1_Array(13).value := l_mileage_line_array(i).attribute13;
	    Custom1_Array(14).value := l_mileage_line_array(i).attribute14;
	    Custom1_Array(15).value := l_mileage_line_array(i).attribute15;

            AP_WEB_DFLEX_PKG.GetReceiptCustomFields(l_custom_array,
                	 1, -- from ap_web_oa_mainflow_pkg.validatereceiptline
                         Custom1_Array,
                         Custom2_Array,
                         Custom3_Array,
                         Custom4_Array,
                         Custom5_Array,
                         Custom6_Array,
                         Custom7_Array,
                         Custom8_Array,
                         Custom9_Array,
                         Custom10_Array,
                         Custom11_Array,
                         Custom12_Array,
                         Custom13_Array,
                         Custom14_Array,
                         Custom15_Array
                         );
        
        -- Bug: 7140256 one-off for 6476888, NO_DATA_FOUND, wrong index used.
	l_mileage_line.parameter_id := l_mileage_line_array(i).web_parameter_id;  	
	l_mileage_line.start_date := l_mileage_line_array(i).start_date;  	
	l_mileage_line.end_date := l_mileage_line_array(i).end_date;  	
	l_mileage_line.tripDistance := l_mileage_line_array(i).trip_distance;  	
	l_mileage_line.distanceUnitCode := l_mileage_line_array(i).distance_unit_code;  	
	l_mileage_line.amount := l_mileage_line_array(i).amount;  	
	l_mileage_line.mileageRate := l_mileage_line_array(i).avg_mileage_rate;  	-- ?? base rate?
	l_mileage_line.numberPassengers := l_mileage_line_array(i).number_people;  	
	l_mileage_line.passengerRateUsed := l_mileage_line_array(i).rate_per_passenger;  	
	l_mileage_line.currency_code := l_mileage_line_array(i).reimbursement_currency_code;  	
	l_mileage_line.category_code := l_mileage_line_array(i).category_code;

	OPEN getAddonRates(l_mileage_line_array(i).report_line_id);
	k := 1;
	LOOP
	   -- l_addon_rates(1) :=  'FOREST_ROADS';
	   FETCH getAddonRates INTO l_addon_rates(k);
	   EXIT WHEN getAddonRates%NOTFOUND;
           k := k + 1;
	END LOOP;
	CLOSE getAddonRates;

        AP_WEB_CUST_DFLEX_PKG.CustomCalculateAmount( l_report_header_info -- can be null from wf perspective
                              , l_mileage_line -- should contain all fields as defined in fdd
                              , l_custom_array-- should contain all fields as defined in fdd
                              , l_addon_rates -- should contain all fields as defined in fdd
                              , p_cust_meals_amount => l_temp_array
                              , p_cust_accommodation_amount => l_temp_array
                              , p_cust_night_rate_amount => l_temp_array
                              , p_cust_pdm_rate => l_temp_array);
        -- delete reference to temp array as this is used for per diem only
        -- deleting prevents inadvertent data corruption
        -- Bug: 7140256 one-off for 6476888, VARRAY can be atomically null, CustomCalculateAmount need not initialize this for Mileage
        IF (l_temp_array is not null) THEN
         l_temp_array.delete; -- bug 5358186 
        END IF;
        l_mileage_line_array(i).amount := l_mileage_line.amount;
       END IF; -- if client extension enabled

      END IF; -- IF (category_code = 'MILEAGE') 
    END LOOP;

  AP_WEB_DB_EXPLINE_PKG.updateExpenseMileageLines(l_mileage_line_array, l_bHeaderUpdated);

  -----------------------------------------------------------------------
  l_debug_info := 'update display_total item attribute if ap_expense_report_headers has been updated';
  -----------------------------------------------------------------------      
  IF (l_bHeaderUpdated = TRUE) THEN 
    IF (NOT AP_WEB_DB_EXPRPT_PKG.UpdateHeaderTotal(l_report_header_id)) THEN 
      NULL;
    END IF;

    IF (NOT AP_WEB_DB_EXPRPT_PKG.GetHeaderTotal(l_report_header_id,
                                        l_total)) THEN
      NULL;
    END IF;

    IF (NOT AP_WEB_DB_EXPRPT_PKG.GetReimbCurr(l_report_header_id,
                                        l_reimb_curr)) THEN

      NULL;
    END IF;

    l_total_dsp := to_char(l_total,
			 FND_CURRENCY.Get_Format_Mask(l_reimb_curr,22));

    WF_ENGINE.SetItemAttrText('APEXP',
                               to_char(l_report_header_id),
                               'DISPLAY_TOTAL',
                               l_total_dsp || ' ' || l_reimb_curr);


  END IF;
END IF;

EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('ProcessMileageLines');
    APP_EXCEPTION.RAISE_EXCEPTION;
END ProcessMileageLines;

-------------------------------------------------------------------------------
PROCEDURE hasCompanyViolations( p_item_type  IN VARCHAR2,
			       p_item_key   IN VARCHAR2,
			       p_actid      IN NUMBER,
			       p_funmode    IN VARCHAR2,
			       p_result     OUT NOCOPY VARCHAR2) IS
-------------------------------------------------------------------------------
  l_debug_info	     VARCHAR2(200);
  l_violations_count NUMBER:=0;
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
BEGIN
  
  
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start hasCompanyViolations');

  IF (p_funmode = 'RUN') THEN
    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');
    ------------------------------------------------------
    l_debug_info := 'Select from ap_pol_violations table';
    ------------------------------------------------------
    --Bug 3581975:Select the policy lines with distribution_line_number > 0.
    SELECT count(*)
    INTO   l_violations_count
    FROM   ap_pol_violations
    WHERE  report_header_id = l_report_header_id
    and    distribution_line_number > 0;

    IF (l_violations_count > 0) THEN
      p_result := 'COMPLETE:Y';
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'RULES_VIOLATED',
			        'Y');
    ELSE
      p_result := 'COMPLETE:N';
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'RULES_VIOLATED',
			        'Y');
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end hasCompanyViolations');

EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('hasCompanyViolations');
    APP_EXCEPTION.RAISE_EXCEPTION;
END hasCompanyViolations;


-------------------------------------------------------------------------------
PROCEDURE GenerateAmountMsg(document_id		IN VARCHAR2,
				display_type	IN VARCHAR2,
				document	IN OUT NOCOPY VARCHAR2,
				document_type	IN OUT NOCOPY VARCHAR2) IS

  l_colon    NUMBER;
  l_itemtype VARCHAR2(7);
  l_itemkey  VARCHAR2(15);
  
  l_report_header_id		AP_WEB_DB_EXPLINE_PKG.expLines_headerID;
  l_debug_info			VARCHAR2(2000);
  l_msg				VARCHAR2(2000);
  l_approver_id			NUMBER;
  l_total			NUMBER;
  l_currency			VARCHAR2(25);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GenerateAmountMsg');

  ------------------------------------------------------------
  l_debug_info := 'Decode document_id';
  ------------------------------------------------------------
  l_colon    := instrb(document_id, ':');
  l_debug_info := ' First index: ' || to_char(l_colon);
  l_itemtype := substrb(document_id, 1, l_colon - 1);
  l_itemkey  := substrb(document_id, l_colon  + 1);

  ------------------------------------------------------
  l_debug_info := 'Retrieve Approve_ID Item Attribute';
  ------------------------------------------------------
  l_approver_id := WF_ENGINE.GetItemAttrNumber(l_itemtype,
					       l_itemkey,
					       'APPROVER_ID');

  ------------------------------------------------------
  l_debug_info := 'Retrieve TOTAL Item Attribute';
  ------------------------------------------------------
  l_total := WF_ENGINE.GetItemAttrNumber(l_itemtype,
					 l_itemkey,
					 'TOTAL');

  ------------------------------------------------------
  l_debug_info := 'Retrieve CURRENCY Item Attribute';
  ------------------------------------------------------
  l_currency := WF_ENGINE.GetItemAttrText(l_itemtype,
                                          l_itemkey,
                                          'CURRENCY');

  l_msg :=  ap_web_amount_util.get_meaningful_amount_msg_emp( 
                   p_employee_id => l_approver_id, 
                   p_amount => l_total, 
                   p_date => SYSDATE, 
                   p_currency_code => l_currency); 

  document := l_msg;
  document_type := display_type;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GenerateExpLines');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GenerateAmountMsg', 
                    document_id, l_debug_info);
    raise;
END GenerateAmountMsg;

-------------------------------------------------------------------------------
PROCEDURE GetRespAppInfo(p_item_key         IN VARCHAR2,
                         p_resp_id          OUT NOCOPY NUMBER,
                         P_appl_id          OUT NOCOPY NUMBER) IS
-------------------------------------------------------------------------------
  l_debug_info			VARCHAR2(2000);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetRespAppInfo');

  ------------------------------------------------------
  l_debug_info := 'Retrieve RESPONSIBILITY_ID Item Attribute';
  ------------------------------------------------------
  p_resp_id := WF_ENGINE.GetItemAttrNumber('APEXP',
					   p_item_key,
					   'RESPONSIBILITY_ID');

  ------------------------------------------------------
  l_debug_info := 'Retrieve APPLICATION_ID Item Attribute';
  ------------------------------------------------------
  p_appl_id := WF_ENGINE.GetItemAttrNumber('APEXP',
					   p_item_key,
					   'APPLICATION_ID');

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetRespAppInfo');

EXCEPTION
  WHEN OTHERS THEN  
    if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
            null;
    else
       Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GetRespAppInfo', 
                    p_item_key, l_debug_info);
       raise;
    end if;
END GetRespAppInfo;

-------------------------------------------------------------------------------
PROCEDURE GetAuditType( p_item_type  IN VARCHAR2,
			p_item_key   IN VARCHAR2,
			p_actid      IN NUMBER,
			p_funmode    IN VARCHAR2,
			p_result     OUT NOCOPY VARCHAR2) IS
-------------------------------------------------------------------------------

  CURSOR audit_cur(p_report_header_id IN NUMBER) IS
    select audit_code
    from   ap_expense_report_headers
    where  report_header_id = p_report_header_id;

  CURSOR rule_cur(p_report_header_id IN NUMBER) IS
    select rs.assign_auditor_stage_code
    from   ap_expense_report_headers aerh,
           ap_aud_rule_sets rs,
           ap_aud_rule_assignments_all rsa
    where aerh.report_header_id = p_report_header_id
    and   aerh.org_id = rsa.org_id
    and   rsa.rule_set_id = rs.rule_set_id
    and   rs.rule_set_type = 'RULE'
    and   TRUNC(SYSDATE)    
            BETWEEN TRUNC(NVL(rsa.START_DATE,SYSDATE)) 
            AND     TRUNC(NVL(rsa.END_DATE,SYSDATE));

  l_debug_info	     VARCHAR2(200);
  l_report_header_id AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  audit_rec          audit_cur%ROWTYPE;
  rule_rec           rule_cur%ROWTYPE;
BEGIN 
  
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetAuditType');

  IF (p_funmode = 'RUN') THEN
    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    IF l_report_header_id IS NULL THEN

      p_result := 'COMPLETE:AUDIT';

    ELSE 

      ------------------------------------------------------------
      l_debug_info := 'Retrieve Expense Report audit type';
      ------------------------------------------------------------
      OPEN audit_cur(l_report_header_id);
      FETCH audit_cur INTO audit_rec;

      IF audit_cur%NOTFOUND THEN
        p_result := 'COMPLETE:AUDIT';
      ELSIF audit_rec.audit_code is null THEN
        p_result := 'COMPLETE:AUDIT';
      ELSIF audit_rec.audit_code = 'PAPERLESS_AUDIT' THEN

        OPEN rule_cur(l_report_header_id);
        FETCH rule_cur INTO rule_rec;

        IF rule_cur%FOUND AND rule_rec.assign_auditor_stage_code = 'MANAGER_APPROVAL' THEN
          AP_WEB_AUDIT_QUEUE_UTILS.enqueue_for_audit(l_report_header_id);
        END IF;

        CLOSE rule_cur;

        p_result := 'COMPLETE:RULE_BASED_AUDIT';
      ELSIF audit_rec.audit_code = 'AUTO_APPROVE' THEN
        p_result := 'COMPLETE:AUTO_APPROVED';
      ELSIF audit_rec.audit_code = 'AUDIT' THEN
        p_result := 'COMPLETE:RULE_BASED_AUDIT';
      ELSE
        p_result := 'COMPLETE:AUDIT';
      END IF;

      CLOSE audit_cur;

    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetAuditType');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GetAuditType', 
                    p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END GetAuditType;


-------------------------------------------------------------------------------
PROCEDURE ResetWFNote(p_item_type      IN VARCHAR2,
                      p_item_key       IN VARCHAR2,
                      p_actid          IN NUMBER,
                      p_funmode        IN VARCHAR2,
                      p_result         OUT NOCOPY VARCHAR2) IS
-------------------------------------------------------------------------------

  l_debug_info                  VARCHAR2(200);

BEGIN


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ResetWFNote');

  ---------------------------------------------------------------
  l_debug_info := 'Reset WF_NOTE';
  ---------------------------------------------------------------
  WF_ENGINE.SetItemAttrText(p_item_type,
                            p_item_key,
                            'WF_NOTE',
                            '');

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ResetWFNote');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ResetWFNote',
                    p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END ResetWFNote;

----------------------------------------------------------------------
PROCEDURE AddToOtherErrors(p_item_type            IN  VARCHAR2,
                            p_item_key             IN  VARCHAR2,
                            p_other_error         IN  VARCHAR2) IS
----------------------------------------------------------------------

  l_other_errors	VARCHAR2(2000) := NULL;

  l_prompts		AP_WEB_UTILITIES_PKG.prompts_table;
  l_title		AK_REGIONS_VL.name%TYPE;

  l_debug_info		VARCHAR2(2000);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AddToOtherErrors');

  ---------------------------------------------------------
  l_debug_info := 'Add to Other Errors';
  ---------------------------------------------------------
  l_other_errors := WF_ENGINE.GetItemAttrText(p_item_type,
                                               p_item_key,
                                               'OTHER_ERRORS');
  ---------------------------------------------------------
  l_debug_info := 'Check to see if error title needed';
  ---------------------------------------------------------
  if (l_other_errors IS NULL) then
    ---------------------------------------------------------
    l_debug_info := 'Add font tag';
    ---------------------------------------------------------
    l_other_errors := startOraFieldTextFont;
  else
    l_other_errors := l_other_errors || '<br>';
  end if;

  AddToWFSSError(l_other_errors,  p_other_error);
  l_other_errors := l_other_errors || endOraFieldTextFont;

  WF_ENGINE.SetItemAttrText(p_item_type,
	 		    p_item_key,
			    'OTHER_ERRORS',
			    l_other_errors);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AddToOtherErrors');

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'AddToOtherErrors');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;
    APP_EXCEPTION.RAISE_EXCEPTION;

END AddToOtherErrors;

/*
Written by: 
  Ron Langi
Purpose: 
  To generate HEADER_ERRORS as a plsql doc attr since OWF.G no longer
  supports the use of html tags within a text item.
*/
----------------------------------------------------------------------
PROCEDURE GenerateHeaderErrors(document_id      IN VARCHAR2,
                               display_type    IN VARCHAR2,
                               document        IN OUT NOCOPY VARCHAR2,
                               document_type   IN OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_colon    NUMBER;
  l_itemtype VARCHAR2(7);
  l_itemkey  VARCHAR2(25);

  l_debug_info                  VARCHAR2(200);

BEGIN
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GenerateHeaderErrors');

  ------------------------------------------------------------
  l_debug_info := 'Decode document_id';
  ------------------------------------------------------------
  l_colon    := instrb(document_id, ':');
  l_itemtype := substrb(document_id, 1, l_colon - 1);
  l_itemkey  := substrb(document_id, l_colon + 1);

  ------------------------------------------------------------
  l_debug_info := 'Retrieve HEADER_ERRORS Item Attribute';
  ------------------------------------------------------------
  document := WF_ENGINE.GetItemAttrText(l_itemtype,
                                        l_itemkey,
                                        'HEADER_ERRORS');

  document_type := display_type;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GenerateHeaderErrors');

EXCEPTION
  WHEN OTHERS THEN  
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GenerateHeaderErrors', document_id, l_debug_info);
    raise;

END GenerateHeaderErrors;


/**
 * jrautiai ADJ Fix start
 */
----------------------------------------------------------------------
PROCEDURE SetFromRoleAP(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info                  VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetFromRoleAP');

  IF (p_funmode = 'RUN') THEN
    ----------------------------------------------------------------
    l_debug_info := 'Set #FROM_ROLE to AP';
    ----------------------------------------------------------------
    SetFromRole(p_item_type, 
            p_item_key, 
            p_actid, 
            WF_ENGINE.GetItemAttrText(p_item_type, 
                                      p_item_key, 
                                      'PAYABLES'), 
            'SetFromRoleAP' 
            ); 

    /*
    WF_ENGINE.SetItemAttrText(p_item_type,
                              p_item_key,
                              '#FROM_ROLE',
                              WF_ENGINE.GetItemAttrText(p_item_type,
                                                        p_item_key,
                                                        'PAYABLES'));
    */
    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    p_result := 'COMPLETE';
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetFromRoleAP');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetFromRoleAP',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END SetFromRoleAP;


------------------------------------------------------------------------
PROCEDURE SetPolicyInfo(p_item_type		IN VARCHAR2,
		   	p_item_key		IN VARCHAR2,
		   	p_actid			IN NUMBER,
		   	p_funmode		IN VARCHAR2,
		   	p_result	 OUT NOCOPY VARCHAR2) IS
-------------------------------------------------------------------------
  l_debug_info		VARCHAR2(2000);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetPolicyInfo');
  SetShortPaidLinesInfo(p_item_type,
                        p_item_key,
                        p_actid,
                        p_funmode,
                        'POLICY',
                        p_result);
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetPolicyInfo');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetPolicyInfo', 
                     p_item_type, p_item_key, null, l_debug_info);
    raise;
END SetPolicyInfo;

------------------------------------------------------------------------
PROCEDURE SetMissingReceiptInfo(p_item_type		IN VARCHAR2,
                                p_item_key		IN VARCHAR2,
                                p_actid			IN NUMBER,
                                p_funmode		IN VARCHAR2,
                                p_result	 OUT NOCOPY VARCHAR2) IS
-------------------------------------------------------------------------
  l_debug_info		VARCHAR2(2000);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetMissingReceiptInfo');
  
  SetShortPaidLinesInfo(p_item_type,
                        p_item_key,
                        p_actid,
                        p_funmode,
                        'MISSING_RECEIPT',
                        p_result);
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetMissingReceiptInfo');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetMissingReceiptInfo', 
                     p_item_type, p_item_key, null, l_debug_info);
    raise;
END SetMissingReceiptInfo;

------------------------------------------------------------------------
PROCEDURE SetProvideMissingInfo(p_item_type		IN VARCHAR2,
                                    p_item_key		IN VARCHAR2,
                                    p_actid		IN NUMBER,
                                    p_funmode		IN VARCHAR2,
                                    p_result	 OUT NOCOPY VARCHAR2) IS
------------------------------------------------------------------------
  l_debug_info      VARCHAR2(2000);
  l_mess            Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;
  l_document_number AP_WEB_DB_EXPRPT_PKG.expHdr_invNum;
  l_preparer_name   VARCHAR2(2000);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start SetProvideMissingInfo');
  
  
  ----------------------------------------------------------------
  l_debug_info := 'Set #FROM_ROLE to Preparer';
  ----------------------------------------------------------------
  SetFromRolePreparer(p_item_type, p_item_key, p_actid, p_funmode, p_result);
      
  l_document_number := WF_ENGINE.GetItemAttrText(p_item_type,
                                                 p_item_key,
                                                 'DOCUMENT_NUMBER');
                                                 
  l_preparer_name   := WF_ENGINE.GetItemAttrText(p_item_type,
                                                 p_item_key,
                                                 'PREPARER_DISPLAY_NAME');

  FND_MESSAGE.SET_NAME('SQLAP','OIE_WF_PROVIDE_MISSING_NOTE');
  FND_MESSAGE.Set_Token('EMPLOYEE_NAME', l_preparer_name);
  FND_MESSAGE.Set_Token('REPORT_NUMBER', l_document_number);
  l_mess := FND_MESSAGE.GET;

  WF_ENGINE.SetItemAttrText(p_item_type,
                            p_item_key,
                            'OIENOTES',
                            l_mess);
                            
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end SetProvideMissingInfo');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'SetProvideMissingInfo', 
                     p_item_type, p_item_key, null, l_debug_info);
    raise;
END SetProvideMissingInfo;

PROCEDURE ResetShortpayAdjustmentInfo(p_item_type  IN VARCHAR2,
                                      p_item_key   IN VARCHAR2,
                                      p_actid      IN NUMBER,
                                      p_funmode    IN VARCHAR2,
                                      p_result     OUT NOCOPY VARCHAR2) IS
  l_debug_info       VARCHAR2(2000);
  l_report_header_id NUMBER;
BEGIN
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start ResetShortpayAdjustmentInfo');

  ------------------------------------------------------------
  l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
  ------------------------------------------------------------
  l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                    p_item_key,
                                                    'EXPENSE_REPORT_ID');

  ----------------------------------------------------------------
  l_debug_info := 'Reset adjustment information';
  ----------------------------------------------------------------
  AP_WEB_DB_EXPLINE_PKG.ResetShortpayAdjustmentInfo(l_report_header_id);
  
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end ResetShortpayAdjustmentInfo');
EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'ResetShortpayAdjustmentInfo', 
                     p_item_type, p_item_key, null, l_debug_info);
    raise;
END ResetShortpayAdjustmentInfo;
                                      
/**
 * jrautiai ADJ Fix end
 */
 

/*
Written by: 
  Ron Langi
Purpose: 
  To check the result of the Audit Review.

  The possible results are:
  Reviewed - Auditor Complete
  Rejected - Auditor Rejected
  Request More Info - Auditor Requesting More Info
*/
----------------------------------------------------------------------
PROCEDURE CheckAPReviewResult(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_workflow_approved_flag		AP_WEB_DB_EXPRPT_PKG.expHdr_wkflApprvdFlag;

  l_return_reason		VARCHAR2(80);
  l_return_instruction          Wf_Item_Attribute_Values.TEXT_VALUE%TYPE;

  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CheckAPReviewResult');


  IF (p_funmode = 'RUN') THEN

    ----------------------------------------------------------------
    l_debug_info := 'Set #FROM_ROLE to AP';
    ----------------------------------------------------------------
    SetFromRoleAP(p_item_type, p_item_key, p_actid, p_funmode, p_result);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                              p_item_key,
                              'EXPENSE_REPORT_ID');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Return Reason and Instruction';
    ------------------------------------------------------------
    if (not AP_WEB_DB_EXPRPT_PKG.getAuditReturnReasonInstr(l_report_header_id,
                                                          l_return_reason,
                                                          l_return_instruction)) then 
      l_debug_info := 'Could not retrieve Return Reason and Instruction';
    end if;

    ----------------------------------------------------------
    l_debug_info := 'Set Item Attribute AUDIT_RETURN_REASON';
    ---------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'AUDIT_RETURN_REASON',
			        l_return_reason);

    ----------------------------------------------------------
    l_debug_info := 'Set Item Attribute AUDIT_INSTRUCTIONS';
    ---------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'AUDIT_INSTRUCTIONS',
			        l_return_instruction);

    ----------------------------------------------------------
    l_debug_info := 'Set Item Attribute Line_Info_Body';
    ---------------------------------------------------------
    WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'LINE_INFO_BODY',
			        'plsql:AP_WEB_EXPENSE_WF.generateAdjustmentInfo/'|| p_item_type || ':' || p_item_key || ':AUDIT');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Workflow_Approved_Flag';
    ------------------------------------------------------------
    SELECT WORKFLOW_APPROVED_FLAG
    INTO   l_workflow_approved_flag
    FROM   AP_EXPENSE_REPORT_HEADERS
    WHERE  REPORT_HEADER_ID = l_report_header_id;
  
    IF (l_workflow_approved_flag = AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_REJECTED) THEN
      p_result := 'COMPLETE:REJECTED';
    ELSIF (l_workflow_approved_flag = AP_WEB_DB_EXPRPT_PKG.C_WORKFLOW_APPROVED_REQUEST) THEN
      p_result := 'COMPLETE:REQUEST_MORE_INFO';
    ELSE
      p_result := 'COMPLETE:REVIEWED';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  
  END IF;
  
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CheckAPReviewResult');

  EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CheckAPReviewResult', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END CheckAPReviewResult;


/*
Written by: 
  Ron Langi
Purpose: 
  This adds the expense report back to the Audit queue.
*/
----------------------------------------------------------------------
PROCEDURE AddToAuditQueue(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_debug_info			VARCHAR2(200);
  l_manager_approved            VARCHAR2(5);
  l_workflow_flag               VARCHAR2(5);

  CURSOR audit_cur(p_report_header_id IN NUMBER) IS
    select audit_code, workflow_approved_flag
    from   ap_expense_report_headers
    where  report_header_id = p_report_header_id;

  audit_rec          audit_cur%ROWTYPE;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AddToAuditQueue');


  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                              p_item_key,
                              'EXPENSE_REPORT_ID');

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve UPDATE_MANAGER_APPROVED Activity Attribute';
    -------------------------------------------------------------------
    l_manager_approved := WF_ENGINE.GetActivityAttrText(p_item_type,
                                            p_item_key,
                                            p_actid,
                                           'UPDATE_MANAGER_APPROVED');

    ----------------------------------------------------------------------
    l_debug_info := 'Retrieve Expense Report audit type and workflow flag';
    ----------------------------------------------------------------------
    OPEN audit_cur(l_report_header_id);
    FETCH audit_cur INTO audit_rec;

    IF l_manager_approved = 'Y' THEN

       IF audit_rec.workflow_approved_flag in ('P','Y') THEN
          l_workflow_flag := 'Y';
       ELSE
          l_workflow_flag := 'M';
       END IF;

       ----------------------------------------------------------------------
       l_debug_info := 'Update the Expense Report as Mgr Approved so that it can be auditable';
       ----------------------------------------------------------------------
       IF (NOT AP_WEB_DB_EXPRPT_PKG.SetWkflApprvdFlagAndSource(l_report_header_id,
				  l_workflow_flag, NULL)) THEN
	  NULL;
       END IF;

    END IF; 
    
    
    IF audit_rec.audit_code = 'PAPERLESS_AUDIT' THEN
      ------------------------------------------------------------
      l_debug_info := 'Add to Audit queue';
      ------------------------------------------------------------
      AP_WEB_AUDIT_QUEUE_UTILS.enqueue_for_audit(l_report_header_id);
    END IF;

    CLOSE audit_cur;

    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  
  END IF;
  
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AddToAuditQueue');

  EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AddToAuditQueue', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AddToAuditQueue;


/*
Written by: 
  Ron Langi
Purpose: 
  This removes the expense report from the Audit queue.
*/
----------------------------------------------------------------------
PROCEDURE RemoveFromAuditQueue(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_debug_info			VARCHAR2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start RemoveFromAuditQueue');


  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                              p_item_key,
                              'EXPENSE_REPORT_ID');

    ------------------------------------------------------------
    l_debug_info := 'Remove from Audit queue';
    ------------------------------------------------------------
    AP_WEB_AUDIT_QUEUE_UTILS.remove_from_queue(l_report_header_id);

    p_result := 'COMPLETE:Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  
  END IF;
  
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end RemoveFromAuditQueue');

  EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'RemoveFromAuditQueue', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END RemoveFromAuditQueue;


/*
Written by: 
  Ron Langi
Purpose: 
  This stores a Preparer-Auditor note based on the Manager/Preparer/Employee/Sysadmin
  action/response from a notification activity.

  The following is gathered from the WF:
  - RESULT_TYPE contains the lookup type for the result of the Notification.
  - RESULT_CODE contains the lookup code for the result of the Notification.
  - RESPONSE contains the respond attr for the Notification.

  The Preparer-Auditor note is stored in the form of:
  Preparer Response: <Preparer Response>
  or
  Employee Action: <Employee Response> (for 3rd Party Approval)
  or
  Approver Action: <Approver Response>
  or
  Sysadmin Action: <Sysadmin Response>
*/
----------------------------------------------------------------------
PROCEDURE StoreNote(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       IN OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_debug_info			VARCHAR2(200);

  l_message_name fnd_new_messages.message_name%type;
  l_result_type varchar2(80);
  l_result_code varchar2(80);
  l_response varchar2(80);
  l_type_display_name varchar2(80);
  l_code_display_name varchar2(80);
  l_note_prefix varchar2(2000);

  l_orig_language_code ap_expense_params.note_language_code%type := null;
  l_orig_language fnd_languages.nls_language%type := null;
  l_new_language_code ap_expense_params.note_language_code%type := null;
  l_new_language fnd_languages.nls_language%type := null;

  l_entered_by NUMBER := fnd_global.user_id;

  l_user_name fnd_user.user_name%TYPE := null;
  l_ame_enabled varchar2(1) := 'N';

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start StoreNote');

  IF (p_funmode = 'RUN') THEN

    -------------------------------------------------------------------
    l_debug_info := 'Need to generate Note based on language setup';
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    l_debug_info := 'Save original language';
    -------------------------------------------------------------------
    l_orig_language_code := userenv('LANG');
    select nls_language
    into   l_orig_language
    from   fnd_languages
    where  language_code = l_orig_language_code;

    -------------------------------------------------------------------
    l_debug_info := 'Check AP_EXPENSE_PARAMS.NOTE_LANGUAGE_CODE';
    -------------------------------------------------------------------
    begin
      select note_language_code
      into   l_new_language_code
      from   ap_expense_params;

      exception
        when no_data_found then
          null;
    end;

    -------------------------------------------------------------------
    l_debug_info := 'Else use instance base language';
    -------------------------------------------------------------------
    if (l_new_language_code is null) then
      select language_code
      into   l_new_language_code
      from   fnd_languages
      where  installed_flag in ('B');
    end if;

    -------------------------------------------------------------------
    l_debug_info := 'Set nls context to new language';
    -------------------------------------------------------------------
    select nls_language
    into   l_new_language
    from   fnd_languages
    where  language_code = l_new_language_code;

    fnd_global.set_nls_context(p_nls_language => l_new_language);

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Activity Result Type';
    -------------------------------------------------------------------
    l_result_type := WF_ENGINE.GetActivityAttrText(p_item_type,
                                                   p_item_key,
                                                   p_actid,
                                                   'RESULT_TYPE');


    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Note prefix';
    -------------------------------------------------------------------
    if (l_result_type = 'WFSTD_APPROVAL') then
      l_message_name := 'OIE_NOTES_APPROVER_ACTION';
      l_ame_enabled := nvl(WF_ENGINE.GetItemAttrText(p_item_type,
                                                     p_item_key,
                                                     'AME_ENABLED'),'N');

      IF ( l_ame_enabled <> 'Y' ) THEN
	BEGIN
          -- Bug: 8419020
          l_debug_info := 'Retreiving role info from wf notifications';
            
          SELECT n.recipient_role INTO l_user_name
	  FROM  WF_ITEM_ACTIVITY_STATUSES s,
          wf_notifications n
	  WHERE s.item_type = 'APEXP'
	  AND   s.item_key = p_item_key
	  AND   s.notification_id = n.notification_id
	  AND   n.message_type = 'APEXP'
	  AND   n.message_name = 'OIE_REQ_EXPENSE_REPORT_APPRVL'
	  AND  (n.item_key = p_item_key
                OR p_item_key = SubStr(n.context,7,length(p_item_key)) )
	  AND   n.status <> 'CANCELED';
     
	  AP_WEB_DB_HR_INT_PKG.GetUserIdFromName(l_user_name, l_entered_by);
	EXCEPTION
	  WHEN OTHERS THEN
	    l_entered_by := -1;
	END;

      END IF;

      IF ( l_ame_enabled = 'Y' OR l_entered_by = -1 ) THEN
        AP_WEB_OA_MAINFLOW_PKG.GetUserId(WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                                   p_item_key,
                                                                   'APPROVER_ID'),
                                       l_entered_by);
      END IF;
    elsif (l_result_type = 'EMPLOYEE_APPROVAL') then
      l_message_name := 'OIE_NOTES_EMPLOYEE_ACTION';
      AP_WEB_OA_MAINFLOW_PKG.GetUserId(WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                                   p_item_key,
                                                                   'EMPLOYEE_ID'),
                                       l_entered_by);
      -- EMPLOYEE_APPROVAL is to be treated the same as WFSTD_APPROVAL
      l_result_type := 'WFSTD_APPROVAL';
    else
      l_message_name := 'OIE_NOTES_PREPARER_RESPONSE';
      AP_WEB_OA_MAINFLOW_PKG.GetUserId(WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                                   p_item_key,
                                                                   'PREPARER_ID'),
                                       l_entered_by);
    end if;

    begin
      -------------------------------------------------------------------
      -- fnd_global.set_nls_context() seems to work for WF but not FND_MESSAGES
      -------------------------------------------------------------------
      select message_text
      into   l_note_prefix
      from   fnd_new_messages
      where  application_id = 200
      and    message_name = l_message_name
      and    language_code = l_new_language_code;

      exception
        when no_data_found then
          FND_MESSAGE.SET_NAME('SQLAP', l_message_name);
          l_note_prefix := FND_MESSAGE.GET;
    end;

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Activity Result Code';
    -------------------------------------------------------------------
    l_result_code := WF_ENGINE.GetActivityAttrText(p_item_type,
                                                   p_item_key,
                                                   p_actid,
                                                   'RESULT_CODE');

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Activity Response';
    -------------------------------------------------------------------
    l_response := WF_ENGINE.GetActivityAttrText(p_item_type,
                                                   p_item_key,
                                                   p_actid,
                                                   'RESPONSE');
  
    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                      p_item_key,
                                                      'EXPENSE_REPORT_ID');

    ------------------------------------------------------------
    l_debug_info := 'Retrieve lookup display name';
    ------------------------------------------------------------
    WF_LOOKUP_TYPES_PUB.fetch_lookup_display(l_result_type, 
                                             l_result_code,
                                             l_type_display_name,
                                             l_code_display_name);

    ------------------------------------------------------------
    l_debug_info := 'store the result and response as a note';
    ------------------------------------------------------------
    AP_WEB_NOTES_PKG.CreateERPrepToAudNote (
      p_report_header_id       => l_report_header_id,
      p_note                   => l_note_prefix||' '||l_code_display_name||'
'||WF_ENGINE.GetItemAttrText(p_item_type, p_item_key, l_response),
      p_lang                   => l_new_language_code,
      p_entered_by             => l_entered_by
    );

    -------------------------------------------------------------------
    l_debug_info := 'Restore nls context to original language';
    -------------------------------------------------------------------
    fnd_global.set_nls_context(p_nls_language => l_orig_language);

    -------------------------------------------------------------------
    -- only clear audit issues if it is a preparer response
    -------------------------------------------------------------------
    if (l_result_type <> 'WFSTD_APPROVAL') then
      ------------------------------------------------------------
      l_debug_info := 'clear the header/line level return/audit reason/instructions in AERH/AERL';
      ------------------------------------------------------------
      AP_WEB_DB_EXPRPT_PKG.clearAuditReturnReasonInstr(l_report_header_id);
      AP_WEB_DB_EXPLINE_PKG.clearAuditReturnReasonInstr(l_report_header_id);

      ----------------------------------------------------------
      l_debug_info := 'clear Item Attribute AUDIT_RETURN_REASON';
      ---------------------------------------------------------
      WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'AUDIT_RETURN_REASON',
			        '');

      ----------------------------------------------------------
      l_debug_info := 'Set Item Attribute AUDIT_INSTRUCTIONS';
      ---------------------------------------------------------
      WF_ENGINE.SetItemAttrText(p_item_type,
	 		        p_item_key,
			        'AUDIT_INSTRUCTIONS',
			        '');
    end if;

    p_result := 'COMPLETE:Y';

  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end StoreNote');

  EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'StoreNote', 
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END StoreNote;


--------------------------------------------------------------------------

/*Written By: Amulya Mishra
  Purpose :   Notification Escalation project.
              Gets job level from HR for a person. 
*/
----------------------------------------------------------------------

PROCEDURE GetJobLevelAndSupervisor(
                                 p_personId IN NUMBER,
                                 p_jobLevel OUT NOCOPY NUMBER)
IS
----------------------------------------------------------------------

BEGIN
        SELECT 
           nvl(pj.approval_authority, 0)
        INTO  p_jobLevel
        FROM 
          per_jobs pj,
          per_all_assignments_f pa
        WHERE 
             pj.job_id = pa.job_id 
        AND  pa.person_id = p_personId 
        AND  pa.primary_flag = 'Y'
        AND  pa.assignment_type in ('E' , 'C') --Support Contingent Workres
        AND  pa.assignment_status_type_id not in
                      (select assignment_status_type_id
                       from per_assignment_status_types
                       where per_system_status = 'TERM_ASSIGN') 
        AND trunc(sysdate) between pa.effective_start_date and  pa.effective_end_date;

EXCEPTION        
	WHEN OTHERS THEN	
          p_jobLevel := 0;
end GetJobLevelAndSupervisor;
----------------------------------------------------------------------------


----------------------------------------------------------------------
PROCEDURE IsEmployeeTerminated(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_person_id		NUMBER		:= NULL;

  fixable_exception		EXCEPTION;
  l_error_message		VARCHAR2(2000);
  l_debug_info			VARCHAR2(200);

BEGIN

  IF (p_funmode = 'RUN') THEN

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Employee Id Item Attribute';
    ---------------------------------------------------------------
    l_person_id := WF_ENGINE.GetItemAttrText(p_item_type,
                                             p_item_key,
                                             'EMPLOYEE_ID');

    -- Check whether person is terminated  
    IF (AP_WEB_DB_HR_INT_PKG.isPersonTerminated(l_person_id)='Y') THEN 
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'IsPersonTerminated',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END IsEmployeeTerminated;


----------------------------------------------------------------------
PROCEDURE IsEmployeeActive(p_item_type      IN VARCHAR2,
                       p_item_key       IN VARCHAR2,
                       p_actid          IN NUMBER,
                       p_funmode        IN VARCHAR2,
                       p_result  OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_person_id           NUMBER          := NULL;

  fixable_exception             EXCEPTION;
  l_error_message               VARCHAR2(2000);
  l_debug_info                  VARCHAR2(200);

BEGIN
  
  IF (p_funmode = 'RUN') THEN

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Employee Id Item Attribute';
    ---------------------------------------------------------------
    l_person_id := WF_ENGINE.GetItemAttrText(p_item_type,
                                             p_item_key,
                                             'EMPLOYEE_ID');
  
    -- Check whether person is active
    IF (AP_WEB_DB_HR_INT_PKG.isPersonActive(l_person_id)='Y') THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;
  
  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'IsEmployeeActive',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END IsEmployeeActive;

----------------------------------------------------------------------
PROCEDURE IsManagerActive(p_item_type      IN VARCHAR2,
                       p_item_key       IN VARCHAR2,
                       p_actid          IN NUMBER,
                       p_funmode        IN VARCHAR2,
                       p_result  OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_person_id           NUMBER          := NULL;

  fixable_exception             EXCEPTION;
  l_error_message               VARCHAR2(2000);
  l_debug_info                  VARCHAR2(200);

BEGIN

  IF (p_funmode = 'RUN') THEN

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Manager Id Item Attribute';
    ---------------------------------------------------------------
    l_person_id := WF_ENGINE.GetItemAttrText(p_item_type,
                                             p_item_key,
                                             'MANAGER_ID');

    -- Check whether person is active
    IF (AP_WEB_DB_HR_INT_PKG.isPersonActive(l_person_id)='Y') THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'IsManagerActive',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END IsManagerActive;


-- 3257576 - Gets the manager info and sets p_error_message, p_instructions
-- p_special_instr if manager is terminated or does not exist or is suspended
---------------------------------------------------------------------------
PROCEDURE GetManagerInfoAndCheckStatus(
			p_employee_id		    IN 	NUMBER,
			p_employee_name		    IN 	VARCHAR2,
			p_manager_id            OUT NOCOPY NUMBER,
			p_manager_name          OUT NOCOPY VARCHAR2,
			p_manager_status        OUT NOCOPY VARCHAR2,
			p_error_message         OUT NOCOPY VARCHAR2,
                        p_instructions          OUT NOCOPY VARCHAR2,
                        p_special_instr         OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------------------------
  l_debug_info			VARCHAR2(200);
  l_emp_info_rec             AP_WEB_DB_HR_INT_PKG.EmployeeInfoRec;
  l_employee_name            per_workforce_x.full_name%TYPE;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start GetManagerInfoAndCheckStatus');

  -----------------------------------------------------------
  l_debug_info := 'Trying to retrieve employee manager info';
  -----------------------------------------------------------
  AP_WEB_DB_HR_INT_PKG.GetManagerIdAndStatus(
                           p_employee_id,
                           p_manager_id,
                           p_manager_name,
                           p_manager_status);

  -----------------------------------------------------------------------
  l_debug_info := 'After GetManagerIdAndStatus ' || to_char(p_manager_id)
                  || 'p_manager_status '||p_manager_status;
  -----------------------------------------------------------------------

  IF (p_manager_id IS NULL) THEN
     IF (p_employee_name IS NULL) THEN
       IF AP_WEB_DB_HR_INT_PKG.GetEmployeeInfo(p_employee_id,l_emp_info_rec) THEN
          l_employee_name := l_emp_info_rec.employee_name;
       END IF;
     END IF;
     --------------------------------
     l_debug_info := 'No supervisor';
     --------------------------------
     FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_SUPERVISOR');
     FND_MESSAGE.Set_Token('EMPLOYEE_NAME', nvl(p_employee_name,l_employee_name));
     p_error_message := FND_MESSAGE.Get;

     FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR1');
     p_instructions := FND_MESSAGE.Get;

     FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_SPL_INSTR');
     p_special_instr := FND_MESSAGE.Get;
  ELSIF (p_manager_status = 'TERM_ASSIGN') THEN
     -----------------------------------------
     l_debug_info := 'Approver is terminated';
     -----------------------------------------
     FND_MESSAGE.Set_Name('SQLAP', 'OIE_APPROVER_TERMINATED');
     FND_MESSAGE.Set_Token('APPROVER_NAME', p_manager_name);
     p_error_message := FND_MESSAGE.Get;

     FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR1');
     p_instructions := FND_MESSAGE.Get;

     FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_SPL_INSTR');
     p_special_instr := FND_MESSAGE.Get;
  ELSIF ((p_manager_status = 'SUSP_ASSIGN') or 
         (p_manager_status = 'SUSP_CWK_ASG')) THEN
     -----------------------------------------------------------
     l_debug_info := 'Approver is suspended/on temporary leave';
     -----------------------------------------------------------
     FND_MESSAGE.Set_Name('SQLAP', 'OIE_APPROVER_SUSPENDED');
     FND_MESSAGE.Set_Token('APPROVER_NAME', p_manager_name);
     p_error_message := FND_MESSAGE.Get;

     FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR2');
     p_instructions := FND_MESSAGE.Get;

     FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_SPL_INSTR');
     p_special_instr := FND_MESSAGE.Get;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end GetManagerInfoAndCheckStatus');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GetManagerInfoAndCheckStatus', 
                     null, null, null, l_debug_info);
    raise;
END GetManagerInfoAndCheckStatus;

----------------------------------------------------------------------------
/* Written By : Amulya Mishra
   Bug 3389386: For Expense report with Both Pay only personal transactions,
                set the expense_status_code as PAID because the report gets
                automatically manager and payable approved and the header
                total is 0.

                This is done inorder to avoid any usage of decode in files
                TrackExpenseReportsVO.xml and apwvw003.sql
*/
----------------------------------------------------------------------------

Procedure  SetExpenseStatusCode(p_report_header_id IN Number) 
IS
----------------------------------------------------------------------------
   l_num_both_personal_lines     NUMBER := 0;
   
BEGIN

   IF (AP_WEB_DB_EXPLINE_PKG.GetNoOfBothPayPersonalLines(p_report_header_id,l_num_both_personal_lines)) THEN
     NULL;
   END IF;

   IF l_num_both_personal_lines > 0 THEN

     UPDATE AP_EXPENSE_REPORT_HEADERS
     SET    EXPENSE_STATUS_CODE = 'PAID'
     WHERE REPORT_HEADER_ID = p_report_header_id;

  END IF;


END SetExpenseStatusCode;
-----------------------------------------------------------------------------


----------------------------------------------------------------------------
/* Written By : Amulya Mishra
   Bug 2777245: Update expense report header and lines data after submission
                through self-service and just before workflow kicks off.

   Note:        Customer can use this procedure to manipualte the values in
                Header and Lines table.
*/
----------------------------------------------------------------------------

Procedure  UpdateHeaderLines(p_report_header_id IN Number)
IS
----------------------------------------------------------------------------

BEGIN

     UPDATE AP_EXPENSE_REPORT_HEADERS
     SET DESCRIPTION= AP_WEB_UTILITIES_PKG.RtrimMultiByteSpaces(description) 
     WHERE REPORT_HEADER_ID = p_report_header_id;

     UPDATE AP_EXPENSE_REPORT_LINES
     SET JUSTIFICATION = AP_WEB_UTILITIES_PKG.RtrimMultiByteSpaces(justification),
         SUBMITTED_AMOUNT = AMOUNT
     WHERE REPORT_HEADER_ID = p_report_header_id;

END UpdateHeaderLines;


-----------------------------------------------------------------------------
Procedure  RaiseSubmitEvent(
                            p_report_header_id IN Number,
                            p_workflow_appr_flag IN VARCHAR2) IS
----------------------------------------------------------------------------

  l_debug_info                  VARCHAR2(200);

  l_user_id                     NUMBER;
  l_resp_id                     NUMBER;
  l_resp_appl_id                NUMBER;

  l_para_list                   WF_PARAMETER_LIST_T;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start RaiseSubmitEvent');

  ----------------------------------------------------------
  l_debug_info := 'Get USER_ID/RESP_ID/RESP_APPL_ID';
  ----------------------------------------------------------
  l_user_id      := FND_PROFILE.VALUE('USER_ID');
  l_resp_id      := FND_PROFILE.VALUE('RESP_ID');
  l_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');

  ----------------------------------------------------------
  l_debug_info := 'Add to event param list  USER_ID/RESP_ID/RESP_APPL_ID';
  ----------------------------------------------------------
  wf_event.AddParameterToList(p_name =>'USER_ID',
                              p_value =>l_user_id,
                              p_parameterlist =>l_para_list);

  wf_event.AddParameterToList(p_name =>'RESPONSIBILITY_ID',
                              p_value =>l_resp_id,
                              p_parameterlist =>l_para_list);

  wf_event.AddParameterToList(p_name =>'APPLICATION_ID',
                              p_value =>l_resp_appl_id,
                              p_parameterlist =>l_para_list);

  ----------------------------------------------------------
  l_debug_info := 'Raise Submit Event';
  ----------------------------------------------------------
  wf_event.raise(p_event_name => C_SUBMIT_EVENT_NAME,
                 p_event_key  => p_report_header_id,
                 p_parameters => l_para_list);

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end RaiseSubmitEvent');

  EXCEPTION
  WHEN OTHERS THEN

    -- bug 2203689, set workflow_approved_flag to S so that users can
    -- re-submit the report without re-entering data again

    -- Bug 3248874 : Also set expense_status_code as NULL.
    --               Source as NonValidateWebExpense.

    UPDATE ap_expense_report_headers erh
    SET    workflow_approved_flag = 'S',  
           expense_status_code = null,
           source = 'NonValidatedWebExpense'
    WHERE  report_header_id = p_report_header_id;
    COMMIT;


    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'RaiseSubmitEvent');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
    END IF;

    -- always raise exceptions regardless it from RaiseSubmitEvent
    -- or other callees
    APP_EXCEPTION.RAISE_EXCEPTION;

END RaiseSubmitEvent;


----------------------------------------------------------------------
PROCEDURE InitSubmit(
                                 p_item_type    IN VARCHAR2,
                                 p_item_key     IN VARCHAR2,
                                 p_actid        IN NUMBER,
                                 p_funmode      IN VARCHAR2,
                                 p_result       IN OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  l_debug_info                  VARCHAR2(200);

  l_report_header_id	ap_expense_report_headers.report_header_id%type;
  l_preparer_id		ap_expense_report_headers.employee_id%type;
  l_employee_id		ap_expense_report_headers.employee_id%type;
  l_document_number	ap_expense_report_headers.invoice_num%type;
  l_total		ap_expense_report_lines.amount%type;
  l_new_total		ap_expense_report_lines.amount%type;
  l_reimb_curr		ap_expense_report_headers.default_currency_code%type;
  l_cost_center		ap_expense_report_headers.flex_concatenated%type;
  l_purpose		ap_expense_report_headers.description%type;
  l_approver_id		ap_expense_report_headers.override_approver_id%type;
  l_week_end_date	ap_expense_report_headers.week_end_date%type;
  l_workflow_flag	ap_expense_report_headers.workflow_approved_flag%type;
  l_submit_from_oie	varchar2(1);

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start InitSubmit');

  l_report_header_id := to_number(p_item_key);

  select aerh.report_header_id,
         fnd.employee_id,
         aerh.employee_id,
         aerh.invoice_num,
         aerh.default_currency_code,
         aerh.flex_concatenated,
         aerh.description,
         aerh.override_approver_id,
         aerh.week_end_date,
         aerh.workflow_approved_flag
  into   l_report_header_id,
         l_preparer_id,
         l_employee_id,
         l_document_number,
         l_reimb_curr,
         l_cost_center,
         l_purpose,
         l_approver_id,
         l_week_end_date,
         l_workflow_flag
  from   ap_expense_report_headers aerh,
         fnd_user fnd
  where  aerh.report_header_id = l_report_header_id
  and    fnd.user_id = aerh.created_by;

  select sum(aerl.amount),
         sum(decode(sign(aerl.amount),-1,0,aerl.amount))
  into   l_total,
         l_new_total
  from   ap_expense_report_lines aerl
  where  aerl.report_header_id = l_report_header_id
  and    (itemization_parent_id is null OR itemization_parent_id <> -1);

  StartExpenseReportProcess(
                                    l_report_header_id,
                                    l_preparer_id,
                                    l_employee_id,
                                    l_document_number,
                                    l_total,
                                    l_new_total,
                                    l_reimb_curr,
                                    l_cost_center,
                                    l_purpose,
                                    l_approver_id,
                                    l_week_end_date,
                                    l_workflow_flag,
                                    p_submit_from_oie => 'Y',
                                    p_event_raised => 'Y');

  p_result := 'COMPLETE';

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end InitSubmit');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'InitSubmit',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END InitSubmit;

------------------------------------------------------------------------
FUNCTION CheckAccess(
                     p_ntf_id    IN NUMBER,
                     p_item_key  IN NUMBER,
                     p_user_name IN VARCHAR2) RETURN VARCHAR2
------------------------------------------------------------------------
IS

  l_item_type      wf_items.item_type%type;
  l_item_key       wf_items.item_key%type;
  l_access_granted varchar2(1) := 'N';
  l_user_name      wf_notifications.recipient_role%type;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start CheckAccess');

  -- get the item type for the notif
  select message_type
  into   l_item_type
  from   wf_notifications
  where  notification_id = p_ntf_id
  and    rownum = 1;

  --  check the following:
  --  1. NtfId is valid for ReportHeaderId
  if (l_item_type = 'APEXP') then
    --Bug 4425821: Uptake AME parallel approvers
    BEGIN
      select 'Y'
      into   l_access_granted
      from   wf_item_activity_statuses
      where  item_type = l_item_type
      and    ((item_key = to_char(p_item_key)) or (item_key like to_char(p_item_key)  || '-%'))
      and    notification_id = p_ntf_id
      and    rownum = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
         select 'Y'
         into   l_access_granted
         from   wf_item_activity_statuses_h
         where  item_type = l_item_type
         and    ((item_key = to_char(p_item_key)) or (item_key like to_char(p_item_key)  || '-%'))
         and    notification_id = p_ntf_id
         and    rownum = 1;
    END;        
  elsif (l_item_type = 'APWHOLDS') then

    BEGIN
      select item_key
      into   l_item_key
      from   wf_item_activity_statuses
      where  item_type = l_item_type
      and    notification_id = p_ntf_id
      and    rownum = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
         select item_key
         into   l_item_key
         from   wf_item_activity_statuses_h
         where  item_type = l_item_type
         and    notification_id = p_ntf_id
         and    rownum = 1;
    END; 

    select 'Y'
    into   l_access_granted
    from   dual
    where  
    (p_item_key = WF_ENGINE.GetItemAttrNumber(l_item_type, l_item_key, 'EXPENSE_REPORT_ID')
     or
     p_item_key = WF_ENGINE.GetItemAttrNumber(l_item_type, l_item_key, 'HOLDING_EXPENSE_REPORT_ID'))
    and    rownum = 1;

  elsif (l_item_type = 'APWRECPT') then

    BEGIN
      select 'Y'
      into   l_access_granted
      from   wf_item_activity_statuses
      where  item_type = l_item_type
      and    item_key like '%'||to_char(p_item_key)||'%'
      and    notification_id = p_ntf_id
      and    rownum = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
         select 'Y'
         into   l_access_granted
         from   wf_item_activity_statuses_h
         where  item_type = l_item_type
         and    item_key like '%'||to_char(p_item_key)||'%'
         and    notification_id = p_ntf_id
         and    rownum = 1;
    END; 
  else

    -- No Access
    RETURN l_access_granted;

  end if;

  /* bug 5360860: comment out as per wf dev product teams need not make this check
     as the check is already performed by Workflow UI and Workflow Mailer doesn't 
     sends any emails to proxy user  for the notification recieved by the originial 
     recipient. */
  /*
  --  2. User has access to the NtfId
  select 'Y'
  into   l_access_granted
  from   wf_notifications wfn , 
         WF_USER_ROLES wur
  where  wur.user_name = p_user_name
  and    wfn.notification_id = p_ntf_id
  and  ( wfn.recipient_role = wur.role_name 
       OR
       ( wfn.more_info_role is not null and wfn.more_info_role = wur.role_name )
       OR
       ( wfn.from_role is not null and wfn.from_role = wur.role_name ) )
  and    rownum = 1;
  */

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end CheckAccess');

  RETURN l_access_granted;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'N'; 
  WHEN OTHERS THEN
    RETURN 'N';
END CheckAccess;

/*
  Bug 4425821: Uptake AME parallel approvers
  Called from AME Approval Process.
  Gets the next set of approvers, checks if Approval is complete,
  If yes return 
  else spans 'AME Request Approval Process', copies attibute values from AME APproval
  process' to render the notification.
*/
----------------------------------------------------------------------
PROCEDURE AMERequestApproval(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  l_debug_info			  varchar2(200);

  l_approvalProcessCompleteYNOut  varchar2(1);
  l_nextApproversOut              ame_util.approversTable2;

  l_childItemKeySeq               number;
  l_childItemKey                  wf_items.item_key%type;
  l_masterUserKey                 wf_items.user_key%type;

  l_manager_name		  wf_users.name%type;
  l_manager_display_name	  wf_users.display_name%type;

  l_master_report_id              number;

  fixable_exception		EXCEPTION;
  l_error_message		VARCHAR2(2000);
  l_instructions        	fnd_new_messages.message_text%type;
  l_special_instr               fnd_new_messages.message_text%type;
  l_no_notif    CONSTANT VARCHAR2(20) := 'NO_NOTIFICATION'; 
  l_payment                    VARCHAR2(20); 
  l_num_personal_lines         NUMBER := 0; 

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AMERequestApproval');

  IF (p_funmode = 'RUN') THEN
    if (AP_WEB_DB_EXPLINE_PKG.GetNoOfBothPayPersonalLines(p_item_key,l_num_personal_lines)) then  
       null;  
    end if; 
    
    ---------------------------------------------------------------- 
    l_debug_info := 'Retrieve Profile Option Payment Due From'; 
    ---------------------------------------------------------------- 
    IF (NOT AP_WEB_DB_EXPRPT_PKG.getPaymentDueFromReport(p_item_key,l_payment)) THEN 
        l_debug_info := 'Could not set workflow attribute Payment_Due_From'; 
    END IF; 
    
    IF (l_payment = 'BOTH' and l_num_personal_lines > 0 ) THEN 
        p_result := 'COMPLETE:' || l_no_notif; 
        return; 
    END IF; 

     -------------------------------------------------
     l_debug_info := 'Call AMEs getNextApprovers4 api';
     -------------------------------------------------  
     BEGIN
       AME_API2.getNextApprovers4(applicationIdIn   => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                              transactionTypeIn => p_item_type,
	                      transactionIdIn   => p_item_key,
                              approvalProcessCompleteYNOut => l_approvalProcessCompleteYNOut,
			      nextApproversOut   => l_nextApproversOut);
     EXCEPTION
        when others then
	  FND_MESSAGE.Set_Name('SQLAP', 'OIE_GETNEXTAPPROVER_ERROR');
          l_error_message := FND_MESSAGE.Get;
          -- bug 3257576
          FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR4');
          l_instructions := FND_MESSAGE.Get;
	  raise fixable_exception ;
     END;

     IF (l_approvalProcessCompleteYNOut = ame_util.booleanTrue) THEN
       p_result := 'COMPLETE:Y';
       return;
     ELSIF (l_approvalProcessCompleteYNOut = ame_util2.completeNoApprovers) THEN
       p_result := 'COMPLETE:NOAPPROVER';
       return;
     END IF;
 
     l_childItemKeySeq := WF_ENGINE.GetItemAttrNumber(p_item_type,
						   p_item_key,
						   'AME_CHILD_ITEM_KEY_SEQ');

     FOR i IN 1 .. l_nextApproversOut.count LOOP
       IF (l_childItemKeySeq is null) THEN
         l_childItemKeySeq := 1;
       ELSE
         l_childItemKeySeq := l_childItemKeySeq + 1;
       END IF;

       l_childItemKey := p_item_key || '-' || to_char(l_childItemKeySeq);
 
       WF_ENGINE.CreateProcess(p_item_type,
			       l_childItemKey,
                               'AME_REQUEST_APPROVAL_PROCESS');

       l_masterUserKey := WF_ENGINE.GetItemUserKey(p_item_type,
                                                   p_item_key);

       WF_ENGINE.SetItemUserKey(p_item_type,
                                l_childItemKey,
                                l_masterUserKey);


       if (l_nextApproversOut(i).orig_system = 'PER') then
          WF_DIRECTORY.GetUserName(l_nextApproversOut(i).orig_system,
			   	l_nextApproversOut(i).orig_system_id,
			   	l_manager_name,
			   	l_manager_display_name);
       else
          -- 6143415: To support position hierarchy
          WF_DIRECTORY.GetRoleName(l_nextApproversOut(i).orig_system,
			   	l_nextApproversOut(i).orig_system_id,
			   	l_manager_name,
			   	l_manager_display_name);
       end if;

       --------------------------------------------------------
       l_debug_info := 'Set Approver_ID Info Item Attribute';
       --------------------------------------------------------
       WF_ENGINE.SetItemAttrText(p_item_type,
			      l_childItemKey,
			      'APPROVER_ID',
			      l_nextApproversOut(i).orig_system_id);

       --------------------------------------------------------
       l_debug_info := 'Set Approver_Name Info Item Attribute';
       --------------------------------------------------------
       WF_ENGINE.SetItemAttrText(p_item_type,
			      l_childItemKey,
			      'APPROVER_NAME',
			      l_manager_name);

       ----------------------------------------------------------------
       l_debug_info := 'Set Approver_Display_Name Info Item Attribute';
       ----------------------------------------------------------------
       WF_ENGINE.SetItemAttrText(p_item_type,
			      l_childItemKey,
			      'APPROVER_DISPLAY_NAME',
			      l_manager_display_name); 

       ----------------------------------------------------------------
       -- Bug 7119347: Store approver authority, used during reassign
       l_debug_info := 'Set Approver_Authority Info Item Attribute';
       ----------------------------------------------------------------
       begin
         WF_ENGINE.SetItemAttrText(p_item_type,
			      l_childItemKey,
			      'AME_APPROVER_AUTHORITY',
			      l_nextApproversOut(i).authority); 
       exception
	 when others then
	   if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	     -- AME_APPROVER_AUTHORITY item attribute doesn't exist, need to add it
	     WF_ENGINE.AddItemAttr(p_item_type, l_childItemKey, 'AME_APPROVER_AUTHORITY');

    	     WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	l_childItemKey,
                              	'AME_APPROVER_AUTHORITY',
                              	l_nextApproversOut(i).authority);
	   else
	     raise;
	   end if;
       end;

       l_master_report_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
							 p_item_key,
							 'EXPENSE_REPORT_ID');


       WF_ENGINE.SetItemAttrText(p_item_type,
 				 l_childItemKey,
				 'AME_MASTER_ITEM_KEY',
				 p_item_key);

       WF_ENGINE.SetItemAttrText(p_item_type,
 				 l_childItemKey,
				 'AME_APPROVAL_TYPE',
				 l_nextApproversOut(i).approver_category);

       ----------------------------------------------------------------
       l_debug_info := 'Set wf attributes from the master process';
       ----------------------------------------------------------------
       BEGIN
          WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	      l_childItemKey,
                              	      'ORG_ID',
 				      WF_ENGINE.GetItemAttrNumber(p_item_type,
						   	          p_item_key,
						                  'ORG_ID'));
   
          WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	      l_childItemKey,
                              	      'USER_ID',
 				      WF_ENGINE.GetItemAttrNumber(p_item_type,
						   	          p_item_key,
						                  'USER_ID'));
   
          WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	      l_childItemKey,
                              	      'RESPONSIBILITY_ID',
 				      WF_ENGINE.GetItemAttrNumber(p_item_type,
						   	          p_item_key,
						                  'RESPONSIBILITY_ID'));
   
          WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	      l_childItemKey,
                              	      'APPLICATION_ID',
 				      WF_ENGINE.GetItemAttrNumber(p_item_type,
						   	          p_item_key,
						                  'APPLICATION_ID'));
       EXCEPTION
	WHEN OTHERS THEN
	  if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	    null;
	  else
	    raise;
	  end if;
       END;
   
       -- Bug: 9267472 one-off for 7649190, Purpose not shown in the manager approval notification when AME is enabled
       WF_ENGINE.SetItemAttrText(p_item_type,
                                 l_childItemKey,
                                 'PURPOSE',
                                  WF_ENGINE.GetItemAttrText(p_item_type,
                                                            p_item_key,
                                                            'PURPOSE'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'AME_ENABLED',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'AME_ENABLED'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'WITHDRAW_WARNING',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'WITHDRAW_WARNING'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'GRANTS_ENABLED',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'GRANTS_ENABLED'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'LINE_TABLE',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'LINE_TABLE'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'EMP_LINE_TABLE',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'EMP_LINE_TABLE'));

       WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	   l_childItemKey,
                              	   'EXPENSE_REPORT_ID',
 				   WF_ENGINE.GetItemAttrNumber(p_item_type,
						   	       p_item_key,
						               'EXPENSE_REPORT_ID'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'DOCUMENT_NUMBER',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'DOCUMENT_NUMBER'));

       WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	   l_childItemKey,
                              	   'PREPARER_ID',
 				   WF_ENGINE.GetItemAttrNumber(p_item_type,
						   	       p_item_key,
						               'PREPARER_ID'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'PREPARER_NAME',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'PREPARER_NAME'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'PREPARER_DISPLAY_NAME',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'PREPARER_DISPLAY_NAME'));

       WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	   l_childItemKey,
                              	   'EMPLOYEE_ID',
 				   WF_ENGINE.GetItemAttrNumber(p_item_type,
						   	       p_item_key,
						               'EMPLOYEE_ID'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'EMPLOYEE_NAME',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'EMPLOYEE_NAME'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'EMPLOYEE_DISPLAY_NAME',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'EMPLOYEE_DISPLAY_NAME'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'PAYMENT_DUE_FROM',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'PAYMENT_DUE_FROM'));

       WF_ENGINE.SetItemAttrNumber(p_item_type,
                              	   l_childItemKey,
                              	   'TOTAL',
 				   WF_ENGINE.GetItemAttrNumber(p_item_type,
						   	       p_item_key,
						               'TOTAL'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'DISPLAY_TOTAL',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'DISPLAY_TOTAL'));

       WF_ENGINE.SetItemAttrDate(p_item_type,
                              	   l_childItemKey,
                              	   'WEEK_END_DATE',
 				   WF_ENGINE.GetItemAttrDate(p_item_type,
						   	       p_item_key,
						               'WEEK_END_DATE'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'EMPLOYEE_PROJECT_ENABLED',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'EMPLOYEE_PROJECT_ENABLED'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'CURRENCY',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'CURRENCY'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'DOC_COST_CENTER',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'DOC_COST_CENTER'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'EMP_COST_CENTER',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'EMP_COST_CENTER'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'HEADER_ATTACHMENTS',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'HEADER_ATTACHMENTS'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'SUBMIT_FROM_OIE',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'SUBMIT_FROM_OIE'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'EXPENSE_DETAILS',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'EXPENSE_DETAILS'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'EMP_VIOLATION_NOTE',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'EMP_VIOLATION_NOTE'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'VIOLATION_NOTE',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'VIOLATION_NOTE'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'MILEAGE_NOTE',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'MILEAGE_NOTE'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'VERIFY_NOTE',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'VERIFY_NOTE'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'AUDIT_RETURN_REASON',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'AUDIT_RETURN_REASON'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'AUDIT_INSTRUCTIONS',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'AUDIT_INSTRUCTIONS'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'CASH_LINE_ERRORS_AP',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'CASH_LINE_ERRORS_AP'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'CASH_LINE_ERRORS_PREPARER',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'CASH_LINE_ERRORS_PREPARER'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'CCARD_LINE_ERRORS_AP',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'CCARD_LINE_ERRORS_AP'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'CCARD_LINE_ERRORS_PREPARER',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'CCARD_LINE_ERRORS_PREPARER'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'GEN_HEADER_ERRORS',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'GEN_HEADER_ERRORS'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'IS_DEFAULT_COST_CENTER_USED',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'IS_DEFAULT_COST_CENTER_USED'));

       WF_ENGINE.SetItemAttrText(p_item_type,
                              	   l_childItemKey,
                              	   'IS_PROJECTS_REPORT',
 				   WF_ENGINE.GetItemAttrText(p_item_type,
						   	       p_item_key,
						               'IS_PROJECTS_REPORT'));




       ----------------------------------------------------------------
       l_debug_info := 'StartProcess ChildItemKey: ' || l_childItemKey;
       ----------------------------------------------------------------
       WF_ENGINE.StartProcess(p_item_type,
			      l_childItemKey);

     END LOOP;

     WF_ENGINE.SetItemAttrText(p_item_type,
 				p_item_key,
				'AME_CHILD_ITEM_KEY_SEQ',
				l_childItemKeySeq);

     p_result := 'COMPLETE:N';

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AMERequestApproval');

EXCEPTION
  WHEN fixable_exception THEN
      -- bug 3257576
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_PROBLEM',
				l_error_message);
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_INSTRUCTIONS',
				l_instructions);
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_SPECIAL_INSTR',
				l_special_instr);

      p_result := 'COMPLETE:NOAPPROVER';
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AMERequestApproval',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AMERequestApproval;

/*
  Bug 4425821: Uptake AME parallel approvers
  Called from AME Request Approval process.
  Checks and returns if Action/FYI notification to be sent to the approver.
*/
----------------------------------------------------------------------
PROCEDURE AMEGetApprovalType(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  l_debug_info			varchar2(200);
  l_ActionOrFyi                 varchar2(1);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AMEGetApprovalType');

  IF (p_funmode = 'RUN') THEN

    --------------------------------------------------------------
    l_debug_info := 'Retrieve AME approval category - Action/FYI';
    --------------------------------------------------------------
    l_ActionOrFyi := WF_ENGINE.GetItemAttrText(p_item_type,
					       p_item_key,
					       'AME_APPROVAL_TYPE');

    IF (nvl(l_ActionOrFyi,'A') = 'A') THEN
      p_result := 'COMPLETE:A';
    ELSE
      p_result := 'COMPLETE:F';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AMEGetApprovalType');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AMEGetApprovalType',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AMEGetApprovalType;

/*
  Bug 4425821: Uptake AME parallel approvers
  Called from AME Request Approval Process. 
  We get the approver response and update the attribute 'AME Approver Response'
  with approver response, which would be used in AME Approval Process'.
  Update AME of approver response.
*/
----------------------------------------------------------------------
PROCEDURE AMEPropagateApprovalResult(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  l_debug_info		  varchar2(200);
  l_AmeMasterItemKey      varchar2(30);
  l_approverResponse      varchar2(30);
  l_approver_id           number;
  l_response 	          varchar2(80);
  l_approvalStatusIn      varchar2(20);
  l_approver_name         varchar2(240);

  l_approverIn            ame_util.approverRecord2;

  l_debug varchar2(3000);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AMEPropagateApprovalResult');

  IF (p_funmode = 'RUN') THEN

    l_AmeMasterItemKey := WF_ENGINE.GetItemAttrText(p_item_type,
					       p_item_key,
					       'AME_MASTER_ITEM_KEY');

    l_approverResponse := WF_ENGINE.GetItemAttrText(p_item_type,
					       l_AmeMasterItemKey,
					       'AME_APPROVER_RESPONSE');

    l_response := WF_ENGINE.GetActivityAttrText(p_item_type,
                                                p_item_key,
                                                p_actid,
                                                'RESPONSE');
    --------------------------------------------------------------
    l_debug_info := 'l_response : '|| l_response || 
                    'l_approverResponse : '|| l_approverResponse || 
                    'l_AmeMasterItemKey : '|| l_AmeMasterItemKey;
    ---------------------------------------------------------------
 
    IF ((l_approverResponse IS NULL) OR (l_approverResponse <> 'REJECTED'))
       AND (l_response IS NOT NULL) THEN
       WF_ENGINE.SetItemAttrText(p_item_type,
 				    l_AmeMasterItemKey,
				    'AME_APPROVER_RESPONSE',
				    l_response);
       IF (l_response = 'REJECTED') THEN
          WF_ENGINE.SetItemAttrText(p_item_type,
 				    l_AmeMasterItemKey,
				    'AME_REJECTED_CHILD_ITEM_KEY',
				    p_item_key);
       END IF;
       --bug 6686996
       IF (l_response = 'APPROVED') THEN
          begin
            WF_ENGINE.SetItemAttrText(p_item_type,
 				    l_AmeMasterItemKey,
				    'AME_APPROVED_CHILD_ITEM_KEY',
				    p_item_key);
          exception
	    when others then
	      if (wf_core.error_name = 'WFENG_ITEM_ATTR') then
	        -- AME_APPROVED_CHILD_ITEM_KEY item attribute doesn't exist, need to add it
	        WF_ENGINE.AddItemAttr(p_item_type, l_AmeMasterItemKey, 'AME_APPROVED_CHILD_ITEM_KEY');

    	        WF_ENGINE.SetItemAttrText(p_item_type,
                              	l_AmeMasterItemKey,
                              	'AME_APPROVED_CHILD_ITEM_KEY',
                              	p_item_key);
	      else
	        raise;
	      end if;
           end;
       END IF;
       --Bug 6411930: copy approver display name and note from rejected 
       --child to parent, they are used to display the information in the 
       --rejection notif to the preparer
       WF_ENGINE.SetItemAttrText(p_item_type,
                                 l_AmeMasterItemKey,
                              	 'APPROVER_ID',
 				 WF_ENGINE.GetItemAttrText(p_item_type,
				 	   	           p_item_key,
						           'APPROVER_ID'));
       WF_ENGINE.SetItemAttrText(p_item_type,
                                 l_AmeMasterItemKey,
                              	 'APPROVER_NAME',
 				 WF_ENGINE.GetItemAttrText(p_item_type,
				 	   	           p_item_key,
						           'APPROVER_NAME'));
       WF_ENGINE.SetItemAttrText(p_item_type,
                                 l_AmeMasterItemKey,
                              	 'APPROVER_DISPLAY_NAME',
 				 WF_ENGINE.GetItemAttrText(p_item_type,
				 	   	           p_item_key,
						           'APPROVER_DISPLAY_NAME'));
       WF_ENGINE.SetItemAttrText(p_item_type,
                                 l_AmeMasterItemKey,
                              	 'WF_NOTE',
 				 WF_ENGINE.GetItemAttrText(p_item_type,
				 	   	           p_item_key,
						           'WF_NOTE'));

    END IF;

    ------------------------------------------------------
    l_debug_info := 'Retrieve Approver_ID Item Attribute';
    -------------------------------------------------------
    l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						 l_AmeMasterItemKey,
						 'APPROVER_ID');

    ------------------------------------------------------
    l_debug_info := 'Retrieve Approver_ID Item Attribute';
    -------------------------------------------------------
    l_approver_name := WF_ENGINE.GetItemAttrText(p_item_type,
						 p_item_key,
						 'APPROVER_NAME');

    IF (l_response = 'APPROVED') THEN
      l_approvalStatusIn := AME_UTIL.approvedStatus;
    ELSIF (l_response = 'REJECTED') THEN
      l_approvalStatusIn := AME_UTIL.rejectStatus;
    ELSIF (l_response = 'NO_RESPONSE') THEN
      l_approvalStatusIn := AME_UTIL.noResponseStatus;
    ELSIF (l_response = 'FYI') THEN
      l_approvalStatusIn := AME_UTIL.notifiedStatus;
    END IF;
   
    ------------------------------------------------------------------------------------------ 
    l_debug_info := 'l_response:'|| l_response || 'l_approvalStatusIn:' || l_approvalStatusIn;
    ------------------------------------------------------------------------------------------ 
    IF (l_response <> 'FYI') THEN

    ------------------------------------------------------
    l_debug_info := 'Call AME_API2.updateApprovalStatus ';
    ------------------------------------------------------  	
    l_approverIn.name := l_approver_name;
    --l_approverIn.orig_system := 'PER';
    --l_approverIn.orig_system_id := l_approver_id;
    l_approverIn.approval_status := l_approvalStatusIn;
    
    -- Bug 8278999 (sodash) status is updated in postnotif function IsApprovalRequestTransferred
    /* AME_API2.updateApprovalStatus(applicationIdIn    => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                              	    transactionTypeIn  => p_item_type,   
                               	    transactionIdIn    => l_AmeMasterItemKey,  
                                    approverIn => l_approverIn); 
    
    AME_API2.updateApprovalStatus2(applicationIdIn    => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                               	    transactionIdIn    => l_AmeMasterItemKey,
                                    approvalStatusIn   => l_approvalStatusIn,
                                    approverNameIn     => l_approver_name, 
                              	    transactionTypeIn  => 'APEXP'); 
    */
    END IF;

    ------------------------------------------------------
    l_debug_info := 'End AMEPropagateApprovalResult ' || l_AmeMasterItemKey ;
    ------------------------------------------------------  	

    p_result := 'Y';

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AMEPropagateApprovalResult');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AMEPropagateApprovalResult',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AMEPropagateApprovalResult;

/*
   Bug 4425821: Uptake AME parallel approvers
   Called from AME Approval Process. 
   Checks for Approver Response which is tracked in attribute 'AME Approver Response'
   Result : Approve/Reject
*/
----------------------------------------------------------------------
PROCEDURE AMEGetApprovalResult(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  l_debug_info			varchar2(200);
  l_approverResponse            varchar2(30);
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AMEGetApprovalResult');

  IF (p_funmode = 'RUN') THEN

    --------------------------------------------------------------
    l_debug_info := 'Check Approver Response - APPROVED/REJECTED';
    --------------------------------------------------------------
    l_approverResponse := WF_ENGINE.GetItemAttrText(p_item_type,
					       p_item_key,
					       'AME_APPROVER_RESPONSE');

    IF (l_approverResponse = 'APPROVED') THEN
      p_result := 'COMPLETE:APPROVED';
    ELSIF (l_approverResponse = 'REJECTED') THEN
      p_result := 'COMPLETE:REJECTED';
    ELSIF (l_approverResponse = 'FYI') THEN
      p_result := 'COMPLETE:FYI';
    ELSIF (l_approverResponse = 'NO_RESPONSE') THEN
      p_result := 'COMPLETE:NO_RESPONSE';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AMEGetApprovalResult');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AMEGetApprovalResult',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AMEGetApprovalResult;

/*
   Bug 4425821: Uptake AME parallel approvers
   Called from AME Request Approval Process.
   Completes Block Activity in 'AME Approval Process'.
*/
----------------------------------------------------------------------
PROCEDURE AMECompleteApproval(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  l_debug_info			varchar2(200);
  l_AmeMasterItemKey            varchar2(30);
  l_err_name      		varchar2(30);
  l_err_msg       		varchar2(2000);
  l_err_stack     		varchar2(32000);
  l_check_error   		varchar2(1);
  l_result        		varchar2(1);

  l_approvalProcessCompleteYNOut  varchar2(1);
  l_nextApproversOut              ame_util.approversTable2;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AMECompleteApproval');

  IF (p_funmode = 'RUN') THEN

    l_AmeMasterItemKey := WF_ENGINE.GetItemAttrText(p_item_type,
					       p_item_key,
					       'AME_MASTER_ITEM_KEY');

    ------------------------------------------------------
    l_debug_info := 'Call CompleteActivity ' || l_AmeMasterItemKey ;
    ------------------------------------------------------  	
    begin
      WF_ENGINE.CompleteActivity(itemtype => p_item_type,
 			       itemkey => l_AmeMasterItemKey,
                               activity => 'AME_APPROVAL_BLOCK',
                               result => null);
      l_result := 'Y';
    exception
      WHEN others THEN 
       
        l_check_error := WF_ENGINE.GetActivityAttrText(p_item_type,
                                                       p_item_key,
                                                       p_actid,
                                                       'CHECK_ERROR');
        if l_check_error = 'Y' then
           wf_core.get_error(l_err_name, l_err_msg, l_err_stack);
           if (l_err_name = 'WFENG_NOT_NOTIFIED') then
              l_result := 'N';
           else
              raise;
           end if;
        else
           -- if approval is complete, complete as 'Y' to avoid error notification
           -- from being sent to sysadmin
           AME_API2.getNextApprovers4(applicationIdIn   => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                              transactionTypeIn => p_item_type,
	                      transactionIdIn   => l_AmeMasterItemKey,
                              approvalProcessCompleteYNOut => l_approvalProcessCompleteYNOut,
			      nextApproversOut   => l_nextApproversOut);

           if (l_approvalProcessCompleteYNOut = ame_util.booleanTrue) then
              l_result := 'Y';
           else
             raise;
           end if; -- end if l_approvalProcessCompleteYNOut
        end if; -- end if l_check_error = 'Y'

    end;


    ------------------------------------------------------
    l_debug_info := 'End CompleteActivity ' || l_AmeMasterItemKey ;
    ------------------------------------------------------ 
    if (nvl(l_result,'N') = 'N') then
       p_result := 'COMPLETE:N';
    else
       p_result := 'COMPLETE:Y';
    end if;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AMECompleteApproval');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AMECompleteApproval',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AMECompleteApproval;

/*
   Bug 4425821: Uptake AME parallel approvers
   Called from AME Approval Process.
   Gets the current pending approvers, if the pending approvers is > 1 then 
   set expense_current_approver_id to -99999, if there is only one pending
   approver then set expense_current_approver_id to the approver id.
   We need to set it to -99999 inorder to distinguish if there is a single or
   multiple current approvers, when displaying current approver in Track Submitted
   Expense Reports table in Home Page.
*/
----------------------------------------------------------------------
PROCEDURE AMESetCurrentApprover(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_debug_info			  varchar2(200);
  l_approvalProcessCompleteYNOut  varchar2(10);
  l_approversOut                  ame_util.approversTable2;
  l_report_header_id              number;
BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start AMESetCurrentApprover');

  IF (p_funmode = 'RUN') THEN

    l_report_header_id := to_char(p_item_key);
    -------------------------------------------------------
    l_debug_info := 'Calling ame_api2.getpendingapprovers';
    -------------------------------------------------------
    ame_api2.getpendingapprovers(applicationidin => AP_WEB_DB_UTIL_PKG.GetApplicationID,
				transactiontypein => p_item_type,
				transactionidin => p_item_key,
				approvalprocesscompleteynout => l_approvalProcessCompleteYNOut,
				approversout => l_approversOut);

    if (l_approversOut.count > 1) then
       UPDATE ap_expense_report_headers_all
       SET expense_current_approver_id = C_AME_MULTIPLE_CURR_APPROVER
       WHERE report_header_id = l_report_header_id;
    elsif (l_approversOut.count = 1) then
       UPDATE ap_expense_report_headers_all
       SET expense_current_approver_id = l_approversOut(1).orig_system_id
       WHERE report_header_id = l_report_header_id;
    end if;

    p_result := 'COMPLETE';

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end AMESetCurrentApprover');

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'AMESetCurrentApprover',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END AMESetCurrentApprover;

---------------------------------------------------------------------------
FUNCTION IsExpAccountsUpdated(p_report_line_id	IN NUMBER) 
RETURN VARCHAR2 IS
-----------------------------------------------------------------------
  l_ExpAccountsUpdated	        VARCHAR2(10);
BEGIN
 
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start IsExpAccountsUpdated');

  select  decode(nvl(preparer_modified_flag, 'N'), 'Y', AP_WEB_FND_LOOKUPS_PKG.getYesNoMeaning('Y'), null)
  into    l_ExpAccountsUpdated
  from    ap_exp_report_dists
  where   report_line_id = p_report_line_id
  and     rownum = 1;


  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end IsExpAccountsUpdated');

  RETURN l_ExpAccountsUpdated;

EXCEPTION
  WHEN OTHERS THEN
    RETURN l_ExpAccountsUpdated;
END IsExpAccountsUpdated;

FUNCTION getItemKey(p_notification_id	IN NUMBER) RETURN VARCHAR2 IS
 l_context         wf_notifications.context%type;
 l_temp_context    wf_notifications.context%type;
 l_item_key        wf_notifications.context%type;
 l_debug_info      varchar2(200);
BEGIN
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'start getItemKey');

  select context into l_context 
  from wf_notifications 
  where notification_id = p_notification_id;

  --l_context would have something like 'APEXP:22591-2:579934'

  l_temp_context := substr(l_context,instrb(l_context, ':')+1); --'22591-2:579934'
  l_item_key := substr(l_temp_context,1,instrb(l_temp_context, ':')-1); --'22591-2'

  return l_item_key;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_EXPENSE_WF', 'end getItemKey');
EXCEPTION
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('AP_WEB_EXPENSE_WF.getItemKey',
				    l_debug_info);
    APP_EXCEPTION.RAISE_EXCEPTION;
END getItemKey;

----------------------------------------------------------------------
PROCEDURE IsPreparerActive(p_item_type      IN VARCHAR2,
                       p_item_key       IN VARCHAR2,
                       p_actid          IN NUMBER,
                       p_funmode        IN VARCHAR2,
                       p_result  OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_person_id           NUMBER          := NULL;

  l_debug_info                  VARCHAR2(200);

BEGIN
  
  IF (p_funmode = 'RUN') THEN

    ---------------------------------------------------------------
    l_debug_info := 'Retrieve Employee Id Item Attribute';
    ---------------------------------------------------------------
    l_person_id := WF_ENGINE.GetItemAttrText(p_item_type,
                                             p_item_key,
                                             'PREPARER_ID');
  
    -- Check whether person is active
    IF (AP_WEB_DB_HR_INT_PKG.isPersonActive(l_person_id)='Y') THEN
      p_result := 'COMPLETE:Y';
    ELSE
      p_result := 'COMPLETE:N';
    END IF;
  
  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'IsPreparerActive',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END IsPreparerActive;

END AP_WEB_EXPENSE_WF;

/

/*
l
/

SELECT LINE, SEQUENCE, NAME, TYPE, TEXT FROM user_errors
WHERE  name = 'AP_WEB_EXPENSE_WF'
AND    type = 'PACKAGE BODY'
/
*/

COMMIT;
EXIT;

