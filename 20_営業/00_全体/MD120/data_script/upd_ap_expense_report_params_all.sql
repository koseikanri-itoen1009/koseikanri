set linesize 1000
set pagesize 100

-- ***********************************
-- ap_expense_report_params_all
-- ***********************************
PROMPT ##### ap_expense_report_params_all PRE UPDATE Info #####>>>
SELECT parameter_id
      ,org_id
      ,count(1)
FROM   ap_expense_report_params_all
WHERE  parameter_id = '10000'
GROUP BY parameter_id
        ,org_id;

PROMPT ##### ap_expense_report_params_all UPDATE #####>>>
update ap_expense_report_params_all
set org_id = NULL
where parameter_id = '10000';

PROMPT ##### ap_expense_report_params_all POST UPDATE Info #####>>>
SELECT parameter_id
      ,org_id
      ,count(1)
FROM   ap_expense_report_params_all
WHERE  parameter_id = '10000'
GROUP BY parameter_id
        ,org_id;

-- ***********************************
-- ap_expense_reports_all
-- ***********************************
PROMPT ##### ap_expense_reports_all PRE UPDATE Info #####>>>
SELECT expense_report_id
      ,org_id
      ,count(1)
FROM   ap_expense_reports_all
WHERE  expense_report_id = '10000'
GROUP BY expense_report_id
        ,org_id;

PROMPT ##### ap_expense_reports_all UPDATE #####>>>
update ap_expense_reports_all
set org_id = NULL
where expense_report_id = '10000';

PROMPT ##### ap_expense_reports_all POST UPDATE Info #####>>>
SELECT expense_report_id
      ,org_id
      ,count(1)
FROM   ap_expense_reports_all
WHERE  expense_report_id = '10000'
GROUP BY expense_report_id
        ,org_id;
