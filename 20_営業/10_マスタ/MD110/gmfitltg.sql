REM 
REM Bug 1939018 umoogala - Added for ARU db drv auto generation
REM 
REM dbdrv: sql ~PROD ~PATH ~FILE none none none sqlplus &phase=en+11 \
REM dbdrv: checkfile:nocheck
REM 
REM 
REM *hb************************************************************************
REM  SCRIPT NAME
REM 	gmfitltg.sql
REM 
REM  INPUT PARAMETERS
REM 		None
REM  RETURNS
REM 		None
REM 
REM  DESCRIPTION
REM	This SQL script will drop the existing trigger and create a new
REM	Database Trigger gmf_ic_item_tl_biur_tg on table  IC_ITEM_MST_TL. 
REM
REM	The gmf_ic_item_mst_tl_biur_tg will update the description in MLS
REM	tables of INV.
REM 
REM  USAGE
REM 
REM  AUTHOR
REM	Sanjay Rastogi - 06/11/2000  BUG 1325844
REM 
REM  HISTORY
REM  Jalaj Srivastava 11/08/2001 BUG 1868095 
REM    Modified the select for selecting orgs to be synched
REM  Jalaj Srivastava 01/30/2002 Bug 2206257
REM             This trigger was introdcued in OPM family pack G
REM             but the present code is incompatible with G
REM             'coz of data model changes
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
REM  Jalaj Srivastava Bug 2548269
REM    Description needs to be updated for even discrete child orgs
REM    if the attribute description is controlled at master level.
REM  Nayini Vikranth 02/13/2003 BUG#2673225
REM    Modified the where clause from 'source_lang = :new.source_lang' to
REM    'source_lang = :old.source_lang', such that correct item desctiopn gets
REM    synched to Discrete inventory for MLS Environment.
REM  Anil  06/03/2003  BUg#2673225 Added NVL function in the last condition of 
REM    update statement for description synchronization in Discrete. 
REM  Sastry 08/27/2003 BUG#3071034 Modified code to fetch the inventory_item_id
REM    by calling the newly added function GMIUTILS.get_inventory_item_id 
REM    instead of fetching from cursor c_inv_item_id_cur. The inventory_item_id
REM    is stored in package variable which can be accessed from other places
REM  Jalaj Srivastava Bug 3128085
REM    The cursor c_update_orgs should also return process child orgs which are not 
REM    defined in gmi_item_organizations table. Earlier it used to return only 
REM    discrete child orgs.
REM  Jalaj Srivastava Bug 3662953
REM    Cursor c_update_orgs should return only child orgs which are attached to the item. 
REM *************************************************************************************

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE TRIGGER GMF_IC_ITEM_MST_TL_BIUR_TG
/*       $Header: gmfitltg.sql 115.15.115100.1 2004/10/08 18:47:12 appldev ship $ */
AFTER INSERT OR UPDATE
ON  IC_ITEM_MST_TL
FOR EACH ROW
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Trigger Name     : GMF_IC_ITEM_MST_TL_BIUR_TG
 * Description      : OPM品目マスタトリガーの標準機能アドオン
 * MD.050           : 
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021.04.22    1.0   R.Oikawa         品目摘要の変更が無い場合は、Disc品目マスタの更新
 *                                       を通らないようにカスタマイズ
 *
 *****************************************************************************************/
DECLARE 

  /*  EXCEPTIONS */
  ex_item_not_inserted	exception;

  /*  VARIABLES  */ 
v_inventory_item_id		mtl_system_items.inventory_item_id%TYPE;
/* Variable to determine the item attribute control. Master or Child - B2548269 */
i_item_desc1			integer DEFAULT gmf_pr_item_ins.get_attribute_control('MTL_SYSTEM_ITEMS.DESCRIPTION');

  /* Following variables are used for stored procedure which extracts error message.*/ 

  v_msg_id		fnd_new_messages.MESSAGE_NUMBER%TYPE	:= -20000;
  v_msg_text		fnd_new_messages.message_text%TYPE;
  v_msg_code		fnd_new_messages.message_name%TYPE;
  v_op_code		fnd_new_messages.LAST_UPDATED_BY%TYPE   := :new.LAST_UPDATED_BY;
-- 2021.04.22 Ver.1.0 ADD START
  v_description  mtl_system_items_tl.description%TYPE := NULL;
-- 2021.04.22 Ver.1.0 ADD END

/* Declare cusrsor to select all organization to which the item will be replicated */
/* Added column to differentiate Process Child (P) vs. master (M). - B2548269 */
CURSOR c_inventory_org IS
	SELECT i.organization_id, 'P' org_type /* Process Orgs */
        FROM   mtl_parameters p,
	       gmi_item_organizations i 
	WHERE  i.organization_id = p.organization_id and
	       p.organization_id <> p.master_organization_id
        UNION
        SELECT p.master_organization_id, 'M' /* Master Orgs */
        FROM   mtl_parameters p,
               gmi_item_organizations g
        WHERE  p.organization_id        = g.organization_id; 

