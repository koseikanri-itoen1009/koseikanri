 REM dbdrv: sql ~PROD ~PATH ~FILE none none none sqlplus &phase=en+10 \
REM dbdrv: checkfile:nocheck
REM *hb************************************************************************
REM  SCRIPT NAME
REM 	gmfitmtg.sql
REM 
REM  INPUT PARAMETERS
REM 		None
REM  RETURNS
REM 		None
REM 
REM  DESCRIPTION
REM	This SQL script will drop the existing trigger and create a new
REM	Database Trigger ic_item_biur_tg on table  IC_ITEM_MST. 
REM	This script is started from ofsynym.sql
REM 
REM  USAGE
REM 
REM  AUTHOR
REM	Sanjay Rastogi - 06/05/96
REM 
REM  HISTORY
REM	Sanjay Rastogi - 07/14/1997	PCR 510462
REM		Modified SELECT statements selecting from mtl_system_items and
REM		mtl_revsion_items table to utilize exisiting indexes for 
REM		performance improvement.
REM	Jatinder Gogna - 11/20/98 Removed call to local function to get profile.
REM		option. Instead calling fnd_profile.value.
REM 	Jatinder Gogna - 1/6/99 Added retreival of default encumbrance account.
REM		BUG 785473.
REM	Jatinder Gogna - 4/22/99 Made changes to replicate items to Inventory
REM		Orgs linked to OPM.
REM	Jatinder Gogna - 5/3/99 - Made changes for workflow. Changed trigger to
REM		after insert or update and useed inactive_ind similar to 
REM		delete_mark. B881921
REM	Jatinder Gogna - 05/05/99 - Changed substr & instr to substrb & instrb
REM		as per AOL standards.
REM	Jatinder Gogna - 05/25/99 - Modified to use MLS procedure.
REM     Jatinder Gogna - 7/1/99 Added logic to assign default category set &
REM             category to item if they are not assigned for inventory and
REM             purchasing functional area. B925425
REM   	Chetan Nagar   - 10/22/1999 AOL Standards
REM	Jatinder Gogna - 12/1/99 - Chnaged RECEIPT_REQUIRED_FLAG to Y
REM		B1042835.
REM	Chetan Nagar	- 01/06/2000	Bug 1122256
REM		Update/Insert mtl_system_items.INVENTORY_ITEM_FLAG based on
REM		ic_item_mst.noninv_ind.
REM	Jatinder Gogna - 02/15/00 - Added changes for OM integration.
REM  	B1297909	17-May-2000	Chetan Nagar
REM  	Financial Integration Module Dependency Changes
REM	Venkat Chukkapalli - 03/15/01- Bug 1311378 Set costing_enabled_flag
REM 		to 'Y' and inventory_asset_flag to Y or N depending on
REM		noninv_ind.
REM     Jalaj Srivastava 06/12/01 Bug 1805589 
REM     Update the item description in mtl_system_items_b when the OPM item is
REM     updated.
REM     Jalaj Srivastava
REM     Changes for OPM item MLS
REM     Jalaj S.         09/18/01 -SET 4 new parameters pi_lot_control_code
REM                                ,pi_location_control_code
REM                                ,auto_lot_alpha_prefix
REM                                ,start_auto_lot_number
REM                                Bug 1993127
REM                                Changes for item synch org 1868095
REM	Jatinder Gogna - 4/10/2001 - Bug 1548457   Added code to get
REM		ALLOW_ITEM_DESC_UPDATE_FLAG from po_system_parameters_all.
REM	Jatinder Gogna - 10/30/2001 - Bug 1900967 - Added logic to insert
REM		Item categories before the item update to ensure the mtl_system_items
REM		triggers do not fail.
REM     Jalaj Srivastava 01/30/2002 Bug 2206257
REM             This trigger was incompatible with OPM family pack G and below
REM             'coz of data model changes
REM              -- ic_item_mst table was converted into MLS which resulted in
REM                 2 tables ic_item_mst_b and ic_item_mst_tl. 
REM                 This was done in OPM family pack G.
REM                 This trigger G and beyond is based on ic_item_mst_b
REM                 For this purpose synonym ic_item_mst_b would be created
REM                 through file gmioff1.sql so that this code can run
REM                 on installs below G.
REM              -- A new table gmi_item_organizations is added in OPM family 
REM                 pack H which would store organizations to which the item
REM                 would be synched over in apps. For more details see bug
REM                 1868095. This is used below to select orgs where the item
REM                 needs to be synched.
REM                 A new view gmi_item_organizations_view would be created
REM                 only for backward compatibility and would only be for 
REM                 installs below OPM family pack H. 
REM                 File gmioff2.sql would create a synonym 
REM                 gmi_item_organizations for this view. This file would 
REM                 be used only H and below.
REM        Jalaj Srivastava Bug 2199205 01/30/2002
REM           Include code to update description in mtl_system_items_tl
REM           only for OPM family pack E and F. G onwards MLS was introduced
REM           which took care of this problem.
REM           Set ato_forecast_control_flag to 2 while updating mtl_system_items
REM        Jalaj Srivastava Bug 2263975 03/13/2002
REM           Below mini pack H lot_control_code and location_control_code
REM           should be passed as 1.  
REM    	   Jalaj Srivastava Bug 2302952 04/16/2002
REM     	 If the item is inactive in OPM it should be not be purchasable,
REM	         transactable etc. 
REM	   Jatinder Gogna Bug 2548269 09/30/2002
REM		Modified the logic to replicate the attributes to child 
REM		organization for the master organization updated by this trigger
REM		. This is done if these attributes are set to be controlled at 
REM		the master organization.
REM
REM      A. Mundhe Bug 2667867 11/13/2002
REM      Modified cursor c_ic_item_mst_tl. Added filter to improve performance. 
REM
REM		A. Mundhe Bug 2698087 12/10/2002
REM      Set the stock enabled, bom_enabled, build_in_wip and 
REM      mtl_transactions_enabled flags to 'N' for non inventory items.
REM     Jalaj Srivastava Bug 2721118
REM        From now on this file can only be sent to installs
REM        which have INV 11i family pack I (DMF I/ 11.5.9)
REM        we will now call INV_item_pvt.create_item to insert
REM        new items in mtl_system_items. 
REM        This new create_item API will insert the default functional area categories 
REM        revisions, cost rows and pending status. 
REM        Removed code which was inserting revisions and default categories when the 
REM        was inserted.
REM        Since now this file will only go on installs having at least 
REM        11i.INV.I, we will update the dual uom control, secondary uom code
REM        and deviation high/low fields.
REM    Jalaj Srivastava Bug 2847159
REM        This trigger will now be a autonomous transaction which will commit/rollback itself.
REM        This is done so that we can call INV_ITEM_PVT.Create_Item which issues savepoints 
REM        not allowed in the trigger. Rollback should be issue for all exceptions.
REM    Joe DiIorio Bug 2990349 - Added when clause for autolot.
REM    Sastry 08/27/2003 BUG#3071034 Modified code to fetch the inventory_item_id
REM        by calling the newly added function GMIUTILS.get_inventory_item_id 
REM        instead of fetching from cursor c_item_id_cur. The inventory_item_id
REM        is stored in package variable which can be accessed from other places.
REM  Jalaj Srivastava Bug 3128085
REM    The cursor c_update_orgs should also return process child orgs which are not 
REM    defined in gmi_item_organizations table.Earlier it used to return only 
REM    discrete child orgs.
REM  Jalaj Srivastava Bug 3132893
REM    Default discrete Categories need to be inserted in gmi_item_categories table also.
REM    List of which discrete default categories need to be inserted 
REM    would be picked up from mtl_item_categories.
REM    While update of items, we would insert default categories in 
REM    mtl_item_categories and gmi_item_categories only for functional 
REM    areas which are newly enabled.
REM
REM  A. Mundhe  Bug 3150286 
REM     Removed update of mtl_system_items_b.allow_item_desc_update_flag 
REM     when OPM item is updated.
REM  Sastry 10/03/2003 BUG#3174722 - To include the fix for BUG#2813091 
REM     Added a condition to the select statement so that it returns one row instead of
REM     fetching many rows, as revisions concept doesn't exist for the OPM Items.
REM     Jalaj Srivastava Bug 3158806
REM       Added new input parameter pi_hold_days to PROCEDURE pr_item_ins.
REM       This would be used to populate the postprocessing_lead_time 
REM       column in mtl_system_items. We would NOT update this column in discrete. 
REM       Only when a item is being created for the first time in discrete this
REM       column would be populated. Column ic_hold_days belongs to the table ic_item_cpg. 
REM       Since, the item trigger is autonomous we would use level code 
REM       column in ic_item_mst_b which has the mirror value of ic_hold_days
REM       set from the form and the APIs.
REM     Jalaj Srivastava Bug 3304755
REM       BOM items has added new attributes for catchweight/VMI functionality
REM       We need to populate these addional attributes while creating items.
REM       Added new input parameter ont_pricing_qty_source in the call to PROCEDURE pr_item_ins.
REM   Rameshwar  04-MAR-2004 BUG#3480063 - Added two unions to get the discrete  
REM       organizations and corresponding master organizations, 
REM       so that item synchs to discrete orgs also.	
REM   Anoop Baddam  13-APR-2004 BUG#3151733 - Modified the cursor c_inventory_org
REM       by commenting fnd_profile.value('user_id') and added fnd_global.user_id.
REM       When an item is created through form fnd_profile.value('user_id') had 
REM       correct value but when created through api it is null and hence it was not fetching orgs.
REM   Jalaj Srivastava Bug 3646892
REM       Remove dependency of bom_enabled_flag on noninv_ind.
REM   Jalaj Srivastava Bug 3871661
REM       No need to update mtl_system_items_tl. Now this file cannot be sent to
REM       installs lower than G.
REM  Supriya Malluru  2-Dec-2004 Bug 3685040
REM    Cursor c_update_orgs should return only child orgs which are attached to the item. 
REM
REM   Archana Mundhe  4-MAR-2005 Bug 4143205 - FP bug 4109016 to 11.5.10.2CU.
REM    Modified Update of mtl_system_items_b to update the flags controlled
REM    by item status only if the inactive ind is changed. Also added code to
REM    to turn the functional areas ON if the item is activated.
REM
REM   Archana Mundhe 15-Mar-2005  Bug 4194374
REM    Modified the call to Gmf_pr_item_ins.pr_item_ins to insert
REM    secondary_uom_code as NULL, dual_uom_deviation_high/low as 0,
REM    dual_uom_control as 0 and ont_pricing_qty_source as 'P'.
REM    These dual uom attributes will not be updated for existing items.
REM
REM   Archana Mundhe 28-MAR-2005 Bug 4222167 - FP Bug 4219762 to 11.5.102CU 
REM    Item synch will be limited to user orgs only if profile 
REM    'GMI: Item synch User orgs only' is set to Yes.
REM
REM   Priya Gupta 14-April-2005 Bug 4228077 - backed out this fix. 
REM
REM   Archana Mundhe 19-Jul-2005 Bug 4496150
REM   Do not update ato_forecast_control_flag while updating mtl_system_items
REM
REM   Anthony Cataldo 27-Sep-2006 Bug 5499101
REM   Remove autonomous transaction definition from this trigger to avoid deadlock
REM 
REM   Anthony Cataldo 03-Oct-2006 Bug 5398369
REM   Exception handling cleanup - removed begin/end/rollback as no longer autonom
REM   Also now handled OTHERS exception
REM 
REM *hf************************************************************************

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;
CREATE OR REPLACE TRIGGER GMF_IC_ITEM_MST_BIUR_TG
/*       $Header: gmfitmtg.sql 115.75.115100.13 2007/04/24 21:46:31 uphadtar ship $ */
AFTER INSERT OR UPDATE
ON  IC_ITEM_MST_B
FOR EACH ROW
WHEN ((nvl(old.lot_suffix,-99) = nvl(new.lot_suffix,-99)) OR
      (nvl(old.lot_suffix,-99) <> nvl(new.lot_suffix, -99) AND
nvl(old.last_update_date,SYSDATE-1) <> new.last_update_date))
DECLARE

