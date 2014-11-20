REM dbdrv: sql ~PROD ~PATH ~FILE none none none sqlplus &phase=en+10 \
REM dbdrv: checkfile:nocheck
REM *hb************************************************************************
REM  SCRIPT NAME
REM    ofitemtg.sql
REM
REM  INPUT PARAMETERS
REM    None
REM  RETURNS
REM    None
REM
REM  DESCRIPTION
REM    This SQL script will drop the existing trigger and create a new
REM    Database Trigger ic_item_biur_tg on table  IC_ITEM_MST.
REM    This script is started from ofsynym.sql
REM
REM  USAGE
REM
REM  AUTHOR
REM    Sanjay Rastogi - 06/05/96
REM    Yuta Suzuki    - 10/09/08 modify
REM    Yuta Suzuki    - 11/11/08 bug fix
REM    Yuta Suzuki    - 01/13/09 bug fix(#959)
REM
REM *hf************************************************************************

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;
CREATE OR REPLACE TRIGGER GMF_IC_ITEM_MST_BIUR_TG
/*       $Header: gmfitmtg.sql 115.75.115100.12 2006/10/04 18:44:45 acataldo ship $ */
AFTER INSERT OR UPDATE
ON  IC_ITEM_MST_B
FOR EACH ROW
WHEN (
       (NVL(old.lot_suffix,-99) = NVL(new.lot_suffix,-99))
  OR   (NVL(old.lot_suffix,-99) <> NVL(new.lot_suffix, -99)
    AND NVL(old.last_update_date,SYSDATE-1) <> new.last_update_date)
     )
DECLARE

  /*  VARIABLES  */
  v_item_no                     ic_item_mst.item_no%TYPE;
  v_item_desc1                  ic_item_mst.item_desc1%TYPE;
  v_cost_of_sales_account       mtl_parameters.cost_of_sales_account%TYPE;
  v_sales_Account               mtl_parameters.sales_account%TYPE;
  v_expense_Account             mtl_parameters.expense_account%TYPE;
  v_encumbrance_account         mtl_parameters.encumbrance_account%TYPE;
  v_new_inventory_item_id       mtl_system_items.inventory_item_id%TYPE;
  v_dummy_item_id               mtl_system_items.inventory_item_id%TYPE;
  v_revision_item_id            mtl_system_items.inventory_item_id%TYPE;
  v_category_item_id            mtl_system_items.inventory_item_id%TYPE;
  v_inv_item_status_code        mtl_system_items.inventory_item_status_code%TYPE;
  v_primary_unit_of_measure     mtl_system_items.primary_unit_of_measure%TYPE;
  v_bom_enabled_flag            mtl_system_items.bom_enabled_flag%TYPE DEFAULT 'N';
  v_purchasing_enabled_flag     mtl_system_items.purchasing_enabled_flag%TYPE DEFAULT 'Y';
  v_mtl_xactions_enabled_flag   mtl_system_items.mtl_transactions_enabled_flag%TYPE DEFAULT 'Y';
  v_stock_enabled_flag          mtl_system_items.stock_enabled_flag%TYPE DEFAULT 'Y';
  v_build_in_wip_flag           mtl_system_items.build_in_wip_flag%TYPE DEFAULT 'N';
  v_customer_order_enabled_flag mtl_system_items.customer_order_enabled_flag%TYPE DEFAULT 'Y';
  v_internal_order_enabled_flag mtl_system_items.internal_order_enabled_flag%TYPE DEFAULT 'Y';
  v_invoice_enabled_flag        mtl_system_items.invoice_enabled_flag%TYPE DEFAULT 'Y';
  v_allow_item_desc_update_flag mtl_system_items.allow_item_desc_update_flag%TYPE := 'Y';
  v_prev_allow_update_flag      mtl_system_items.allow_item_desc_update_flag%TYPE := 'Y';
  v_inventory_item_flag         mtl_system_items.inventory_item_flag%TYPE DEFAULT 'Y';
  v_primary_uom_code            mtl_units_of_measure.uom_code%TYPE;
  v_secondary_uom_code          mtl_units_of_measure.uom_code%TYPE;
  v_prev_org_id                 gl_plcy_mst.org_id%TYPE := -999;
  v_user_id                     fnd_user.user_id%TYPE;
  v_dual_uom_deviation_high     NUMBER;
  v_dual_uom_deviation_low      NUMBER;
  v_lot_control_code            NUMBER;
  v_location_control_code       NUMBER;
  v_mtl_event                   VARCHAR2(20);
  is_inactive_ind_updated       VARCHAR2(1) := 'N';
  v_category_id                 pls_integer;
  i_item_desc1                  pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DESCRIPTION');
  i_cost_of_sales_account       pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.COST_OF_SALES_ACCOUNT');
  i_sales_Account               pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.SALES_ACCOUNT');
  i_expense_Account             pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.EXPENSE_ACCOUNT');
  i_encumbrance_account         pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.ENCUMBRANCE_ACCOUNT');
  i_primary_uom_code            pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.PRIMARY_UOM_CODE');
  i_primary_unit_of_measure     pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.PRIMARY_UOM_CODE');
  i_allow_item_desc_update_flag pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.ALLOW_ITEM_DESC_UPDATE_FLAG');
  i_lot_control_code            pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.LOT_CONTROL_CODE');
  i_location_control_code       pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.LOCATION_CONTROL_CODE');
  i_costing_enabled_flag        pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.COSTING_ENABLED_FLAG');
  i_inventory_asset_flag        pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INVENTORY_ASSET_FLAG');
  i_auto_lot_alpha_prefix       pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.AUTO_LOT_ALPHA_PREFIX');
  i_start_auto_lot_number       pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.START_AUTO_LOT_NUMBER');
  i_ato_forecast_control        pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.ATO_FORECAST_CONTROL');
  i_bom_enabled_flag            pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.BOM_ENABLED_FLAG');
  i_inventory_item_flag         pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INVENTORY_ITEM_FLAG');
  i_purchasing_item_flag        pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.PURCHASING_ITEM_FLAG');
  i_purchasing_enabled_flag     pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.PURCHASING_ENABLED_FLAG');
  i_mtl_xactions_enabled_flag   pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.MTL_TRANSACTIONS_ENABLED_FLAG');
  i_stock_enabled_flag          pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.STOCK_ENABLED_FLAG');
  i_build_in_wip_flag           pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.BUILD_IN_WIP_FLAG');
  i_customer_order_enabled_flag pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.CUSTOMER_ORDER_ENABLED_FLAG');
  i_customer_order_flag         pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.CUSTOMER_ORDER_FLAG');
  i_internal_order_enabled_flag pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INTERNAL_ORDER_ENABLED_FLAG');
  i_internal_order_flag         pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INTERNAL_ORDER_FLAG');
  i_invoice_enabled_flag        pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INVOICE_ENABLED_FLAG');
  i_secondary_uom_code          pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.SECONDARY_UOM_CODE');
  i_dual_uom_deviation_high     pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DUAL_UOM_DEVIATION_HIGH');
  i_dual_uom_deviation_low      pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DUAL_UOM_DEVIATION_LOW');
  i_dual_uom_control            pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DUAL_UOM_CONTROL');
  i_tracking_quantity_ind       pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.TRACKING_QUANTITY_IND');
  i_secondary_default_ind       pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.SECONDARY_DEFAULT_IND');
  i_ont_pricing_qty_source      pls_integer
    DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.ONT_PRICING_QTY_SOURCE');
  v_of_gemms_user_id            mtl_system_items.created_by%TYPE DEFAULT :new.created_by;
  v_error_status                NUMBER;
  v_error_text                  VARCHAR2(200);
  status_def_tmp                VARCHAR2(30);
  rtn_status                    NUMBER;
  v_date                        DATE;
  err_text                      VARCHAR2(100);
  l_count                       pls_integer;
  v_msg_id                      fnd_new_messages.message_number%TYPE := -20000;
  v_msg_text                    fnd_new_messages.message_text%TYPE;
  v_msg_code                    fnd_new_messages.message_name%TYPE;
  v_op_code                     fnd_new_messages.last_updated_by%TYPE := :new.last_updated_by;
  /* FLAGS */
  flg_item_to_be_inserted       VARCHAR2(1);
  flg_item_to_be_updated        VARCHAR2(1);
  flg_rev_item_to_be_updated    VARCHAR2(1);
  flg_rev_item_to_be_inserted   VARCHAR2(1);
  flg_item_user_orgs_only       VARCHAR2(1);
  /* EXCEPTIONS */
  ex_no_primary_uom_code_avlbl  EXCEPTION;
  ex_no_account_codes_avlbl     EXCEPTION;
  ex_unable_to_update_item      EXCEPTION;
  ex_unable_to_insert_item      EXCEPTION;
  ex_unable_to_insert_rev_item  EXCEPTION;
  ex_no_profile_option_value    EXCEPTION;
  ex_error_profile_option_value EXCEPTION;
  /* CURSORS */
  CURSOR c_item_cur(v_item_no IN VARCHAR2, v_organization_id IN NUMBER) IS
    SELECT inventory_item_id
    FROM   mtl_system_items_b
    WHERE  organization_id = v_organization_id
    AND    segment1 = v_item_no;
--
  CURSOR c_inventory_org IS
    SELECT i.organization_id
          ,o.operating_unit org_id
          ,'P' org_type
          ,p.master_organization_id master_org_id
    FROM   mtl_parameters p
          ,gmi_item_organizations i
          ,org_organization_definitions o
          ,ic_whse_mst w
    WHERE  i.organization_id = o.organization_id
    AND    i.organization_id = p.organization_id
    AND    p.organization_id <> p.master_organization_id
    AND    i.organization_id = w.mtl_organization_id(+)
    AND    (flg_item_user_orgs_only  = 'N'
      OR   EXISTS (SELECT 1
                   FROM   sy_orgn_usr usr
                   WHERE  usr.user_id = v_user_id
                   AND    usr.orgn_code = w.orgn_code))
    UNION
    SELECT i.organization_id
          ,o.operating_unit org_id
          ,'P' org_type
          ,p.master_organization_id master_org_id
    FROM   mtl_parameters p
          ,gmi_item_organizations i
          ,org_organization_definitions o
    WHERE  i.organization_id = p.organization_id
    AND    p.organization_id <> p.master_organization_id
    AND    o.organization_id = i.organization_id
    AND    UPPER(p.process_enabled_flag) <> 'Y'
    UNION
    SELECT p.master_organization_id
          ,o.operating_unit org_id
          ,'M'
          ,p.master_organization_id master_org_id
    FROM   mtl_parameters p
          ,gmi_item_organizations g
          ,org_organization_definitions o
    WHERE  p.organization_id        = g.organization_id
    AND    p.master_organization_id = o.organization_id
    AND    upper(p.process_enabled_flag) <> 'Y'
    UNION
    SELECT p.master_organization_id
          ,o.operating_unit org_id
          ,'M' org_type
          ,p.master_organization_id master_org_id
    FROM   mtl_parameters p
          ,gmi_item_organizations g
          ,org_organization_definitions o
          ,ic_whse_mst w
    WHERE  p.organization_id        = g.organization_id
    AND    p.master_organization_id = o.organization_id
    AND    g.organization_id = w.mtl_organization_id(+)
    AND    (flg_item_user_orgs_only  = 'N'
      OR   EXISTS (SELECT 1
                   FROM   sy_orgn_usr usr
                   WHERE  usr.user_id = v_user_id
                   AND    usr.orgn_code = w.orgn_code))
    ORDER BY 3 ASC;
--
  CURSOR c_item_status (v_item_status IN mtl_system_items.inventory_item_status_code%TYPE) IS
    SELECT v.attribute_name
          ,DECODE(a.status_control_code
                 ,1,v.attribute_value
                 ,2,v.attribute_value
                 ,DECODE(v.attribute_name
                        ,'MTL_SYSTEM_ITEMS.BOM_ENABLED_FLAG','N'
                        ,'MTL_SYSTEM_ITEMS.BUILD_IN_WIP_FLAG','N'
                        ,'Y')) attribute_value
    FROM   mtl_status_attribute_values v
          ,mtl_item_attributes a
    WHERE  v.attribute_name = a.attribute_name
    AND    v.inventory_item_status_code = v_item_status;
--
  CURSOR c_allow_item_desc_cur1(v_org_id IN number) IS
    SELECT NVL(allow_item_desc_update_flag, 'Y')
    FROM   po_system_parameters_all
    WHERE  org_id = v_org_id
    AND    ROWNUM = 1;
--
  CURSOR c_allow_item_desc_cur2 IS
    SELECT nvl(ALLOW_ITEM_DESC_UPDATE_FLAG, 'Y')
    FROM   po_system_parameters_all
    WHERE  org_id is null
    AND    ROWNUM = 1;
--
  CURSOR c_update_orgs (pmaster_org NUMBER,pinventory_item_id NUMBER) IS
    SELECT mp.organization_id
          ,decode(mp.organization_id, pmaster_org, 0, 1) type
    FROM   mtl_parameters mp
    WHERE  mp.master_organization_id = pmaster_org
    AND    (mp.master_organization_id = mp.organization_id
      OR   NOT EXISTS (SELECT 1
                       FROM   gmi_item_organizations gio
                       WHERE  gio.organization_id = mp.organization_id))
    AND    EXISTS (SELECT 1
                   FROM   mtl_system_items_b
                   WHERE  inventory_item_id = pinventory_item_id
                   AND    organization_id   = mp.organization_id)
    UNION
    SELECT pmaster_org
          ,0
    FROM   dual;
--
  r_item_rec c_item_cur%ROWTYPE;
--
/*
Cursor Cur_missing_def_cat_in_opm (V_opm_item_id NUMBER, V_odm_item_id NUMBER) IS
  SELECT distinct mic.category_set_id category_set_id
  FROM   mtl_item_categories mic, mtl_default_category_sets mdcs
  WHERE  mic.inventory_item_id  = V_odm_item_id
  AND    mdcs.category_set_id   = mic.category_set_id
  AND    EXISTS     (select 1
                                 from   mtl_parameters mp, gmi_item_organizations gio
                                 where  mp.organization_id = gio.organization_id
                                 and    (    (mp.organization_id  = mic.organization_id)
                                          OR (mp.master_organization_id = mic.organization_id)
                                        )
                                )
  AND    NOT EXISTS             (select 1
                                 from   gmi_item_categories
                                 where  item_id   = V_opm_item_id
                                 and    category_set_id = mic.category_set_id
                                );
*/
--yutsuzuk modify
  CURSOR cur_missing_def_cat_in_opm (V_opm_item_id NUMBER, V_odm_item_id NUMBER) IS
    SELECT /*+ use_nl( mic mdcs ) */
           DISTINCT mic.category_set_id category_set_id
    FROM   mtl_item_categories mic
          ,mtl_default_category_sets mdcs
    WHERE  mic.inventory_item_id  = V_odm_item_id
    AND    mdcs.category_set_id   = mic.category_set_id
    AND    (EXISTS (SELECT /*+ INDEX(mp mtl_parameters_u1) */
                           1
                    FROM   mtl_parameters mp
                         , gmi_item_organizations gio
                    WHERE  mp.organization_id = gio.organization_id
                    AND    mp.organization_id = mic.organization_id
                    AND    ROWNUM = 1)
           OR
            EXISTS (SELECT /*+ INDEX(mp mtl_parameters_N1) */
                           1
                    FROM   mtl_parameters mp
                         , gmi_item_organizations gio
                    WHERE  mp.organization_id = gio.organization_id
                    AND    mp.master_organization_id = mic.organization_id
                    AND    ROWNUM = 1)
           )
    AND    NOT EXISTS (SELECT 1
                       FROM   gmi_item_categories
                       where  item_id = V_opm_item_id
                       and    category_set_id = mic.category_set_id
                       AND    ROWNUM = 1);
--yutsuzuk modify
--
--yutsuzuk add
  lb_ret             BOOLEAN;
  ln_req_id          NUMBER;
--
BEGIN
--yutsuzuk modify
--20081111 modify
--  IF (NVL(:old.program_update_date,SYSDATE-1) = NVL(:new.program_update_date,SYSDATE-1)) THEN
  IF ((INSERTING)
      AND (:new.program_update_date IS NULL)
      AND (:new.program_application_id IS NULL)
--20090113 modify
--      AND (:new.program_id IS NULL)
--      AND (:new.request_id IS NULL))
      AND (:new.program_id IS NULL))
