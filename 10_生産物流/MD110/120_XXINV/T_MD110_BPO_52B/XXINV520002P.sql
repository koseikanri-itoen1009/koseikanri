/*******************************************************************************
 *
 * Copyright(c) Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Program Name           : xxinv520002p
 * Description            : Policy of Fine-Grain-Access-Control
 *                          for GMD_RECIPES_B
 * Version                : 1.0
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/06/04   1.0   Oracle—é–Ø—Y‘å   Create
 *
 *******************************************************************************/
--
BEGIN
  --CreatePolicy
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'APPS'
   ,object_name     => 'GMD_RECIPES_B'
   ,policy_name     => 'XXINV520002P'
   ,function_schema => 'APPS'
   ,policy_function => 'XXINV520002C.GMD_RECIPES_B_SEL'
   ,statement_types => 'SELECT'
   );
END;
/