-- Jalaj Srivastava Bug 2847159
-- trigger will now be a autonomous transaction which will commit itself.
-- This is done so that we can call INV_ITEM_PVT.Create_Item which issues savepoints 
-- not allowed in the trigger.

-- Bug 5499101 removed to avoid deadlock and added to pr_item_ins in gmfitmpb
-- PRAGMA AUTONOMOUS_TRANSACTION;

  /*  VARIABLES  */
v_item_no			ic_item_mst.item_no%TYPE;
v_item_desc1		    	ic_item_mst.item_desc1%TYPE;
v_cost_of_sales_account		mtl_parameters.cost_of_sales_account%TYPE;
v_sales_Account			mtl_parameters.sales_account%TYPE;
v_expense_Account		mtl_parameters.expense_account%TYPE;
v_encumbrance_account		mtl_parameters.encumbrance_account%TYPE;
v_new_inventory_item_id		mtl_system_items.inventory_item_id%TYPE;
v_dummy_item_id			mtl_system_items.inventory_item_id%TYPE;
v_revision_item_id		mtl_system_items.inventory_item_id%TYPE;
v_category_item_id		mtl_system_items.inventory_item_id%TYPE;
v_primary_uom_code		mtl_units_of_measure.uom_code%TYPE;
v_inv_item_status_code		mtl_system_items.inventory_item_status_code%TYPE;
/* variable for determining the values from item status */
v_primary_unit_of_measure       mtl_system_items.primary_unit_of_measure%TYPE;
v_bom_enabled_flag		mtl_system_items.bom_enabled_flag%TYPE DEFAULT 'N';
v_purchasing_enabled_flag	mtl_system_items.purchasing_enabled_flag%TYPE DEFAULT 'Y';
v_mtl_xactions_enabled_flag	mtl_system_items.mtl_transactions_enabled_flag%TYPE DEFAULT 'Y';
v_stock_enabled_flag		mtl_system_items.stock_enabled_flag%TYPE DEFAULT 'Y';
v_build_in_wip_flag		mtl_system_items.build_in_wip_flag%TYPE DEFAULT 'N';
v_customer_order_enabled_flag	mtl_system_items.customer_order_enabled_flag%TYPE DEFAULT 'Y';
v_internal_order_enabled_flag	mtl_system_items.internal_order_enabled_flag%TYPE DEFAULT 'Y';
v_invoice_enabled_flag		mtl_system_items.invoice_enabled_flag%TYPE DEFAULT 'Y';
v_secondary_uom_code		mtl_units_of_measure.uom_code%TYPE;
v_dual_uom_deviation_high       NUMBER;
v_dual_uom_deviation_low	NUMBER;
v_allow_item_desc_update_flag	mtl_system_items.allow_item_desc_update_flag%TYPE := 'Y'; /* B 1548457 */
v_prev_allow_update_flag	mtl_system_items.allow_item_desc_update_flag%TYPE := 'Y'; /* B 1548457 */
v_prev_org_id			gl_plcy_mst.org_id%TYPE := -999; /* B 1548457 */
/** Bug 2263975 **/
v_lot_control_code              NUMBER;
v_location_control_code         NUMBER;
v_mtl_event                     VARCHAR2(20);