--20090113 modify
  OR ((UPDATING)
      AND (NVL(:old.program_update_date,SYSDATE-1) = NVL(:new.program_update_date,SYSDATE-1)))
  THEN
--20081111 modify
--
    GMI_DEBUG_UTIL.Println('Insert/Update from Forms');
--
    IF  (UPDATING)
    AND (:old.last_update_date  = :new.last_update_date)
    AND (:old.last_updated_by   = :new.last_updated_by)
    AND (:old.last_update_login = :new.last_update_login)
    THEN
--
      GMI_DEBUG_UTIL.Println('Pre Set_Mode');
--
      lb_ret    := FND_REQUEST.SET_MODE(
                     db_trigger => TRUE
                     );
--
      GMI_DEBUG_UTIL.Println('Pre Submit_Request');
--
      ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                     application => 'XXCMN'
                    ,program     => 'XXCMN810003C'
                    ,argument1   => :new.item_no
                     );
--
      GMI_DEBUG_UTIL.Println('Success : '||TO_CHAR(ln_req_id));
--
    END IF;
--
  ELSE
--
  GMI_DEBUG_UTIL.Println('Entering Item Synch Trigger.........');
  GMI_DEBUG_UTIL.Println('Calling gmf_sync.glsynch_initialize.........');
--
  GMF_SYNC_INIT.GLSYNCH_INITIALIZE;
  GMI_DEBUG_UTIL.Println('After gmf_sync.glsynch_initialize.........');