/* Declare Cursor to get existing inventory_item_id for atleast one organization */
CURSOR c_inv_item_id_cur(v_item_no in varchar2) IS
	SELECT 	inventory_item_id
	FROM 	mtl_system_items mtl
	WHERE 	mtl.segment1 = v_item_no
	AND 	ROWNUM = 1;
/* Cursor to select discrete child organization, whose master level controlled attributes may 
   need to be updated. B2548269 */
/* Jalaj Srivastava Bug 3128085
   This cursor should also return process child orgs which are not defined in 
   gmi_item_organizations table. What we need to do is whenever a master org is updated   
   all child orgs (discrete and process) should get updated with master level controlled attributes */   
/* Jalaj Srivastava Bug 3662953
   Return only child orgs which are attached to the item. */      
CURSOR c_update_orgs ( pmaster_org number,pinventory_item_id number) IS
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

BEGIN 

  gmf_sync_init.glsynch_initialize;
  IF (gmf_session_vars.GMI_INSTALLED = 'I' AND
      (gmf_session_vars.INV_INSTALLED = 'I' OR 
	gmf_session_vars.INV_INSTALLED = 'S')) THEN

	/* Generate the inventory_item_id if required */
	BEGIN
          -- BEGIN BUG#3071034 Sastry
          -- Commented the following code and added code to get the
          -- inventory_item_id from newly added function.          
          /*OPEN c_inv_item_id_cur(gmf_session_vars.item_no);
          FETCH c_inv_item_id_cur INTO v_inventory_item_id;
          CLOSE c_inv_item_id_cur;*/
          v_inventory_item_id := GMIUTILS.get_inventory_item_id(gmf_session_vars.item_no);
          IF v_inventory_item_id IS NULL THEN 
            raise ex_item_not_inserted;
          END IF;
          -- END BUG#3071034
        /* EXCEPTION
          When no_data_found then
            raise ex_item_not_inserted; */
	END;
-- 2021.04.22 Ver.1.0 ADD START
    BEGIN
      SELECT msit.description
      INTO   v_description
      FROM   mtl_system_items_tl msit,
             mtl_parameters mp
      WHERE  msit.inventory_item_id = v_inventory_item_id
      AND    msit.organization_id   = mp.organization_id
      AND    mp.organization_code   = 'ZZZ'
      AND    msit.language          = :new.language
      AND    msit.source_lang       = NVL(:old.source_lang,userenv('LANG'))
      ;
    EXCEPTION
      WHEN OTHERS THEN
        v_description  := NULL;
    END;
    --
    IF ( v_description <> :new.item_desc1 ) THEN
-- 2021.04.22 Ver.1.0 ADD END
	
	/* Loop thru all OPM linked inventory orgs */
	FOR r_inventory_org in c_inventory_org LOOP
	  <<update_of_item>>
       	  BEGIN
	    /* if the org is master, the following cursor will also return 
	       the discrete child orgs. B2548269 */
            FOR r_update_orgs in c_update_orgs(r_inventory_org.organization_id,v_inventory_item_id) LOOP
              /* The attributes should be updated as follow (B2548269):
			org type	control		Update
			0 (Process)	1 (Master)	Yes
			0		2 (Child)	Yes
			1 (Discrete)	1		Yes
			1		2		No  */
	        /*BEGIN BUG#2673225 Nayini Vikranth */ 
	        /*Correct Item Description will be synched to Discrete Inventory */	
	        /*Bug 2977656  Anil   Added NVL function in the last condition for description 
	          synchronization*/
	        UPDATE mtl_system_items_tl
		SET	description = decode (r_update_orgs.type*i_item_desc1, 2, description, :new.item_desc1),
			language = decode (r_update_orgs.type*i_item_desc1, 2,language, :new.language),
			source_lang = decode (r_update_orgs.type*i_item_desc1, 2,language, :new.source_lang),
			last_update_date = :new.last_update_date,
			last_updated_by = :new.last_updated_by
        	WHERE   organization_id = r_update_orgs.organization_id 
		AND 	inventory_item_id =  v_inventory_item_id 
		AND 	LANGUAGE = :new.language
		AND	source_lang = NVL(:old.source_lang,userenv('LANG'));
		/*END BUG#2673225*/
	     END LOOP;
	   END update_of_item;
	
	END LOOP;
-- 2021.04.22 Ver.1.0 ADD START
    END IF;
-- 2021.04.22 Ver.1.0 ADD END
  END IF; /* IF GMI AND INV(S, I) ARE INSTALLED */

EXCEPTION
	  /* handle  ALL COULD_NOT exceptions. */
	when ex_item_not_inserted then
		null;
END;
/
commit;
exit;
