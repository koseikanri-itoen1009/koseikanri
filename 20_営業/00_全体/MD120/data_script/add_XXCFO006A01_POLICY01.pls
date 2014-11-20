BEGIN
DBMS_RLS.ADD_POLICY (
  object_schema => 'APPS',
  object_name => 'AP_INVOICES_ALL',
  policy_name => 'XXCFO006A01_POLICY01',
  function_schema => 'APPS',
  policy_function => 'XXCFO006A01P1.GET_POLICY_CONDITION',
  statement_types => 'SELECT'
) ;
END ;
/