--
  IF (gmf_session_vars.GMI_INSTALLED = 'I'
     AND (gmf_session_vars.INV_INSTALLED = 'I' OR gmf_session_vars.INV_INSTALLED = 'S')) THEN
    GMI_DEBUG_UTIL.Println('In the If Condition of session Vars.........');
--
    gmf_session_vars.item_id := :new.item_id;
    gmf_session_vars.item_no := :new.item_no;
    GMI_DEBUG_UTIL.Println('gmf_session_vars.item_id := '||gmf_session_vars.item_id);
    GMI_DEBUG_UTIL.Println('gmf_session_vars.item_no := '||gmf_session_vars.item_no);
--
    v_inv_item_status_code := FND_PROFILE.VALUE('INV_STATUS_DEFAULT');
    GMI_DEBUG_UTIL.Println('v_inv_item_status_code := '|| v_inv_item_status_code);
--
    IF (v_inv_item_status_code IS NULL) THEN
      GMI_DEBUG_UTIL.Println('v_inv_item_status_code is NULL,Raising an exception');
      RAISE ex_no_profile_option_value;
    END IF;
--
    GMI_DEBUG_UTIL.Println('Before the FOR loop to get the status' || 'attribute values');
--
    /* Now get the status attribute values */
    FOR r_item_status in c_item_status(v_inv_item_status_code) LOOP
--
      GMI_DEBUG_UTIL.Println('r_item_status_attribute_name is :' || r_item_status.attribute_name);