/* Bug 2698087 */
v_inventory_item_flag   mtl_system_items.inventory_item_flag%TYPE DEFAULT 'Y';

/* Bug 4222167 */
v_user_id  FND_USER.USER_ID%TYPE;

/* Jalaj Srivastava Bug 3132893 */
v_category_id			pls_integer;

/* Bug 4143205 */
is_inactive_ind_updated   varchar2(1) := 'N';

/* Variables to determine the item attribute control. Master or Child - B2548269 */
i_item_desc1			pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DESCRIPTION');
i_cost_of_sales_account		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.COST_OF_SALES_ACCOUNT');
i_sales_Account			pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.SALES_ACCOUNT');
i_expense_Account		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.EXPENSE_ACCOUNT');
i_encumbrance_account		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.ENCUMBRANCE_ACCOUNT');
i_primary_uom_code		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.PRIMARY_UOM_CODE');
i_primary_unit_of_measure       pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.PRIMARY_UOM_CODE');
i_allow_item_desc_update_flag	pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.ALLOW_ITEM_DESC_UPDATE_FLAG');
i_lot_control_code              pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.LOT_CONTROL_CODE');
i_location_control_code         pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.LOCATION_CONTROL_CODE');
i_costing_enabled_flag		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.COSTING_ENABLED_FLAG');
i_inventory_asset_flag	        pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INVENTORY_ASSET_FLAG');
i_auto_lot_alpha_prefix	        pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.AUTO_LOT_ALPHA_PREFIX');
i_start_auto_lot_number		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.START_AUTO_LOT_NUMBER');
i_ato_forecast_control		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.ATO_FORECAST_CONTROL');
i_bom_enabled_flag		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.BOM_ENABLED_FLAG');
i_inventory_item_flag		pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INVENTORY_ITEM_FLAG');
i_purchasing_item_flag	        pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.PURCHASING_ITEM_FLAG');
i_purchasing_enabled_flag	pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.PURCHASING_ENABLED_FLAG');
i_mtl_xactions_enabled_flag	pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.MTL_TRANSACTIONS_ENABLED_FLAG');
i_stock_enabled_flag	        pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.STOCK_ENABLED_FLAG');
i_build_in_wip_flag	        pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.BUILD_IN_WIP_FLAG');
i_customer_order_enabled_flag   pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.CUSTOMER_ORDER_ENABLED_FLAG');
i_customer_order_flag           pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.CUSTOMER_ORDER_FLAG');
i_internal_order_enabled_flag   pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INTERNAL_ORDER_ENABLED_FLAG');
i_internal_order_flag           pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INTERNAL_ORDER_FLAG');
i_invoice_enabled_flag          pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.INVOICE_ENABLED_FLAG');
i_secondary_uom_code            pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.SECONDARY_UOM_CODE');
i_dual_uom_deviation_high       pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DUAL_UOM_DEVIATION_HIGH');
i_dual_uom_deviation_low        pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DUAL_UOM_DEVIATION_LOW');
i_dual_uom_control              pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DUAL_UOM_CONTROL');
/* Jalaj Srivastava Bug 3304755 */
i_tracking_quantity_ind         pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.TRACKING_QUANTITY_IND');
i_secondary_default_ind         pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.SECONDARY_DEFAULT_IND');
i_ont_pricing_qty_source        pls_integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.ONT_PRICING_QTY_SOURCE');

   /*VARAIBLES used for stored procedures which determine GEMMS user_id in OF*/

v_of_gemms_user_id		mtl_system_items.created_by%TYPE DEFAULT :new.created_by;
v_error_status			number;
v_error_text			varchar2(200);
status_def_tmp			varchar2(30);
rtn_status			number;
v_date				date;
err_text			varchar2(100);
l_count				pls_integer;


  /* Following variables are used for stored procedure which extracts error message.*/

  v_msg_id		fnd_new_messages.MESSAGE_NUMBER%TYPE	:= -20000;
  v_msg_text		fnd_new_messages.message_text%TYPE;
  v_msg_code		fnd_new_messages.message_name%TYPE;
  v_op_code		fnd_new_messages.LAST_UPDATED_BY%TYPE   := :new.LAST_UPDATED_BY;

  /*	FLAGS */

flg_item_to_be_inserted			varchar2(1);
flg_item_to_be_updated			varchar2(1);
flg_rev_item_to_be_updated 		varchar2(1);
flg_rev_item_to_be_inserted 		varchar2(1);
flg_item_user_orgs_only             varchar2(1); --BUG#3480063



  /*	EXCEPTIONS */

ex_no_primary_uom_code_avlbl		exception;
ex_no_account_codes_avlbl		exception;
ex_unable_to_update_item		exception;
ex_unable_to_insert_item		exception;
ex_unable_to_insert_rev_item		exception;
ex_no_profile_option_value		exception;
ex_error_profile_option_value		exception;


  /* DECLARE c_item_cur CURSOR     GET the item from inv.mtl_system_items by searching  new.item_no in segment1 col of the table*/

/* Removed restriction of organization_id = 0 */
CURSOR c_item_cur(v_item_no IN varchar2, v_organization_id IN NUMBER) IS
	SELECT	inventory_item_id
	FROM	mtl_system_items_b
	WHERE	organization_id = v_organization_id
	AND	segment1 = v_item_no;

/* Declare cusrsor to select all organization to which the item will be
replicated */
/* Added column to differentiate Process Child (P) vs. master (M). - B2548269 */
/*   *******************************************************************
     Jalaj Srivastava Bug 2721118
     Added master_org_id in the select which is needed by 
     inv_item_pvt.create_item api called from Gmf_pr_item_ins.pr_item_ins
     ******************************************************************* */ 
/*BEGIN BUG#3480063 Rameshwar
   Cursor is modified to synch the item to user orgs (or all orgs) based on  
   the profile (IC$USERORGSONLY) value.
   And also added two unions to get discrete orgs and corresponding master orgs.
 */
 
/* BUG#3151733 Anoop
   Modified cursor c_inventory_org by commenting fnd_profile.value('user_id')
   and adding fnd_global.user_id.
*/
/* Bug 4222167 Modified cursor to look at the flag flg_item_user_orgs_only */
CURSOR c_inventory_org IS
	SELECT  i.organization_id, o.operating_unit org_id, 'P' org_type /* Process Orgs */
	       ,p.master_organization_id master_org_id
        FROM    mtl_parameters p,
		gmi_item_organizations i, 
		org_organization_definitions o,
		ic_whse_mst w
	WHERE   i.organization_id = o.organization_id and
		i.organization_id = p.organization_id and
		p.organization_id <> p.master_organization_id and
		i.organization_id = w.mtl_organization_id(+) and
      (flg_item_user_orgs_only  = 'N' OR exists (
			select 1
			from sy_orgn_usr usr
			where usr.user_id = v_user_id and 
			    usr.orgn_code = w.orgn_code)) 
	UNION 
	SELECT  i.organization_id, o.operating_unit org_id,'P' org_type /* Process Orgs */
		,p.master_organization_id master_org_id
	FROM    mtl_parameters p,
		gmi_item_organizations i,
		org_organization_definitions o
	WHERE   i.organization_id = p.organization_id and
		p.organization_id <> p.master_organization_id AND
		o.organization_id = i.organization_id and  
		upper(p.process_enabled_flag) <> 'Y'	
	UNION 
	SELECT  p.master_organization_id, o.operating_unit org_id, 'M' /* Master Orgs */
		,p.master_organization_id master_org_id
	FROM    mtl_parameters p,
		gmi_item_organizations g,
		org_organization_definitions o
	WHERE   p.organization_id        = g.organization_id and
		p.master_organization_id = o.organization_id and
		upper(p.process_enabled_flag) <> 'Y'	
	UNION 
        SELECT  p.master_organization_id, o.operating_unit org_id, 'M' org_type /* Master Orgs */
               ,p.master_organization_id master_org_id 
        FROM    mtl_parameters p,
                gmi_item_organizations g,
	        org_organization_definitions o,
                ic_whse_mst w
        WHERE   p.organization_id        = g.organization_id and
	        p.master_organization_id = o.organization_id and
                g.organization_id = w.mtl_organization_id(+) and
		          (flg_item_user_orgs_only  = 'N' OR exists (
                        select 1
                        from sy_orgn_usr usr
                        where usr.user_id = v_user_id and 
                            usr.orgn_code = w.orgn_code)) 	        
	ORDER by 3 asc;
     /* *************************************************
	Jalaj Srivastava Bug 2721118
	Added order by in the above select to synch the 
	master orgs first
	************************************************* */

