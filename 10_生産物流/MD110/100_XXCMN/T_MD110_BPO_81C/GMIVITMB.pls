WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY GMI_ITEM_PVT AS
--$Header: GMIVITMB.pls 115.3 99/10/21 07:50:52 porting ship  $
-- Body start of comments
--+==========================================================================+
--|                   Copyright (c) 1998 Oracle Corporation                  | 
--|                          Redwood Shores, CA, USA                         | 
--|                            All rights reserved.                          |
--+==========================================================================+
--| FILE NAME                                                                |
--|    GMIVITMB.pls                                                          |
--|                                                                          |
--| PACKAGE NAME                                                             |
--|    GMI_ITEM_PVT                                                          |
--|                                                                          |
--| DESCRIPTION                                                              |
--|    This package contains all utility functions that insert/update Item   |
--|    related tables                                                        |
--|                                                                          |
--| CONTENTS                                                                 |
--|    Insert_Ic_Item_Mst                                                    |
--|    Insert_Ic_Item_Cpg                                                    |
--|                                                                          |
--| HISTORY                                                                  |
--|                                                                          |
--+==========================================================================+
-- Body end of comments

-- Global variables
G_PKG_NAME  CONSTANT  VARCHAR2(30) := 'GMI_ITEM_PVT';

-- Func start of comments
--+==========================================================================+
--|  FUNCTION NAME                                                           |
--|    Insert_Ic_Item_Mst                                                    |
--|                                                                          |
--|  USAGE                                                                   |
--|    Insert a row into ic_item_mst                                         |
--|                                                                          |
--|  DESCRIPTION                                                             |
--|    This procedure inserts a row into ic_item_mst                         |
--|                                                                          |
--|  PARAMETERS                                                              |
--|    p_ic_item_mst_rec IN RECORD - Item Master Details                     |
--|                                                                          |
--|  RETURNS                                                                 |
--|    TRUE  - If insert successful                                          |
--|    FALSE - If insert fails                                               |
--|                                                                          |
--|  HISTORY                                                                 |
--|    16-FEB-1999  M.Godfrey    Upgrade to R11                              |
--|    21-OCT-1999  H.Verdding   Added Addition Of Attribute Fields          |
--|                              B1042722                                    |
--|    11-NOV-2008  Y.Suzuki     Added Update Who Fields                     |
--|    18-NOV-2008  Y.Suzuki     Modified Update Who Fields                  |
--+==========================================================================+
-- Func end of comments
FUNCTION Insert_Ic_Item_Mst 
(p_ic_item_mst_rec  IN ic_item_mst%ROWTYPE)
RETURN BOOLEAN
IS