--
      IF r_item_status.attribute_name = 'MTL_SYSTEM_ITEMS.BOM_ENABLED_FLAG' THEN
        v_bom_enabled_flag := r_item_status.ATTRIBUTE_VALUE;
      ELSIF r_item_status.attribute_name = 'MTL_SYSTEM_ITEMS.PURCHASING_ENABLED_FLAG' THEN
        v_purchasing_enabled_flag := r_item_status.ATTRIBUTE_VALUE;
      ELSIF r_item_status.attribute_name = 'MTL_SYSTEM_ITEMS.MTL_TRANSACTIONS_ENABLED_FLAG' THEN
        v_mtl_xactions_enabled_flag := r_item_status.ATTRIBUTE_VALUE;
      ELSIF r_item_status.attribute_name = 'MTL_SYSTEM_ITEMS.STOCK_ENABLED_FLAG' THEN
        v_stock_enabled_flag := r_item_status.ATTRIBUTE_VALUE;
      ELSIF r_item_status.attribute_name = 'MTL_SYSTEM_ITEMS.BUILD_IN_WIP_FLAG' THEN
        v_build_in_wip_flag := r_item_status.ATTRIBUTE_VALUE;
      ELSIF r_item_status.attribute_name = 'MTL_SYSTEM_ITEMS.CUSTOMER_ORDER_ENABLED_FLAG' THEN
        v_customer_order_enabled_flag := r_item_status.ATTRIBUTE_VALUE;
      ELSIF r_item_status.attribute_name = 'MTL_SYSTEM_ITEMS.INTERNAL_ORDER_ENABLED_FLAG' THEN
        v_internal_order_enabled_flag := r_item_status.ATTRIBUTE_VALUE;
      ELSIF r_item_status.attribute_name = 'MTL_SYSTEM_ITEMS.INVOICE_ENABLED_FLAG' THEN
        v_invoice_enabled_flag := r_item_status.ATTRIBUTE_VALUE;
      END IF;
--
      GMI_DEBUG_UTIL.Println('v_bom_enabled_flag :' || v_bom_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_purchasing_enabled_flag :' || v_purchasing_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_mtl_xactions_enabled_flag :' || v_mtl_xactions_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_stock_enabled_flag :'||  v_stock_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_build_in_wip_flag :'||v_build_in_wip_flag);
    END LOOP;
--
    -- Removed bom_enabled_flag and build_in_wip_flag.
    IF (:new.inactive_ind = 1) THEN
      GMI_DEBUG_UTIL.Println('Item is Inactive. Setting all the flags to N');
      v_purchasing_enabled_flag := 'N';
      v_mtl_xactions_enabled_flag := 'N';
      v_stock_enabled_flag := 'N';
      v_customer_order_enabled_flag := 'N';
      v_internal_order_enabled_flag := 'N';
      v_invoice_enabled_flag := 'N';
    -- Added else to turn on the functional areas if new.inactive_ind = 0.
    ELSIF (:new.inactive_ind = 0 and :old.inactive_ind = 1) THEN
      v_purchasing_enabled_flag := 'Y';
      v_mtl_xactions_enabled_flag := 'Y';
      v_stock_enabled_flag := 'Y';
      v_customer_order_enabled_flag := 'Y';
      v_internal_order_enabled_flag := 'Y';
      v_invoice_enabled_flag := 'Y';
      GMI_DEBUG_UTIL.Println(':new.inactive_ind :' || :new.inactive_ind);
      GMI_DEBUG_UTIL.Println('v_bom_enabled_flag :' || v_bom_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_purchasing_enabled_flag :' ||v_purchasing_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_mtl_xactions_enabled_flag :' ||v_mtl_xactions_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_stock_enabled_flag :'||v_stock_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_build_in_wip_flag :'||v_build_in_wip_flag);
      GMI_DEBUG_UTIL.Println('v_customer_order_enabled_flag :'||v_customer_order_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_internal_order_enabled_flag :'||v_internal_order_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_invoice_enabled_flag :'||v_invoice_enabled_flag);
      GMI_DEBUG_UTIL.Println('v_inventory_item_flag :'||v_inventory_item_flag);
    END IF;
--
    -- Set the stock enabled, bom_enabled, build_in_wip and
    -- mtl_transactions_enabled flags to 'N' for non inventory items.
    IF :new.noninv_ind = 1 THEN
      v_inventory_item_flag := 'N';
    END IF;
    /* Get the values dependent on inventory_item_flag */
    IF v_inventory_item_flag = 'N' THEN
      v_stock_enabled_flag := 'N';
      v_build_in_wip_flag := 'N';
    END IF;
    /* Get values dependent on stock_enabled_flag */
    IF v_stock_enabled_flag = 'N' THEN
      v_mtl_xactions_enabled_flag := 'N';
    END IF;
--
    GMI_DEBUG_UTIL.PrintLn('Before Calling GMIUTILS.get_inventory_item_id');
    v_new_inventory_item_id := GMIUTILS.get_inventory_item_id(:new.item_no);
--
    IF v_new_inventory_item_id IS NULL THEN
      SELECT mtl_system_items_s.nextval
      INTO   v_new_inventory_item_id
      FROM   dual;
    END IF;
--
    GMI_DEBUG_UTIL.PrintLn('v_new_inventory_item_id :'|| v_new_inventory_item_id);
--
    IF (:new.dualum_ind IN (0,1)) THEN
      v_dual_uom_deviation_high := NULL;
      v_dual_uom_deviation_low  := NULL;
    ELSE
      v_dual_uom_deviation_high := :new.deviation_hi;
      v_dual_uom_deviation_low  := :new.deviation_lo;
    END IF;
--
    IF (GML_PO_FOR_PROCESS.CHECK_PO_FOR_PROC) THEN
      v_lot_control_code := :new.lot_ctl + 1;
      v_location_control_code := :new.loct_ctl + 1;
    ELSE
      v_lot_control_code := 1;
      v_location_control_code := 1;
    END IF;
    GMI_DEBUG_UTIL.PrintLn('v_lot_control_code :'|| v_lot_control_code);
    GMI_DEBUG_UTIL.PrintLn('v_location_control_code :'|| v_location_control_code);
--
    IF NVL(FND_PROFILE.VALUE('IC$USERORGSONLY'),'N') = 'Y' THEN
      flg_item_user_orgs_only :='Y';
    ELSE
      flg_item_user_orgs_only :='N';
    END IF;
    GMI_DEBUG_UTIL.PrintLn('flg_item_user_orgs_only :'|| flg_item_user_orgs_only);
--
    -- Cache the user_id in a local variable.
    v_user_id := FND_PROFILE.VALUE('USER_ID');
    GMI_DEBUG_UTIL.PrintLn('v_user_id :'|| v_user_id);
    -- Added condition to check if inactive ind has changed.
    IF (:new.inactive_ind <> :old.inactive_ind) THEN
      is_inactive_ind_updated := 'Y';
    END IF;
