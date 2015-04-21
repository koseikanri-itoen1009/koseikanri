--
--  Copyright (c) 1996 Oracle Corporation, Redwood Shores, CA, USA
--  All rights reserved.
--
--  FILENAME
--
--      INVTXMGB.pls
--
--  DESCRIPTION
--
--      BODY of  package INV_TXN_MANAGER_API
--      This file contains the body of the Inventory-Transactions-
--      Processor Wrapper to call Transaction Manager with record in MTI.
--
--
--  NOTES
--
--  HISTORY
--
--    02-AUG-01   rambrose         Created
--
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY INV_TXN_MANAGER_PUB AS
/* $Header: INVTXMGB.pls 115.107.115100.21 2009/11/11 16:12:23 juherber ship $ */

--------------------------------------------------
-- Private Procedures and Functions
--------------------------------------------------

g_pkg_name VARCHAR2(30) := 'INV_TXN_MANAGER_PUB';
g_interface_id NUMBER;
g_tree_id      NUMBER;

/** Following portion of the code is the common objects DECLARATION/DEFINITION
    that are used in the Package **/

l_error_code  VARCHAR2(3000);
l_error_exp   VARCHAR2(3000);
l_debug       number;


TYPE seg_rec_type IS RECORD
   (colname    varchar2(30),
    colvalue   varchar2(150));
TYPE bool_array IS TABLE OF NUMBER
  INDEX BY BINARY_INTEGER;


--client_info_org_id NUMBER := -1;
--pjm_installed NUMBER := -1;

TS_DEFAULT    NUMBER := 1;
TS_SAVE_ONLY  NUMBER := 2;
TS_PROCESS    NUMBER := 3;
SALORDER      NUMBER := 2;
INTORDER      NUMBER := 8;
MDS_RELIEF    NUMBER := 1;
MPS_RELIEF    NUMBER := 2; 


R_WORK_ORDER  NUMBER := 1; 
R_PURCH_ORDER NUMBER := 2; 
R_SALES_ORDER NUMBER := 3; 
TO_BE_PROCESSED NUMBER := 2;
NOT_TO_BE_PROCESSED NUMBER := 1;

--moved this to INVTXGGS.pls. 
--gi_flow_schedule NUMBER := 0 ;
g_true        NUMBER := 1;
g_false       NUMBER := 0;

g_userid NUMBER;


/*FUNCTION getitemid( itemid OUT NUMBER, orgid IN NUMBER, rowid VARCHAR2);
FUNCTION getacctid( acct OUT nocopy NUMBER, orgid IN NUMBER, rowid VARCHAR2);
FUNCTION setorgclientinfo(orgid IN NUMBER);
FUNCTION getlocid(locid OUT nocopy NUMBER, orgid IN NUMBER, subinv NUMBER,
                        rowid VARCHAR2, locctrl NUMBER);
FUNCTION getxlocid(locid OUT nocopy  NUMBER, orgid IN NUMBER, subinv IN VARCHAR2,
                        rowid IN VARCHAR2, locctrl IN NUMBER);
FUNCTION getsrcid(trxsrc OUT nocopy  NUMBER, srctype IN NUMBER, orgid IN NUMBER, 
                        rowid IN VARCHAR2);
PROCEDURE errupdate(rowid IN VARCHAR2);
FUNCTION lotcheck(rowid IN VARCHAR2, orgid IN NUMBER, itemid IN NUMBER, intid IN NUMBER,
                      priuom IN VARCHAR2, trxuom VARCHAR2, lotuniq IN NUMBER,
                      shlfcode IN NUMBER, shlfdays IN NUMBER, serctrl IN NUMBER,
			    srctype IN NUMBER, acttype IN NUMBER);
FUNCTION validate_loc_for_project(ltv_locid IN NUMBER, ltv_orgid IN NUMBER,
                                     ltv_srctype IN NUMBER, ltv_trxact IN NUMBER, 
                                     ltv_trx_src_id IN NUMBER, tev_flow_schedule  IN NUMBER);
FUNCTION validate_unit_number(unit_number IN NUMBER, orgid IN NUMBER,
                                 itemid IN NUMBER, srctype IN NUMBER, acttype IN NUMBER);
*/


TYPE seg_arr_type IS TABLE OF seg_rec_type INDEX BY BINARY_INTEGER;

--TYPE segment_array IS TABLE OF segment_rec_type INDEX BY BINARY_INTEGER;

TYPE segment_array IS TABLE OF VARCHAR2(200);


/******************************************************************
 *
 * loaderrmsg
 *
 ******************************************************************/
PROCEDURE loaderrmsg(mesg1 IN VARCHAR2, mesg2 IN VARCHAR2) IS
BEGIN
      fnd_message.set_name('INV', mesg1);
      l_error_code := fnd_message.get;

      fnd_message.set_name('INV', mesg2);
      l_error_exp := fnd_message.get;
END;

/*******************************************************************
 * LotTrxInsert(p_transaction_interface_id IN NUMBER)
 * Added this function to process lot split, merge and translate.
   * As part of J-dev, we will bypass this API.
   * This API has been onbsoleted.
   * we will use tmpinsert() to move records.
 *******************************************************************/

  

/** end of lot transactions changes **/

/******************************************************************
 * Check_Partial_Split - private procedure to check if the lot split
 * transaction is a partial split, i.e., there are remaining qty 
 * in the parent lots. In this case, we need to insert additional
 * record in mmtt for the remaining qty 
 * This procedure assumes that the primary qty is already calculated
 * and the qty comparison is done with the primary qty.
 * This procedure is called after calling LotTrxInsert
 * As part of J-dev, we will use tmpInsert to
 * move lot transaction records from MTI to MMTT. (also for I)
 * Some changes have been made in this API  for I + J, to enable bulk
 * insert. do not re-insert the parent transaction.
 *  do not insert into MMTT here, but into MTI only, if we are
 *  creating a new record for this transaction    
 *******************************************************************/
Function Check_Partial_Split(
    p_parent_id 	IN NUMBER,
    p_current_index     IN NUMBER
) RETURN boolean
IS
    cursor mti_csr(p_interface_id NUMBER) IS
       select mti.transaction_header_id,
	 mti.acct_period_id,
	 mti.distribution_account_id,
	 mti.transaction_interface_id,
	 mti.transaction_Type_id,
         mti.source_code, /*Bug:5026331. Populating non-null columns*/
         mti.source_line_id,
         mti.source_header_id,
	 mti.inventory_item_id,
	 mti.revision,
	 mti.organization_id,
	 mti.subinventory_code,
	 mti.locator_id,
	 mti.transaction_quantity,
	 mti.primary_quantity,
	 mti.transaction_uom,
	 mti.lpn_id,
	 mti.transfer_lpn_id,
	 mti.cost_group_id,
	 mti.transaction_source_type_id,
	 mti.transaction_Action_id,
	 mti.parent_id,
	 mti.created_by,
	 mtli.lot_number,
	 mtli.lot_expiration_date,
	 mtli.description,
	 mtli.vendor_id,
	 mtli.supplier_lot_number,
	 mtli.territory_code,
	 mtli.grade_code,
	 mtli.origination_date,
	 mtli.date_code,
	 mtli.status_id,
	 mtli.change_date,
	 mtli.age,
	 mtli.retest_date,
	 mtli.maturity_date,
	 mtli.lot_attribute_category,
	 mtli.item_size,
	 mtli.color,
	 mtli.volume,
	 mtli.volume_uom,
	 mtli.place_of_origin,
	 mtli.best_by_date,
	 mtli.length,
	 mtli.length_uom,
	 mtli.recycled_content,
	 mtli.thickness,
	 mtli.thickness_uom,
	 mtli.width,
	 mtli.width_uom,
	 mtli.curl_wrinkle_fold,
	 mtli.c_attribute1,
	 mtli.c_Attribute2,
	 mtli.c_attribute3,
	 mtli.c_attribute4,
	 mtli.c_attribute5,
	 mtli.c_attribute6,
	 mtli.c_attribute7,
	 mtli.c_attribute8,
	 mtli.c_attribute9,
	 mtli.c_attribute10,
	 mtli.c_attribute11,
	 mtli.c_attribute12,
	 mtli.c_attribute13,
	 mtli.c_attribute14,
	 mtli.c_attribute15,
	 mtli.c_attribute16,
	 mtli.c_attribute17,
	 mtli.c_attribute18,
	 mtli.c_attribute19,
	 mtli.c_attribute20,
	 mtli.d_attribute1,
	 mtli.d_attribute2,
	 mtli.d_attribute3,
	 mtli.d_attribute4,
	 mtli.d_attribute5,
	 mtli.d_attribute6,
	 mtli.d_attribute7,
	 mtli.d_attribute8,
	 mtli.d_attribute9,
	 mtli.d_attribute10,
	 mtli.n_attribute1,
	 mtli.n_attribute2,
	 mtli.n_attribute3,
	 mtli.n_attribute4,
	 mtli.n_attribute5,
	 mtli.n_attribute6,
	 mtli.n_attribute7,
	 mtli.n_attribute8,
	 mtli.n_attribute9,
	 mtli.n_attribute10,
	 mtli.attribute1,
	 mtli.attribute2,
	 mtli.attribute3,
	 mtli.attribute4,
	 mtli.attribute5,
	 mtli.attribute6,
	 mtli.attribute7,
	 mtli.attribute8,
	 mtli.attribute9,
	 mtli.attribute10,
	 mtli.attribute11,
	 mtli.attribute12,
	 mtli.attribute13,
	 mtli.attribute14,
	 mtli.attribute15,
	 mtli.attribute_category,
	 msi.description item_description,
	 msi.location_control_code,
	 msi.restrict_subinventories_code,
	 msi.restrict_locators_code,
	 msi.revision_qty_control_code,
	 msi.primary_uom_code,
	 msi.shelf_life_code,
	 msi.shelf_life_days,
	 msi.allowed_units_lookup_code,
	 mti.transaction_batch_id,
	 mti.transaction_batch_seq,
	 mti.kanban_card_id,
	 mti.transaction_mode --J-dev
	 FROM MTL_TRANSACTIONS_INTERFACE MTI,
	 MTL_TRANSACTION_LOTS_INTERFACE MTLI,
	 MTL_SYSTEM_ITEMS_B MSI
	 WHERE mti.transaction_interface_id = p_interface_id
	 AND MTI.transaction_interface_id = mtli.transaction_interface_id
	 AND MTI.organization_id = msi.organization_id
	 AND mti.inventory_item_id = msi.inventory_item_id
	 and mti.process_flag = 1;
    l_count NUMBER := 0;
    l_partial_total_qty NUMBER :=0;
    l_remaining_qty NUMBER := 0;
    l_split_qty NUMBER := 0;
    l_split_uom VARCHAR2(3);
    l_transaction_interface_id NUMBER; --J-dev
BEGIN
   
   SELECT count(parent_id)
     INTO   l_count
     FROM   mtl_transactions_interface
     WHERE  parent_id = p_parent_id;
   
   SELECT abs(primary_quantity)
     INTO   l_split_qty
     FROM   mtl_transactions_interface
     WHERE  transaction_interface_id = p_parent_id;
   
   SELECT sum(abs(primary_quantity))
     INTO l_partial_total_qty 
     FROM   mtl_transactions_interface
     WHERE  parent_id = p_parent_id
     AND    transaction_interface_id <> p_parent_id;
   
   l_remaining_qty := l_split_qty - l_partial_total_qty;
   
   if( p_current_index = l_count AND  l_remaining_qty > 0 ) then
      select mtl_material_transactions_s.nextval
	into l_transaction_interface_id --J-dev
	FROM dual;
      for l_mti_csr in mti_csr(p_parent_id ) LOOP
	 IF (l_debug = 1) THEN
	    inv_log_util.trace('insert into mmti is ' || l_mti_csr.transaction_interface_id, 'INV_TXN_MANAGER_PUB', 9);
	 END IF;

	    INSERT INTO   mtl_transactions_interface
	      ( transaction_header_id ,
		transaction_interface_id ,
		transaction_mode ,
		lock_flag ,
		source_code, /*Bug:5026331.Populating non-null columns */
                source_line_id,
                source_header_id,
                Process_flag
		,last_update_date ,
		last_updated_by ,
		creation_date ,
		created_by ,
		last_update_login
		,request_id ,
		program_application_id ,
		program_id ,
		program_update_date
		,inventory_item_id ,
		revision ,
		organization_id
		,subinventory_code ,
		locator_id
		,transaction_quantity ,
		primary_quantity ,
		transaction_uom
		,transaction_type_id ,
		transaction_action_id ,
		transaction_source_type_id
		,transaction_date ,
		acct_period_id ,
		distribution_account_id,
		/*item_description ,
		item_location_control_code ,
		item_restrict_subinv_code
		,item_restrict_locators_code ,
		item_revision_qty_control_code ,
		item_primary_uom_code
		,item_shelf_life_code ,
		item_shelf_life_days ,
		item_lot_control_code
		,item_serial_control_code ,
		allowed_units_lookup_code,*/--J-dev not in MTI
		parent_id,--J-dev
		lpn_id ,
		transfer_lpn_id
		,cost_group_id,
		transaction_batch_id,
	      transaction_batch_seq,
	      kanban_card_id)
	      VALUES
	      ( l_mti_csr.transaction_header_id,
		l_transaction_interface_id,--J-dev
		l_mti_csr.transaction_mode /*2722754 */,
		2,--J-dev
                l_mti_csr.source_code, /*Bug:5026331.Populating non-null columns */
                l_mti_csr.source_line_id,
                l_mti_csr.source_header_id,
		1,--J-dev
		sysdate,
		l_mti_csr.created_by,
		sysdate,
		l_mti_csr.created_by,
		l_mti_csr.created_by,
		NULL,
		NULL,
		NULL,
		NULL,
		l_mti_csr.inventory_item_id,
		l_mti_csr.revision,
		l_mti_csr.organization_id,
		l_mti_csr.subinventory_code,
		l_mti_csr.locator_id,
		l_remaining_qty,
		l_remaining_qty,
		l_mti_csr.primary_uom_code,
		l_mti_csr.transaction_type_id,
		l_mti_csr.transaction_action_id,
		l_mti_csr.transaction_source_type_id,
		sysdate,
		l_mti_csr.acct_period_id,
		l_mti_csr.distribution_account_id,
		/*l_mti_csr.item_description,
		l_mti_csr.location_control_code,
		l_mti_csr.restrict_subinventories_code,
		l_mti_csr.restrict_locators_code,
		l_mti_csr.revision_qty_control_code,
		l_mti_csr.primary_uom_code,
		l_mti_csr.shelf_life_code,
		l_mti_csr.shelf_life_days,
		2,
		1,
		l_mti_csr.allowed_units_lookup_code,*/--J-dev Not in MTI
	      l_mti_csr.parent_id,
	      null, /*Bug:5026331.Removed l_mti_csr.lpn_id for lpn_id and using that for transfer_lpn_id below.*/
	      l_mti_csr.lpn_id,
	      l_mti_csr.cost_group_id,
	      l_mti_csr.transaction_batch_id,
	      l_mti_csr.transaction_batch_seq,
	      l_mti_csr.kanban_card_id);
	    INSERT  INTO mtl_transaction_lots_interface
	      (transaction_interface_id --J-dev
	       ,last_update_date ,
	    last_updated_by ,
	    creation_date ,
	    created_by ,
	    last_update_login
            ,request_id ,
	    program_application_id ,
	    program_id ,
	       program_update_date
	       ,transaction_quantity ,
	       primary_quantity
	       ,lot_number ,
	       lot_expiration_date
	       ,description ,
	       vendor_id ,
	       supplier_lot_number ,
	       territory_code 
	       ,grade_code ,
	       origination_date ,
	       date_code 
	       ,status_id ,
	       change_date ,
	       age ,
	       retest_date
	       ,maturity_date ,
	       lot_attribute_category ,
	       item_size 
	       ,color ,
	       volume ,
	       volume_uom
	       ,place_of_origin ,
	       best_by_date ,
	       length ,
	       length_uom 
	       ,recycled_content ,
	       thickness ,
	       thickness_uom 
	       ,width ,
	       width_uom ,
	       curl_wrinkle_fold
	       ,c_attribute1 ,
	       c_attribute2 ,
	      c_attribute3 ,
	      c_attribute4 ,
	      c_attribute5
	      ,c_attribute6 ,
	      c_attribute7 ,
	      c_attribute8 ,
	      c_attribute9 ,
	      c_attribute10
	      ,c_attribute11 ,
	      c_attribute12 ,
	      c_attribute13 ,
	      c_attribute14 ,
	      c_attribute15
	      ,c_attribute16 ,
	      c_attribute17 ,
	      c_attribute18 ,
	      c_attribute19 ,
	      c_attribute20
	      ,d_attribute1 ,
	      d_attribute2 ,
	      d_attribute3 ,
	      d_attribute4 ,
	      d_attribute5
	      ,d_attribute6 ,
	      d_attribute7 ,
	      d_attribute8 ,
	      d_attribute9 ,
	      d_attribute10
	      ,n_attribute1 ,
	      n_attribute2 ,
	      n_attribute3 ,
	      n_attribute4 ,
	      n_attribute5
	      ,n_attribute6 ,
	      n_attribute7 ,
	      n_attribute8 ,
	      n_attribute9 ,
	      n_attribute10 ,
	      attribute1 ,
	      attribute2,
	      attribute3,
	      attribute4,
	      attribute5,
	      attribute6,
	      attribute7,
	      attribute8,
	      attribute9,
	      attribute10,
	      attribute11,
	      attribute12,
	      attribute13,
	      attribute14,
	      attribute15,
	      attribute_category )
	      VALUES
	      ( l_transaction_interface_id,
		SYSDATE,
		l_mti_csr.created_by,
		SYSDATE,
		l_mti_csr.created_by,
		l_mti_Csr.created_by,
		NULL,
		NULL,
		NULL,
		NULL,
		l_remaining_qty,
		l_remaining_qty,
		l_mti_csr.lot_number,
		l_mti_csr.lot_expiration_date,
		l_mti_csr.description,
		l_mti_csr.vendor_id,
		l_mti_csr.supplier_lot_number,
		l_mti_csr.territory_code,
		l_mti_csr.grade_code,
		l_mti_csr.origination_date,
		l_mti_csr.date_code,
		l_mti_csr.status_id,
		l_mti_csr.change_date,
		l_mti_csr.age,
		l_mti_csr.retest_date,
		l_mti_csr.maturity_date,
		l_mti_csr.lot_attribute_category,
		l_mti_csr.item_size,
		l_mti_csr.color,
		l_mti_csr.volume,
		l_mti_csr.volume_uom,
		l_mti_csr.place_of_origin,
		l_mti_csr.best_by_date,
		l_mti_csr.length,
		l_mti_csr.length_uom,
		l_mti_csr.recycled_content,
		l_mti_csr.thickness,
		l_mti_csr.thickness_uom,
		l_mti_csr.width,
		l_mti_csr.width_uom,
		l_mti_csr.curl_wrinkle_fold,
		l_mti_csr.c_attribute1,
		l_mti_csr.c_attribute2,
		l_mti_csr.c_attribute3,
	      l_mti_csr.c_attribute4,
	      l_mti_csr.c_attribute5,
	      l_mti_csr.c_attribute6,
	      l_mti_csr.c_attribute7,
	      l_mti_csr.c_attribute8,
	      l_mti_csr.c_attribute9,
	      l_mti_csr.c_attribute10,
	      l_mti_csr.c_attribute11,
	      l_mti_csr.c_attribute12,
	      l_mti_csr.c_attribute13,
	      l_mti_csr.c_attribute14,
	      l_mti_csr.c_attribute15,
	      l_mti_csr.c_attribute16,
	      l_mti_csr.c_attribute17,
	      l_mti_csr.c_attribute18,
	      l_mti_csr.c_attribute19,
	      l_mti_csr.c_attribute20,
	      l_mti_csr.d_attribute1,
	      l_mti_csr.d_attribute2,
	      l_mti_csr.d_attribute3,
	      l_mti_csr.d_attribute4,
	      l_mti_csr.d_attribute5,
	      l_mti_csr.d_attribute6,
	      l_mti_csr.d_attribute7,
	      l_mti_csr.d_attribute8,
	      l_mti_csr.d_attribute9,
	      l_mti_csr.d_attribute10,
	      l_mti_csr.n_attribute1,
	      l_mti_csr.n_attribute2,
	      l_mti_csr.n_attribute3,
	      l_mti_csr.n_attribute4,
	      l_mti_csr.n_attribute5,
	      l_mti_csr.n_attribute6,
	      l_mti_csr.n_attribute7,
	      l_mti_csr.n_attribute8,
	      l_mti_csr.n_attribute9,
	      l_mti_csr.n_attribute10,
	      l_mti_csr.attribute1,
	      l_mti_csr.attribute2,
	      l_mti_csr.attribute3,
	      l_mti_csr.attribute4,
	      l_mti_csr.attribute5,
	      l_mti_csr.attribute6,
	      l_mti_csr.attribute7,
	      l_mti_csr.attribute8,
	      l_mti_csr.attribute9,
	      l_mti_csr.attribute10,
	      l_mti_csr.attribute11,
	      l_mti_csr.attribute12,
	      l_mti_csr.attribute13,
	      l_mti_csr.attribute14,
	      l_mti_csr.attribute15,
	     l_mti_csr.attribute_category);

      END LOOP;
   END if;
   return true;