BEGIN

  INSERT INTO ic_item_mst
  ( item_id
  , item_no
  , item_desc1
  , item_desc2  
  , alt_itema    
  , alt_itemb    
  , item_um
  , dualum_ind 
  , item_um2
  , deviation_lo
  , deviation_hi
  , level_code  
  , lot_ctl
  , lot_indivisible
  , sublot_ctl
  , loct_ctl
  , noninv_ind
  , match_type
  , inactive_ind
  , inv_type
  , shelf_life  
  , retest_interval
  , item_abccode
  , gl_class
  , inv_class    
  , sales_class
  , ship_class
  , frt_class
  , price_class
  , storage_class
  , purch_class
  , tax_class
  , customs_class
  , alloc_class
  , planning_class
  , itemcost_class
  , cost_mthd_code
  , upc_code
  , grade_ctl
  , status_ctl  
  , qc_grade
  , lot_status
  , bulk_id
  , pkg_id
  , qcitem_id
  , qchold_res_code
  , expaction_code
  , fill_qty
  , fill_um
  , expaction_interval
  , phantom_type
  , whse_item_id
  , experimental_ind
  , exported_date
  , created_by
  , creation_date
  , last_updated_by
  , last_update_date
  , last_update_login
  , trans_cnt
  , delete_mark
  , text_code
  , seq_dpnd_class
  , commodity_code
  , attribute1
  , attribute2
  , attribute3
  , attribute4
  , attribute5
  , attribute6
  , attribute7
  , attribute8
  , attribute9
  , attribute10
  , attribute11
  , attribute12
  , attribute13
  , attribute14
  , attribute15
  , attribute16
  , attribute17
  , attribute18
  , attribute19
  , attribute20
  , attribute21
  , attribute22
  , attribute23
  , attribute24
  , attribute25
  , attribute26
  , attribute27
  , attribute28
  , attribute29
  , attribute30
  , attribute_category
  )
  VALUES
  ( p_ic_item_mst_rec.item_id
  , p_ic_item_mst_rec.item_no
  , p_ic_item_mst_rec.item_desc1
  , p_ic_item_mst_rec.item_desc2
  , p_ic_item_mst_rec.alt_itema
  , p_ic_item_mst_rec.alt_itemb
  , p_ic_item_mst_rec.item_um
  , p_ic_item_mst_rec.dualum_ind
  , p_ic_item_mst_rec.item_um2
  , p_ic_item_mst_rec.deviation_lo
  , p_ic_item_mst_rec.deviation_hi
  , p_ic_item_mst_rec.level_code
  , p_ic_item_mst_rec.lot_ctl
  , p_ic_item_mst_rec.lot_indivisible
  , p_ic_item_mst_rec.sublot_ctl
  , p_ic_item_mst_rec.loct_ctl
  , p_ic_item_mst_rec.noninv_ind
  , p_ic_item_mst_rec.match_type
  , p_ic_item_mst_rec.inactive_ind
  , p_ic_item_mst_rec.inv_type
  , p_ic_item_mst_rec.shelf_life
  , p_ic_item_mst_rec.retest_interval
  , p_ic_item_mst_rec.item_abccode
  , p_ic_item_mst_rec.gl_class
  , p_ic_item_mst_rec.inv_class
  , p_ic_item_mst_rec.sales_class
  , p_ic_item_mst_rec.ship_class
  , p_ic_item_mst_rec.frt_class
  , p_ic_item_mst_rec.price_class
  , p_ic_item_mst_rec.storage_class
  , p_ic_item_mst_rec.purch_class
  , p_ic_item_mst_rec.tax_class
  , p_ic_item_mst_rec.customs_class
  , p_ic_item_mst_rec.alloc_class
  , p_ic_item_mst_rec.planning_class
  , p_ic_item_mst_rec.itemcost_class
  , p_ic_item_mst_rec.cost_mthd_code
  , p_ic_item_mst_rec.upc_code
  , p_ic_item_mst_rec.grade_ctl
  , p_ic_item_mst_rec.status_ctl
  , p_ic_item_mst_rec.qc_grade
  , p_ic_item_mst_rec.lot_status
  , p_ic_item_mst_rec.bulk_id
  , p_ic_item_mst_rec.pkg_id
  , p_ic_item_mst_rec.qcitem_id
  , p_ic_item_mst_rec.qchold_res_code
  , p_ic_item_mst_rec.expaction_code
  , p_ic_item_mst_rec.fill_qty
  , p_ic_item_mst_rec.fill_um
  , p_ic_item_mst_rec.expaction_interval
  , p_ic_item_mst_rec.phantom_type
  , p_ic_item_mst_rec.whse_item_id
  , p_ic_item_mst_rec.experimental_ind
  , p_ic_item_mst_rec.exported_date
  , p_ic_item_mst_rec.created_by
  , p_ic_item_mst_rec.creation_date
  , p_ic_item_mst_rec.last_updated_by
  , p_ic_item_mst_rec.last_update_date
  , p_ic_item_mst_rec.last_update_login
  , p_ic_item_mst_rec.trans_cnt
  , p_ic_item_mst_rec.delete_mark
  , p_ic_item_mst_rec.text_code
  , p_ic_item_mst_rec.seq_dpnd_class
  , p_ic_item_mst_rec.commodity_code
  , p_ic_item_mst_rec.attribute1
  , p_ic_item_mst_rec.attribute2
  , p_ic_item_mst_rec.attribute3
  , p_ic_item_mst_rec.attribute4
  , p_ic_item_mst_rec.attribute5
  , p_ic_item_mst_rec.attribute6
  , p_ic_item_mst_rec.attribute7
  , p_ic_item_mst_rec.attribute8
  , p_ic_item_mst_rec.attribute9
  , p_ic_item_mst_rec.attribute10
  , p_ic_item_mst_rec.attribute11
  , p_ic_item_mst_rec.attribute12
  , p_ic_item_mst_rec.attribute13
  , p_ic_item_mst_rec.attribute14
  , p_ic_item_mst_rec.attribute15
  , p_ic_item_mst_rec.attribute16
  , p_ic_item_mst_rec.attribute17
  , p_ic_item_mst_rec.attribute18
  , p_ic_item_mst_rec.attribute19
  , p_ic_item_mst_rec.attribute20
  , p_ic_item_mst_rec.attribute21
  , p_ic_item_mst_rec.attribute22
  , p_ic_item_mst_rec.attribute23
  , p_ic_item_mst_rec.attribute24
  , p_ic_item_mst_rec.attribute25
  , p_ic_item_mst_rec.attribute26
  , p_ic_item_mst_rec.attribute27
  , p_ic_item_mst_rec.attribute28
  , p_ic_item_mst_rec.attribute29
  , p_ic_item_mst_rec.attribute30
  , p_ic_item_mst_rec.attribute_category
  );
  