--
    /* Loop thru all OPM linked inventory orgs */
    FOR r_inventory_org in c_inventory_org LOOP
    << try_to_fetch_item>>
      BEGIN
        flg_item_to_be_updated := 'Y';
        OPEN  c_item_cur(:new.item_no, r_inventory_org.organization_id);
        FETCH c_item_cur INTO r_item_rec;
        IF c_item_cur%NOTFOUND THEN
          GMI_DEBUG_UTIL.Println('In FOR LOOP r_inventory_org, Item not found');
          flg_item_to_be_updated := 'N';
        END IF;
        CLOSE c_item_cur;
      END try_to_fetch_item;
      GMI_DEBUG_UTIL.Println('In FOR LOOP r_inventory_org After try to fetch item');
--
      <<get_account_codes>>
      BEGIN
        GMI_DEBUG_UTIL.Println('In Block get_account_codes');
        SELECT cost_of_sales_account
              ,sales_account
              ,expense_account
              ,encumbrance_account
        INTO   v_cost_of_sales_account
              ,v_sales_Account
              ,v_expense_Account
              ,v_encumbrance_account
        FROM   mtl_parameters
        WHERE  organization_id = r_inventory_org.organization_id
        AND    ROWNUM = 1;
      EXCEPTION
        WHEN others THEN
          v_error_status := SQLCODE;
          v_error_text   := SQLERRM;
          GMI_DEBUG_UTIL.PrintLn('Before Raising EXCEPTION '|| 'ex_no_account_codes_avlbl');
          GMI_DEBUG_UTIL.PrintLn('r_inventory_org.organization_id '|| r_inventory_org.organization_id);
          GMI_DEBUG_UTIL.PrintLn('v_error_status'|| v_error_status);
          GMI_DEBUG_UTIL.PrintLn('v_error_text '|| v_error_text);
          RAISE ex_no_account_codes_avlbl;
      END get_account_info;
--
      /** uom conversion change get unit_of_measure also along with uom_code **/
      <<get_primary_uom_code>>
      BEGIN
        GMI_DEBUG_UTIL.PrintLn('In Block get_primary_uom_code');
        SELECT b.uom_code
              ,b.unit_of_measure
        INTO   v_primary_uom_code
              ,v_primary_unit_of_measure
        FROM   sy_uoms_mst a
              ,mtl_units_of_measure b
        WHERE  a.um_code = :new.item_um
        AND    a.unit_of_measure = b.unit_of_measure;
        IF (:new.dualum_ind > 0) THEN
          SELECT  b.uom_code
          INTO    v_secondary_uom_code
          FROM    sy_uoms_mst a,mtl_units_of_measure b
          WHERE   a.um_code = :new.item_um2
          AND     a.unit_of_measure = b.unit_of_measure;
        END IF;
      EXCEPTION
        WHEN others THEN
          v_error_status := SQLCODE;
          v_error_text   := SQLERRM;
          GMI_DEBUG_UTIL.PrintLn('Before Raising EXCEPTION '||'ex_no_primary_uom_code_avlbl');
          GMI_DEBUG_UTIL.PrintLn(':new.item_um '|| :new.item_um);
          GMI_DEBUG_UTIL.PrintLn(':new.item_um2 '|| :new.item_um2);
          GMI_DEBUG_UTIL.PrintLn('v_error_status'|| v_error_status);
          GMI_DEBUG_UTIL.PrintLn('v_error_text '|| v_error_text);
          RAISE  ex_no_primary_uom_code_avlbl;
      END get_primary_uom_code;
--
      /* Item synchronization in mtl_system_items and ic_item_mst tables starts */
      IF (gmf_session_vars.PO_INSTALLED = 'I' AND
        v_prev_org_id <> r_inventory_org.org_id) THEN
        IF (r_inventory_org.org_id IS NOT NULL) THEN
          OPEN  c_allow_item_desc_cur1(r_inventory_org.org_id);
          FETCH c_allow_item_desc_cur1 INTO v_allow_item_desc_update_flag;
          IF c_allow_item_desc_cur1%NOTFOUND  THEN
            v_allow_item_desc_update_flag := 'Y';
          END IF;
          v_prev_org_id := r_inventory_org.org_id;
          v_prev_allow_update_flag := v_allow_item_desc_update_flag;
          CLOSE c_allow_item_desc_cur1;
        ELSE
          OPEN c_allow_item_desc_cur2;
          FETCH c_allow_item_desc_cur2 INTO v_allow_item_desc_update_flag;
          IF c_allow_item_desc_cur2%NOTFOUND  THEN
            v_allow_item_desc_update_flag := 'Y';
          END IF;
          v_prev_org_id := r_inventory_org.org_id;
          v_prev_allow_update_flag := v_allow_item_desc_update_flag;
          CLOSE c_allow_item_desc_cur2;
        END IF;
      ELSE
        v_allow_item_desc_update_flag := v_prev_allow_update_flag;
      END IF;
      flg_rev_item_to_be_inserted := 'N';
      flg_rev_item_to_be_updated  := 'N';
      GMI_DEBUG_UTIL.PrintLn('flg_rev_item_to_be_inserted'||flg_rev_item_to_be_inserted);
      GMI_DEBUG_UTIL.PrintLn('flg_rev_item_to_be_updated'||flg_rev_item_to_be_updated);
      IF (flg_item_to_be_updated = 'Y') THEN
        <<update_of_item>>
        BEGIN
          GMI_DEBUG_UTIL.PrintLn('In the block update_of_item');
          v_category_item_id :=  r_item_rec.inventory_item_id;
          FOR r_update_orgs in c_update_orgs(r_inventory_org.organization_id,v_category_item_id ) LOOP
            GMI_DEBUG_UTIL.PrintLn('In FOR LOOP r_update_orgs');
            GMI_DEBUG_UTIL.PrintLn('Before Inserting INTO mtl_item_categories');
            GMI_DEBUG_UTIL.PrintLn('v_category_item_id '|| v_category_item_id);
            INSERT INTO mtl_item_categories
              (
              inventory_item_id,
              organization_id,
              category_set_id,
              category_id,
              last_update_date,
              last_updated_by,
              creation_date,
              created_by,
              last_update_login,
              program_application_id,
              program_id,
              program_update_date,
              request_id
              )
            SELECT v_category_item_id
                  ,r_update_orgs.organization_id
                  ,s.category_set_id
                  ,s.default_category_id
                  ,sysdate
                  ,v_of_gemms_user_id
                  ,sysdate
                  ,v_of_gemms_user_id
                  ,-1
                  ,-1
                  ,-1
                  ,sysdate
                  ,-1
            FROM  mtl_category_sets_b  s
            WHERE s.category_set_id IN (
                    SELECT d.category_set_id
                    FROM   mtl_default_category_sets  d
                    WHERE  d.functional_area_id = DECODE(
                                                    decode(
                                                      r_update_orgs.type*i_inventory_item_flag
                                                     ,2,'N'
                                                     ,v_inventory_item_flag)
                                                   ,'Y',1,0)
                    OR     d.functional_area_id = DECODE(
                                                    decode(
                                                      r_update_orgs.type*i_purchasing_enabled_flag
                                                     ,2,'N'
                                                     ,v_purchasing_enabled_flag)
                                                   ,'Y',2,0)
                    OR     d.functional_area_id = DECODE(
                                                    decode(
                                                      r_update_orgs.type*i_internal_order_enabled_flag
                                                     ,2,'N'
                                                     ,v_internal_order_enabled_flag)
                                                   ,'Y',2,0)
                    OR     d.functional_area_id = DECODE(
                                                    decode(
                                                      r_update_orgs.type*i_costing_enabled_flag
                                                     ,2,'N'
                                                     ,'Y')
                                                   ,'Y',5,0)
                    OR     d.functional_area_id = DECODE(
                                                    decode(
                                                      r_update_orgs.type*i_customer_order_enabled_flag
                                                     ,2,'N'
                                                     ,v_customer_order_enabled_flag)
                                                   ,'Y',7,0)
                    OR     d.functional_area_id = DECODE(
                                                    decode(
                                                      r_update_orgs.type*i_customer_order_enabled_flag
                                                     ,2,'N'
                                                     ,v_customer_order_enabled_flag)
                                                   ,'Y',11,0)
                    OR     d.functional_area_id = DECODE(
                                                    decode(
                                                      r_update_orgs.type*i_internal_order_enabled_flag
                                                     ,2,'N'
                                                     ,v_internal_order_enabled_flag)
                                                   ,'Y',11,0))
            AND  s.default_category_id IS NOT NULL
            -- Check if the item already has any category assignment
            AND NOT EXISTS
                  (SELECT 'x'
                   FROM   mtl_item_categories mic
                   WHERE  mic.inventory_item_id     = v_category_item_id
                   AND    mic.organization_id   = r_update_orgs.organization_id
                   AND    mic.category_set_id   = s.category_set_id);
            GMI_DEBUG_UTIL.PrintLn('After Inserting INTO mtl_item_categories');