EXCEPTION
   when FND_API.G_EXC_ERROR then
      IF (l_debug = 1) THEN
       inv_log_util.trace('SQL : ' || substr(sqlerrm, 1, 200), 'INV_TXN_MANAGER_PUB','9');
       inv_log_util.trace('Error in check_partial_split : ' || l_error_exp, 'INV_TXN_MANAGER_PUB','9');
    END IF;
	return FALSE;
   when Others  then
    IF (l_debug = 1) THEN
       inv_log_util.trace('SQL : ' || substr(sqlerrm, 1, 200), 'INV_TXN_MANAGER_PUB','9');
       inv_log_util.trace('Error in check_partial_split : ' || l_error_exp, 'INV_TXN_MANAGER_PUB','9');
    END IF;
	return false;
END Check_Partial_Split;


 /* getacctid()
 * moved to group API INV_TXN_MANAGER_GRP()
 ******************************************************************/



/******************************************************************
-- Procedure moved to group api INV_TXN_MANAGER_GRP
--   getitemid
-- Description
--   find the item_id using the flex field segments
-- Output Parameters
--   x_item_id   locator or null if error occurred
 ******************************************************************/

 /******************************************************************
 -- Procedure moved to group api INV_TXN_MANAGER_GRP
 --   getsrcid
 -- Description
 --   find the Source ID using the flex field segments
 -- Output Parameters
 --   x_trxsrc   transaction source id or null if error occurred
 ******************************************************************/


/******************************************************************
 *
 * errupdate()
 *
 ******************************************************************/

PROCEDURE errupdate(p_rowid in varchar2)
IS

 l_userid  NUMBER := -1; -- = prg_info.userid;
 l_reqstid  NUMBER := -1; -- = prg_info.reqstid;
 l_applid  NUMBER := -1; -- = prg_info.appid;
 l_progid  NUMBER := -1; -- = prg_info.progid;
 l_loginid  NUMBER := -1; --= prg_info.loginid;
BEGIN

    -- WHENEVER NOT FOUND CONTINUE;

    UPDATE MTL_TRANSACTIONS_INTERFACE
       SET ERROR_CODE = substrb(l_error_code,1,240),
           ERROR_EXPLANATION = substrb(l_error_exp,1,240),
           LAST_UPDATE_DATE = sysdate,
           LAST_UPDATED_BY = l_userid,
           LAST_UPDATE_LOGIN = l_loginid,
           PROGRAM_UPDATE_DATE = SYSDATE,
           PROCESS_FLAG = 3,
           LOCK_FLAG = 2
     WHERE ROWID = p_rowid;

    return;

EXCEPTION
  WHEN OTHERS THEN
        RETURN;
END errupdate;



/******************************************************************
-- Procedure (moved to group api INV_TXN_MANAGER_GRP)
--   derive_segment_ids
-- Description
--   derive segment-ids  based on segment values 
-- Output Parameters
--   
 ******************************************************************/


/******************************************************************
 *
 * validate_group
 * Validate a group of MTI records in a batch together
   
 * J-dev (WIP related validations)
   * Actual implemetation is mved to INV_TXN_MANAGER_GRP(INVTXGGB.pls)
   * The public spec here, does not accept p_validation_level.
   * if p_validation_level is to be used, the group api has to be invoked.
 ******************************************************************/
   PROCEDURE validate_group(
			    p_header_id NUMBER,
			    x_return_status OUT NOCOPY VARCHAR2, 
			    x_msg_count OUT NOCOPY NUMBER,
			    x_msg_data OUT NOCOPY VARCHAR2,
			    p_userid NUMBER, 
			    p_loginid NUMBER)
			    
   IS
      
      srctypeid   NUMBER;
      tvu_flow_schedule  VARCHAR2(50);
      tev_scheduled_flag NUMBER;
      flow_schedule_children   VARCHAR2(50);
      l_count  NUMBER;
      l_profile VARCHAR2(100);
      EXP_TO_AST_ALLOWED NUMBER;
      EXP_TYPE_REQUIRED NUMBER;
      NUMHOLD NUMBER:=0;
      l_return_status VARCHAR2(10) :=FND_API.G_RET_STS_SUCCESS;
      l_msg_count NUMBER;
      l_msg_data VARCHAR2(2000);
   BEGIN
      if (l_debug is null) then
	 l_debug := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
      end if;

      inv_txn_manager_grp.validate_group(p_header_id => p_header_id,
					 x_return_status =>l_return_status,
					 x_msg_count =>l_msg_count,
					 x_msg_data => l_msg_data,
                                         p_userid =>p_userid,
                                         p_loginid => p_loginid,
					 p_validation_level =>
					 fnd_api.g_valid_level_full);
      x_return_status := l_return_status;
      x_msg_count := l_msg_count;
      x_msg_data := l_msg_data;
      IF (l_return_status = FND_API.g_ret_sts_success) THEN

	 x_return_status := FND_API.G_RET_STS_SUCCESS;
	 --Bug: 3559328: Performance bug fix. The fnd API to clear is
	 --already called in the private API. Since this is just a wrapper,
	 --we do not need to call it here as it would alreday have been cleared
	 --FND_MESSAGE.clear;
      END IF;
     
EXCEPTION
    WHEN OTHERS THEN
       IF (l_debug = 1) THEN
          inv_log_util.trace('Error in validate_group : ' || l_error_exp, 'INV_TXN_MANAGER_PUB','1');
          inv_log_util.trace('Error:'||substr(sqlerrm,1,250),'INV_TXN_MANAGER_PUB',1);
       END IF;
       x_return_status := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.clear;

END validate_group;





/******* LINE VALIDATION OBJECTS  ***************/

/******************************************************************
 *
 * lotcheck moved to group API INV_TXN_MANAGER_GRP
 *
 ******************************************************************/

        


/******************************************************************
 *
 * setorgclientinfo() moved to group API INV_TXN_MANAGER_GRP
 *
 ******************************************************************/


/******************************************************************
-- Function moved to INV_TXN_MANAGER_GRP
--   getloc
-- Description
--   Private function to get Locator id using Flex API's
--   Uses FND_FLEX_KEY_API (AFFFKAIS/B.pls) and 
--        FND_FLEX_EXT (AFFFEXTS/B.pls)
--
--   Assumes that only Id's are populated in the MTI segments
--
-- Returns
--   Returns false if any error occurs
-- Output Parameters
--   x_locid   locator or null if error occurred
 ******************************************************************/


/******************************************************************
-- Function moved to INV_TXN_MANAGER_GRP
--   getlocid
-- Description
--   find the locator using the flex field segments
--   Calls private function getLoc to do the work
-- Output Parameters
--   x_locator   locator or null if error occurred
 ******************************************************************/


/******************************************************************
-- Function moved to INV_TXN_MANAGER_GRP
--   getxlocid
-- Description
--   find the locator using the flex field segments
--   Calls private function getLoc to do the work
-- Output Parameters
--   x_locator   locator or null if error occurred
 ******************************************************************/




/******************************************************************
 *
   * validate_loc_for_project()
   * moved to INV_TXN_MANAGER_GRP
 *
 ******************************************************************/



/******************************************************************
 *
   * validate_unit_number()
   * moved to INV_TXN_MANAGER_GRP
 *
 ******************************************************************/



/******************************************************************
 *
 * validate_lines() : Outer
 *
 ******************************************************************/
PROCEDURE validate_lines(p_header_id NUMBER, 
                 	 p_commit VARCHAR2 := fnd_api.g_false     ,
                 	 p_validation_level NUMBER  := fnd_api.g_valid_level_full  ,
                         x_return_status OUT NOCOPY VARCHAR2,
                         x_msg_count OUT NOCOPY NUMBER,
                         x_msg_data OUT NOCOPY VARCHAR2,
                         p_userid NUMBER, 
                         p_loginid NUMBER, 
                         p_applid NUMBER, 
                         p_progid NUMBER)
AS

    CURSOR AA1 IS
    SELECT 
        TRANSACTION_INTERFACE_ID,
        TRANSACTION_HEADER_ID,
        REQUEST_ID,
        INVENTORY_ITEM_ID,
        ORGANIZATION_ID,
        SUBINVENTORY_CODE,
        TRANSFER_ORGANIZATION,
        TRANSFER_SUBINVENTORY,
        TRANSACTION_UOM,
        TRANSACTION_DATE,
        TRANSACTION_QUANTITY,
        LOCATOR_ID,
        TRANSFER_LOCATOR,
        TRANSACTION_SOURCE_ID,
        TRANSACTION_SOURCE_TYPE_ID,
        TRANSACTION_ACTION_ID,
        TRANSACTION_TYPE_ID,
        DISTRIBUTION_ACCOUNT_ID,
        NVL(SHIPPABLE_FLAG,'Y'),
        ROWID,
	NEW_AVERAGE_COST,
	VALUE_CHANGE,
	PERCENTAGE_CHANGE,
	MATERIAL_ACCOUNT,
	MATERIAL_OVERHEAD_ACCOUNT,
	RESOURCE_ACCOUNT,
	OUTSIDE_PROCESSING_ACCOUNT,
	OVERHEAD_ACCOUNT,
        REQUISITION_LINE_ID,
        OVERCOMPLETION_TRANSACTION_QTY,   /* Overcompletion Transactions */
        END_ITEM_UNIT_NUMBER,
        SCHEDULED_PAYBACK_DATE, /* Borrow Payback */
        REVISION,   /* Borrow Payback */
        ORG_COST_GROUP_ID,  /* PCST */
        COST_TYPE_ID, /* PCST */
        PRIMARY_QUANTITY,
        SOURCE_LINE_ID,
        PROCESS_FLAG,
        TRANSACTION_SOURCE_NAME,
	TRX_SOURCE_DELIVERY_ID,
	TRX_SOURCE_LINE_ID,
	PARENT_ID,
	TRANSACTION_BATCH_ID,
	TRANSACTION_BATCH_SEQ
    FROM MTL_TRANSACTIONS_INTERFACE
    WHERE TRANSACTION_HEADER_ID = p_header_id
      AND PROCESS_FLAG = 1
    ORDER BY ORGANIZATION_ID,INVENTORY_ITEM_ID,REVISION,
          SUBINVENTORY_CODE,LOCATOR_ID;


   line_vldn_error_flag VARCHAR(1);
   l_Line_Rec_Type Line_Rec_Type;
   l_count number;
  
BEGIN
    if ( l_debug is null) then
       l_debug := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
    end if;

    fnd_flex_key_api.set_session_mode('seed_data');

     FOR l_Line_rec_Type IN AA1 LOOP
       BEGIN
         savepoint line_validation_svpt;
	 validate_lines(p_line_Rec_Type => l_Line_rec_type,
			p_commit => p_commit,
			p_validation_level => p_validation_level,
			p_error_flag => line_vldn_error_flag,
			p_userid => p_userid,
			p_loginid => p_loginid,
			p_applid => p_applid,
			p_progid => p_progid); 
	 IF (line_vldn_error_flag = 'Y') then
	    IF (l_debug = 1) THEN
	       inv_log_util.trace('Error in Line Validatin', 'INV_TXN_MANAGER_PUB', 9);
	    END IF;
	 END IF;
	 
       END;
     END LOOP;
     
     x_return_status := FND_API.G_RET_STS_SUCCESS;

EXCEPTION
     WHEN OTHERS THEN
	IF (l_debug = 1) THEN
   	inv_log_util.trace('Error in outer validate_lines'||substr(sqlerrm,1,240),
				'INV_TXN_MANAGER_PUB',1);
	END IF;
	x_return_status := FND_API.G_RET_STS_ERROR;

END validate_lines;


/******************************************************************
 *
 * validate_lines()
 *  Validate one transaction record in MTL_TRANSACTIONS_INTERFACE
 *
 ******************************************************************/
PROCEDURE validate_lines(p_line_Rec_Type line_rec_type, 
                 	 p_commit VARCHAR2 := fnd_api.g_false     ,
                 	 p_validation_level NUMBER  := fnd_api.g_valid_level_full  ,
                         p_error_flag OUT NOCOPY VARCHAR2, 
                         p_userid NUMBER, 
                         p_loginid NUMBER, 
                         p_applid NUMBER, 
                         p_progid NUMBER)
AS

    l_error_flag         VARCHAR2(2);
BEGIN

    if (l_debug is null) then
       l_debug := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
    end if;

    inv_txn_manager_grp.validate_lines( p_line_Rec_Type => p_Line_rec_type,
					p_error_flag =>l_error_flag,
					p_validation_level => p_validation_level,
					p_userid => p_userid,
					p_loginid => p_loginid,
					p_applid => p_applid,
					p_progid => p_progid);
    p_error_flag := l_error_flag;
    IF (l_error_flag = 'Y') THEN
       IF (l_debug = 1) THEN
	  inv_log_util.trace('Error in Line Validatin', 'INV_TXN_MANAGER_PUB', 9);
       END IF;
    END IF;
 
EXCEPTION
    WHEN OTHERS THEN
    p_error_flag:='Y';
    IF (l_debug = 1) THEN
       inv_log_util.trace('Error in validate_line : ' || l_error_exp, 'INV_TXN_MANAGER_PUB','1');
       inv_log_util.trace('Error:'||substr(sqlerrm,1,250),'INV_TXN_MANAGER_PUB',1);
    END IF;
    
END validate_lines;


/******************************************************************
 *
 * get_open_period()
 *
 ******************************************************************/
FUNCTION get_open_period(p_org_id NUMBER,p_trans_date DATE,p_chk_date NUMBER) RETURN NUMBER IS

chk_date NUMBER;  /* 0 ignore date,1-return 0 if date doesn't fall in current 
                     period, -1 if Oracle error, otherwise period id*/
trans_date  DATE; /* transaction_date */
acct_period_id NUMBER;  /* period_close_id of current period */

BEGIN
    if ( l_debug is null) then
       l_debug := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
    end if;

    acct_period_id := 0; /* default value */
   
     if (chk_date = 1) THEN
 
         SELECT ACCT_PERIOD_ID
         INTO   acct_period_id
         FROM   ORG_ACCT_PERIODS
         WHERE  PERIOD_CLOSE_DATE IS NULL
         AND    ORGANIZATION_ID = p_org_id
         AND    NVL(p_trans_date,SYSDATE)
                BETWEEN PERIOD_START_DATE and SCHEDULE_CLOSE_DATE
         ORDER BY PERIOD_START_DATE DESC, SCHEDULE_CLOSE_DATE ASC;

    else

    	 SELECT ACCT_PERIOD_ID
    	 INTO   acct_period_id
    	 FROM   ORG_ACCT_PERIODS 
    	 WHERE  PERIOD_CLOSE_DATE IS NULL
      	 AND ORGANIZATION_ID = p_org_id
      	 AND TRUNC(SCHEDULE_CLOSE_DATE) >= 
             TRUNC(nvl(p_trans_date,SYSDATE))
         AND TRUNC(PERIOD_START_DATE) <= 
             TRUNC(nvl(p_trans_date,SYSDATE)) ;
    end if;    

   return(acct_period_id);

exception
   when NO_DATA_FOUND then
        acct_period_id := 0;
        return(acct_period_id);
   when OTHERS then
        acct_period_id  := -1;
        return(acct_period_id);


end get_open_period;



/******************************************************************
 *
 * tmpinsert() moved to INV_TXN_MANAGER_GRP
 *
 ******************************************************************/
FUNCTION tmpinsert(p_header_id IN NUMBER)
RETURN BOOLEAN
IS

    l_lt_flow_schedule NUMBER;
    l_return BOOLEAN :=TRUE;
BEGIN
    if (l_debug is null) then
       l_debug := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
    end if;

    l_return := inv_txn_manager_grp.tmpinsert(p_header_id=>p_header_id);
    IF (l_return) then
       RETURN TRUE;
     ELSE
       RETURN FALSE;
    END IF;
    
 EXCEPTION
   WHEN OTHERS THEN
    IF (l_debug = 1) THEN
       inv_log_util.trace('Error in tmpinsert: sqlerrm : ' || substr(sqlerrm, 1, 200),
            'INV_TXN_MANAGER_PUB','9');
    END IF;
    RETURN FALSE; 

END tmpinsert;



/******************************************************************
 *
 * bflushchk()
 *
 ******************************************************************/
FUNCTION bflushchk(p_txn_hdr_id IN OUT  NOCOPY NUMBER)
RETURN BOOLEAN
IS

 l_new_hdr_id NUMBER;    /* New Assy Backflush Header ID */
 l_old_hdr_id NUMBER;

BEGIN
    l_old_hdr_id := p_txn_hdr_id;
    SELECT mtl_material_transactions_s.nextval
    INTO l_new_hdr_id
    FROM DUAL;

    p_txn_hdr_id := l_new_hdr_id;

    UPDATE mtl_material_transactions_temp
       SET transaction_header_id = l_new_hdr_id, 
           LOCK_FLAG = 'Y'
     WHERE process_flag = 'Y'
       and nvl(LOCK_FLAG,'N') = 'N'
       and transaction_header_id in
    (SELECT  mmtt.transaction_header_id
       FROM mtl_material_transactions mmt,
            mtl_material_transactions_temp mmtt
      WHERE mmt.transaction_set_id = l_old_hdr_id
        AND mmt.completion_transaction_id = 
                      mmtt.completion_transaction_id);


    IF SQL%NOTFOUND THEN
        p_txn_hdr_id := -1;
    END IF;
    

    RETURN TRUE;
    EXCEPTION
	WHEN OTHERS THEN
	IF (l_debug = 1) THEN
   	inv_log_util.trace('*** SQL error '||substr(sqlerrm, 1, 200), 'INV_TXN_MANAGER_GRP',9);
	END IF;
        RETURN FALSE;

END bflushchk;

/******************************************************************
 *
 * poget()
 *
 ******************************************************************/
PROCEDURE poget(p_prof IN VARCHAR2, x_ret OUT NOCOPY VARCHAR2)
IS
BEGIN
  SELECT FND_PROFILE.value(p_prof) 
  INTO x_ret
  FROM dual; 
END poget; 