--2008/11/11 yutsuzuk add start
--2008/11/18 yutsuzuk mod start
--  UPDATE ic_item_mst_b
--  SET program_application_id = p_ic_item_mst_rec.program_application_id
--    , program_id             = p_ic_item_mst_rec.program_id
--    , program_update_date    = p_ic_item_mst_rec.program_update_date
--    , request_id             = p_ic_item_mst_rec.request_id
--  WHERE  item_id = p_ic_item_mst_rec.item_id;
  UPDATE ic_item_mst_b
  SET program_application_id = FND_GLOBAL.PROG_APPL_ID
    , program_id             = FND_GLOBAL.CONC_PROGRAM_ID
    , program_update_date    = SYSDATE
    , request_id             = FND_GLOBAL.CONC_REQUEST_ID
  WHERE  item_id = p_ic_item_mst_rec.item_id;
--2008/11/18 yutsuzuk mod end
--2008/11/11 yutsuzuk add end

  RETURN TRUE;

  EXCEPTION

  WHEN OTHERS THEN
--     IF  FND_MSG_PUB.check_msg_level
--        (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
--     THEN
      
    FND_MSG_PUB.Add_Exc_Msg (  G_PKG_NAME
                             , 'insert_ic_item_mst'
                            );
--     END IF;
    RETURN FALSE;

END Insert_Ic_Item_Mst;

-- Func start of comments
--+==========================================================================+
--|  FUNCTION NAME                                                           |
--|    Insert_Ic_Item_Cpg                                                    |
--|                                                                          |
--|  USAGE                                                                   |
--|    Insert a row into ic_item_cpg                                         |
--|                                                                          |
--|  DESCRIPTION                                                             |
--|    This procedure inserts a row into ic_item_cpg                         |
--|                                                                          |
--|  PARAMETERS                                                              |
--|    p_ic_item_cpg_rec IN RECORD - CPG Item Additional Attributes          |
--|                                                                          |
--|  RETURNS                                                                 |
--|    TRUE  - If insert successful                                          |
--|    FALSE - If insert fails                                               |
--|                                                                          |
--|  HISTORY                                                                 |
--|                                                                          |
--+==========================================================================+
-- Func end of comments
FUNCTION Insert_Ic_Item_Cpg
(p_ic_item_cpg_rec  IN ic_item_cpg%ROWTYPE)
RETURN BOOLEAN
IS

BEGIN

  INSERT INTO ic_item_cpg
  ( item_id
  , ic_matr_days
  , ic_hold_days
  , created_by
  , creation_date
  , last_updated_by
  , last_update_date
  , last_update_login
  )
  VALUES
  ( p_ic_item_cpg_rec.item_id
  , p_ic_item_cpg_rec.ic_matr_days
  , p_ic_item_cpg_rec.ic_hold_days
  , p_ic_item_cpg_rec.created_by
  , p_ic_item_cpg_rec.creation_date
  , p_ic_item_cpg_rec.last_updated_by
  , p_ic_item_cpg_rec.last_update_date
  , p_ic_item_cpg_rec.last_update_login
  );

  RETURN TRUE;

  EXCEPTION
    WHEN OTHERS THEN
--     IF  FND_MSG_PUB.check_msg_level
--        (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
--     THEN
    
    FND_MSG_PUB.Add_Exc_Msg (  G_PKG_NAME
                            , 'insert_ic_item_cpg'
                            );
--     END IF;
    RETURN FALSE;

END Insert_Ic_Item_Cpg;

END GMI_ITEM_PVT;
/
COMMIT;
EXIT;