--
            GMI_DEBUG_UTIL.PrintLn('Before Updating mtl_system_items_tl');
            UPDATE  mtl_system_items_b m
            SET     m.enabled_flag            = decode(:new.delete_mark
                                                      ,1,'N','Y')
                   ,m.inventory_item_flag     = decode(r_update_orgs.type*i_inventory_item_flag
                                                      ,2,m.inventory_item_flag,v_inventory_item_flag)
                   ,m.unit_of_issue           = decode(r_update_orgs.type*i_primary_unit_of_measure
                                                      ,2,m.unit_of_issue,v_primary_unit_of_measure)
                   ,m.primary_uom_code        = decode(r_update_orgs.type*i_primary_uom_code
                                                      ,2,m.primary_uom_code, v_primary_uom_code)
                   ,m.primary_unit_of_measure = decode(r_update_orgs.type*i_primary_unit_of_measure
                                                      ,2,m.primary_unit_of_measure,v_primary_unit_of_measure)
                   ,m.last_updated_by         = :new.last_updated_by
                   ,m.last_update_date        = :new.last_update_date
                   ,m.cost_of_sales_account   = decode(r_update_orgs.type*i_cost_of_sales_account
                                                      ,2,m.cost_of_sales_account
                                                      ,nvl(m.cost_of_sales_account,v_cost_of_sales_account))
                   ,m.sales_account           = decode(r_update_orgs.type*i_sales_account
                                                      ,2,m.sales_account
                                                      ,nvl(m.sales_account,v_sales_account))
                   ,m.expense_account         = decode(r_update_orgs.type*i_expense_account
                                                      ,2,m.expense_account
                                                      ,nvl(m.expense_account,v_expense_account))
                   ,m.encumbrance_account     = decode(r_update_orgs.type*i_encumbrance_account
                                                      ,2,m.encumbrance_account
                                                      ,nvl(m.encumbrance_account,v_encumbrance_account))
                   ,m.costing_enabled_flag    = decode(r_update_orgs.type*i_costing_enabled_flag
                                                      ,2,m.costing_enabled_flag,'Y')
                   ,m.inventory_asset_flag    = decode(r_update_orgs.type*i_inventory_asset_flag
                                                      ,2,m.inventory_asset_flag
                                                      ,decode(:new.noninv_ind,0,'Y','N'))
                   ,m.description             = decode(r_update_orgs.type*i_item_desc1
                                                      ,2,description,:new.item_desc1)
                   ,m.lot_control_code        = decode(r_update_orgs.type*i_lot_control_code
                                                      ,2,m.lot_control_code
                                                      ,v_lot_control_code)
                   ,m.auto_lot_alpha_prefix   = decode(r_update_orgs.type*i_auto_lot_alpha_prefix
                                                      ,2,m.auto_lot_alpha_prefix
                                                      ,nvl(m.auto_lot_alpha_prefix
                                                          ,decode(v_lot_control_code,2,'L',NULL)))
                   ,m.start_auto_lot_number   = decode(r_update_orgs.type*i_start_auto_lot_number
                                                      ,2,m.start_auto_lot_number
                                                      ,nvl(m.start_auto_lot_number
                                                          ,decode(v_lot_control_code,2,1,NULL)))
                   ,m.location_control_code   = decode(r_update_orgs.type*i_location_control_code
                                                      ,2,m.location_control_code
                                                      ,v_location_control_code)
                   ,m.bom_enabled_flag        = DECODE(v_inventory_item_flag
                                                      ,'N',decode(r_update_orgs.type*i_bom_enabled_flag
                                                                 ,2,m.bom_enabled_flag
                                                                 ,v_bom_enabled_flag)
                                                      ,m.bom_enabled_flag)
                   ,m.purchasing_enabled_flag = DECODE(is_inactive_ind_updated
                                                      ,'Y',decode(r_update_orgs.type*i_purchasing_enabled_flag
                                                                 ,2,m.purchasing_enabled_flag
                                                                 ,decode(m.purchasing_item_flag
                                                                        ,'N','N'
                                                                        ,v_purchasing_enabled_flag))
                                                      ,m.purchasing_enabled_flag)
                   ,m.mtl_transactions_enabled_flag = DECODE(is_inactive_ind_updated
                                                            ,'Y',decode(r_update_orgs.type*i_mtl_xactions_enabled_flag
                                                                       ,2,m.mtl_transactions_enabled_flag
                                                                       ,v_mtl_xactions_enabled_flag)
                                                            ,m.mtl_transactions_enabled_flag)
                   ,m.stock_enabled_flag     = DECODE(is_inactive_ind_updated
                                                     ,'Y',decode(r_update_orgs.type*i_stock_enabled_flag
                                                                ,2,m.stock_enabled_flag
                                                                ,v_stock_enabled_flag)
                                                     ,m.stock_enabled_flag)
                   ,m.build_in_wip_flag      = DECODE(v_inventory_item_flag
                                                     ,'N',decode(r_update_orgs.type*i_build_in_wip_flag
                                                                ,2,m.build_in_wip_flag
                                                                ,v_build_in_wip_flag)
                                                     ,m.build_in_wip_flag)
                   ,m.customer_order_enabled_flag = DECODE(is_inactive_ind_updated
                                                          ,'Y',decode(r_update_orgs.type*i_customer_order_enabled_flag
                                                                     ,2,m.customer_order_enabled_flag
                                                                     ,decode(m.customer_order_flag
                                                                            ,'N','N'
                                                                            ,v_customer_order_enabled_flag))
                                                          ,m.customer_order_enabled_flag)
                   ,m.internal_order_enabled_flag = DECODE(is_inactive_ind_updated
                                                          ,'Y',decode(r_update_orgs.type*i_internal_order_enabled_flag
                                                                     ,2,m.internal_order_enabled_flag
                                                                     ,decode(m.internal_order_flag
                                                                            ,'N','N'
                                                                            ,v_internal_order_enabled_flag))
                                                          ,m.internal_order_enabled_flag)
                   ,m.invoice_enabled_flag   = DECODE(is_inactive_ind_updated
                                                     ,'Y',decode(r_update_orgs.type*i_invoice_enabled_flag
                                                                ,2,m.invoice_enabled_flag
                                                                ,v_invoice_enabled_flag)
                                                     ,m.invoice_enabled_flag)
            WHERE   organization_id = r_update_orgs.organization_id
            AND     inventory_item_id =  v_category_item_id;