/* Declare Cursor to get existing inventory_item_id for atleast one organization */
CURSOR c_item_id_cur(v_item_no IN varchar2) IS
	SELECT inventory_item_id
	FROM mtl_system_items
	WHERE
		segment1 = v_item_no AND
		ROWNUM = 1;

/* Cursor to get the attribute values for the item status */
/* Status 1 = Set Value, 2 = Default Value, 3 = Not Used */
/* For status = 3 we will used hardcocded values for OPM */
CURSOR c_item_status (v_item_status IN mtl_system_items.inventory_item_status_code%TYPE) IS
	select
		v.ATTRIBUTE_NAME,
		decode(a.STATUS_CONTROL_CODE, 1, v.ATTRIBUTE_VALUE, 2, v.ATTRIBUTE_VALUE,
		decode(v.ATTRIBUTE_NAME, 'MTL_SYSTEM_ITEMS.BOM_ENABLED_FLAG', 'N', 'MTL_SYSTEM_ITEMS.BUILD_IN_WIP_FLAG',
		'N', 'Y')) ATTRIBUTE_VALUE
	from
		MTL_STATUS_ATTRIBUTE_VALUES v,
		MTL_ITEM_ATTRIBUTES a
	where
		v.ATTRIBUTE_NAME = a.ATTRIBUTE_NAME and
		v.INVENTORY_ITEM_STATUS_CODE = v_item_status;

/* Bug 1548457
Cursor to get ALLOW_ITEM_DESC_UPDATE_FLAG 
c_allow_item_desc_cur1 if org_id is not null
c_allow_item_desc_cur2 if org_id is null
*/
CURSOR c_allow_item_desc_cur1(v_org_id IN number) IS
	SELECT nvl(ALLOW_ITEM_DESC_UPDATE_FLAG, 'Y')
	FROM po_system_parameters_all
	WHERE
		org_id = v_org_id AND
		ROWNUM = 1;

CURSOR c_allow_item_desc_cur2 IS
	SELECT nvl(ALLOW_ITEM_DESC_UPDATE_FLAG, 'Y')
	FROM po_system_parameters_all
	WHERE
		org_id is null AND
		ROWNUM = 1;

/* Cursor to select discrete child organization, whose master level controlled attributes may 
   need to be updated. B2548269 */
/* Jalaj Srivastava Bug 3128085
   This cursor should also return process child orgs which are not defined in 
   gmi_item_organizations table. What we need to do is whenever a master org is updated   
   all child orgs should get updated with master level controlled attributes */
/*  Supriya Malluru  Bug 3685040
   Return only child orgs which are attached to the item. */   
CURSOR c_update_orgs ( pmaster_org number,pinventory_item_id number ) IS
	SELECT mp.organization_id, decode(mp.organization_id, pmaster_org, 0, 1) type
	FROM mtl_parameters mp
	WHERE
		mp.master_organization_id = pmaster_org and
		( mp.master_organization_id = mp.organization_id or 
		  not exists (select 1 
		              from   gmi_item_organizations gio
		              where  gio.organization_id = mp.organization_id
		             ) 
		)
        and exists (select 1
                    from   mtl_system_items_b
                    where  inventory_item_id = pinventory_item_id 
                    and    organization_id   = mp.organization_id
                   )
	UNION 
	SELECT pmaster_org , 0 FROM dual;

r_item_rec		c_item_cur%ROWTYPE;

/* Jalaj Srivastava Bug 3132893 
   This cursor would select discrete default category sets for OPM items  
   which are defined in mtl_item_categories but not in gmi_item_categories for 
   organizations/masters as defined in gmi_item_organizations table */
   
Cursor Cur_missing_def_cat_in_opm (V_opm_item_id NUMBER, V_odm_item_id NUMBER) IS 
  SELECT distinct mic.category_set_id category_set_id 
  FROM   mtl_item_categories mic, mtl_default_category_sets mdcs 
  WHERE  mic.inventory_item_id	= V_odm_item_id 
  AND    mdcs.category_set_id   = mic.category_set_id 
  AND    EXISTS 		(select 1 
                                 from   mtl_parameters mp, gmi_item_organizations gio 
                                 where  mp.organization_id = gio.organization_id 
                                 and    (    (mp.organization_id 	= mic.organization_id)
                                          OR (mp.master_organization_id	= mic.organization_id)
                                        ) 
                                ) 
  AND    NOT EXISTS             (select 1 
                                 from   gmi_item_categories 
                                 where  item_id		= V_opm_item_id 
                                 and    category_set_id	= mic.category_set_id 
                                );
                                
