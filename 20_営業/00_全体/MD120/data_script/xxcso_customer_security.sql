BEGIN
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_PARTIES'
   ,p_policy_name       => 'XXCSO_PARTY_UPD_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_party_upd_prdct'
   ,p_statement_types   => 'UPDATE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_ORG_PROFILES_EXT_B'
   ,p_policy_name       => 'XXCSO_ORG_PRO_EXT_INS_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_org_pro_ext_ins_prdct'
   ,p_statement_types   => 'INSERT'
   ,p_update_check      => TRUE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_ORG_PROFILES_EXT_B'
   ,p_policy_name       => 'XXCSO_ORG_PRO_EXT_UPD_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_org_pro_ext_upd_prdct'
   ,p_statement_types   => 'UPDATE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_ORG_PROFILES_EXT_B'
   ,p_policy_name       => 'XXCSO_ORG_PRO_EXT_DEL_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_org_pro_ext_del_prdct'
   ,p_statement_types   => 'DELETE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_LOCATIONS'
   ,p_policy_name       => 'XXCSO_LOCATION_UPD_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_location_upd_prdct'
   ,p_statement_types   => 'UPDATE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_CUST_ACCOUNTS'
   ,p_policy_name       => 'XXCSO_ACCOUNT_INS_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_account_ins_prdct'
   ,p_statement_types   => 'INSERT'
   ,p_update_check      => TRUE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_CUST_ACCOUNTS'
   ,p_policy_name       => 'XXCSO_ACCOUNT_UPD_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_account_upd_prdct'
   ,p_statement_types   => 'UPDATE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_CUST_ACCT_SITES_ALL'
   ,p_policy_name       => 'XXCSO_ACCT_SITE_INS_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_acct_site_ins_prdct'
   ,p_statement_types   => 'INSERT'
   ,p_update_check      => TRUE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_CUST_SITE_USES_ALL'
   ,p_policy_name       => 'XXCSO_SITE_USES_INS_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_site_use_ins_prdct'
   ,p_statement_types   => 'INSERT'
   ,p_update_check      => TRUE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_CUST_SITE_USES_ALL'
   ,p_policy_name       => 'XXCSO_SITE_USES_UPD_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_site_use_upd_prdct'
   ,p_statement_types   => 'UPDATE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'HZ_CUST_SITE_USES_ALL'
   ,p_policy_name       => 'XXCSO_SITE_USES_DEL_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_site_use_del_prdct'
   ,p_statement_types   => 'DELETE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'AS_LEADS_ALL'
   ,p_policy_name       => 'XXCSO_LEAD_UPD_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_lead_upd_prdct'
   ,p_statement_types   => 'UPDATE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'JTF_TASKS_B'
   ,p_policy_name       => 'XXCSO_TASK_INS_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_task_ins_prdct'
   ,p_statement_types   => 'INSERT'
   ,p_update_check      => TRUE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'JTF_TASKS_B'
   ,p_policy_name       => 'XXCSO_TASK_UPD_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_task_upd_prdct'
   ,p_statement_types   => 'UPDATE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
  fnd_access_control_util.add_policy(
    p_object_schema     => 'APPS'
   ,p_object_name       => 'JTF_TASKS_B'
   ,p_policy_name       => 'XXCSO_TASK_DEL_PLC'
   ,p_function_schema   => 'APPS'
   ,p_policy_function   => 'xxcso_009002j_pkg.get_task_del_prdct'
   ,p_statement_types   => 'DELETE'
   ,p_update_check      => FALSE
   ,p_enable            => TRUE
  );
END;
/