--
            v_revision_item_id :=  r_item_rec.inventory_item_id;
            flg_rev_item_to_be_updated := 'Y';
            GMI_DEBUG_UTIL.PrintLn('After Updating mtl_system_items_b');
          END LOOP;
          GMI_DEBUG_UTIL.PrintLn('End of LOOP, End of Block update_of_item');
        END update_of_item;
      ELSE
        <<insert_of_item>>
        BEGIN
          GMI_DEBUG_UTIL.PrintLn('Beginning of Block insert_of_item');
          IF (r_inventory_org.org_type = 'M') THEN
            v_mtl_event := 'INSERT';
          ELSIF (r_inventory_org.org_type = 'P') THEN
            v_mtl_event := 'ORG_ASSIGN';
          END IF;
          GMI_DEBUG_UTIL.PrintLn('Before Gmf_pr_item_ins.pr_item_ins');
          Gmf_pr_item_ins.pr_item_ins(
            v_new_inventory_item_id
           ,r_inventory_org.organization_id
           ,:new.item_no
           ,:new.delete_mark
           ,:new.inactive_ind
           ,v_primary_unit_of_measure
           ,:new.item_desc1
           ,:new.noninv_ind
           ,v_primary_uom_code
           ,v_of_gemms_user_id
           ,v_cost_of_sales_account
           ,v_sales_Account
           ,v_inv_item_status_code
           ,v_expense_Account
           ,v_encumbrance_account
           ,v_bom_enabled_flag
           ,v_purchasing_enabled_flag
           ,v_mtl_xactions_enabled_flag
           ,v_stock_enabled_flag
           ,v_build_in_wip_flag
           ,v_customer_order_enabled_flag
           ,v_internal_order_enabled_flag
           ,v_invoice_enabled_flag
           ,0
           ,NULL
           ,0
           ,0
           ,v_lot_control_code
           ,v_location_control_code
           ,v_allow_item_desc_update_flag
           ,r_inventory_org.master_org_id
           ,v_mtl_event
           ,:new.level_code
           ,0
           ,v_error_text
           ,v_error_status);
--
          IF v_error_status <> 0 THEN
            GMI_DEBUG_UTIL.PrintLn('Before RAISE ex_unable_to_insert_item');
            GMI_DEBUG_UTIL.PrintLn('v_error_status'|| v_error_status);
            RAISE ex_unable_to_insert_item;
          END IF;
          GMI_DEBUG_UTIL.PrintLn('END of Block insert_of_item');
        EXCEPTION
          WHEN ex_unable_to_insert_item THEN
            RAISE ex_unable_to_insert_item;
        END insert_of_item;
      END IF;   /* item_to_be_updated */
--
      /* Item synchronization in ic_item_mst and mtl_system_item  ENDS */
      IF (flg_rev_item_to_be_updated = 'Y') THEN
        <<check_item_in_rev>>
        BEGIN
          GMI_DEBUG_UTIL.PrintLn('Beginning of block check_item_in_rev');
          SELECT inventory_item_id
          INTO   v_dummy_item_id
          FROM   mtl_item_revisions
          WHERE  organization_id = r_inventory_org.organization_id
          AND    inventory_item_id = v_revision_item_id
          AND    ROWNUM = 1;
        EXCEPTION
          WHEN no_data_found THEN
            flg_rev_item_to_be_inserted := 'Y';
        END check_item_in_rev;
      END IF; /* revision_item_to_be_updated */
      IF (flg_rev_item_to_be_inserted = 'Y') THEN
        GMI_DEBUG_UTIL.PrintLn('Before Calling Gmf_pr_item_ins.pr_rev_item_ins');
        GMI_DEBUG_UTIL.PrintLn('v_revision_item_id'|| v_revision_item_id);
        GMI_DEBUG_UTIL.PrintLn('organization_id'|| r_inventory_org.organization_id);
        GMI_DEBUG_UTIL.PrintLn('v_of_gemms_user_id'|| v_of_gemms_user_id);
        GMI_DEBUG_UTIL.PrintLn('v_error_text'|| v_error_text);
        GMI_DEBUG_UTIL.PrintLn('v_error_status'|| v_error_status);
        Gmf_pr_item_ins.pr_rev_item_ins(
          v_revision_item_id
         ,r_inventory_org.organization_id
         ,v_of_gemms_user_id
         ,v_error_text
         ,v_error_status);
        IF  v_error_status <> 0 THEN
          GMI_DEBUG_UTIL.PrintLn('Before Raising EXCEPTION '||'ex_unable_to_insert_rev_item');
          GMI_DEBUG_UTIL.PrintLn('v_error_status '|| v_error_status);
          RAISE ex_unable_to_insert_rev_item;
        END IF;
      END IF;   /* revision_item_to_be_inserted */
    END LOOP;
    <<insert_mtl_def_cat_in_opm>>
    BEGIN
      GMI_DEBUG_UTIL.PrintLn('Begin block insert_mtl_def_cat_in_opm');
      FOR Cur_missing_def_cat_in_opm_rec IN Cur_missing_def_cat_in_opm(:new.item_id,v_new_inventory_item_id) LOOP
        BEGIN
          SELECT DISTINCT mic.category_id
          INTO   v_category_id
          FROM   mtl_item_categories mic
          WHERE  mic.inventory_item_id = v_new_inventory_item_id
          AND    mic.category_set_id   = Cur_missing_def_cat_in_opm_rec.category_set_id
          AND    EXISTS (select 1
                         from   mtl_parameters mp, gmi_item_organizations gio
                         where  mp.organization_id = gio.organization_id
                         and    ((mp.organization_id  = mic.organization_id)
                           OR (mp.master_organization_id  = mic.organization_id)));
        EXCEPTION
          WHEN TOO_MANY_ROWS THEN
            SELECT default_category_id
            INTO   v_category_id
            FROM   mtl_category_sets
            WHERE  category_set_id = Cur_missing_def_cat_in_opm_rec.category_set_id;
        END;