BEGIN

  GMI_DEBUG_UTIL.Println('Entering Item Synch Trigger.........');
  GMI_DEBUG_UTIL.Println('Calling gmf_sync.glsynch_initialize.........');

  gmf_sync_init.glsynch_initialize;
  GMI_DEBUG_UTIL.Println('After gmf_sync.glsynch_initialize.........');

  IF (gmf_session_vars.GMI_INSTALLED = 'I' AND
      (gmf_session_vars.INV_INSTALLED = 'I' OR gmf_session_vars.INV_INSTALLED = 'S')
     ) THEN --{
        GMI_DEBUG_UTIL.Println('In the If Condition of session Vars.........');
	/* B1325944
           Added these two lines to avoid mutating trigger issue in
           ic_item_mst_tl_biur_tg trigger */
	gmf_session_vars.item_id := :new.item_id;
        gmf_session_vars.item_no := :new.item_no;
        GMI_DEBUG_UTIL.Println('gmf_session_vars.item_id := '||
				gmf_session_vars.item_id);
        GMI_DEBUG_UTIL.Println('gmf_session_vars.item_no := '||
				gmf_session_vars.item_no);
        /* Get the default inventory status */
	v_inv_item_status_code := fnd_profile.value ('INV_STATUS_DEFAULT');
	
	GMI_DEBUG_UTIL.Println('v_inv_item_status_code := '|| v_inv_item_status_code);
	
	if (v_inv_item_status_code is NULL) THEN
	        GMI_DEBUG_UTIL.Println('v_inv_item_status_code is NULL,Raising an exception');
		RAISE ex_no_profile_option_value;
	END IF;
        
        GMI_DEBUG_UTIL.Println('Before the FOR loop to get the status' || 'attribute values');
	/* Now get the status attribute values */
	FOR r_item_status in c_item_status(v_inv_item_status_code) LOOP --{
	
	        GMI_DEBUG_UTIL.Println('r_item_status_attribute_name is :' || r_item_status.attribute_name);
                      
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
		 GMI_DEBUG_UTIL.Println('v_bom_enabled_flag :' || v_bom_enabled_flag);
                 GMI_DEBUG_UTIL.Println('v_purchasing_enabled_flag :' || v_purchasing_enabled_flag);
                 GMI_DEBUG_UTIL.Println('v_mtl_xactions_enabled_flag :' || v_mtl_xactions_enabled_flag);
                 GMI_DEBUG_UTIL.Println('v_stock_enabled_flag :'||  v_stock_enabled_flag);
                 GMI_DEBUG_UTIL.Println('v_build_in_wip_flag :'||v_build_in_wip_flag);
	END LOOP; --}
	
        /********************************* 
	 Jalaj Srivastava Bug 2302952
	 If the item is inactive in OPM 
	 it should be not be purchasable,
	 transactable etc. 
	 ******************************** */
      -- Bug 4143205
      -- Removed bom_enabled_flag and build_in_wip_flag.
      IF (:new.inactive_ind = 1) THEN --{
	     GMI_DEBUG_UTIL.Println('Item is Inactive. Setting all the flags to N');
	     v_purchasing_enabled_flag := 'N';
             v_mtl_xactions_enabled_flag := 'N';
             v_stock_enabled_flag := 'N';
	     v_customer_order_enabled_flag := 'N';
	     v_internal_order_enabled_flag := 'N';
	     v_invoice_enabled_flag := 'N';
      -- Bug 4143205
      -- Added else to turn on the functional areas if new.inactive_ind = 0.
      ELSIF (:new.inactive_ind = 0 and :old.inactive_ind = 1) THEN --}{
        v_purchasing_enabled_flag := 'Y';
        v_mtl_xactions_enabled_flag := 'Y';
        v_stock_enabled_flag := 'Y';
        v_customer_order_enabled_flag := 'Y';
        v_internal_order_enabled_flag := 'Y';
        v_invoice_enabled_flag := 'Y';
        GMI_DEBUG_UTIL.Println(':new.inactive_ind :' || :new.inactive_ind);
        GMI_DEBUG_UTIL.Println('v_bom_enabled_flag :' || v_bom_enabled_flag);
        GMI_DEBUG_UTIL.Println('v_purchasing_enabled_flag :' ||
                                v_purchasing_enabled_flag);
        GMI_DEBUG_UTIL.Println('v_mtl_xactions_enabled_flag :' ||
                                v_mtl_xactions_enabled_flag);
        GMI_DEBUG_UTIL.Println('v_stock_enabled_flag :'||
                                v_stock_enabled_flag);
        GMI_DEBUG_UTIL.Println('v_build_in_wip_flag :'||v_build_in_wip_flag);
        GMI_DEBUG_UTIL.Println('v_customer_order_enabled_flag :'||
                                v_customer_order_enabled_flag);
        GMI_DEBUG_UTIL.Println('v_internal_order_enabled_flag :'||
                                v_internal_order_enabled_flag);
        GMI_DEBUG_UTIL.Println('v_invoice_enabled_flag :'||
                                v_invoice_enabled_flag);
        GMI_DEBUG_UTIL.Println('v_inventory_item_flag :'||
                                v_inventory_item_flag);
      END IF; --}

      -- Bug 2698087
      -- Set the stock enabled, bom_enabled, build_in_wip and 
      -- mtl_transactions_enabled flags to 'N' for non inventory items.
      IF :new.noninv_ind = 1 THEN
         v_inventory_item_flag := 'N';
      END IF;
      /* Get the values dependent on inventory_item_flag */
      IF v_inventory_item_flag = 'N' THEN
         v_stock_enabled_flag := 'N';
         /***********************************************************************
          Jalaj Srivastava Bug 3646892
          Remove dependency of bom_enabled_flag on noninv_ind.
          ***********************************************************************/
          --v_bom_enabled_flag := 'N';
         v_build_in_wip_flag := 'N';
      END IF;
      /* Get values dependent on stock_enabled_flag */
      IF v_stock_enabled_flag = 'N' THEN
         v_mtl_xactions_enabled_flag := 'N';
      END IF;

	/* Generate the inventory_item_id if required */
	-- BEGIN BUG#3071034 Sastry
	-- Commented the following code and added code to get the
	-- inventory_item_id by calling the newly added function.
	/*OPEN c_item_id_cur(:new.item_no);
	FETCH c_item_id_cur INTO v_new_inventory_item_id;*/
	
	GMI_DEBUG_UTIL.PrintLn('Before Calling GMIUTILS.get_inventory_item_id');
	v_new_inventory_item_id := GMIUTILS.get_inventory_item_id(:new.item_no);	
	--IF c_item_id_cur%NOTFOUND  THEN
	IF v_new_inventory_item_id IS NULL THEN
		select mtl_system_items_s.nextval
		into v_new_inventory_item_id
		from dual;
	END IF;
	--CLOSE c_item_id_cur;
	--END BUG#3071034	
        GMI_DEBUG_UTIL.PrintLn('v_new_inventory_item_id :'|| v_new_inventory_item_id);
        
        IF (:new.dualum_ind IN (0,1)) THEN
            v_dual_uom_deviation_high := NULL; 
            v_dual_uom_deviation_low  := NULL; 
        ELSE
            v_dual_uom_deviation_high := :new.deviation_hi;
            v_dual_uom_deviation_low  := :new.deviation_lo;
        END IF;
        /* Bug 2263975 */
	IF (GML_PO_FOR_PROCESS.CHECK_PO_FOR_PROC) THEN
	    v_lot_control_code := :new.lot_ctl + 1;
	    v_location_control_code := :new.loct_ctl + 1;
        ELSE
	   v_lot_control_code := 1;
           v_location_control_code := 1;
        END IF;
        GMI_DEBUG_UTIL.PrintLn('v_lot_control_code :'|| v_lot_control_code);
        GMI_DEBUG_UTIL.PrintLn('v_location_control_code :'|| v_location_control_code);  
        
        --BEGIN BUG#3480063
	IF NVL(FND_PROFILE.VALUE('IC$USERORGSONLY'),'N') = 'Y' THEN
	   flg_item_user_orgs_only :='Y';
	ELSE 
	   flg_item_user_orgs_only :='N';
	END IF;
	GMI_DEBUG_UTIL.PrintLn('flg_item_user_orgs_only :'|| flg_item_user_orgs_only);
        --END BUG#3480063
  
        -- Bug 4222167 
        -- Cache the user_id in a local variable.
        v_user_id := FND_PROFILE.VALUE('USER_ID');
        GMI_DEBUG_UTIL.PrintLn('v_user_id :'|| v_user_id);
        -- Bug 4143205
        -- Added condition to check if inactive ind has changed.
        IF (:new.inactive_ind <> :old.inactive_ind) THEN
           is_inactive_ind_updated := 'Y';
        END IF;

        /* Loop thru all OPM linked inventory orgs */
	FOR r_inventory_org in c_inventory_org LOOP  --{
		<< try_to_fetch_item>>
		BEGIN
		        flg_item_to_be_updated := 'Y';
			OPEN c_item_cur(:new.item_no, r_inventory_org.organization_id);
			FETCH c_item_cur INTO r_item_rec;
			IF c_item_cur%NOTFOUND  THEN
			        GMI_DEBUG_UTIL.Println('In FOR LOOP r_inventory_org, Item not found');
				flg_item_to_be_updated := 'N';
			END IF;
           		CLOSE c_item_cur;
	   	END try_to_fetch_item;
                GMI_DEBUG_UTIL.Println('In FOR LOOP r_inventory_org After try to fetch item');
		<<get_account_codes>>
		BEGIN
		        GMI_DEBUG_UTIL.Println('In Block get_account_codes');
			SELECT	cost_of_sales_account,
		 		sales_account,
				expense_account,
				encumbrance_account
			INTO	v_cost_of_sales_account,
				v_sales_Account,
				v_expense_Account,
				v_encumbrance_account
			FROM 	mtl_parameters
			WHERE	organization_id = r_inventory_org.organization_id
			AND 	rownum = 1;

		EXCEPTION
			WHEN	others	THEN
				v_error_status := SQLCODE;
				v_error_text	:= SQLERRM;
				GMI_DEBUG_UTIL.PrintLn('Before Raising EXCEPTION '|| 'ex_no_account_codes_avlbl');
                                GMI_DEBUG_UTIL.PrintLn('r_inventory_org.organization_id '|| r_inventory_org.organization_id);
                                GMI_DEBUG_UTIL.PrintLn('v_error_status'|| v_error_status);
                                GMI_DEBUG_UTIL.PrintLn('v_error_text '|| v_error_text);
				RAISE	ex_no_account_codes_avlbl;
		END get_account_codes;

               /** MC BUG# 1554483   **/
               /** uom conversion change get unit_of_measure also along with uom_code **/
		<<get_primary_uom_code>>
		BEGIN
		        GMI_DEBUG_UTIL.PrintLn('In Block get_primary_uom_code');
			SELECT	b.uom_code,b.unit_of_measure
			INTO   	v_primary_uom_code,v_primary_unit_of_measure
			FROM    sy_uoms_mst a,mtl_units_of_measure b
			WHERE 	a.um_code = :new.item_um
                        AND     a.unit_of_measure = b.unit_of_measure;

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
				v_error_text	:= SQLERRM;
			       GMI_DEBUG_UTIL.PrintLn('Before Raising EXCEPTION '||'ex_no_primary_uom_code_avlbl');
                               GMI_DEBUG_UTIL.PrintLn(':new.item_um '|| :new.item_um);
                               GMI_DEBUG_UTIL.PrintLn(':new.item_um2 '|| :new.item_um2);
                               GMI_DEBUG_UTIL.PrintLn('v_error_status'|| v_error_status);
                               GMI_DEBUG_UTIL.PrintLn('v_error_text '|| v_error_text);
			RAISE  ex_no_primary_uom_code_avlbl;

		END get_primary_uom_code;

		  /* Item synchronization in mtl_system_items and ic_item_mst tables starts */
		/* get allow_item_desc_update_flag  - B 1548457 */
		IF (gmf_session_vars.PO_INSTALLED = 'I' AND
		    v_prev_org_id <> r_inventory_org.org_id) THEN
			IF (r_inventory_org.org_id IS NOT NULL) THEN
				OPEN c_allow_item_desc_cur1(r_inventory_org.org_id);
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
                
		IF (flg_item_to_be_updated = 'Y') THEN --{
			<<update_of_item>>
			BEGIN
			        GMI_DEBUG_UTIL.PrintLn('In the block update_of_item');
				/* Insert the item categories if it doesn't exists */
				/* Jatinder Gogna - 10/30/2001 - Bug 1900967 - Added logic to insert
				Item categories before the item update to ensure the mtl_system_items
				triggers do not fail. */
			        /* Jalaj Srivastava Bug 3132893. 
                                   We need to insert default categories only for those functional area categories 
                                   which are newly enabled */
                                   
                                /* if the org is master, the following cursor will also return 
				   the discrete and process child orgs.not defined in gmi_item_organizations. B2548269 
				 the loop below is opened so that default categories could be syncjed
				 in all orgs depending on the functional area and the attribute control */
				v_category_item_id :=  r_item_rec.inventory_item_id;
				
		                FOR r_update_orgs in c_update_orgs(r_inventory_org.organization_id,v_category_item_id ) LOOP --{ /* B3685040*/
	                           GMI_DEBUG_UTIL.PrintLn('In FOR LOOP r_update_orgs');
				/* The attributes should be updated as follow (B2548269):
					org type	control		Update
					0 (Process)	1 (Master)	Yes
					0		2 (Child)	Yes
					1 (Discrete)	1		Yes
					1		2		No  */
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
			       SELECT
			         v_category_item_id,
			         r_update_orgs.organization_id,
			         s.category_set_id,
			         s.default_category_id,
			         sysdate,
			         v_of_gemms_user_id,
			         sysdate,
			         v_of_gemms_user_id,
			         -1,
			         -1,
			         -1,
			         sysdate,
			         -1
			       FROM
			         mtl_category_sets_b  s
			       WHERE
			         s.category_set_id IN
			           ( SELECT  d.category_set_id
			             FROM  mtl_default_category_sets  d
			             WHERE 
			                  d.functional_area_id = DECODE(decode (r_update_orgs.type*i_inventory_item_flag, 2,'N',v_inventory_item_flag), 'Y', 1, 0 )
			               OR d.functional_area_id = DECODE(decode (r_update_orgs.type*i_purchasing_enabled_flag, 2,'N',v_purchasing_enabled_flag), 'Y', 2, 0 )
			               OR d.functional_area_id = DECODE(decode (r_update_orgs.type*i_internal_order_enabled_flag, 2,'N',v_internal_order_enabled_flag), 'Y', 2, 0 )
			               OR d.functional_area_id = DECODE(decode (r_update_orgs.type*i_costing_enabled_flag, 2,'N','Y'), 'Y', 5, 0 )
			               OR d.functional_area_id = DECODE(decode (r_update_orgs.type*i_customer_order_enabled_flag, 2,'N',v_customer_order_enabled_flag), 'Y', 7, 0 )
			               OR d.functional_area_id = DECODE(decode (r_update_orgs.type*i_customer_order_enabled_flag, 2,'N',v_customer_order_enabled_flag), 'Y', 11, 0 )
			               OR d.functional_area_id = DECODE(decode (r_update_orgs.type*i_internal_order_enabled_flag, 2,'N',v_internal_order_enabled_flag), 'Y', 11, 0 )
			           )
			         AND  s.default_category_id IS NOT NULL 
			         -- Check if the item already has any category assignment
			         AND NOT EXISTS
			           ( SELECT  'x'
			             FROM  mtl_item_categories mic
			             WHERE
			               mic.inventory_item_id     = v_category_item_id 
			               AND mic.organization_id   = r_update_orgs.organization_id 
			               AND mic.category_set_id   = s.category_set_id 						
			           );
                                 GMI_DEBUG_UTIL.PrintLn('After Inserting INTO mtl_item_categories');
   					
				/* The attributes should be updated as follow (B2548269):
					org type	control		Update
					0 (Process)	1 (Master)	Yes
					0		2 (Child)	Yes
					1 (Discrete)	1		Yes
					1		2		No  */
                      		
				/* Bug 3150286 */
				/* Do not update allow_item_desc_update_flag upon OPM item update*/
                                /* Bug 4143205 */
                                /* Update the flags controlled by item status only 
                                   if inactive_ind has changed */
			        /* Bug 4194374 */
                                /* Removed updates to tracking_quantity_ind, dual_uom_comtrol,
                                   m.secondary_uom_code, m.secondary_default_ind,m.ont_pricing_qty_source,
                                   m.dual_uom_deviation_high,m.dual_uom_deviation_low. */
                                /* Bug 4496150 */
                                /* Removed update to forecast_control_flag */  
                                /* Bug 5987702. Decode of is_inactive_ind_updated is removed during update of 
                                   stock_enabled_flag and mtl_transactions_enabled_flag so that these flags 
                                   are updated when the user changes both non-inventory and inactive attributes */

                                GMI_DEBUG_UTIL.PrintLn('Before Updating mtl_system_items_tl');
				UPDATE  mtl_system_items_b m
				SET	m.enabled_flag = decode(:new.delete_mark,1,'N','Y'),
                                        m.inventory_item_flag = decode(r_update_orgs.type*i_inventory_item_flag, 
                                                                       2, 
                                                                       m.inventory_item_flag,
                                                                       v_inventory_item_flag),				
					m.unit_of_issue = decode(r_update_orgs.type*i_primary_unit_of_measure, 
					                         2,
							         m.unit_of_issue, 
							         v_primary_unit_of_measure),
					m.primary_uom_code = decode(r_update_orgs.type*i_primary_uom_code, 
					                            2,
							            m.primary_uom_code, 
							            v_primary_uom_code),
					m.primary_unit_of_measure = decode(r_update_orgs.type*i_primary_unit_of_measure,
					                            2,
							            m.primary_unit_of_measure, 
							            v_primary_unit_of_measure),
					m.last_updated_by  = :new.last_updated_by,
					m.last_update_date = :new.last_update_date ,
					m.cost_of_sales_account = decode(r_update_orgs.type*i_cost_of_sales_account, 
					                                 2, 
					                                 m.cost_of_sales_account,  
						                         nvl(m.cost_of_sales_account, v_cost_of_sales_account)),
		 			m.sales_account = decode(r_update_orgs.type*i_sales_account,
		 			                         2, 
						                 m.sales_account, 
						                 nvl(m.sales_account, v_sales_account)),
					m.expense_account = decode(r_update_orgs.type*i_expense_account,
					                           2, 
						                   m.expense_account, 
						                   nvl(m.expense_account, v_expense_account)),
					m.encumbrance_account = decode(r_update_orgs.type*i_encumbrance_account, 
					                               2, 
					                               m.encumbrance_account, 
						                       nvl(m.encumbrance_account, v_encumbrance_account)),
					m.costing_enabled_flag = decode(r_update_orgs.type*i_costing_enabled_flag, 
					                                2, 
					                                m.costing_enabled_flag, 
					                                'Y'),
					m.inventory_asset_flag = decode(r_update_orgs.type*i_inventory_asset_flag, 
					                                2, 
					                                m.inventory_asset_flag,
						                        decode(:new.noninv_ind,
						                               0,
						                               'Y',
						                               'N')),
                                        m.description = decode (r_update_orgs.type*i_item_desc1, 
                                                                2,
								description, 
								:new.item_desc1),
                                        m.lot_control_code = decode(r_update_orgs.type*i_lot_control_code, 
                                                                    2,
								    m.lot_control_code, 
								    v_lot_control_code),
					m.auto_lot_alpha_prefix = decode(r_update_orgs.type*i_auto_lot_alpha_prefix, 
					                                 2, 
					                                 m.auto_lot_alpha_prefix, 
							                 nvl(m.auto_lot_alpha_prefix, 
								             decode(v_lot_control_code,
								                    2,
								                    'L',
								                    NULL))),
					m.start_auto_lot_number = decode(r_update_orgs.type*i_start_auto_lot_number, 
					                                 2, 
					                                 m.start_auto_lot_number, 
							                 nvl(m.start_auto_lot_number, 
								             decode(v_lot_control_code,
								                    2,
								                    1,
								                    NULL))),
					m.location_control_code = decode(r_update_orgs.type*i_location_control_code, 
					                                 2, 
					                                 m.location_control_code, 
							                 v_location_control_code), 
				    m.bom_enabled_flag = DECODE(v_inventory_item_flag, 
				                                'N',
                                                                decode(r_update_orgs.type*i_bom_enabled_flag,
                                                                       2,
                                                                       m.bom_enabled_flag,
                                                                       v_bom_enabled_flag),
                                                                m.bom_enabled_flag),
                                    m.purchasing_enabled_flag = DECODE(is_inactive_ind_updated, 
                                                                       'Y',
                                                                       decode(r_update_orgs.type*i_purchasing_enabled_flag,
                                                                       2,
                                                                       m.
                                                                       purchasing_enabled_flag,
                                                                       decode(m.purchasing_item_flag,
                                                                              'N',
                                                                              'N',
                                                                              v_purchasing_enabled_flag)),
                                                                       m.purchasing_enabled_flag),
                                    m.mtl_transactions_enabled_flag = DECODE(r_update_orgs.type*i_mtl_xactions_enabled_flag,
                                                                             2,
                                                                             m.mtl_transactions_enabled_flag,
                                                                             v_mtl_xactions_enabled_flag),
                                    m.stock_enabled_flag = DECODE(r_update_orgs.type*i_stock_enabled_flag,
                                                                  2,
                                                                  m.stock_enabled_flag,
                                                                  v_stock_enabled_flag),
                                    m.build_in_wip_flag  = DECODE(v_inventory_item_flag,
                                                                  'N',decode(r_update_orgs.type*i_build_in_wip_flag,
                                                                             2,
                                                                             m.build_in_wip_flag,
                                                                             v_build_in_wip_flag),
                                                                  m.build_in_wip_flag),
                                    m.customer_order_enabled_flag = DECODE(is_inactive_ind_updated,
                                                                           'Y',
                                                                           decode(r_update_orgs.type*i_customer_order_enabled_flag,
                                                                                  2,
                                                                                  m.customer_order_enabled_flag,
                                                                                  decode(m.customer_order_flag,
                                                                                         'N',
                                                                                         'N',
                                                                                         v_customer_order_enabled_flag)),
                                                                           m.customer_order_enabled_flag),
                                    m.internal_order_enabled_flag = DECODE(is_inactive_ind_updated,
                                                                           'Y',decode(r_update_orgs.type*i_internal_order_enabled_flag,
                                                                                      2,
                                                                                      m.internal_order_enabled_flag,
                                                                                      decode(m.internal_order_flag,
                                                                                      'N',
                                                                                      'N',
                                                                                      v_internal_order_enabled_flag)),
                                                                           m.internal_order_enabled_flag),
                                    m.invoice_enabled_flag = DECODE(is_inactive_ind_updated,
                                                                    'Y',
                                                                    decode(r_update_orgs.type*i_invoice_enabled_flag,
                                                                           2,
                                                                           m.invoice_enabled_flag,v_invoice_enabled_flag),
                                                                    m.invoice_enabled_flag)
			 	WHERE	organization_id   = r_update_orgs.organization_id 
				AND 	inventory_item_id = v_category_item_id;
					
				v_revision_item_id :=  r_item_rec.inventory_item_id;
                                flg_rev_item_to_be_updated := 'Y';
                                GMI_DEBUG_UTIL.PrintLn('After Updating mtl_system_items_b');
                                END LOOP; --}
                                GMI_DEBUG_UTIL.PrintLn('End of LOOP, End of Block update_of_item');
			END update_of_item;
		ELSE --}{
			<<insert_of_item>>
			BEGIN
                 /** MC BUG# 1554483  **/
                 /** pass unit_of_measure instead of item_um in pr_item_ins procedure  **/
                 /********************************************************************
                   Jalaj Srivastava Bug 2721118
                   For Master orgs the item create event is INSERT and for 
                   child orgs it is ORG_ASSIGN
                  ********************************************************************/ 
                                GMI_DEBUG_UTIL.PrintLn('Beginning of Block insert_of_item');
                                IF (r_inventory_org.org_type = 'M') THEN 
                                  v_mtl_event := 'INSERT';
                                ELSIF (r_inventory_org.org_type = 'P') THEN 
                                   v_mtl_event := 'ORG_ASSIGN';
                                END IF;
                  -- Bug 4194374
                  -- Insert secondary_uom_code as NULL, dual_uom_deviation_high/low as 0,
                  -- dual_uom_control as 0 and ont_pricing_qty_source as 0.
                  GMI_DEBUG_UTIL.PrintLn('Before Gmf_pr_item_ins.pr_item_ins');
				Gmf_pr_item_ins.pr_item_ins(v_new_inventory_item_id,
						r_inventory_org.organization_id,
						:new.item_no,
						:new.delete_mark,
						:new.inactive_ind,
						v_primary_unit_of_measure,
						:new.item_desc1,
						-- Bug 1122256
						:new.noninv_ind,
				  		v_primary_uom_code,
						v_of_gemms_user_id,
						v_cost_of_sales_account,
						v_sales_Account,
						v_inv_item_status_code,
						v_expense_Account,
						v_encumbrance_account,
						v_bom_enabled_flag,
						v_purchasing_enabled_flag,
						v_mtl_xactions_enabled_flag,
						v_stock_enabled_flag,
						v_build_in_wip_flag,
						v_customer_order_enabled_flag,
						v_internal_order_enabled_flag,
						v_invoice_enabled_flag,
                                                0,
                                                NULL,
                                                0,
                                                0,
                                                v_lot_control_code,
						v_location_control_code,
					        v_allow_item_desc_update_flag,
					        r_inventory_org.master_org_id, 
					        v_mtl_event,
					        :new.level_code, /* Jalaj Srivastava Bug 3158806 
                                                                    level code has mirror value of 
                                                                    ic_hold_days from ic_item_cpg */
                                                0, 
						v_error_text,
						v_error_status);

				/* 10/22/1999 CN  Replaced != with <> to confirm to standards
				 IF  v_error_status != 0 THEN */
				IF  v_error_status <> 0 THEN
				        GMI_DEBUG_UTIL.PrintLn('Before RAISE ex_unable_to_insert_item');
                                        GMI_DEBUG_UTIL.PrintLn('v_error_status'|| v_error_status);
					RAISE ex_unable_to_insert_item;
				END IF;
                        GMI_DEBUG_UTIL.PrintLn('END of Block insert_of_item');
			EXCEPTION
				WHEN ex_unable_to_insert_item THEN
					RAISE ex_unable_to_insert_item;
			END insert_of_item;
			
		END IF; --}  /* item_to_be_updated */

		/* Item synchronization in ic_item_mst and mtl_system_item  ENDS */
		IF (flg_rev_item_to_be_updated = 'Y') THEN
			<<check_item_in_rev>>
			BEGIN
			GMI_DEBUG_UTIL.PrintLn('Beginning of block check_item_in_rev');
				SELECT 	inventory_item_id
				INTO 	v_dummy_item_id
				FROM 	mtl_item_revisions
				WHERE 	organization_id = r_inventory_org.organization_id
				AND	inventory_item_id = v_revision_item_id
				AND     rownum = 1; /*BUG#3174722 Sastry - Added the condition rownum=1*/

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
			Gmf_pr_item_ins.pr_rev_item_ins(v_revision_item_id,
				r_inventory_org.organization_id,
				v_of_gemms_user_id,
				v_error_text,
				v_error_status);

			/* 10/22/1999 CN  Replaced != with <> to confirm to standards
			 IF  v_error_status != 0 THEN */
			IF  v_error_status <> 0 THEN
			        GMI_DEBUG_UTIL.PrintLn('Before Raising EXCEPTION '||
                                     'ex_unable_to_insert_rev_item');
                                GMI_DEBUG_UTIL.PrintLn('v_error_status '|| v_error_status);
				RAISE ex_unable_to_insert_rev_item;
			END IF;
		END IF;   /* revision_item_to_be_inserted */

	END LOOP; --}
	/* Jalaj Srivastava Bug 3132893. 
        --OK, the item went successfully
        --we would insert categories in OPM for the default category sets 
        --which are attached in mtl_item_categories for this item */
        
        <<insert_mtl_def_cat_in_opm>>
	BEGIN 
	GMI_DEBUG_UTIL.PrintLn('Begin block insert_mtl_def_cat_in_opm');
	  --lets fetch all distinct default category sets assigned to this item in discrete
	  --and not attached as yet in OPM.
	  FOR Cur_missing_def_cat_in_opm_rec IN Cur_missing_def_cat_in_opm(:new.item_id,v_new_inventory_item_id) LOOP --{
	    --now we need to get the category assigned to the default category sets
	    --remember, in OPM, item defintion is global vs. discrete where item definition is org specific
	    --to be able to insert in OPM, we need a consistent picture. i.e. we expect only one row to 
	    --be returned below.
            BEGIN	  
             SELECT distinct mic.category_id 
             INTO   v_category_id 
             FROM   mtl_item_categories mic 
             WHERE  mic.inventory_item_id	= v_new_inventory_item_id  
             AND    mic.category_set_id    	= Cur_missing_def_cat_in_opm_rec.category_set_id 
             AND    EXISTS 			(select 1 
                                 		 from   mtl_parameters mp, gmi_item_organizations gio 
                                 		 where  mp.organization_id = gio.organization_id 
                                 		 and    (    (mp.organization_id 	= mic.organization_id)
                                          		  OR (mp.master_organization_id	= mic.organization_id)
                                        		) 
                                		);     
            EXCEPTION
              --looks like different categories are attached to the same default category set  
              --in different orgs. 
              --Inconsistent picture, we have no option but to assign default category_id from mtl_category_sets
              --this would not affect assigned categories in discrete NOW. 
              --ONLY, when the user updates categories in OPM, then changes would be synched over to discrete. 
              --if default category does not exist then we would not insert in gmi_item_categories.
              --since we have nothing to insert.
              WHEN TOO_MANY_ROWS THEN    
                select default_category_id 
                INTO   v_category_id
                FROM   mtl_category_sets 
                WHERE  category_set_id	= Cur_missing_def_cat_in_opm_rec.category_set_id;                   		                                    		
            END;
            
            IF (v_category_id IS NOT NULL) THEN 
              GMI_DEBUG_UTIL.PrintLn('Before insert into gmi_item_categories');
              INSERT INTO gmi_item_categories 
                (
                 ITEM_ID, 
                 CATEGORY_SET_ID, 
                 CATEGORY_ID, 
                 CREATED_BY, 
                 CREATION_DATE, 
                 LAST_UPDATED_BY, 
                 LAST_UPDATE_DATE, 
                 LAST_UPDATE_LOGIN   
                )
              VALUES 
                (              
                 :new.item_id,
                 Cur_missing_def_cat_in_opm_rec.category_set_id,
                 v_category_id,
                 v_of_gemms_user_id,
                 sysdate,
                 v_of_gemms_user_id,
                 sysdate, 
                 :new.last_update_login
                );            
                GMI_DEBUG_UTIL.PrintLn('After insert into gmi_item_categories');
            END IF;
	  END LOOP; --}
	  GMI_DEBUG_UTIL.PrintLn('END block insert_mtl_def_cat_in_opm');
	END insert_mtl_def_cat_in_opm;        
  END IF; --} /* IF GMI AND INV(S, I) ARE INSTALLED */
  
  --Jalaj Srivastava Bug 2847159
  --trigger will now be a autonomous transaction which will commit itself.
  --This is done so that we can call INV_ITEM_PVT.Create_Item which issues savepoints 
  --not allowed in the trigger.
  --issue a commit to complete autonomous transactions
  
  -- 5499101 remove commit as we have removed autonomous transaction definition from this trigger
  -- COMMIT;

EXCEPTION
         --Jalaj Srivastava Bug 2847159
         --trigger will now be a autonomous transaction which will commit/rollback itself.
         --This is done so that we can call INV_ITEM_PVT.Create_Item which issues savepoints 
         --not allowed in the trigger.
         --issue a rollback for all exceptions
         
	 -- handle  ALL COULD_NOT exceptions
	  
	 -- B5398369 Need to remove BEGIN/END/Rollback since no longer autonomous trans
	 -- B5398369 Also now handle OTHERS exception

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