/******************************************************************
*
  * process_Transactions()
  *
  ******************************************************************/
  FUNCTION process_Transactions
  ( 
    p_api_version            IN      NUMBER           ,
    p_init_msg_list          IN      VARCHAR2 := fnd_api.g_false     ,
    p_commit                 IN      VARCHAR2 := fnd_api.g_false     ,
    p_validation_level       IN      NUMBER   := fnd_api.g_valid_level_full  ,
    x_return_status          OUT     NOCOPY VARCHAR2      ,
    x_msg_count              OUT     NOCOPY NUMBER        ,
    x_msg_data               OUT     NOCOPY VARCHAR2        ,
    x_trans_count            OUT     NOCOPY NUMBER          ,
    p_table	                 IN      NUMBER := 1     ,
    p_header_id              IN      NUMBER) 
  RETURN NUMBER
  IS
     l_header_id NUMBER;
     l_source_header_id NUMBER;
     l_totrows NUMBER;
     l_initotrows NUMBER;
     l_midtotrows NUMBER;
     l_userid NUMBER;
     l_loginid NUMBER;
     l_progid NUMBER;
     l_applid NUMBER;
     l_reqstid NUMBER; 
     l_valreq NUMBER;
     l_errd_int_id NUMBER;
     l_trx_type NUMBER;
     l_item_id NUMBER;
     l_org_id NUMBER;
     l_srctypeid NUMBER;
     l_tempid NUMBER;
     l_actid NUMBER; 
     l_srcid NUMBER;
     l_locid NUMBER;
     l_xlocid NUMBER;
     l_rctrl NUMBER;
     l_lctrl NUMBER;
     l_trx_qty NUMBER;
     l_qty  NUMBER := 0;
     l_aqty  NUMBER := 0;
     l_oqty  NUMBER := 0;
     l_src_code VARCHAR2(30); 
     l_rowid VARCHAR2(21); 
     l_sub_code VARCHAR2(11);
     l_xfrsub VARCHAR2(11);
     l_lotnum VARCHAR2(31);
     l_rev VARCHAR2(4);
     l_disp VARCHAR2(3000);
     l_message VARCHAR2(100); 
     l_source_code VARCHAR2(30);
     l_profval VARCHAR2(256);
     l_expbuf VARCHAR2(241);
     l_prfvalue VARCHAR2(10);
     done BOOLEAN;
     first BOOLEAN;
     tree_exists BOOLEAN;
     l_result NUMBER;
     l_msg_data  VARCHAR2(2000);
     line_vldn_error_flag VARCHAR(1);
     l_Line_Rec_Type Line_Rec_Type;
     rollback_line_validation EXCEPTION;
     l_trx_batch_id  NUMBER;
     l_last_trx_batch_id  NUMBER;
     batch_error BOOLEAN;
     l_process  NUMBER;
     l_return_status      VARCHAR2(30);
     l_ret_sts_pre VARCHAR2(30);--J-dev for return status if preInvWipProcessing
     l_ret_sts_post VARCHAR2(30);--J-dev for return status ifpreInvWipProcessing
     l_source_type_id NUMBER; --J-dev used to check if WIP returned
     --successful rows.
     l_batch_count NUMBER;
     l_dist_acct_id NUMBER;
     l_batch_size  NUMBER ;  /*Patchset J:Interface Trip Stop Enhancements*/
     l_count NUMBER := 0;  -- Bug 8223272

     
     CURSOR AA1 IS
	SELECT 
	  TRANSACTION_INTERFACE_ID,
	  TRANSACTION_HEADER_ID,
	  REQUEST_ID,
	  INVENTORY_ITEM_ID,
	  ORGANIZATION_ID,
	  SUBINVENTORY_CODE,
	  TRANSFER_ORGANIZATION,
	  TRANSFER_SUBINVENTORY,
	  TRANSACTION_UOM,
	  TRANSACTION_DATE,
	  TRANSACTION_QUANTITY,
	  LOCATOR_ID,
	  TRANSFER_LOCATOR,
	  TRANSACTION_SOURCE_ID,
	  TRANSACTION_SOURCE_TYPE_ID,
	  TRANSACTION_ACTION_ID,
	  TRANSACTION_TYPE_ID,
	  DISTRIBUTION_ACCOUNT_ID,
	  NVL(SHIPPABLE_FLAG,'Y'),
	  ROWID,
	  NEW_AVERAGE_COST,
	  VALUE_CHANGE,
	  PERCENTAGE_CHANGE,
	  MATERIAL_ACCOUNT,
	  MATERIAL_OVERHEAD_ACCOUNT,
	  RESOURCE_ACCOUNT,
	  OUTSIDE_PROCESSING_ACCOUNT,
	  OVERHEAD_ACCOUNT,
	  REQUISITION_LINE_ID,
	  OVERCOMPLETION_TRANSACTION_QTY,   /* Overcompletion Transactions */
	  END_ITEM_UNIT_NUMBER,
	  SCHEDULED_PAYBACK_DATE, /* Borrow Payback */
	  REVISION,   /* Borrow Payback */
	  ORG_COST_GROUP_ID,  /* PCST */
	  COST_TYPE_ID, /* PCST */
	  PRIMARY_QUANTITY,
	  SOURCE_LINE_ID,
	  PROCESS_FLAG,
	  TRANSACTION_SOURCE_NAME,
	  TRX_SOURCE_DELIVERY_ID,
	  TRX_SOURCE_LINE_ID,
	  PARENT_ID,
	  TRANSACTION_BATCH_ID,
	  TRANSACTION_BATCH_SEQ
	  FROM MTL_TRANSACTIONS_INTERFACE
	  WHERE TRANSACTION_HEADER_ID = p_header_id
	  AND PROCESS_FLAG = 1
	  ORDER BY TRANSACTION_BATCH_ID,TRANSACTION_BATCH_SEQ,ORGANIZATION_ID,
	  INVENTORY_ITEM_ID,REVISION,SUBINVENTORY_CODE,LOCATOR_ID;

     l_index NUMBER := 0;
     l_previous_parent_id NUMBER := 0;
     l_validation_status VARCHAR2(1) := 'Y';
  BEGIN
     l_debug := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
     
     l_header_id := p_header_id;
     --dbms_output.put_line(' came to process_trx');
     IF (l_debug = 1) THEN
	inv_log_util.trace
	  ('-----Inside process_Transactions-------.trxhdr='|| p_header_id,
	   'INV_TXN_MANAGER_PUB', 9);
     END IF;
     
     
     /* FND_MESSAGE.SET_NAME('INV', 'BAD_INPUT_ARGUMENTS');
     FND_MSG_PUB.ADD;
       RAISE FND_API.G_EXC_ERROR; */
       
       /*----------------------------------------------------------+
       |  retrieving information 
       +----------------------------------------------------------*/
       
       poget('LOGIN_ID', l_loginid);
     poget('USER_ID', l_userid);
     poget('CONC_PROGRAM_ID', l_progid);
     poget('CONC_REQUEST_ID', l_reqstid);
     poget('PROG_APPL_ID', l_applid);
     
     IF l_loginid is NULL THEN
	l_loginid := -1;
     END IF;
     IF l_userid is NULL THEN
	l_userid := -1;
     END IF;
     /*l_loginid := 1068;
     l_userid := 1068;
       l_progid := 32321;
       l_reqstid := null;
       l_applid := 401;*/
       
       x_return_status := FND_API.G_RET_STS_ERROR;
     x_msg_count  :=  0;
     x_msg_data := '';
     x_trans_count := 0;
     
     -- Bug 3339212. We were rolling back everything if
     --there is an error in process transactions. This leads o erasing all
     -- the save point set, which would result in cannot establishing save points
     -- which could have been set by other teams calling our API. So, we
     -- would rollback to this point if anything fails in process
     --transactions.
     -- Bug 3686000: The savepoint to be established only when the caller calls
     -- this API with p_commit as false. Otherwise, during an exception, we
     -- will not find the save point as we would have committed if p_commit
     -- has been set to true in downstream processing.
     IF NOT FND_API.To_Boolean( p_commit ) then
	SAVEPOINT PROCESS_TRANSACTIONS_SVPT;
     END IF;
     
     --fnd_global.apps_initialize(1003593, 53466, 385);
     IF (p_table = 2) THEN 
	/** Process Rows in MTL_MATERIAL_TRANSACTION_TEMP **/
	IF (l_debug = 1) THEN
	   inv_log_util.trace('Process Rows in MTL_MATERIAL_TRANSACTION_TEMP', 'INV_TXN_MANAGER_PUB', 9);
	END IF;
	
	UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
	  SET LAST_UPDATE_DATE = SYSDATE,
	  TRANSACTION_TEMP_ID = NVL(TRANSACTION_TEMP_ID, mtl_material_transactions_s.nextval),
	  LAST_UPDATED_BY = l_userid,
	  LAST_UPDATE_LOGIN = l_loginid,
	  PROGRAM_APPLICATION_ID = l_applid,
	  PROGRAM_ID = l_progid,
	  REQUEST_ID = l_reqstid,
	  PROGRAM_UPDATE_DATE = SYSDATE,
	  ERROR_CODE = NULL,
	  ERROR_EXPLANATION = NULL
	  WHERE PROCESS_FLAG = 'Y'
	  AND NVL(TRANSACTION_STATUS,TS_DEFAULT) <> TS_SAVE_ONLY  /* 2STEP */
	  AND TRANSACTION_HEADER_ID = l_header_id;
	
        -- Bug 4200332
        -- This is extra precaution we need to add because we dont document it 
        -- clearly enough. Should remove this eventually
	--bug 4455718. support 6 decimals for wip/
	UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
	SET    PRIMARY_QUANTITY = ROUND(PRIMARY_QUANTITY,5),
               TRANSACTION_QUANTITY = ROUND(TRANSACTION_QUANTITY,5)
	WHERE  PROCESS_FLAG = 'Y'
	AND    NVL(TRANSACTION_STATUS,TS_DEFAULT) <> TS_SAVE_ONLY  /* 2STEP */
	  AND    TRANSACTION_HEADER_ID = l_header_id
	  AND transaction_source_type_id <> 5;

	UPDATE mtl_transaction_lots_temp
	  SET  PRIMARY_QUANTITY = ROUND(PRIMARY_QUANTITY,5),
	  TRANSACTION_QUANTITY = ROUND(TRANSACTION_QUANTITY,5)
	  WHERE transaction_temp_id
	  IN( SELECT transaction_temp_id
	      FROM mtl_material_transactions_temp
	      WHERE  PROCESS_FLAG = 'Y'
	      AND    NVL(TRANSACTION_STATUS,TS_DEFAULT) <> TS_SAVE_ONLY  /* 2STEP */
	      AND    TRANSACTION_HEADER_ID = l_header_id
	      AND transaction_source_type_id <> 5);


	UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
	SET    PRIMARY_QUANTITY = ROUND(PRIMARY_QUANTITY,6),
               TRANSACTION_QUANTITY = ROUND(TRANSACTION_QUANTITY,6)
	WHERE  PROCESS_FLAG = 'Y'
	AND    NVL(TRANSACTION_STATUS,TS_DEFAULT) <> TS_SAVE_ONLY  /* 2STEP */
	  AND    TRANSACTION_HEADER_ID = l_header_id
	  AND transaction_source_type_id = 5;

	UPDATE mtl_transaction_lots_temp
	  SET  PRIMARY_QUANTITY = ROUND(PRIMARY_QUANTITY,6),
	  TRANSACTION_QUANTITY = ROUND(TRANSACTION_QUANTITY,6)
	  WHERE transaction_temp_id
	  IN( SELECT transaction_temp_id
	      FROM mtl_material_transactions_temp
	      WHERE  PROCESS_FLAG = 'Y'
	      AND    NVL(TRANSACTION_STATUS,TS_DEFAULT) <> TS_SAVE_ONLY  /* 2STEP */
	      AND    TRANSACTION_HEADER_ID = l_header_id
	      AND transaction_source_type_id = 5);
	
	
	IF (l_debug = 1) THEN
	   inv_log_util.trace('Rows in MMTT ready to process ', 'INV_TXN_MANAGER_PUB', 9);
	END IF;
	
	SELECT count(1)
	  INTO l_process
	  FROM MTL_MATERIAL_TRANSACTIONS_TEMP
	  WHERE TRANSACTION_HEADER_ID = l_header_id
	  AND PROCESS_FLAG = 'Y'
	  AND TRANSACTION_STATUS = 3 /* not able to use the TS_PROCESS macro */
	  AND ROWNUM < 2;
	--the assumption is that default txns are
	--never mixed up with the 2level txns. so
	-- we can avoid temp validation call if there
	--are no rows with transaction_status = TS_PROCESS 
	IF l_process = 1 THEN
	   IF (l_debug = 1) THEN
	      inv_log_util.trace('Calling INV_PROCESS_TEMP.processTransaction', 'INV_TXN_MANAGER_PUB', 9);
	   END IF;
	   l_result := INV_PROCESS_TEMP.processTransaction(l_header_id,
							   INV_PROCESS_TEMP.FULL,
							   INV_PROCESS_TEMP.IGNORE_ALL);
	END IF;
	
	
	SELECT count(*)
	  INTO l_totrows
	  FROM MTL_MATERIAL_TRANSACTIONS_TEMP
	  WHERE TRANSACTION_HEADER_ID = l_header_id
	  AND PROCESS_FLAG = 'Y'
	  AND NVL(TRANSACTION_STATUS,TS_DEFAULT) <> TS_SAVE_ONLY; /* 2STEP */
	
	l_midtotrows := l_totrows;
	l_initotrows := l_totrows;
	x_trans_count := l_totrows;
	
	IF (l_totrows = 0) THEN
     	   IF FND_API.To_Boolean( p_commit ) then
	      COMMIT WORK;
	   END If;
	   FND_MESSAGE.set_name('INV','INV_PROC_WARN');
	   l_disp := FND_MESSAGE.get;
	   IF (l_debug = 1) THEN
	      inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
	   END IF;
           return -1;
	END IF;
	
	/*+-----------------------------------------------------------------+
	| Check if we are processing WIP transactions to determine which  |
	  | to invoke to process transactions                               |
	  +-----------------------------------------------------------------+*/
	  SELECT TRANSACTION_SOURCE_TYPE_ID
	  INTO l_srctypeid
	  FROM MTL_MATERIAL_TRANSACTIONS_TEMP
	  WHERE TRANSACTION_HEADER_ID = l_header_id
          AND ROWNUM < 2;
	
	done := FALSE;
	first := TRUE;
	while (NOT done) LOOP 
           IF (first) THEN
	      IF (l_debug = 1) THEN
		 inv_log_util.trace('Calling Process_lpn_trx', 'INV_TXN_MANAGER_PUB',9);
	      END IF;
	      FND_MESSAGE.set_name('INV','INV_CALL_PROC');
	      FND_MESSAGE.set_token('token1',l_header_id);
	      FND_MESSAGE.set_token('token2',l_totrows);
	      l_disp := FND_MESSAGE.get;
	      IF (l_debug = 1) THEN
		 inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
	      END IF;
           END IF;
	   
           -- If transactions are of type WIP, then call the WIP API. This
           -- API does the WIP pre-processing before calling
	   --process_lpn_trx
	   /** WIP J dev condition. Add another condtion in the if
	   /* statement below. if WIP.J is not installed call
	   /* wip_mtlTempProc_grp()...else call process_lpn_trx()*/  
           IF (l_srctypeid = 5 AND wip_constants.dmf_patchset_level<wip_constants.DMF_PATCHSET_J_VALUE) THEN
	      wip_mtlTempProc_grp.processtemp
		(
		 p_initMsgList => FND_API.G_FALSE, 
		 p_processInv => FND_API.G_TRUE, -- call INV TM after WIP logic
		 p_txnHdrID  => l_header_id,
		 x_returnStatus => l_return_status ,
		 x_errormsg     => l_msg_data);
	      if (l_return_status <> fnd_api.g_ret_sts_success) then
	         IF (l_debug = 1) THEN
		    inv_log_util.trace('Failure from MMTT:WIP processTemp!!', 'INV_TXN_MANAGER_PUB',1);
	         END IF;
                 l_result := -1;
	      end if;
	    ELSE
	      l_result := INV_LPN_TRX_PUB.process_lpn_trx
		(
		 p_trx_hdr_id => l_header_id,
		 p_commit   => p_commit,
		 x_proc_msg => l_msg_data,
		 p_proc_mode => 1,
		 p_process_trx => fnd_api.g_true,
		 p_atomic => fnd_api.g_false );
           END IF;
	   
           IF (l_result <> 0) THEN
	      
	      FND_MESSAGE.set_name('INV','INV_INT_PROCCODE');
	      IF (l_debug = 1) THEN
		 inv_log_util.trace('Error from PROCESS_LPN_TRX.. '||l_msg_data,'INV_TXN_MANAGER_PUB',9);
	      END IF;
	      l_error_exp := l_msg_data;
	      x_msg_data := l_msg_data;
	      x_return_status := l_return_status;
	      /*      No need to update MMTT after returning from process_lpn_trx as this has already
	      been done within the Java code. - Bug 2284667 */
		
		
		IF FND_API.To_Boolean( p_commit ) then
                   COMMIT WORK;
		END If;
		
		return -1;
           END IF;
           IF (l_debug = 1) THEN
              inv_log_util.trace('After process_lpn_trx without errors','INV_TXN_MANAGER_PUB', 9);
           END IF;
	   
           IF (first) THEN
	      FND_MESSAGE.set_name('INV','INV_RETURN_PROC');
	      l_disp := FND_MESSAGE.get;
	      IF (l_debug = 1) THEN
		 inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
	      END IF;
           END IF;
	   
     	   IF FND_API.To_Boolean( p_commit ) then
	      COMMIT WORK;
	   END If;
           IF (first) THEN
	      IF (NOT bflushchk(l_header_id)) THEN
		 l_error_exp := FND_MESSAGE.get;
		 IF (l_debug = 1) THEN
		    inv_log_util.trace('Error in call to bflushchk', 'INV_TXN_MANAGER_PUB',9);
		 END IF;
		 --ROLLBACK WORK;
		 return -1;
	      END IF;
	      IF (l_header_id <> -1) THEN
		 FND_MESSAGE.set_name('INV','INV_BFLUSH_PROC');
		 l_disp := FND_MESSAGE.get;
		 IF (l_debug = 1) THEN
		    inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
		 END IF;
		 SELECT count(*)
		   INTO l_totrows
		   FROM MTL_MATERIAL_TRANSACTIONS_TEMP
		   WHERE TRANSACTION_HEADER_ID = l_header_id
		   AND PROCESS_FLAG = 'Y';
		 
		 IF (l_totrows > 200) THEN
		    UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
		      SET TRANSACTION_HEADER_ID = (-1) * l_header_id
		      WHERE TRANSACTION_HEADER_ID = l_header_id
		      AND PROCESS_FLAG = 'Y';
		    
		    UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
		      SET TRANSACTION_HEADER_ID = ABS(l_header_id)
		      WHERE TRANSACTION_HEADER_ID = (-1)* (l_header_id)
		      AND PROCESS_FLAG = 'Y'
		      AND ROWNUM < 201;
		 END IF;
		 FND_MESSAGE.set_name('INV','INV_CALL_PROC');
		 FND_MESSAGE.set_token('token1',l_header_id);
		 FND_MESSAGE.set_token('token2',l_totrows);
		 l_disp := FND_MESSAGE.get;
		 IF (l_debug = 1) THEN
		    inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
		 END IF;
               ELSE
		 done := TRUE;
	      END IF;
	      first := FALSE;
	    ELSE 
	      UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
		SET TRANSACTION_HEADER_ID = abs(l_header_id)
                WHERE TRANSACTION_HEADER_ID = (-1)* (l_header_id)
		AND PROCESS_FLAG = 'Y'
		AND ROWNUM < 201;
	      IF SQL%NOTFOUND THEN
		 FND_MESSAGE.set_name('INV','INV_RETURN_PROC');
		 done := TRUE;
	      END IF;
	      
           END IF;
	END LOOP;
	
	
      ELSE
	
	
	/** Table = 1 - MTL_TRANSACTIONS_INTERFACE **/ 
	/** Table = 1 - MTL_TRANSACTIONS_INTERFACE **/ 
	/*Patchset J:Trip Stop Interface Enhancements:setting the
	/*transaction batch id for Shipping transactions depending
	/*on the profile INV:Batch Size*/
        /*Bug 3947667, enabling it irrespective of patchset */
	
     --	IF (INV_CONTROL.G_CURRENT_RELEASE_LEVEL >= INV_RELEASE.G_J_RELEASE_LEVEL) THEN
     BEGIN
	   l_batch_size:=  nvl(fnd_profile.VALUE('INV_BATCH_SIZE'),0);
     EXCEPTION
        WHEN VALUE_ERROR THEN
           l_batch_size :=0;
           inv_log_util.trace('Inv Batch size set to null for non numeric value','INV_TXN_MANAGER_PUB', 9);
     END;

	   
	   IF (l_debug = 1) THEN
	      inv_log_util.trace('Inv Batch size:'||l_batch_size, 'INV_TXN_MANAGER_PUB', 9);
	   END IF;
	   
	   UPDATE MTL_TRANSACTIONS_INTERFACE
	     SET LAST_UPDATE_DATE = SYSDATE,
	     TRANSACTION_INTERFACE_ID = NVL(TRANSACTION_INTERFACE_ID,
					    mtl_material_transactions_s.nextval),
	     TRANSACTION_BATCH_ID=nvl(transaction_batch_id,
				      decode(transaction_source_type_id,2,
					     decode(l_batch_size,0,TRANSACTION_BATCH_ID,
						    ceil(ROWNUM/l_batch_size)),
					     8,decode(l_batch_size,0,TRANSACTION_BATCH_ID,
						      ceil(ROWNUM/l_batch_size)),
                    16,decode(l_batch_size,0,TRANSACTION_BATCH_ID,
						      ceil(ROWNUM/l_batch_size)),
					     transaction_batch_id)),
	     LAST_UPDATED_BY = l_userid,
	     LAST_UPDATE_LOGIN = l_loginid,
	     PROGRAM_APPLICATION_ID = l_applid,
	     PROGRAM_ID = l_progid,
	     REQUEST_ID = l_reqstid,
	     PROGRAM_UPDATE_DATE = SYSDATE,
	     LOCK_FLAG = 1
	     WHERE PROCESS_FLAG = 1
	     AND TRANSACTION_HEADER_ID = l_header_id;
	/* ELSE
	   
	   UPDATE MTL_TRANSACTIONS_INTERFACE
	     SET LAST_UPDATE_DATE = SYSDATE,
	     TRANSACTION_INTERFACE_ID = NVL(TRANSACTION_INTERFACE_ID,
					    mtl_material_transactions_s.nextval),
	     LAST_UPDATED_BY = l_userid,
	     LAST_UPDATE_LOGIN = l_loginid,
	     PROGRAM_APPLICATION_ID = l_applid,
	     PROGRAM_ID = l_progid,
	     REQUEST_ID = l_reqstid,
	     PROGRAM_UPDATE_DATE = SYSDATE,
	     LOCK_FLAG = 1
	     WHERE PROCESS_FLAG = 1
	     AND TRANSACTION_HEADER_ID = l_header_id;
	END IF; */
	l_initotrows := SQL%ROWCOUNT;
	
	IF FND_API.To_Boolean( p_commit ) then
           COMMIT WORK;
	END If;
	
	IF (l_debug = 1) THEN
	   inv_log_util.trace('MTI Rows cnt before Validation='||l_initotrows, 'INV_TXN_MANAGER_PUB', 9);
	END IF;
	IF (l_totrows = 0) THEN
       	   FND_MESSAGE.set_name('INV','INV_PROC_WARN');
   	   l_disp := FND_MESSAGE.get;  
	   IF (l_debug = 1) THEN
	      inv_log_util.trace(l_disp || ' totrows = 0', 'INV_TXN_MANAGER_PUB',9);
	   END IF;
           return -1;
	END IF;
	
	/*+-----------------------------------------------------------------+
        | Check if we are processing WIP transactions to determine whether|
	  | to do the derivation for flow_schedule.                         |
	  +-----------------------------------------------------------------+*/
	  SELECT NVL(VALIDATION_REQUIRED,1), MTT.TRANSACTION_SOURCE_TYPE_ID
	  INTO l_valreq, l_srctypeid
	  FROM MTL_TRANSACTIONS_INTERFACE MTI,
	  MTL_TRANSACTION_TYPES MTT
	  WHERE TRANSACTION_HEADER_ID = l_header_id
	  AND MTT.TRANSACTION_TYPE_ID = MTI.TRANSACTION_TYPE_ID
	  AND ROWNUM < 2;
	
	/*+--------------------------------------------------------------+ 
	| The global INV_TXN_MANAGER_GRP.gi_flow_schedule will be '1' (or true) for        |
	  | WIP flow schedules ONLY.                                     |
	  +--------------------------------------------------------------+ */
	  
	  
	  
	  
	  IF ( l_srctypeid = 5 ) THEN
	    BEGIN 
	       SELECT DECODE(UPPER(FLOW_SCHEDULE),'Y', 1, 0) 
		 INTO inv_txn_manager_grp.gi_flow_schedule
		 FROM MTL_TRANSACTIONS_INTERFACE 
		 WHERE TRANSACTION_HEADER_ID = l_header_id 
		 AND TRANSACTION_SOURCE_TYPE_ID = 5
		 AND TRANSACTION_ACTION_ID IN (30,31, 32) --CFM Scrap Transactions 
		 AND PROCESS_FLAG = 1
		 AND ROWNUM < 2 ;
	    EXCEPTION
	       WHEN NO_DATA_FOUND THEN	
		  inv_txn_manager_grp.gi_flow_schedule := 0 ;
	    END;
	   ELSE
		  inv_txn_manager_grp.gi_flow_schedule := 0 ; 
	  END IF;
	  
	  
	  /** WIP J dev condition. If WIP J is not installed do as now,
	  /*else call a new new API wip_mti_pub.preInvWIPProcessing()
	  /* This has to be called before validate_group()
	  /* we should retain create_flow sch for WIP I and below.*/
	  
	  IF (l_srctypeid = 5 AND wip_constants.DMF_PATCHSET_LEVEL>= wip_constants.DMF_PATCHSET_J_VALUE) THEN

              -- Bug 8223272 Code changes start
              loaderrmsg('INV_INT_QTYCODE','INV_INT_QTYSGNEXP');

                UPDATE MTL_TRANSACTIONS_INTERFACE MTI
                   SET LAST_UPDATE_DATE = SYSDATE,
                       LAST_UPDATED_BY = l_userid,
                       LAST_UPDATE_LOGIN = l_loginid,
                       PROGRAM_UPDATE_DATE = SYSDATE,
                       PROCESS_FLAG = 3,
                       LOCK_FLAG = 2,
                       ERROR_CODE = substrb(l_error_code,1,240),
                       ERROR_EXPLANATION = substrb(l_error_exp,1,240)
                 WHERE TRANSACTION_HEADER_ID = p_header_id
                 AND PROCESS_FLAG = 1
                 AND UPPER(NVL(FLOW_SCHEDULE, 'N')) = 'Y'
                 AND ((TRANSACTION_ACTION_ID = 32 AND TRANSACTION_QUANTITY > 0) OR
                      (TRANSACTION_ACTION_ID = 31 AND TRANSACTION_QUANTITY < 0));

               l_count := SQL%ROWCOUNT;

            IF (l_debug = 1) THEN
                inv_log_util.trace('WIP Validating transaction quantity ' || l_count || ' failed', 'INV_TXN_MANAGER_PUB', 1);
            END IF;
              -- Bug 8223272 Code changes end

	     wip_mti_pub.preInvWIPProcessing(p_txnHeaderID =>l_header_id,
					     x_returnStatus => l_ret_sts_pre);
	     IF (l_ret_sts_pre  = fnd_api.g_ret_sts_success) THEN
		IF (l_debug = 1) THEN
		   inv_log_util.trace('Success from:!!preInvWIPProcessing', 'INV_TXN_MANAGER_PUB',1);
		END IF;
		
		IF FND_API.To_Boolean( p_commit ) then
		   COMMIT WORK; /* Commit after preInvWIP all MTI records */
		END IF;
		
		--check if all records have been failed by the wip API.
		BEGIN
		   SELECT transaction_source_type_id INTO l_source_type_id
		     FROM MTL_TRANSACTIONS_INTERFACE
		     WHERE TRANSACTION_HEADER_ID = l_header_id
		     AND PROCESS_FLAG = 1  
		     AND ROWNUM < 2;
		EXCEPTION 
		   WHEN NO_DATA_FOUND THEN
		      x_return_status := FND_API.G_RET_STS_ERROR;
		      x_msg_data := 'All records failed by preInvWipProcessing';
		      RETURN -1;            
		END;
	      ELSE
		      IF (l_debug = 1) THEN
			 inv_log_util.trace('Failure from:!!preInvWIPProcessing', 'INV_TXN_MANAGER_PUB',1);
		      END IF;
		      RAISE fnd_api.g_exc_unexpected_error;
	     end if;--check for success
	     
	     
	   ELSE
		IF ( inv_txn_manager_grp.gi_flow_schedule <> 0 ) THEN
		   WIP_FLOW_UTILITIES.Create_Flow_Schedules(l_header_id) ;
		END IF;
		
	  END IF;--J-dev
	  
	  
	  /***** Group Validation *******************************/
	  validate_group
	    (l_header_id,
	     x_return_status,
	     x_msg_count,
	     x_msg_data,
	     l_userid,
	     l_loginid);
	  
	  IF x_return_status = FND_API.G_RET_STS_ERROR   THEN
	     IF (l_debug = 1) THEN
		inv_log_util.trace('Unexpected Error in Validate Group : ' || x_msg_data,'INV_TXN_MANAGER_PUB', 9);
	     END IF;
	     RAISE fnd_api.g_exc_unexpected_error;
	  END IF;
	  
	  /** Moved to after Validate_lines loop J-dev*/
	  /******* Group Validation for WIP records *******************/
	  /* This WIP API could potentially error some records in MTI. If any records
	  /* have been errored, they would be stamped with error-code/explanation */
	  /*IF (l_srctypeid = 5 ) THEN
          wip_mti_pub.postInvWIPValidation(
	    p_txnHeaderID  => l_header_id,
	    x_returnStatus => x_return_status
	    );
	    END IF;*/
	    
	    IF FND_API.To_Boolean( p_commit ) then
	       COMMIT WORK; /* Commit after group validating all MTI records */
	    END IF;
	    
	    IF (l_debug = 1) THEN
	       inv_log_util.trace('Group validation complete ', 'INV_TXN_MANAGER_PUB', 9);
	    END IF;
	    
	    batch_error := FALSE;
	    
	    FOR l_Line_rec_Type IN AA1 LOOP
          BEGIN
	     l_trx_batch_id := l_Line_rec_Type.TRANSACTION_BATCH_ID;
	     IF batch_error AND l_trx_batch_id = l_last_trx_batch_id THEN
		/** This group of transactions has failed move on to next **/
		/** UPDATE MTI row with Group Failure Message **/
		null;
	      ELSE
		batch_error := FALSE;
		l_last_trx_batch_id := l_trx_batch_id;
		
		/** Change for Lot Transactions **/
		IF( l_line_rec_type.transaction_source_type_id = 13 ) THEN
		   IF(l_line_rec_type.transaction_action_id in (40, 41, 42)
		      )THEN
		      IF (l_debug = 1) THEN
			 inv_log_util.trace('Previous parent: ' ||
					    l_previous_parent_id, 'INV_TXN_MANAGER_PUB', 9);
			 inv_log_util.trace('Current parent: ' || l_line_rec_type.parent_id, 'INV_TXN_MANAGER_PUB', 9);
		      END IF;  
		      if( Nvl(l_previous_parent_id,0) <>
			  l_line_rec_type.parent_id ) THEN
			 
			 /***** Its a new Batch. Before we do any validations, we have to
			 -- check for the transaction bacth id. For all lot
			 --  transctions, the batch id should be filled in for
			 --  the TM to perform a complete rollback in case any
			 --  of the records fail within a group/batch.
			 --  Bug 2804402
			 *******/
			   
			   l_batch_count := 0;
			 SELECT COUNT(1) INTO l_batch_count FROM
			   mtl_transactions_interface WHERE parent_id =
			   l_line_rec_type.parent_id AND
			   transaction_batch_id IS NULL;
			   
			   IF (l_batch_count > 0 ) THEN
			      loaderrmsg('INV_INVALID_BATCH','INV_INVALID_BATCH_NUMBER');			      
			      
			      UPDATE MTL_TRANSACTIONS_INTERFACE
				SET LAST_UPDATE_DATE = SYSDATE,
				LAST_UPDATED_BY = l_userid,
				LAST_UPDATE_LOGIN = l_loginid,
				PROGRAM_UPDATE_DATE = SYSDATE,
				PROCESS_FLAG = 3,
				LOCK_FLAG = 2,
				ERROR_CODE = substr(l_error_code, 1, 240),
				ERROR_EXPLANATION = substrb(l_error_exp, 1, 240)
				WHERE  parent_id = l_line_rec_type.parent_id
				AND  PROCESS_FLAG = 1;
			      raise rollback_line_validation;
			      
			   END IF;
			   
			   
		           l_index := 0;
		           l_previous_parent_id := l_line_rec_type.parent_id;
			   l_validation_status := 'Y';
		      end if;
		      
		      l_index := l_index + 1;
		      
		      IF( l_index = 1 ) then
			 IF( l_line_rec_type.transaction_action_id = 40 ) THEN
			    FND_MESSAGE.SET_NAME('INV', 'INV_LOT_SPLIT_VALIDATIONS');
			    l_error_code := FND_MESSAGE.GET; 
			    
			    INV_LOT_TRX_VALIDATION_PVT.validate_lot_split_trx
			      (
			       x_return_status 	=> x_return_status,
			       x_msg_count		=> x_msg_count,
			       x_msg_data		=> x_msg_data,
			       x_validation_Status => l_validation_status,
			       p_parent_id		=> l_line_rec_type.parent_id);
			    
			    if( x_return_status <> FND_API.G_RET_STS_SUCCESS  ) THEN
			       
			       -- Fetch all the error messages from the stack and log them.
			       -- Update the MTI with last error message only, since the error messages can be redundant.
			       
			       for i in 1 .. x_msg_count
				 loop
				    x_msg_data := fnd_msg_pub.get(i,'F');
				    IF (l_debug = 1) THEN
				       inv_log_util.trace('Error in Validate_lot_Split_Trx: ' || x_msg_data, 'INV_TXN_MANAGER_PUB', 9);
				    END IF;
				 end loop;
				 
				 UPDATE MTL_TRANSACTIONS_INTERFACE
				   SET LAST_UPDATE_DATE = SYSDATE,
				   LAST_UPDATED_BY = l_userid,
				   LAST_UPDATE_LOGIN = l_loginid,
				   PROGRAM_UPDATE_DATE = SYSDATE,
				   PROCESS_FLAG = 3,
				   LOCK_FLAG = 2,
				   ERROR_CODE = substr(l_error_code, 1, 240),
				   ERROR_EXPLANATION = substrb(x_msg_data, 1, 240)
				   WHERE  ROWID = l_line_rec_type.rowid
				   AND  PROCESS_FLAG = 1;
				 raise rollback_line_validation;
			    end if;
		          ELSIF( l_line_rec_type.transaction_action_id = 41) then
			    FND_MESSAGE.SET_NAME('INV', 'INV_LOT_MERGE_VALIDATIONS');
			    l_error_code := FND_MESSAGE.GET;
			    
			    INV_LOT_TRX_VALIDATION_PVT.validate_lot_merge_trx
			      (
			       x_return_status 	=> x_return_status,
			       x_msg_count		=> x_msg_count,
			       x_msg_data		=> x_msg_data,
			       x_validation_Status => l_validation_status,
			       p_parent_id		=> l_line_rec_type.parent_id);
			    if( x_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
			       -- Fetch all the error messages from the stack and log them.
			       -- Update the MTI with last error message only, since the error messages can be redundant.
			       for i in 1 .. x_msg_count
				 loop
				    x_msg_data := fnd_msg_pub.get(i,'F');
				    IF (l_debug = 1) THEN
				       inv_log_util.trace('Error in Validate_lot_Merge_Trx: ' || x_msg_data, 'INV_TXN_MANAGER_PUB', 9);
				    END IF;
				 end loop;
				 
				 UPDATE MTL_TRANSACTIONS_INTERFACE
                                   SET LAST_UPDATE_DATE = SYSDATE,
                                   LAST_UPDATED_BY = l_userid,
                                   LAST_UPDATE_LOGIN = l_loginid,
                                   PROGRAM_UPDATE_DATE = SYSDATE,
                                   PROCESS_FLAG = 3,
                                   LOCK_FLAG = 2,
                                   ERROR_CODE = substrb(l_error_code,1,240),
                                   ERROR_EXPLANATION = substrb(x_msg_data,1,240)
				   WHERE ROWID = l_Line_rec_type.rowid
				   AND PROCESS_FLAG = 1;
				 raise rollback_line_validation;
			    end if;
		          ELSIF( l_line_rec_type.transaction_action_id = 42 ) then
			    FND_MESSAGE.SET_NAME('INV', 'INV_LOT_TRANSLATE_VALIDATIONS');
			    l_error_code := FND_MESSAGE.GET;
			    
			    INV_LOT_TRX_VALIDATION_PVT.validate_lot_translate_trx
			      (
			       x_return_status 	=> x_return_status,
			       x_msg_count		=> x_msg_count,
			       x_msg_data		=> x_msg_data,
			       x_validation_Status => l_validation_status,
			       p_parent_id		=> l_line_rec_type.parent_id);
			    if( x_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
			       -- Fetch all the error messages from the stack and log them.
			       -- Update the MTI with last error message only, since the error messages can be redundant.
			       for i in 1 .. x_msg_count
				 loop
				    x_msg_data := fnd_msg_pub.get(i,'F');
				    IF (l_debug = 1) THEN
				       inv_log_util.trace('Error in Validate_lot_Translate_Trx: ' || x_msg_data, 'INV_TXN_MANAGER_PUB', 9);
				    END IF;
				 end loop;
				 
				 UPDATE MTL_TRANSACTIONS_INTERFACE
				   SET LAST_UPDATE_DATE = SYSDATE,
				   LAST_UPDATED_BY = l_userid,
				   LAST_UPDATE_LOGIN = l_loginid,
				   PROGRAM_UPDATE_DATE = SYSDATE,
				   PROCESS_FLAG = 3,
				   LOCK_FLAG = 2,
				   ERROR_CODE = substr(l_error_code, 1, 240),
				   ERROR_EXPLANATION = substrb(x_msg_data, 1, 240)
				   WHERE  ROWID = l_line_rec_type.rowid
				   AND  PROCESS_FLAG = 1;
				 raise rollback_line_validation;
			    end if;
			 END IF;
		      END IF;
		   END IF;
		END IF;
		/** End of Change for Lot Transactions ***/
		if( l_line_Rec_type.transaction_source_type_id = 13 AND
		    l_line_rec_type.transaction_action_id in (40, 41, 42) AND
		    l_index > 1 AND
		    l_validation_status <> 'Y' ) then
                   IF( l_line_rec_type.transaction_action_id = 40 ) THEN
		      FND_MESSAGE.SET_NAME('INV', 'INV_LOT_SPLIT_VALIDATIONS');
		      l_error_code := FND_MESSAGE.GET;
		    elsif( l_line_rec_type.transaction_action_id = 41 ) THEN
		      FND_MESSAGE.SET_NAME('INV', 'INV_LOT_MERGE_VALIDATIONS');
		      l_error_code := FND_MESSAGE.GET;
		    elsif( l_line_rec_type.transaction_action_id = 42 ) THEN
		      FND_MESSAGE.SET_NAME('INV', 'INV_LOT_TRANSLATE_VALIDATIONS');
		      l_error_code := FND_MESSAGE.GET;
                   end if;
		   
                   UPDATE MTL_TRANSACTIONS_INTERFACE
		     SET LAST_UPDATE_DATE = SYSDATE,
		     LAST_UPDATED_BY = l_userid,
		     LAST_UPDATE_LOGIN = l_loginid,
		     PROGRAM_UPDATE_DATE = SYSDATE,
		     PROCESS_FLAG = 3,
		     LOCK_FLAG = 2,
		     ERROR_CODE = substr(l_error_code, 1, 240),
		     ERROR_EXPLANATION = substrb(x_msg_data, 1, 240)
		     WHERE  ROWID = l_line_rec_type.rowid
                     AND  PROCESS_FLAG = 1;
                   raise rollback_line_validation;
		end if;
		
		/* bug 2807083, populate the distribution account id of lot translate txn */
		IF (l_debug = 1) THEN
                   inv_log_util.trace('l_line_rec_type.distribution_account_id is ' || 
				      l_line_rec_type.distribution_account_id, 'INV_TXN_MANAGER_PUB', 9);
		END IF;
		IF (l_line_rec_type.distribution_account_id is NULL) THEN
                   SELECT distribution_account_id
		     INTO   l_dist_acct_id
		     FROM   mtl_transactions_interface
		     WHERE  rowid = l_line_rec_type.rowid;
                   l_line_rec_type.distribution_account_id := l_dist_acct_id;
		END IF;
		
		IF (l_debug = 1) THEN
                   inv_log_util.trace('l_dist_acct_id is ' || l_dist_acct_id, 'INV_TXN_MANAGER_PUB', 9);
		END IF;
		
		validate_lines( p_line_Rec_Type => l_Line_rec_type,
				p_error_flag =>line_vldn_error_flag,
				p_userid => l_userid,
				p_loginid => l_loginid,
				p_applid => l_applid,
				p_progid => l_progid);
		IF (line_vldn_error_flag = 'Y') then
		   IF (l_debug = 1) THEN
		      inv_log_util.trace('Error in Line Validatin', 'INV_TXN_MANAGER_PUB', 9);
                  END IF;
		  RAISE rollback_line_validation;
                END IF;
		
		savepoint line_validation_svpt;
		
		FND_MESSAGE.set_name('INV','INV_MOVE_TO_TEMP');
		FND_MESSAGE.set_token('token',l_header_id);
		l_disp := FND_MESSAGE.get;
		IF (l_debug = 1) THEN
		   inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
		END IF;

      		/* Insert into MMTT */
		/** Change for lOt Transactions **/
                IF l_line_rec_type.transaction_source_type_id = 13 AND
		  l_line_Rec_type.transaction_action_id in (40, 41, 42) THEN
		   
                   IF (l_debug = 1) THEN
                      inv_log_util.trace('I am in here' , 'INV_TXN_MANAGER_PUB', 9);
                   END IF;
		   /*if( l_previous_parent_id <> l_line_rec_type.parent_id ) then
		   l_index := 0;
		     l_previous_parent_id := l_line_rec_type.parent_id;
		     end if;
		     
		     l_index := l_index + 1;*/
		     
		     IF (l_debug = 1) THEN
			inv_log_util.trace('l_index = ' || l_index, 'INV_TXN_MANAGER_PUB', 9);
			inv_log_util.trace('l_transaction_interface_id is '|| l_line_rec_type.transaction_interface_id,
					   'INV_TXN_MANAGER_PUB', 9);
		     END IF;
		     /*--J-dev we do not need to do this now, this will be
		     * done in tmpinsert()
		       * removed call to LotTrxInsert
		       */
		       
		       IF( l_line_rec_type.transaction_action_id = 40 ) THEN
			  IF( NOT Check_Partial_Split(l_line_rec_type.parent_id, l_index)) THEN
			     l_error_exp := FND_MESSAGE.GET;
			     IF (l_debug = 1) THEN
				inv_log_util.trace('Error in Check_Partial_Split= ' || l_error_exp, 'INV_TXN_MANAGER_PUB', 9);
			     END IF;
			     FND_MESSAGE.SET_NAME('INV', 'INV_INT_TMPXFRCODE');
			     l_error_code := FND_MESSAGE.GET;
			     
			     rollback to line_validation_svpt;
			     
			     UPDATE MTL_TRANSACTIONS_INTERFACE
			       SET LAST_UPDATE_DATE = SYSDATE, 
			       LAST_UPDATED_BY = l_userid,
			       LAST_UPDATE_LOGIN = l_loginid,
			       PROGRAM_UPDATE_DATE = SYSDATE,
			       PROCESS_FLAG = 3,
			       LOCK_FLAG = 2,
			       ERROR_CODE = substr(l_error_code, 1, 240),
			       ERROR_EXPLANATION = substr(l_error_exp, 1, 240)
			       WHERE rowid = l_line_rec_type.rowid
			       AND   process_flag = 1;
			     raise rollback_line_validation;
			  END IF;
		       END IF;
                END IF; --J-dev
                /** end of changes for lot transactions **/
		--J dev, done as a bulk insert now. outside the
		--level loop.
		
		
	     END IF;    
	  EXCEPTION
	     when rollback_line_validation then
		IF (l_debug = 1) THEN
		   inv_log_util.trace('Failed Interface ID : ' || l_Line_rec_Type.Transaction_Interface_id || ' Item: ' || l_Line_rec_Type.Inventory_Item_Id || 'Org : '|| l_Line_rec_Type.Organization_id , 'INV_TXN_MANAGER_PUB', 9);
		END IF;
		batch_error := TRUE;
	     when others then
		batch_error := TRUE;
		IF (l_debug = 1) THEN
		   inv_log_util.trace('Error in INV_TXN_MANAGER_PUB LOOP - rollback last transaction Interface ID ' || l_Line_rec_Type.Transaction_Interface_ID, 'INV_TXN_MANAGER_PUB', 9);
		END IF;
		rollback to line_validation_svpt;
	  END; 
	    END LOOP; -- endloop for AA1 (MTI)
	    
	    --J-dev check that all records for line validation are failed here.
	    
	    --check for batch error at line validation
	    loaderrmsg('INV_GROUP_ERROR','INV_GROUP_ERROR');
	    
	    UPDATE MTL_TRANSACTIONS_INTERFACE MTI
	      SET LAST_UPDATE_DATE = SYSDATE,
	      LAST_UPDATED_BY = l_userid,
	      LAST_UPDATE_LOGIN = l_loginid,
	      PROGRAM_UPDATE_DATE = SYSDATE,
	      PROCESS_FLAG = 3,
	      LOCK_FLAG = 2,
	      ERROR_CODE = substrb(l_error_code,1,240)
	      WHERE TRANSACTION_HEADER_ID = l_header_id
	      AND PROCESS_FLAG = 1
	      AND EXISTS
	      (SELECT 'Y'
	       FROM MTL_TRANSACTIONS_INTERFACE MTI2
	       WHERE MTI2.TRANSACTION_HEADER_ID = l_header_id
	       AND MTI2.PROCESS_FLAG = 3
	       AND MTI2.ERROR_CODE IS NOT NULL
           AND MTI2.TRANSACTION_BATCH_ID = MTI.TRANSACTION_BATCH_ID);

/* Commented following and added EXISTS clause above for bug 7371786

	      AND TRANSACTION_BATCH_ID IN
	      (SELECT DISTINCT MTI2.TRANSACTION_BATCH_ID
	       FROM MTL_TRANSACTIONS_INTERFACE MTI2
	       WHERE MTI2.TRANSACTION_HEADER_ID = l_header_id
	       AND MTI2.PROCESS_FLAG = 3
	       AND MTI2.ERROR_CODE IS NOT NULL);
*/
	       --                               group error changes.
	       IF FND_API.To_Boolean( p_commit ) then
		  COMMIT WORK; /* Commit after LineValidation all MTI records */
	       END IF;
	       --check if all records have been failed by the Line Validation
		BEGIN
		   SELECT transaction_source_type_id INTO l_source_type_id
		     FROM MTL_TRANSACTIONS_INTERFACE
		     WHERE TRANSACTION_HEADER_ID = l_header_id
		     AND PROCESS_FLAG = 1  
		     AND ROWNUM < 2;
		EXCEPTION 
		   WHEN NO_DATA_FOUND THEN
		      x_return_status := FND_API.G_RET_STS_ERROR;
		      x_msg_data := 'All records failed after line validation';
		      IF (l_debug = 1) THEN
			 inv_log_util.trace('All records failed after line validation', 'INV_TXN_MANAGER_PUB',1);
		      END IF;
		      RETURN -1;            
		END;
		
		--J-dev
		/******* Group Validation for WIP records *******************/
		/* This WIP API could potentially error some records in MTI. If any records
		/* have been errored, they would be stamped with error-code/explanation */
		IF (l_srctypeid = 5 ) THEN
		   wip_mti_pub.postInvWIPValidation(
						    p_txnHeaderID  => l_header_id,
						    x_returnStatus => x_return_status
						    );
		   IF (x_return_status  = fnd_api.g_ret_sts_success) THEN
		      IF (l_debug = 1) THEN
			 inv_log_util.trace('Success from:!!postInvWIPValid', 'INV_TXN_MANAGER_PUB',1);
		      END IF;

		       
		      --J-dev check that all records for line validation are failed here.
		      --bug 3727791
		      --check for batch error at line validation
		      loaderrmsg('INV_GROUP_ERROR','INV_GROUP_ERROR');
		      
		      UPDATE MTL_TRANSACTIONS_INTERFACE MTI
			SET LAST_UPDATE_DATE = SYSDATE,
			LAST_UPDATED_BY = l_userid,
			LAST_UPDATE_LOGIN = l_loginid,
			PROGRAM_UPDATE_DATE = SYSDATE,
			PROCESS_FLAG = 3,
			LOCK_FLAG = 2,
			ERROR_CODE = substrb(l_error_code,1,240)
			WHERE TRANSACTION_HEADER_ID = l_header_id
			AND PROCESS_FLAG = 1
			AND EXISTS
			(SELECT 'Y'
			 FROM MTL_TRANSACTIONS_INTERFACE MTI2
			 WHERE MTI2.TRANSACTION_HEADER_ID = l_header_id
			 AND MTI2.PROCESS_FLAG = 3
			 AND MTI2.ERROR_CODE IS NOT NULL
             AND MTI2.TRANSACTION_BATCH_ID = MTI.TRANSACTION_BATCH_ID);

/* Commented following and added EXISTS clause above for bug 7371786
			AND TRANSACTION_BATCH_ID IN
			(SELECT DISTINCT MTI2.TRANSACTION_BATCH_ID
			 FROM MTL_TRANSACTIONS_INTERFACE MTI2
			 WHERE MTI2.TRANSACTION_HEADER_ID = l_header_id
			 AND MTI2.PROCESS_FLAG = 3
			 AND MTI2.ERROR_CODE IS NOT NULL);
*/
			 --group error changes.

		      
		      IF FND_API.To_Boolean( p_commit ) then
			 COMMIT WORK; /* Commit after PostInvWip all MTI records */
		      END IF;
		      --check if all records have been failed by the wip API.
		BEGIN
		   SELECT transaction_source_type_id INTO l_source_type_id
		     FROM MTL_TRANSACTIONS_INTERFACE
		     WHERE TRANSACTION_HEADER_ID = l_header_id
		     AND PROCESS_FLAG = 1  
		     AND ROWNUM < 2;
		EXCEPTION 
		   WHEN NO_DATA_FOUND THEN
		      x_return_status := FND_API.G_RET_STS_ERROR;
		      x_msg_data := 'No Transaction found in MTI after PostInvWIP';
		      RETURN -1;            
		END;
		    ELSE
		      IF (l_debug = 1) THEN
			 inv_log_util.trace('Failure from:!!postInvWIPProcessing', 'INV_TXN_MANAGER_PUB',1);
		      END IF;
		      RAISE fnd_api.g_exc_unexpected_error;
		   end if;--check for success 	  
		END IF;
		-- ADD tmp Insert here. In case of an error raise an exception.
		--J-dev
		IF (NOT tmpinsert(l_header_id)) THEN
		   l_error_exp := FND_MESSAGE.get;
		   IF (l_debug = 1) THEN
		      inv_log_util.trace('Error in tmpinsert='|| l_error_exp, 'INV_TXN_MANAGER_PUB', 9);
		   END IF;
		   FND_MESSAGE.set_name('INV','INV_INT_TMPXFRCODE');
		   l_error_code := FND_MESSAGE.get;
		   
		   RAISE fnd_api.g_exc_unexpected_error;
		END IF;
		--- End J dev
		IF FND_API.To_Boolean( p_commit ) then
		   COMMIT WORK; /* Commit after validating all MTI records */
		END IF;
		/* Delete the errored out flow schedules */
		IF ( inv_txn_manager_grp.gi_flow_schedule <> 0 ) THEN
		   WIP_FLOW_UTILITIES.Delete_Flow_Schedules(l_header_id) ;
		END IF;
		
		SELECT count(*)
		  INTO l_midtotrows
		  FROM MTL_MATERIAL_TRANSACTIONS_TEMP
		  WHERE TRANSACTION_HEADER_ID = l_header_id
		  AND PROCESS_FLAG = 'Y';
		
		DELETE FROM MTL_MATERIAL_TRANSACTIONS_TEMP
		  WHERE TRANSACTION_HEADER_ID = l_header_id
		  AND SHIPPABLE_FLAG = 'N'
		  AND PROCESS_FLAG = 'Y';
		
		IF (l_debug = 1) THEN
		   inv_log_util.trace('Goint for rows in MMTT. rcnt = '|| l_midtotrows||',hdrid='||l_header_id, 'INV_TXN_MANAGER_PUB', 9);
		END IF;
		
		done := FALSE;
		first := TRUE;
		while (NOT done) LOOP
		   SAVEPOINT process_trx_save;
		   IF (first) THEN
		      
		      FND_MESSAGE.set_name('INV','INV_CALL_PROC');
		      FND_MESSAGE.set_token('token1',l_header_id);
		      FND_MESSAGE.set_token('token2',l_totrows);
		      l_disp := FND_MESSAGE.get;  
		      IF (l_debug = 1) THEN
			 inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
		      END IF;
		      
		      --FND_MESSAGE.set_name('INV','INV_RETURN_PROC');
		      --l_disp := FND_MESSAGE.get;  
		      --inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
		      
		      SELECT count(*)
			INTO l_totrows
			FROM MTL_MATERIAL_TRANSACTIONS_TEMP
			WHERE TRANSACTION_HEADER_ID = l_header_id
			AND PROCESS_FLAG = 'Y';
		      
		      x_trans_count := l_totrows;
		      
		      IF (l_totrows = 0) THEN
			 
			 FND_MESSAGE.set_name('INV','INV_PROC_WARN');
			 l_disp := FND_MESSAGE.get;  
			 IF (l_debug = 1) THEN
			    inv_log_util.trace(l_disp || ' totrows = 0', 'INV_TXN_MANAGER_PUB',9);
			 END IF;
			 
			 return -1;
		      END IF;
		      
		      IF FND_API.To_Boolean( p_commit ) then
			 COMMIT WORK;
		       ELSE 
			 SAVEPOINT process_trx_save;
		      END IF;
		   END IF;
		   
		   /*WIP J-dev Add another condtion in the if
		   /* statement below. if WIP.J is not installed call
		   /* wip_mtlTempProc_grp()...else call process_lpn_trx()*/
		   -- If transactions are of type WIP, then call the WIP API. This
		   -- API does the WIP pre-processing before calling process_lpn_trx
		   IF (l_srctypeid = 5 AND wip_constants.dmf_patchset_level< wip_constants.DMF_PATCHSET_J_VALUE) THEN
		      wip_mtlTempProc_grp.processtemp
			(
			 p_initMsgList => FND_API.G_FALSE, 
			 p_processInv => FND_API.G_TRUE, -- call INV TM after WIP logic
			 p_txnHdrID  => l_header_id,
			 x_returnStatus => l_return_status ,
			 x_errormsg     => l_msg_data);
		      if (l_return_status <> fnd_api.g_ret_sts_success) then
			 IF (l_debug = 1) THEN
			    inv_log_util.trace('Failure from WIP processTemp!!', 'INV_TXN_MANAGER_PUB',1);
			 END IF;
			 l_result := -1;
		      end if;
		    ELSE
		      l_result := INV_LPN_TRX_PUB.process_lpn_trx
			(
			 p_trx_hdr_id => l_header_id,
			 p_commit   => p_commit,
			 x_proc_msg => l_msg_data,
			 p_proc_mode => 1,
			 p_process_trx => fnd_api.g_true,
			 p_atomic => fnd_api.g_false );
		   END IF;
		   
		   
		   IF (l_result <> 0) THEN
		      l_error_exp := l_msg_data;
		      x_msg_data := l_msg_data;
		      x_return_status := l_return_status;
		      FND_MESSAGE.set_name('INV','INV_INT_PROCCODE');
		      l_error_code := FND_MESSAGE.get;
		      
		      IF (l_debug = 1) THEN
			 inv_log_util.trace('PROCESS_LPN_TRX failed for header_id ' || l_header_id, 'INV_TXN_MANAGER_PUB',1);
			 inv_log_util.trace('Error.... ' || l_error_exp, 'INV_TXN_MANAGER_PUB',9);
		      END IF;

                      -- Bug 5710072: Deleting MSNT/MTLT/MMTT for the headerId, in case they are still present and did not
                      --              get deleted in TM.
                      delete from mtl_serial_numbers_temp
                      where transaction_temp_id in ( 
                      select mmtt.transaction_temp_id
                      from mtl_material_transactions_temp mmtt
                      where mmtt.transaction_header_id = l_header_id );

                      delete from mtl_serial_numbers_temp
                      where transaction_temp_id in (
                      select mtlt.serial_transaction_temp_id
                      from mtl_transaction_lots_temp mtlt
                      where mtlt.transaction_temp_id in (
                      select mmtt.transaction_temp_id
                      from mtl_material_transactions_temp mmtt
                      where mmtt.transaction_header_id = l_header_id));
                    
		      DELETE from mtl_transaction_lots_temp
                      where transaction_temp_id in
                      ( select mmtt.transaction_temp_id
                      from MTL_MATERIAL_TRANSACTIONS_TEMP mmtt
                      WHERE mmtt.TRANSACTION_HEADER_ID = l_header_id );

                      DELETE FROM MTL_MATERIAL_TRANSACTIONS_TEMP
                      WHERE TRANSACTION_HEADER_ID = l_header_id;

                      IF (l_debug = 1) THEN
			 inv_log_util.trace('Deleted MSNT/MTLT/MMTT for header_id ' || l_header_id, 'INV_TXN_MANAGER_PUB',1);
	              END IF;

                      -- End of change for bug 5710072

                      
		      IF FND_API.To_Boolean( p_commit ) then
			 COMMIT WORK;
		      END IF;
		      return -1;
		   END IF;
		   
		   IF (l_debug = 1) THEN
		      inv_log_util.trace('After process_lpn_trx without errors','INV_TXN_MANAGER_PUB', 9);
		   END IF;
		   
		   IF FND_API.To_Boolean( p_commit ) then
		      COMMIT WORK;
		   END IF;
		   
		   IF (first) THEN
		      IF (l_debug = 1) THEN
			 inv_log_util.trace('Calling bflushchk','INV_TXN_MANAGER_PUB',9);
		      END IF;
               IF (NOT bflushchk(l_header_id)) THEN
		  l_error_code := FND_MESSAGE.get;
		  IF (l_debug = 1) THEN
		     inv_log_util.trace('Error in bflushchk header_id:' || l_header_id || ' - ' || l_error_code,'INV_TXN_MANAGER_PUB',9);
		  END IF;
		  --ROLLBACK TO process_trx_save;
		  return -1;
               END IF;
               IF (l_header_id <> -1) THEN
		  FND_MESSAGE.set_name('INV','INV_BFLUSH_PROC');
		  l_disp := FND_MESSAGE.get;
		  IF (l_debug = 1) THEN
		     inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
		  END IF;
		  
		  SELECT count(*)
		    INTO l_totrows
		    FROM MTL_MATERIAL_TRANSACTIONS_TEMP
                    WHERE TRANSACTION_HEADER_ID = l_header_id
		    AND PROCESS_FLAG = 'Y';
		  
		  IF (l_debug = 1) THEN
		     inv_log_util.trace('totrows is ' || l_totrows, 'INV_TXN_MANAGER_PUB', 9);
		  END IF;
		  
		  IF (l_totrows > 200) THEN
		     
		     UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
		       SET TRANSACTION_HEADER_ID = (-1) * l_header_id
		       WHERE TRANSACTION_HEADER_ID = l_header_id
		       AND PROCESS_FLAG = 'Y';
		     
		     UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
		       SET TRANSACTION_HEADER_ID = ABS(l_header_id)
		       WHERE TRANSACTION_HEADER_ID = (-1)* (l_header_id)
		       AND PROCESS_FLAG = 'Y'
		       AND ROWNUM < 201;
		  END IF;
		  FND_MESSAGE.set_name('INV','INV_CALL_PROC');
		  FND_MESSAGE.set_token('token1',l_header_id);
		  FND_MESSAGE.set_token('token2',l_totrows);
		  l_disp := FND_MESSAGE.get;  
		  IF (l_debug = 1) THEN
		     inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
		  END IF;
		  
		ELSE
		  done := TRUE;
		  
		  first := FALSE;
	       END IF;
	       
		    ELSE
		      UPDATE MTL_MATERIAL_TRANSACTIONS_TEMP
			SET TRANSACTION_HEADER_ID = abs(l_header_id)
			WHERE TRANSACTION_HEADER_ID = (-1) * (l_header_id)
			AND PROCESS_FLAG = 'Y'
			AND ROWNUM < 201;                   
		      IF SQL%NOTFOUND THEN
			 FND_MESSAGE.set_name('INV','INV_RETURN_PROC');
			 l_disp := FND_MESSAGE.get;  
			 IF (l_debug = 1) THEN
			    inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
			 END IF;
			 done := TRUE;
		      END IF;
		   END IF;
		END LOOP;
		
		IF (l_initotrows > l_midtotrows) THEN
		   FND_MESSAGE.set_name('INV','INV_MGR_WARN');
		   l_disp := FND_MESSAGE.get;  
		   IF (l_debug = 1) THEN
		      inv_log_util.trace(l_disp, 'INV_TXN_MANAGER_PUB',9);
		      inv_log_util.trace(l_initotrows - l_midtotrows || ' Transactions did not pass validation', 'INV_TXN_MANAGER_PUB',9);
		   END IF;
		   return -1;
		 ELSE
		   return 0;
		END IF;
		
     END IF;
     
     return 0;
     
     
  EXCEPTION
     WHEN OTHERS THEN
	IF (l_debug = 1) THEN
	   inv_log_util.trace('*** SQL error '||substr(sqlerrm, 1, 200), 'INV_TXN_MANAGER_PUB',9);
	END IF;
	
	FND_MESSAGE.set_name('INV','INV_INT_SQLCODE');
	l_error_code := FND_MESSAGE.get;

	IF NOT FND_API.To_Boolean( p_commit ) then
	   ROLLBACK TO PROCESS_TRANSACTIONS_SVPT;
	 ELSE
	   ROLLBACK WORK;
	END IF;
	
	UPDATE MTL_TRANSACTIONS_INTERFACE
	  SET LAST_UPDATE_DATE = SYSDATE,
	  LAST_UPDATED_BY = l_userid,
	  LAST_UPDATE_LOGIN = l_loginid,
	  PROGRAM_UPDATE_DATE = SYSDATE,
	  PROCESS_FLAG = 3,
	  LOCK_FLAG = 2,
	  ERROR_CODE = substrb(l_error_code,1,240),
	  ERROR_EXPLANATION = substrb(l_error_exp,1,240)
	  WHERE TRANSACTION_HEADER_ID = l_header_id
	  AND PROCESS_FLAG = 1;
	
	IF FND_API.To_Boolean( p_commit ) then
	   COMMIT WORK;
	END IF;
	
	return -1;
	
  END process_Transactions;


/******************************************************************
 *
 * Name: insert_relief
 * Description:
 *  Creates a row in MRP_RELIEF_INTERFACE with the values it's passed.
 * This process was taken from mrlpr1.ppc to facilitate PLtion of PL/SQL TM API
 *
 ******************************************************************/
FUNCTION insert_relief(p_new_order_qty NUMBER, p_new_order_date DATE,
              p_old_order_qty NUMBER, p_old_order_date DATE, p_item_id NUMBER, p_org_id NUMBER,
              p_disposition_id NUMBER, p_user_id NUMBER, p_line_num VARCHAR2, p_relief_type NUMBER,
              p_disposition VARCHAR2,p_demand_class VARCHAR2)
RETURN BOOLEAN
IS
BEGIN

    IF (p_relief_type = MDS_RELIEF) THEN
            IF (p_disposition <> R_SALES_ORDER) THEN
                    FND_MESSAGE.set_name('MRP','GEN-invalid entity');
                    FND_MESSAGE.set_token('ENTITY','disposition');
                    FND_MESSAGE.set_token('VALUE',p_disposition);
                    return(FALSE);
            END IF;
    ELSE
       IF (p_relief_type = MPS_RELIEF) THEN
            IF (p_disposition <> R_WORK_ORDER) AND (p_disposition <> R_PURCH_ORDER) THEN
                    FND_MESSAGE.set_name('MRP','GEN-invalid entity');
                    FND_MESSAGE.set_token('ENTITY','disposition');
                    FND_MESSAGE.set_token('VALUE',p_disposition);
                    return(FALSE);
            END IF;
        ELSE
            FND_MESSAGE.set_name('MRP','GEN-invalid entity');
            FND_MESSAGE.set_token('ENTITY','relief_type');
            FND_MESSAGE.set_token('VALUE',p_relief_type);
            return(FALSE);
        END IF;
    END IF;


    INSERT INTO mrp_relief_interface (
             transaction_id,
             inventory_item_id,
             organization_id,
             relief_type,
             disposition_type,
             last_update_date,
             last_updated_by,
             creation_date,
             created_by,
             last_update_login,
             new_order_quantity,
             new_order_date,
             old_order_quantity,
             old_order_date,
             disposition_id,
             demand_class,
             process_status,
             line_num)
      VALUES (
         mrp_relief_interface_s.nextval,
             p_item_id,
             p_org_id,
             p_relief_type,
             p_disposition,
             SYSDATE,
             p_user_id,
             SYSDATE,
             p_user_id,
             -1,
             p_new_order_qty,
             p_new_order_date,
             p_old_order_qty,
             p_old_order_date,
             p_disposition_id,
             p_demand_class,
             TO_BE_PROCESSED,
             p_line_num);

    return(TRUE);

EXCEPTION
    WHEN OTHERS THEN
         IF (l_debug = 1) THEN
            inv_log_util.trace('Error in insert_relief','INV_TXN_MANAGER_PUB',9);
            inv_log_util.trace('SQL : ' || substr(sqlerrm, 1, 200), 'INV_TXN_MANAGER_PUB','9');
         END IF;
         return(FALSE);
END insert_relief;


/******************************************************************
 | Name: mrp_ship_order
 | Description:
 |       Creates a row in MRP_RELIEF_INTERFACE with the values it's passed.
 ******************************************************************/
FUNCTION mrp_ship_order(p_disposition_id NUMBER, p_inv_item_id NUMBER, p_quantity NUMBER, 
			p_last_updated_by NUMBER, p_org_id NUMBER, p_line_num VARCHAR2, 
			p_shipment_date DATE,p_demand_class VARCHAR2)
RETURN BOOLEAN
AS
BEGIN

    IF (NOT insert_relief(p_quantity,
         p_shipment_date,
         0,
         NULL,
         p_inv_item_id,
         p_org_id,
         p_disposition_id,
         p_last_updated_by,
         p_line_num,
         MDS_RELIEF,
         R_SALES_ORDER,
         p_demand_class) ) THEN
        return(FALSE);
    ELSE
        return(TRUE);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         IF (l_debug = 1) THEN
            inv_log_util.trace('Error in mrp_ship_order','INV_TXN_MANAGER_PUB',9);
            inv_log_util.trace('SQL : ' || substr(sqlerrm, 1, 200), 'INV_TXN_MANAGER_PUB','9');
         END IF;
         return(FALSE);

END mrp_ship_order;


/******************************************************************
 *
 * post_temp_validation()
 *
 ******************************************************************/
FUNCTION post_temp_validation(p_line_rec_type line_rec_type
                                   , p_val_req NUMBER
                                   , p_userid NUMBER
                                   , p_flow_schedule NUMBER
                                   , p_lot_number VARCHAR2 -- Added for 4374599
                                   ) RETURN BOOLEAN
IS
      CURSOR Z1 (p_flow_sch NUMBER) IS 
       SELECT
         p_line_rec_type.ROWID,
         p_line_rec_type.INVENTORY_ITEM_ID,
         p_line_rec_type.REVISION,
         p_line_rec_type.ORGANIZATION_ID,
         p_line_rec_type.SUBINVENTORY_CODE,
         p_line_rec_type.LOCATOR_ID,
         ABS(p_line_rec_type.PRIMARY_QUANTITY),
         NULL,
         p_line_rec_type.TRANSACTION_SOURCE_TYPE_ID,
         p_line_rec_type.TRANSACTION_ACTION_ID,
         p_line_rec_type.TRANSACTION_TYPE_ID,            /*Bug:4712499*/
         p_line_rec_type.TRANSACTION_SOURCE_ID,
         p_line_rec_type.TRANSACTION_SOURCE_NAME,
         to_char(p_line_rec_type.SOURCE_LINE_ID),
         MSI.REVISION_QTY_CONTROL_CODE,
         MSI.LOT_CONTROL_CODE,
         decode(p_line_rec_type.TRANSACTION_ACTION_ID,2,p_line_rec_type.TRANSFER_SUBINVENTORY,28,p_line_rec_type.TRANSFER_SUBINVENTORY,null),
         p_line_rec_type.TRANSFER_LOCATOR,
	 p_line_rec_type.TRANSACTION_DATE,
	 MP.NEGATIVE_INV_RECEIPT_CODE
    FROM MTL_PARAMETERS MP,
         MTL_SYSTEM_ITEMS MSI
   WHERE MP.ORGANIZATION_ID = p_line_rec_type.ORGANIZATION_ID
     -- AND MP.NEGATIVE_INV_RECEIPT_CODE = 2
     AND p_line_rec_type.PROCESS_FLAG = 1
     -- AND p_line_rec_type.SHIPPABLE_FLAG='Y'
     AND MSI.LOT_CONTROL_CODE = 1
     AND (   (p_flow_sch <> 1
          AND p_line_rec_type.TRANSACTION_ACTION_ID IN (1,2,3,21,32,34,5) )
	     OR(p_flow_sch = 1
		AND p_line_rec_type.TRANSACTION_ACTION_ID = 32 )
	   )
     AND MSI.ORGANIZATION_ID = MP.ORGANIZATION_ID
     AND MSI.ORGANIZATION_ID = p_line_rec_type.ORGANIZATION_ID
     AND MSI.INVENTORY_ITEM_ID = p_line_rec_type.INVENTORY_ITEM_ID
   UNION
     SELECT
       p_line_rec_type.ROWID,
       p_line_rec_type.INVENTORY_ITEM_ID,
       p_line_rec_type.REVISION,
       p_line_rec_type.ORGANIZATION_ID,
       p_line_rec_type.SUBINVENTORY_CODE,
       p_line_rec_type.LOCATOR_ID,
       ABS(MTLI.PRIMARY_QUANTITY),            
       MTLI.LOT_NUMBER,
       p_line_rec_type.TRANSACTION_SOURCE_TYPE_ID,
       p_line_rec_type.TRANSACTION_ACTION_ID,
       p_line_rec_type.TRANSACTION_TYPE_ID,   /*Bug:4712499*/
       p_line_rec_type.TRANSACTION_SOURCE_ID,
       p_line_rec_type.TRANSACTION_SOURCE_NAME,
       to_char(p_line_rec_type.SOURCE_LINE_ID),
       MSI.REVISION_QTY_CONTROL_CODE,
       MSI.LOT_CONTROL_CODE,
       decode(p_line_rec_type.TRANSACTION_ACTION_ID,2,p_line_rec_type.TRANSFER_SUBINVENTORY,28,p_line_rec_type.TRANSFER_SUBINVENTORY,5,p_line_rec_type.transfer_subinventory,null),
       p_line_rec_type.TRANSFER_LOCATOR,
       p_line_rec_type.TRANSACTION_DATE,
       MP.NEGATIVE_INV_RECEIPT_CODE
  FROM MTL_TRANSACTION_LOTS_INTERFACE MTLI,
       MTL_PARAMETERS MP,
       MTL_SYSTEM_ITEMS MSI
 WHERE MP.ORGANIZATION_ID = p_line_rec_type.ORGANIZATION_ID
   -- AND MP.NEGATIVE_INV_RECEIPT_CODE = 2
   -- AND p_line_rec_type.SHIPPABLE_FLAG='Y'
   AND MTLI.TRANSACTION_INTERFACE_ID = p_line_rec_type.TRANSACTION_INTERFACE_ID
   AND p_line_rec_type.PROCESS_FLAG = 1
   AND TS_DEFAULT <> TS_SAVE_ONLY
   AND MSI.LOT_CONTROL_CODE = 2
   AND (   (p_flow_sch <> 1
          AND p_line_rec_type.TRANSACTION_ACTION_ID IN (1,2,3,21,32,34,5) )
	     OR(p_flow_sch = 1
	AND p_line_rec_type.TRANSACTION_ACTION_ID = 32 )
      )
   AND MSI.ORGANIZATION_ID = MP.ORGANIZATION_ID
   AND MSI.ORGANIZATION_ID = p_line_rec_type.ORGANIZATION_ID
   AND MSI.INVENTORY_ITEM_ID = p_line_rec_type.INVENTORY_ITEM_ID
   AND MTLI.LOT_NUMBER = NVL(p_lot_number, MTLI.LOT_NUMBER); -- Added for 4374599


   CURSOR C1 IS
   SELECT   A.ORGANIZATION_ID,
            A.INVENTORY_ITEM_ID,
            NVL(A.TRANSACTION_SOURCE_ID, 0),
            A.TRANSACTION_SOURCE_TYPE_ID,
            A.TRX_SOURCE_DELIVERY_ID,
            A.TRX_SOURCE_LINE_ID,
            A.REVISION,
            DECODE(C.LOT_CONTROL_CODE, 2, B.LOT_NUMBER, A.LOT_NUMBER),
            A.SUBINVENTORY_CODE, A.LOCATOR_ID,
            DECODE (C.LOT_CONTROL_CODE, 2,
                    ABS(NVL(B.PRIMARY_QUANTITY,0)),
                    A.PRIMARY_QUANTITY *(-1)),
            A.TRANSACTION_SOURCE_NAME,
            A.TRANSACTION_DATE,
	    A.CONTENT_LPN_ID
   FROM     MTL_SYSTEM_ITEMS C,
            MTL_TRANSACTION_LOTS_TEMP B,
            MTL_MATERIAL_TRANSACTIONS_TEMP A
   WHERE    A.TRANSACTION_HEADER_ID = p_line_rec_type.Transaction_Header_Id
   AND      A.TRANSACTION_TEMP_ID = p_line_rec_type.Transaction_Interface_Id
   AND      A.ORGANIZATION_ID = C.ORGANIZATION_ID
   AND      A.INVENTORY_ITEM_ID = C.INVENTORY_ITEM_ID
   AND      B.TRANSACTION_TEMP_ID (+) = A.TRANSACTION_TEMP_ID
   AND      A.PRIMARY_QUANTITY < 0
   ORDER BY A.TRANSACTION_SOURCE_TYPE_ID,
            A.TRANSACTION_SOURCE_ID,
            A.TRANSACTION_SOURCE_NAME,
            A.TRX_SOURCE_LINE_ID,
            A.TRX_SOURCE_DELIVERY_ID,
            A.INVENTORY_ITEM_ID,
            A.ORGANIZATION_ID;

   l_tempid NUMBER; 
   l_item_id NUMBER; 
   l_org_id NUMBER; 
   l_locid NUMBER; 
   l_srctypeid NUMBER; 
   l_actid NUMBER; 
   l_trxtypeid NUMBER;   --Bug:4712499
   l_srcid NUMBER; 
   l_xlocid NUMBER;
   l_temp_rowid VARCHAR2(21); 
   l_sub_code VARCHAR2(11); 
   l_lotnum VARCHAR2(31); 
   l_src_code VARCHAR2(30); 
   l_xfrsub VARCHAR2(11);
   l_rev VARCHAR2(4); 
   l_srclineid VARCHAR2(40);
   l_trxdate DATE;
   l_qoh NUMBER;  
   l_rqoh NUMBER; 
   l_pqoh NUMBER; 
   l_qr NUMBER; 
   l_qs NUMBER; 
   l_att NUMBER; 
   l_atr NUMBER;

   l_rctrl NUMBER;
   l_lctrl NUMBER;
   l_flow_schedule NUMBER;
   l_trx_qty NUMBER; 
   l_qty  NUMBER := 0; 
   tree_exists BOOLEAN; 
   l_revision_control BOOLEAN;
   l_lot_control BOOLEAN;
   l_disp  VARCHAR2(3000);
   l_msg_count  NUMBER;
   l_msg_data   VARCHAR2(2000);
   l_return_status VARCHAR2(1);
   l_tree_id NUMBER;

   /* Added the following variables for Bug 3462946 */ 
   l_neg_inv_rcpt number; 
   l_cnt_res number;
   l_item_qoh NUMBER;
   l_item_rqoh NUMBER;
   l_item_pqoh NUMBER;
   l_item_qr NUMBER;
   l_item_qs NUMBER;
   l_item_att NUMBER;
   l_item_atr NUMBER;

   /* Additional Variables needed to handle TrxRsvRelief code */
   l_ship_qty             NUMBER;
   l_userline             VARCHAR2(40);
   l_demand_class         VARCHAR2(30);
   l_mps_flag             NUMBER;
   l_deliveryid           NUMBER;

   l_lpnid	          NUMBER;

   TargetNode NUMBER;
  x_errd_int_id NUMBER;

   l_procedure_name VARCHAR2(60) := g_pkg_name||'.'||'post_temp_validation';
   l_progress_indicator  VARCHAR2(10);

   -- Enhancement made for the customer: eToys (BUG: 5521801)
   l_override_rsv NUMBER := 2;

BEGIN

    IF (l_debug IS NULL) THEN
        l_debug := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
    END IF;

    IF (l_debug = 1) THEN
       inv_log_util.trace('$Header: INVTXMGB.pls 115.107.115100.21 2009/11/11 16:12:23 juherber ship $',l_procedure_name, 9);
    END IF;

    l_progress_indicator := '10';

    /**********************************************/
    /* the reservation was successfully releived. */
    /* now if we did ship a +ve qty for a intord  */
    /* or a sales order, then we need to notify   */
    /* mrp about this shipment                    */
    /**********************************************/
   
    IF (p_val_req = 1) THEN

       OPEN Z1(p_flow_schedule);
    
       l_progress_indicator := '20';
       tree_exists := FALSE;
       WHILE (TRUE) LOOP
               
          l_progress_indicator := '30';
          FETCH Z1 INTO
                    l_temp_rowid,
                    l_item_id,
                    l_rev,
                    l_org_id,
                    l_sub_code,
                    l_locid,
                    l_trx_qty,
                    l_lotnum,
                    l_srctypeid,
                    l_actid,
                    l_trxtypeid,   /*Bug:4712499*/
                    l_srcid,
                    l_src_code,
		    l_srclineid,
                    l_rctrl,
                    l_lctrl,
                    l_xfrsub,
                    l_xlocid,
		    l_trxdate,
		    l_neg_inv_rcpt;
    
          IF Z1%NOTFOUND THEN

             l_progress_indicator := '40';
             IF (l_debug = 1) THEN
   		inv_log_util.trace('No more rows to validate quantity',l_procedure_name, 9);
             END IF;
             EXIT;

          END IF; -- Z1 Not found
  
          l_progress_indicator := '50';

	  IF l_rctrl = 1 THEN
             l_revision_control := FALSE;
          ELSE
             l_revision_control := TRUE;
          END IF;

          IF l_lctrl = 1 THEN
             l_lot_control := FALSE;
          ELSE
             l_lot_control := TRUE;
          END IF;
        
          tree_exists := TRUE;

-- Bug 2399354  The tree to be cleared prior to creating a tree to avoid
	       --	       using existing trees
	       
	       /*** free cache ***/
          IF p_line_rec_type.TRANSACTION_INTERFACE_ID IS NULL THEN

             IF (l_debug = 1) THEN
                inv_log_util.trace('Transaction interface id is NULL ' ,l_procedure_name, 9);
             END IF;

             l_progress_indicator := '60';
             INV_QUANTITY_TREE_PVT.clear_quantity_cache;

             l_progress_indicator := '70';
             INV_QUANTITY_TREE_PVT.create_tree
		  (   p_api_version_number       => 1.0
		   ,  p_init_msg_lst             => fnd_api.g_false
		   ,  x_return_status            => l_return_status
		   ,  x_msg_count                => l_msg_count
		   ,  x_msg_data                 => l_msg_data
		   ,  p_organization_id          => l_org_id
		   ,  p_inventory_item_id        => l_item_id
		   ,  p_tree_mode                => 2
		   ,  p_is_revision_control      => l_revision_control
		   ,  p_is_lot_control           => l_lot_control
		   ,  p_is_serial_control        => FALSE
		   ,  p_include_suggestion       => FALSE
		   ,  p_demand_source_type_id    => nvl(l_srctypeid,-9999)
		   ,  p_demand_source_header_id  => nvl(l_srcid,-9999)
		   ,  p_demand_source_line_id    => nvl(l_srclineid,-9999)
		   ,  p_demand_source_name       => l_src_code
		   ,  p_demand_source_delivery   => NULL
		   ,  p_lot_expiration_date      => NULL
		   ,  x_tree_id                  => l_tree_id
		   ,  p_onhand_source            => 3 --g_all_subs
		   ,  p_exclusive                => 0 --g_non_exclusive
		   ,  p_pick_release             => 0 --g_pick_release_no
		) ;
   
   	     IF l_return_status = fnd_api.g_ret_sts_error THEN
                l_progress_indicator := '80';
                inv_log_util.trace('Error while creating tree : x_msg_data = '|| l_msg_data,l_procedure_name, 9);
                FND_MESSAGE.set_name('INV','INV_ERR_CREATETREE');
                FND_MESSAGE.set_token('ROUTINE','UE:AVAIL_TO_TRX');
   
                l_error_code := FND_MESSAGE.get;  
                l_error_exp := l_msg_data;  
                RAISE fnd_api.g_exc_error;
             END IF ;

             IF l_return_status = fnd_api.g_ret_sts_unexp_error THEN
                l_progress_indicator := '90';
                inv_log_util.trace('Unexpected Error while creating tree : '|| l_msg_data,l_procedure_name, 9);
                l_error_exp := l_msg_data;  
                RAISE fnd_api.g_exc_unexpected_error;
             END IF;

             tree_exists := TRUE;
             g_tree_id := l_tree_id;
             IF (l_debug = 1) THEN
                inv_log_util.trace('Tree id is '||g_tree_id, l_procedure_name, 9);
             END IF;

          ELSE
 
             /*
              * Tree has been created in the calling program and it will free it
              */
             l_tree_id := g_tree_id;
             tree_exists := FALSE;

          END IF; -- interface_id is NULL
          IF (l_debug = 1) THEN
             inv_log_util.trace('Tree id is '||l_tree_id, l_procedure_name, 9);
             inv_log_util.trace('Revision is '||l_rev, l_procedure_name, 9);
             inv_log_util.trace('Lot is '||l_lotnum, l_procedure_name, 9);
             inv_log_util.trace('Sub is '||l_sub_code, l_procedure_name, 9);
             inv_log_util.trace('XfrSub is '||l_xfrsub, l_procedure_name, 9);
             inv_log_util.trace('Loc id is '||l_locid, l_procedure_name, 9);
          END IF;

          l_progress_indicator := '100';
          INV_QUANTITY_TREE_PVT.query_tree
		  	(   p_api_version_number   => 1.0
			   ,  p_init_msg_lst         => fnd_api.g_false
			   ,  x_return_status        => l_return_status
			   ,  x_msg_count            => l_msg_count
			   ,  x_msg_data             => l_msg_data
			   ,  p_tree_id              => l_tree_id
			   ,  p_revision             => l_rev
			   ,  p_lot_number           => l_lotnum
			   ,  p_subinventory_code    => l_sub_code
			   ,  p_transfer_subinventory_code    => l_xfrsub
			   ,  p_locator_id           => l_locid
			   ,  x_qoh                  => l_qoh
			   ,  x_rqoh                 => l_rqoh
			   ,  x_pqoh                 => l_pqoh
			   ,  x_qr                   => l_qr
			   ,  x_qs                   => l_qs
			   ,  x_att                  => l_att
			   ,  x_atr                  => l_atr
			  );

          IF l_return_status = fnd_api.g_ret_sts_error THEN
             l_progress_indicator := '110';
             inv_log_util.trace('Expected Error while querying tree : '|| l_msg_data,l_procedure_name, 9);
             l_error_code := FND_MESSAGE.get;
             l_error_exp := l_msg_data;
             FND_MESSAGE.set_name('INV','INV_INTERNAL_ERROR');
             FND_MESSAGE.set_token('token1','XACT_QTY1');
             RAISE fnd_api.g_exc_error;
          END IF ;

          IF l_return_status = fnd_api.g_ret_sts_unexp_error THEN
             l_progress_indicator := '120';
             inv_log_util.trace('UnExpected Error while querying tree : ' || l_msg_data,l_procedure_name, 9);
             l_error_code := FND_MESSAGE.get;
             l_error_exp := l_msg_data;
             FND_MESSAGE.set_name('INV','INV_INTERNAL_ERROR');
             FND_MESSAGE.set_token('token1','XACT_QTY1');
             RAISE fnd_api.g_exc_unexpected_error;
          END IF;

          IF (l_debug = 1) THEN
             inv_log_util.trace('L_QOH : ' || l_qoh,l_procedure_name, 9);
             inv_log_util.trace('L_RQOH : ' || l_rqoh,l_procedure_name, 9);
             inv_log_util.trace('L_PQOH : ' || l_pqoh,l_procedure_name, 9);
             inv_log_util.trace('L_QR : ' || l_qr,l_procedure_name, 9);
             inv_log_util.trace('L_QS : ' || l_qs,l_procedure_name, 9);
             inv_log_util.trace('L_ATT : ' || l_att,l_procedure_name, 9);
             inv_log_util.trace('L_ATR : ' || l_atr,l_procedure_name, 9);
          END IF;

          /* 
           * Bug: 3462946 : 
           * Added the code below to check for Negative Balances for a 
           * Negative Balances Allowed Org 
           */
          l_progress_indicator := '130';

	  -- Enhancement made for the customer: eToys (BUG: 5521801)
	  l_override_rsv := NVL(fnd_profile.value('INV_OVERRIDE_RSV_FOR_BACKFLUSH'), 2);
          
	  IF l_att < 0 THEN
             inv_log_util.trace('l_att is than zero',l_procedure_name, 9);
             IF (l_neg_inv_rcpt = 1) THEN 

                inv_log_util.trace('Negative Balance Allowed Org ',l_procedure_name, 9);
                IF (l_qr > 0 OR l_qs >0) THEN
--fix for bug 8990950
--If condition modified with AND l_srctypeid NOT IN (2,8,16)
		 IF (l_override_rsv = 1) AND l_srctypeid NOT IN (2,8,16) THEN
		      IF (l_debug = 1) THEN
			inv_log_util.trace('Do not check low level reservations',l_procedure_name, 9);
		      END IF;
		 ELSE
                   inv_log_util.trace('Transaction quantity must be less than or equal to available quantity',l_procedure_name, 9);                        
                   FND_MESSAGE.set_name('INV','INV_INT_PROCCODE');
                   l_error_code := FND_MESSAGE.get;
                   FND_MESSAGE.set_name('INV','INV_QTY_LESS_OR_EQUAL');
		   FND_MSG_PUB.add;
                   l_error_exp := FND_MESSAGE.get;
                   RAISE fnd_api.g_exc_error;
		 END IF;
                END IF;  -- l_qr > 0 OR l_qs > 0

                l_progress_indicator := '140';
                INV_QUANTITY_TREE_PVT.query_tree
                        (   p_api_version_number   => 1.0
                           ,  p_init_msg_lst         => fnd_api.g_false
                           ,  x_return_status        => l_return_status
                           ,  x_msg_count            => l_msg_count
                           ,  x_msg_data             => l_msg_data
                           ,  p_tree_id              => l_tree_id
                           ,  p_revision             => NULL 
                           ,  p_lot_number           => NULL 
			   ,  p_subinventory_code    => NULL
			   ,  p_locator_id           => NULL 
                           ,  x_qoh                  => l_item_qoh
                           ,  x_rqoh                 => l_item_rqoh
                           ,  x_pqoh                 => l_item_pqoh
                           ,  x_qr                   => l_item_qr
                           ,  x_qs                   => l_item_qs
                           ,  x_att                  => l_item_att
                           ,  x_atr                  => l_item_atr
                          );

                IF l_return_status = fnd_api.g_ret_sts_error THEN
                   l_progress_indicator := '150';
                   inv_log_util.trace('Expected Error while querying tree : ' || l_msg_data,l_procedure_name, 9);
                   l_error_code := FND_MESSAGE.get;
                   l_error_exp := l_msg_data;
                   FND_MESSAGE.set_name('INV','INV_INTERNAL_ERROR');
                   FND_MESSAGE.set_token('token1','XACT_QTY1');
                   RAISE fnd_api.g_exc_error;
                END IF ;

                IF l_return_status = fnd_api.g_ret_sts_unexp_error THEN
                   l_progress_indicator := '160';
                   inv_log_util.trace('UnExpected Error while querying tree : ' || l_msg_data,l_procedure_name, 9);
                   l_error_code := FND_MESSAGE.get;
                   l_error_exp := l_msg_data;
                   FND_MESSAGE.set_name('INV','INV_INTERNAL_ERROR');
                   FND_MESSAGE.set_token('token1','XACT_QTY1');
                   RAISE fnd_api.g_exc_unexpected_error;
                END IF;

                IF (l_debug = 1) THEN
                   inv_log_util.trace('L_ITEM_QOH : ' || l_item_qoh,l_procedure_name, 9);
                   inv_log_util.trace('L_ITEM_RQOH : ' || l_item_rqoh,l_procedure_name, 9);
                   inv_log_util.trace('L_ITEM_PQOH : ' || l_item_pqoh,l_procedure_name, 9);
                   inv_log_util.trace('L_ITEM_QR : ' || l_item_qr,l_procedure_name, 9);
                   inv_log_util.trace('L_ITEM_QS : ' || l_item_qs,l_procedure_name, 9);
                   inv_log_util.trace('L_ITEM_ATT : ' || l_item_att,l_procedure_name, 9);
                   inv_log_util.trace('L_ITEM_ATR : ' || l_item_atr,l_procedure_name, 9);
                   inv_log_util.trace('L_TRX_QTY : ' || l_trx_qty,l_procedure_name, 9);
                END IF;

                l_progress_indicator := '170';
                IF (l_item_qoh <> l_item_att) THEN -- Higher Level Reservations
                   IF (l_item_att < 0 AND l_item_qr > 0) THEN
                   /*
		    *  ------------------------------------------------------------
		    *  Enhancement made for the customer: eToys (BUG: 5521801)
		    *  ------------------------------------------------------------
		    *  Description:
		    * ------------
		    *  This fix will allow the TM to process the transactions posted in MTI by bypassing
		    *  the reservation validation. This feature is achieved by using the profile option.
		    *  Profile Used: INV_OVERRIDE_RSV_FOR_BACKFLUSH
		    *
		    *  For the existing customers, the DEFAULT behavior is that the transactions 
		    *  will go through the reservation validation. The transaction error out if any 
		    *  reservations exist for that item thererby not allowing the inventory to be 
		    *  driven negative.
		    * 
		    *  The above default behavior can be overridden by setting the profile to 'YES'
		    *  thereby immitating the functionality that existed in 11.5.8
		    *  Note:
		    *  -----
		    *  Kindly refer the BUG for an eloborate problem description.
		    */

--Fix for bug 8990950
--If condition modified with AND l_srctypeid NOT IN (2,8,16)
		       IF (l_override_rsv = 1) AND l_srctypeid NOT IN (2,8,16) THEN
			IF (l_debug = 1) THEN
				inv_log_util.trace('Do not check high level reservations',l_procedure_name, 9);
			END IF;
		       ELSE
			 l_progress_indicator := '180';
			 IF (l_debug = 1) THEN
				inv_log_util.trace('Total Org quantity cannot become negative when there are reservations present',l_procedure_name, 9);
			 END IF;
                         FND_MESSAGE.set_name('INV','INV_INT_PROCCODE');
                         l_error_code := FND_MESSAGE.get;
                         FND_MESSAGE.set_name('INV','INV_ORG_QUANTITY');
			 FND_MSG_PUB.add;
                         l_error_exp := FND_MESSAGE.get;
                         RAISE fnd_api.g_exc_error;
		       END IF;

		      /*
		       * The following immediate code is commented inorder to immitate the
		       * 11.5.8 functionality (The re-engineered code can be viewed above).
		       * Now, the 1158 and 11510 functionality co-exist and the expected behavior
		       * can be chosen by setting the profile mentioned in the description above.
		       *
                       * Bug:4712499. 
                       * For subinventory and backflush transfers high level 
                       * reservations should not be checked 
                       */

		    /*
		      IF ( l_srctypeid = 13 AND l_actid = 2 AND l_trxtypeid not in (66,67,68) ) THEN
                         inv_log_util.trace('Do not check high level reservations for subinventory and backflush transfers',l_procedure_name, 9);
                      ELSE
                         l_progress_indicator := '180';
                         inv_log_util.trace('Total Org quantity cannot become negative when there are reservations present',l_procedure_name, 9);
                         FND_MESSAGE.set_name('INV','INV_INT_PROCCODE');
                         l_error_code := FND_MESSAGE.get;
                         FND_MESSAGE.set_name('INV','INV_ORG_QUANTITY');
                         l_error_exp := FND_MESSAGE.get;
                         RAISE fnd_api.g_exc_error;
                      END IF; -- l_srctypeid = 13...
		    */
				
                   END IF; -- l_item_att < 0...
                END IF; -- l_item_att

             ELSE --if (neg_inv_rcpt = 1)
                l_progress_indicator := '190';
                FND_MESSAGE.set_name('INV','INV_NO_NEG_BALANCES');
                l_error_code := FND_MESSAGE.get;
                FND_MESSAGE.set_name('INV','INV_LESS_OR_EQUAL');
                FND_MESSAGE.set_token('ENTITY1','INV_QUANTITY');
                FND_MESSAGE.set_token('ENTITY2','AVAIL_TO_TRANSACT');
                l_error_exp := FND_MESSAGE.get;
                RAISE fnd_api.g_exc_error;
                   --exit;
             END IF; -- neg_inv_rcpt..

          END IF; -- l_att < 0
          /* End of changes for Bug 3462946 */
             
       END LOOP;

       l_progress_indicator := '200';

       CLOSE Z1; 

       l_progress_indicator := '210';
       IF (tree_exists) THEN
          l_progress_indicator := '220';
          INV_QUANTITY_TREE_PVT.free_All
		  	(   p_api_version_number   => 1.0
			   ,  p_init_msg_lst         => fnd_api.g_false
			   ,  x_return_status        => l_return_status
			   ,  x_msg_count            => l_msg_count
			   ,  x_msg_data             => l_msg_data);
       END IF;

    END IF; -- p_val_req = 1
    x_errd_int_id := -9876;
    RETURN TRUE;

EXCEPTION
   WHEN OTHERS THEN
      inv_log_util.trace('Error in post_temp_validation ' , l_procedure_name,1);
      inv_log_util.trace('progress_indicator : ' || l_progress_indicator, l_procedure_name,1);
      inv_log_util.trace('Error : ' || l_error_code, l_procedure_name,1);
      inv_log_util.trace('SQL : ' || substr(sqlerrm, 1, 200), l_procedure_name,1);
      x_errd_int_id := -9876;
      RETURN FALSE;

END post_temp_validation;

PROCEDURE  rel_reservations_mrp_update (p_header_id IN NUMBER,
				       p_transaction_temp_id IN NUMBER,
				       p_res_sts OUT NOCOPY VARCHAR2,
				       p_res_msg OUT NOCOPY VARCHAR2,
				       p_res_count OUT NOCOPY NUMBER,
				       p_mrp_status OUT NOCOPY VARCHAR2)
  
  IS
     CURSOR C1 IS
	SELECT   A.ORGANIZATION_ID,
	  A.INVENTORY_ITEM_ID,
	  NVL(A.TRANSACTION_SOURCE_ID, 0),
	  A.TRANSACTION_SOURCE_TYPE_ID,    
	  A.TRX_SOURCE_DELIVERY_ID,
	  A.TRX_SOURCE_LINE_ID,
	  A.REVISION,
	  DECODE(C.LOT_CONTROL_CODE, 2, B.LOT_NUMBER, A.LOT_NUMBER),
	  A.SUBINVENTORY_CODE, A.LOCATOR_ID,
	  DECODE (C.LOT_CONTROL_CODE, 2,
		  ABS(NVL(B.PRIMARY_QUANTITY,0)),
		  A.PRIMARY_QUANTITY *(-1)),
	  A.TRANSACTION_SOURCE_NAME,
	  A.TRANSACTION_DATE,
	  A.content_lpn_id,
	  A.PRIMARY_QUANTITY,--
	  A.transaction_action_id,
          A.transaction_type_id,     /*Bug:4712499*/
	  A.transfer_subinventory,
	  A.transfer_to_location,
	  Decode(A.process_flag,'Y',1,'N',2,'E',3,3),
	  A.shippable_flag,
	  B.transaction_temp_id,--lot record identifier in MTLT
	  MP.NEGATIVE_INV_RECEIPT_CODE --Fix for bug 8990950
	  FROM     MTL_SYSTEM_ITEMS C,
	  MTL_TRANSACTION_LOTS_TEMP B,
	  MTL_MATERIAL_TRANSACTIONS_TEMP A,
	  MTL_PARAMETERS MP --Fix for bug 8990950
	  WHERE    A.TRANSACTION_HEADER_ID = p_header_id
	  AND      A.TRANSACTION_TEMP_ID = p_transaction_temp_id
	  AND      A.ORGANIZATION_ID = C.ORGANIZATION_ID
	  AND      A.INVENTORY_ITEM_ID = C.INVENTORY_ITEM_ID
	  AND      MP.ORGANIZATION_ID = A.ORGANIZATION_ID --Fix for bug 8990950
	  AND      B.TRANSACTION_TEMP_ID (+) = A.TRANSACTION_TEMP_ID
--	  AND      A.PRIMARY_QUANTITY < 0  /* Bug: 3462946: This clause is commented as BaseTransaction.java already does this validation */
	  ORDER BY A.TRANSACTION_SOURCE_TYPE_ID,
	  A.TRANSACTION_SOURCE_ID,
	  A.TRANSACTION_SOURCE_NAME,
	  A.TRX_SOURCE_LINE_ID,
	  A.TRX_SOURCE_DELIVERY_ID,
	  A.INVENTORY_ITEM_ID,
	  A.ORGANIZATION_ID;
     
     l_return_status  VARCHAR2(1); 
     l_msg_count NUMBER; 
     l_msg_data VARCHAR2(2000);
     l_ship_qty NUMBER;
     l_userline VARCHAR2(40);
     l_demand_class  VARCHAR2(30);
     l_mps_flag NUMBER;
     l_org_id NUMBER;
     l_item_id NUMBER;
     l_sub_code VARCHAR2(11);
     l_locid NUMBER;
     l_lotnum VARCHAR2(31);
     l_rev VARCHAR2(4);
     l_srctypeid NUMBER;
     l_srcid NUMBER;
     l_src_code VARCHAR2(30);
     l_srclineid VARCHAR2(40);
     l_deliveryid NUMBER;
     l_trx_qty NUMBER;
     l_trxdate DATE;
     l_userid NUMBER;
     l_lpnid NUMBER;
     l_line_rec_type line_rec_type;

     l_loginid NUMBER;

     tree_exists BOOLEAN := FALSE;
     l_tree_id NUMBER;
     l_lctrl NUMBER;
     l_rctrl NUMBER;
     l_revision_control BOOLEAN := FALSE;
     l_lot_control BOOLEAN := FALSE;

     l_procedure_name VARCHAR2(60) := g_pkg_name||'.'||'rel_reservations_mrp_update';
     l_progress_indicator  VARCHAR2(10);
     
--Fix for bug 8990950
     l_neg_inv_rcpt NUMBER;
     l_override_rsv NUMBER := 2;
BEGIN
   
   IF (l_debug IS NULL) THEN
      l_debug := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
   END IF;

   IF (l_debug = 1) THEN
      inv_log_util.trace('$Header: INVTXMGB.pls 115.107.115100.21 2009/11/11 16:12:23 juherber ship $' ,l_procedure_name, 9);
   END IF;
   
   l_progress_indicator := '10';

   -- Bug 3296008: caching the USER_ID profile value.
   IF (g_userid is null) THEN
      g_userid := NVL(FND_PROFILE.value('USER_ID'), -1);
   END IF;
   l_userid := g_userid;

   l_progress_indicator := '20';
   --Bug 3517647: Moved the login ID from within the cursor so that
   -- it doesnt get executed for every line
   l_loginid := fnd_global.login_id;
   
   IF l_loginid IS NULL THEN
      l_loginid := -1;
   END IF;
	    
   IF (l_debug = 1) THEN
      inv_log_util.trace('USERID='||l_userid,l_procedure_name, 9);
      inv_log_util.trace('LOGINID='||l_loginid,l_procedure_name, 9);
   END IF;

   p_mrp_status := 'S';
   p_res_sts := 'S';
   p_res_msg := '';
   p_res_count := 0;
--Fix for bug 8990950
  l_override_rsv := NVL(fnd_profile.value('INV_OVERRIDE_RSV_FOR_BACKFLUSH'), 2);
   
   l_progress_indicator := '30';
   OPEN C1;
      
   l_progress_indicator := '40';
   LOOP

      l_progress_indicator := '50';
      FETCH C1 INTO
	   l_org_id,
	   l_item_id,
	   l_srcid,
	   l_srctypeid,
	   l_deliveryid,---
	   l_srclineid,
	   l_rev,
	   l_lotnum,
	   l_sub_code,
	   l_locid,
	   l_trx_qty,
	   l_src_code,
	   l_trxdate,
	   l_lpnid,
	   l_line_rec_type.PRIMARY_QUANTITY,
	   l_line_rec_type.TRANSACTION_ACTION_ID,
	   l_line_rec_type.TRANSACTION_TYPE_ID,    /*Bug:4712499*/
	   l_line_rec_type.transfer_subinventory,
	   l_line_rec_type.transfer_locator,
	   l_line_rec_type.process_flag, 
	   l_line_rec_type.shippable_flag,
	   l_line_rec_type.transaction_interface_id,
	   l_neg_inv_rcpt;			   --Fix for bug 8990950

      IF C1%NOTFOUND THEN
         l_progress_indicator := '60';
	 IF (l_debug = 1) THEN
   	    inv_log_util.trace('No more rows to relieve',l_procedure_name, 9);
	 END IF;
	 p_res_sts := 'S';
	 p_res_msg := '';
	 p_res_count := 0;
	 EXIT;
      END IF;
	 
      l_progress_indicator := '70';
      inv_trx_relief_c_pvt.rsv_relief
	   (x_return_status       => l_return_status,
	    x_msg_count           => l_msg_count,
	    x_msg_data            => l_msg_data,
	    x_ship_qty            => l_ship_qty,--it will be the quantity relieved FROM this api
	    x_userline            => l_userline,
	    x_demand_class        => l_demand_class,
	    x_mps_flag            => l_mps_flag,
	    p_organization_id     => l_org_id,
	    p_inventory_item_id   => l_item_id,
	    p_subinv              => l_sub_code,
	    p_locator             => l_locid,
	    p_lotnumber           => l_lotnum,
	    p_revision            => l_rev,
	    p_dsrc_type           => l_srctypeid,
	    p_header_id           => l_srcid,
	    p_dsrc_name           => l_src_code,
	    p_dsrc_line           => l_srclineid,
	    p_dsrc_delivery       => NULL,--l_deliveryid bug2745896
	    p_qty_at_puom         => abs(l_trx_qty),
	    p_lpn_id	      => l_lpnid
	    );

      l_progress_indicator := '80';
      IF (l_debug = 1) THEN
         inv_log_util.trace('l_return_status : '||l_return_status,l_procedure_name, 9);
         inv_log_util.trace('l_ship_qty : '||l_ship_qty,l_procedure_name, 9); 
         inv_log_util.trace('l_userline : ' || l_userline,l_procedure_name, 9); 
         inv_log_util.trace('l_demand_class : ' || l_demand_class,l_procedure_name, 9);
         inv_log_util.trace('l_mps_flag  : ' || l_mps_flag,l_procedure_name, 9);
         inv_log_util.trace('l_org_id : '||l_org_id,l_procedure_name, 9);
         inv_log_util.trace('l_item_id : ' || l_item_id,l_procedure_name, 9);
         inv_log_util.trace('l_sub_code: ' || l_sub_code,l_procedure_name, 9);
         inv_log_util.trace('l_locid : ' || l_locid,l_procedure_name, 9); 
         inv_log_util.trace('l_lotnum : ' || l_lotnum,l_procedure_name, 9);
         inv_log_util.trace('l_rev : ' || l_rev,l_procedure_name, 9);
         inv_log_util.trace('l_srctypeid : ' || l_srctypeid,l_procedure_name,9);
         inv_log_util.trace('l_header_id '|| l_srcid,l_procedure_name, 9);
         inv_log_util.trace('l_dsrc_name : ' || l_src_code,l_procedure_name, 9); 
         inv_log_util.trace('l_dsrc_line : ' || l_srclineid,l_procedure_name, 9);
         inv_log_util.trace('l_dsrc_delivery :' || l_deliveryid,l_procedure_name, 9);
         inv_log_util.trace('l_dsrc_delivery :' ||l_deliveryid,l_procedure_name, 9);
         inv_log_util.trace('l_trx_qty : ' ||l_trx_qty,l_procedure_name, 9); 
         inv_log_util.trace('l_lpnid : ' || l_lpnid,l_procedure_name, 9); 
      END IF;
	 
      p_res_sts := l_return_status;
      p_res_msg := l_msg_data;
      p_res_count := l_msg_count;

      IF l_return_status <> fnd_api.g_ret_sts_success THEN
         l_progress_indicator := '90';
         IF (l_debug = 1) THEN
            inv_log_util.trace('x_msg_data = ' || l_msg_data,l_procedure_name, 9);
            inv_log_util.trace('Before error return in TrxRsvRelief',l_procedure_name, 9);
         END IF;
         RETURN;

      ELSE  -- success

         l_progress_indicator := '100';
         IF (l_debug = 1) THEN
            inv_log_util.trace('Reservation was successfully relieved',l_procedure_name, 9);
         END IF;
         IF (abs(l_trx_qty)<> 0) AND (l_srctypeid = SALORDER OR l_srctypeid = INTORDER) AND
	      (l_mps_flag <> 0) THEN

            l_progress_indicator := '110';
            IF (l_debug = 1) THEN
               inv_log_util.trace('Calling mrp_ship_order',l_procedure_name, 9);
            END IF;
	       
            IF (NOT mrp_ship_order(l_srclineid, l_item_id,abs(l_trx_qty),
				      l_userid, l_org_id, l_userline,
				      l_trxdate, l_demand_class)) THEN
               l_progress_indicator := '120';
               IF (l_debug = 1) THEN
                  inv_log_util.trace('mrp_ship_order failure',l_procedure_name, 9);
               END IF;
               p_mrp_status := 'E';	       
               RETURN;
            END IF; -- mrp_ship_order

            l_progress_indicator := '130';
	    IF (l_debug = 1) THEN
   	       inv_log_util.trace('After mrp__order',l_procedure_name, 9);
	    END IF;
	 END IF; -- l_trx_qty > 0

      END IF; -- l_return_success

      l_progress_indicator := '130';
--Fix for bug 8990950
--Extra conditions added in if loop. (l_neg_inv_rcpt and l_override_rsv)
--To improve the performance Qty tree is not created if org is negetive balance allowed,
--reservation over ride profile is set to yes and transaction type is not SO, ISO and Project Contract
--i.e. Qty tree has to be created if transaction type is in SO or ISO or Project contract or Neg balance not allowed,
--or over ride profile is set to false.
      IF l_ship_qty <> abs(l_trx_qty)
       AND (l_neg_inv_rcpt <> 1  OR l_override_rsv <> 1
            OR  l_srctypeid IN (2,8,16)) THEN --in this case there 
	    
         IF (l_debug = 1) THEN
            inv_log_util.trace('l_PRIMARY_QUANTITY: '||l_line_rec_type.PRIMARY_QUANTITY,l_procedure_name,9);
            inv_log_util.trace('l_transaction_action_id: '||l_line_rec_type.transaction_action_id,l_procedure_name,9);
            inv_log_util.trace('l_transaction_type_id: '||l_line_rec_type.transaction_type_id,l_procedure_name,9);
            inv_log_util.trace('l_process_flag :'||l_line_rec_type.process_flag,l_procedure_name, 9);	    
            inv_log_util.trace('l_shippable_flag : '||l_line_rec_type.shippable_flag,l_procedure_name,9);
         END IF;
	    
	 l_line_rec_type.inventory_item_id :=l_item_id;
	 l_line_rec_type.revision := l_rev;
	 l_line_rec_type.organization_id := l_org_id;
	 l_line_rec_type.subinventory_code :=  l_sub_code;
	 l_line_rec_type.locator_id := l_locid ;
	 l_line_rec_type.transaction_source_type_id :=l_srctypeid;
	 l_line_rec_type.transaction_source_id := l_srcid;
	 l_line_rec_type.transaction_source_name := l_src_code;
	 l_line_rec_type.source_line_id :=l_srclineid;
	 l_line_rec_type.transaction_date:= l_trxdate;	    
	 
         l_progress_indicator := '1301';
         BEGIN
            SELECT lot_control_code,
                   revision_qty_control_code
            INTO   l_lctrl,
                   l_rctrl
            FROM   mtl_system_items_b
            WHERE  organization_id = l_org_id
            AND    inventory_item_id = l_item_id;
         EXCEPTION 
            WHEN NO_DATA_FOUND THEN
               l_lctrl := 0;
               l_rctrl := 0;
         END;

         l_progress_indicator := '1305';
         IF l_rctrl = 1 THEN
            l_revision_control := FALSE;
         ELSE
            l_revision_control := TRUE;
         END IF;

         IF l_lctrl = 1 THEN
            l_lot_control := FALSE;
         ELSE
            l_lot_control := TRUE;
         END IF;

         IF (l_line_rec_type.transaction_interface_id IS NOT NULL  ) AND ( g_interface_id IS NULL OR g_interface_id <> l_line_rec_type.transaction_interface_id ) THEN

            l_progress_indicator := '135';
	    INV_QUANTITY_TREE_PVT.clear_quantity_cache;
	       
            l_progress_indicator := '1351';
	    INV_QUANTITY_TREE_PVT.create_tree
		    (   p_api_version_number       => 1.0
		     ,  p_init_msg_lst             => fnd_api.g_false
		     ,  x_return_status            => l_return_status
		     ,  x_msg_count                => l_msg_count
		     ,  x_msg_data                 => l_msg_data
		     ,  p_organization_id          => l_org_id
		     ,  p_inventory_item_id        => l_item_id
		     ,  p_tree_mode                => 2
		     ,  p_is_revision_control      => l_revision_control
		     ,  p_is_lot_control           => l_lot_control
		     ,  p_is_serial_control        => FALSE
		     ,  p_include_suggestion       => FALSE
		     ,  p_demand_source_type_id    => nvl(l_srctypeid,-9999)
		     ,  p_demand_source_header_id  => nvl(l_srcid,-9999)
		     ,  p_demand_source_line_id    => nvl(l_srclineid,-9999)
		     ,  p_demand_source_name       => l_src_code
		     ,  p_demand_source_delivery   => NULL
		     ,  p_lot_expiration_date      => NULL
		     ,  x_tree_id                  => l_tree_id
		     ,  p_onhand_source            => 3 --g_all_subs
		     ,  p_exclusive                => 0 --g_non_exclusive
		     ,  p_pick_release             => 0 --g_pick_release_no
		  ) ;
  
   	    IF l_return_status = fnd_api.g_ret_sts_error THEN
               IF (l_debug = 1) THEN
                  inv_log_util.trace('Error while creating tree : x_msg_data = ' || l_msg_data,l_procedure_name, 9);
               END IF;
	       FND_MESSAGE.set_name('INV','INV_ERR_CREATETREE');
	       FND_MESSAGE.set_token('ROUTINE','UE:AVAIL_TO_TRX');
  
               l_error_code := FND_MESSAGE.get;  
               l_error_exp := l_msg_data;  
               RAISE fnd_api.g_exc_error;
            END IF ;

            IF l_return_status = fnd_api.g_ret_sts_unexp_error THEN
               IF (l_debug = 1) THEN
                  inv_log_util.trace('Unexpected Error while creating tree : ' || l_msg_data,l_procedure_name, 9);
               END IF;
               l_error_exp := l_msg_data;  
               RAISE fnd_api.g_exc_unexpected_error;
            END IF;

            g_interface_id := l_line_rec_type.transaction_interface_id;
            tree_exists := TRUE;
            g_tree_id := l_tree_id;
            IF (l_debug = 1) THEN
               inv_log_util.trace('Tree id is '||g_tree_id, l_procedure_name, 9);
            END IF;

         END IF; /* interface id has changed */
	    --qty-tree validation
         l_progress_indicator := '140';
         IF ( ( NOT post_temp_validation(
                      l_line_rec_type 
                    , 1 --always validate it
                    , l_userid 
                    , inv_txn_manager_grp.gi_flow_schedule
                    , l_lotnum -- Added for 4374599
                    ))) THEN
            l_progress_indicator := '140';
            l_error_code := FND_MESSAGE.get;
	       
            UPDATE MTL_TRANSACTIONS_INTERFACE
            SET    LAST_UPDATE_DATE = SYSDATE,
                   LAST_UPDATED_BY = l_userid,
                   LAST_UPDATE_LOGIN = l_loginid,
                   PROGRAM_UPDATE_DATE = SYSDATE,
                   PROCESS_FLAG = 3,
                   LOCK_FLAG = 2,
                   ERROR_CODE = substrb(l_error_code,1,180),
                   ERROR_EXPLANATION = substrb(l_error_exp,1,180)
          --WHERE ROWID = l_Line_rec_type.rowid
            WHERE TRANSACTION_INTERFACE_ID = p_transaction_temp_id
            AND   PROCESS_FLAG = 1
            AND   ORGANIZATION_ID = l_org_id
            AND   INVENTORY_ITEM_ID = l_item_id
            AND   NVL(SUBINVENTORY_CODE,'@@@@') = NVL(l_sub_code,'@@@@');

            l_progress_indicator := '150';
            UPDATE MTL_TRANSACTIONS_INTERFACE
            SET    LAST_UPDATE_DATE = SYSDATE,
                   LAST_UPDATED_BY = l_userid,
                   LAST_UPDATE_LOGIN = l_loginid,
                   PROGRAM_UPDATE_DATE = SYSDATE,
                   PROCESS_FLAG = 3,
                   LOCK_FLAG = 2,
                   ERROR_CODE = substrb(l_error_code,1,180)
          --WHERE TRANSACTION_HEADER_ID = l_header_id
            WHERE TRANSACTION_INTERFACE_ID = p_transaction_temp_id
            AND   PROCESS_FLAG = 1;

            IF (l_debug = 1) THEN
               inv_log_util.trace('After Error in post_temp_validation continue...', l_procedure_name, 9);
            END IF;
            RAISE fnd_api.g_exc_error;
	       
         END IF;
      END IF;
      l_progress_indicator := '160';
   END LOOP;
   l_progress_indicator := '170';
   CLOSE C1;
      
   l_progress_indicator := '180';
   IF (tree_exists) THEN
      l_progress_indicator := '190';
      INV_QUANTITY_TREE_PVT.free_All
		  	(   p_api_version_number   => 1.0
			   ,  p_init_msg_lst         => fnd_api.g_false
			   ,  x_return_status        => l_return_status
			   ,  x_msg_count            => l_msg_count
			   ,  x_msg_data             => l_msg_data);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      inv_log_util.trace('Exception Raised : ' || l_progress_indicator, l_procedure_name,1);
      inv_log_util.trace('***Undef Error Ex..rel_res : ' || substr(sqlerrm, 1, 200), l_procedure_name,1);
      inv_log_util.trace('When others Ex..rel_reservations_mrp_update ' || l_error_code, l_procedure_name,1);
      p_res_sts := 'E';
      p_mrp_status := 'E'; 
      
END rel_reservations_mrp_update ;

/* Bug 4331753: Added this new procedure so that data is moved from snapshot interface to temp table
   by calling the API CSTPACMS.validate_move_snap_to_temp for every wip completion record 
   in MTI (non workorderless) for an Average/LIFO/FIFO costed org. */

PROCEDURE validate_move_snap_to_temp(
    p_header_id     IN   NUMBER,
    x_return_status OUT  NOCOPY VARCHAR2) IS
      
    CURSOR valid_mti_wip_csr (p_trx_header_id NUMBER)
    IS SELECT ROWID "ROW_ID", transaction_interface_id, organization_id, primary_quantity
       FROM mtl_transactions_interface
       WHERE transaction_header_id = p_trx_header_id
        AND transaction_source_type_id = 5
        AND transaction_action_id IN (30, 31, 32)       
        AND process_flag = 1
	AND UPPER(NVL(flow_schedule,'N')) = 'N';
    
    l_primary_cost_method   NUMBER;
    l_error_num             NUMBER;
    l_count                 NUMBER;
    l_cst_temp              NUMBER;
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0);
       
    BEGIN

    IF (l_debug = 1) THEN
	inv_log_util.trace('In validate_move_snap_to_temp', 'INV_TXN_MANAGER_PUB', 9);
    END IF;

        l_count := 0;
        
        FOR valid_mti_wip_rec IN valid_mti_wip_csr(p_header_id) LOOP
        
    	    SELECT PRIMARY_COST_METHOD
    		INTO   l_primary_cost_method
    		FROM   MTL_PARAMETERS 
    		WHERE  ORGANIZATION_ID = valid_mti_wip_rec.organization_id;
      
            IF (l_primary_cost_method = 2 OR l_primary_cost_method = 5 
                 OR l_primary_cost_method = 6 ) THEN
                             
    		 l_cst_temp := CSTPACMS.validate_move_snap_to_temp
        		   (l_txn_interface_id => valid_mti_wip_rec.transaction_interface_id,
        		    l_txn_temp_id      => valid_mti_wip_rec.transaction_interface_id,
        		    l_interface_table  => 1, -- for inventory l_interface_table=1
        		    l_primary_quantity => valid_mti_wip_rec.primary_quantity,
        		    err_num            => l_error_num,
        		    err_code           => l_error_code,
        		    err_msg            => l_error_exp);
                    IF l_error_exp IS NOT NULL THEN
                            errupdate(valid_mti_wip_rec.row_id);
                            l_count := l_count + 1;
                            RAISE fnd_api.g_exc_error;
                    END IF;
            END IF;
        END LOOP;
        
        IF (l_count = 0) THEN
	    IF (l_debug = 1) THEN
		inv_log_util.trace('Snapshot move successfull', 'INV_TXN_MANAGER_PUB', 9);
	    END IF; 
            x_return_status := fnd_api.g_ret_sts_success;
        END IF;

    EXCEPTION
        WHEN fnd_api.g_exc_error THEN
        	IF (l_debug = 1) THEN
        		inv_log_util.trace('Error occurred during snapshot move', 'INV_TXN_MANAGER_PUB', 9);
        	END IF;        
            x_return_status := fnd_api.g_ret_sts_error;
        
        WHEN OTHERS THEN
        	IF (l_debug = 1) THEN
        		inv_log_util.trace('Other error :='||SQLERRM, 'INV_TXN_MANAGER_PUB', 9);
        	END IF;        
            x_return_status := fnd_api.g_ret_sts_unexp_error;
                    
END validate_move_snap_to_temp;    

   
END INV_TXN_MANAGER_PUB;
/
--show errors;
commit;
exit;