--
        IF (v_category_id IS NOT NULL) THEN
          GMI_DEBUG_UTIL.PrintLn('Before insert into gmi_item_categories');
          INSERT INTO gmi_item_categories
            (
            ITEM_ID
           ,CATEGORY_SET_ID
           ,CATEGORY_ID
           ,CREATED_BY
           ,CREATION_DATE
           ,LAST_UPDATED_BY
           ,LAST_UPDATE_DATE
           ,LAST_UPDATE_LOGIN
            )
          VALUES
            (
            :new.item_id
           ,Cur_missing_def_cat_in_opm_rec.category_set_id
           ,v_category_id
           ,v_of_gemms_user_id
           ,sysdate
           ,v_of_gemms_user_id
           ,sysdate
           ,:new.last_update_login
            );
          GMI_DEBUG_UTIL.PrintLn('After insert into gmi_item_categories');
        END IF;
      END LOOP;
      GMI_DEBUG_UTIL.PrintLn('END block insert_mtl_def_cat_in_opm');
    END insert_mtl_def_cat_in_opm;
  END IF; /* IF GMI AND INV(S, I) ARE INSTALLED */
--
  END IF; --yutsuzuk modify
--
EXCEPTION
  WHEN ex_no_primary_uom_code_avlbl THEN
    v_msg_code := 'OFTG_NO_UOM_CODE';
    fnd_message.set_name('GMF',v_msg_code);
    GMI_DEBUG_UTIL.Println('ERROR : Exiting Item Synch Trigger with EXCEPTION ex_no_primary_uom_code_avlbl');
    GMI_DEBUG_UTIL.Println('v_msg_code'|| v_msg_code);
    app_exception.raise_exception;
  WHEN ex_no_account_codes_avlbl THEN
    v_msg_code := 'OFTG_NO_ACCOUNT_CODES';
    fnd_message.set_name('GMF',v_msg_code);
    GMI_DEBUG_UTIL.Println('ERROR : Exiting Item Synch Trigger with EXCEPTION ex_no_account_codes_avlbl');
    GMI_DEBUG_UTIL.Println('v_msg_code'|| v_msg_code);
    app_exception.raise_exception;
  WHEN ex_unable_to_update_item THEN
    v_msg_code := 'OFTG_ERR_ITEM_UPDATE';
    fnd_message.set_name('GMF',v_msg_code);
    GMI_DEBUG_UTIL.Println('ERROR : Exiting Item Synch Trigger with EXCEPTION ex_unable_to_update_item');
    GMI_DEBUG_UTIL.Println('v_msg_code'|| v_msg_code);
    app_exception.raise_exception;
  WHEN ex_unable_to_insert_item THEN
    v_msg_code := 'OFTG_ERR_ITEM_INSERT';
    fnd_message.set_name('GMF',v_msg_code);
    GMI_DEBUG_UTIL.Println('ERROR : Exiting Item Synch Trigger with EXCEPTION ex_unable_to_insert_item');
    GMI_DEBUG_UTIL.Println('v_msg_code'|| v_msg_code);
    app_exception.raise_exception;
  WHEN ex_unable_to_insert_rev_item THEN
    v_msg_code := 'OFTG_ERR_REV_ITEM_INSERT';
    fnd_message.set_name('GMF',v_msg_code);
    GMI_DEBUG_UTIL.Println('ERROR : Exiting Item Synch Trigger with EXCEPTION ex_unable_to_insert_rev_item');
    GMI_DEBUG_UTIL.Println('v_msg_code'|| v_msg_code);
    app_exception.raise_exception;
  WHEN ex_no_profile_option_value THEN
    v_msg_code := 'OFTG_NO_PROFILE_VALUE';
    fnd_message.set_name('GMF',v_msg_code);
    GMI_DEBUG_UTIL.Println('ERROR : Exiting Item Synch Trigger with EXCEPTION ex_no_profile_option_value');
    GMI_DEBUG_UTIL.Println('v_msg_code'|| v_msg_code);
    app_exception.raise_exception;
  WHEN ex_error_profile_option_value THEN
    v_msg_code := 'OFTG_ERR_GETTING_PROFILE_VAL';
    fnd_message.set_name('GMF',v_msg_code);
    GMI_DEBUG_UTIL.Println('ERROR : Exiting Item Synch Trigger with EXCEPTION ex_error_profile_option_value');
    GMI_DEBUG_UTIL.Println('v_msg_code'|| v_msg_code);
    app_exception.raise_exception;
  WHEN others THEN
    v_msg_code := 'GMI_DXFR_SQL_ERROR';
    fnd_message.set_name('GMI',v_msg_code);
    fnd_message.set_token('ERRCODE',SQLCODE);
    fnd_message.set_token('ERRM',SQLERRM);
    GMI_DEBUG_UTIL.Println('ERROR : Exiting Item Synch Trigger with UNHANDLED EXCEPTION');
    GMI_DEBUG_UTIL.Println('v_msg_code'|| sqlerrm);
    app_exception.raise_exception;
END;
/
COMMIT;
EXIT;
