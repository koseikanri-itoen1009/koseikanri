/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_qp_pricelists_lov_v
 * Description     : 価格表LOVビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/10/20    1.0   N.Maeda         新規作成
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW apps.xxcos_qp_pricelists_lov_v
  (
    "ORIG_ORG_ID"
  , "PRICE_LIST_ID"
  , "NAME"
  , "DESCRIPTION"
  , "START_DATE_ACTIVE"
  , "END_DATE_ACTIVE"
  , "QDT_START_DATE_ACTIVE"
  , "QDT_END_DATE_ACTIVE"
  , "CURRENCY_CODE"
  , "AGREEMENT_ID"
  , "SOLD_TO_ORG_ID"
  , "SOURCE_SYSTEM_CODE"
  , "SHAREABLE_FLAG"
  , "ORIG_SYSTEM_HEADER_REF"
  , "LIST_SOURCE_CODE"
  , "QRY_TYPE"
  )
   AS 
    SELECT qlhv.orig_org_id                   orig_org_id
         , qlhv.list_header_id                price_list_id
         , qlhv.name                          name
         , qlhv.description                   description
         , qlhv.start_date_active             start_date_active
         , qlhv.end_date_active               end_date_active
         , qdt.start_date_active              qdt_start_date_active
         , qdt.end_date_active                qdt_end_date_active
         , qdt.to_currency_code               currency_code
         , -9999                              agreement_id
         , -9999                              sold_to_org_id
         , qlhv.source_system_code            source_system_code
         , qlhv.shareable_flag                shareable_flag
         , qlhv.orig_system_header_ref        orig_system_header_ref
         , qlhv.list_source_code              list_source_code
         , 1                                  qry_type
    FROM   qp_list_headers_vl     qlhv
         , qp_currency_details    qdt
    WHERE  qlhv.currency_header_id = qdt.currency_header_id
    AND    qlhv.active_flag        = 'Y'
    AND    qlhv.list_type_code     = 'PRL'
  UNION ALL
    SELECT qlhv.orig_org_id                   orig_org_id
         , qlhv.list_header_id                price_list_id
         , qlhv.name                          name
         , qlhv.description                   description
         , qlhv.start_date_active             start_date_active
         , qlhv.end_date_active               end_date_active
         , qdt.start_date_active              qdt_start_date_active
         , qdt.end_date_active                qdt_end_date_active
         , qdt.to_currency_code               currency_code
         , oab.agreement_id                   agreement_id
         , oab.sold_to_org_id                 sold_to_org_id
         , qlhv.source_system_code            source_system_code
         , qlhv.shareable_flag                shareable_flag
         , qlhv.orig_system_header_ref        orig_system_header_ref
         , qlhv.list_source_code              list_source_code
         , 1                                  qry_type
    FROM   qp_list_headers_vl    qlhv
         , oe_agreements_b       oab
         , qp_currency_details   qdt
    WHERE  qlhv.currency_header_id = qdt.currency_header_id
    AND    qlhv.list_type_code ='AGR'
    AND    qlhv.active_flag = 'Y'
    AND    qlhv.list_header_id = oab.price_list_id 
  UNION ALL
    SELECT qlhv.orig_org_id                   orig_org_id
         , qlhv.list_header_id                price_list_id
         , qlhv.name                          name
         , qlhv.description                   description
         , qlhv.start_date_active             start_date_active
         , qlhv.end_date_active               end_date_active 
         , (SYSDATE-730000)                   qdt_start_date_active
         , (SYSDATE-730000)                   qdt_end_date_active 
         , qlhv.currency_code                 currency_code
         , -9999                              agreement_id
         , -9999                              sold_to_org_id
         , qlhv.source_system_code            source_system_code
         , qlhv.shareable_flag                shareable_flag
         , qlhv.orig_system_header_ref        orig_system_header_ref
         , qlhv.list_source_code              list_source_code
         , 2                                  qry_type
    FROM   qp_list_headers_vl   qlhv 
    WHERE  qlhv.active_flag = 'Y' 
    AND    qlhv.list_type_code = 'PRL' 
  UNION ALL
    SELECT qlhv.orig_org_id                   orig_org_id
         , qlhv.list_header_id                price_list_id
         , qlhv.name                          name
         , qlhv.description                   description
         , qlhv.start_date_active             start_date_active
         , qlhv.end_date_active               end_date_active 
         , (SYSDATE-730000)                   qdt_start_date_active
         , (SYSDATE-730000)                   qdt_end_date_active 
         , qlhv.currency_code                 currency_code
         , oab.agreement_id                   agreement_id
         , oab.sold_to_org_id                 sold_to_org_id
         , qlhv.source_system_code            source_system_code
         , qlhv.shareable_flag                shareable_flag
         , qlhv.orig_system_header_ref        orig_system_header_ref
         , qlhv.list_source_code              list_source_code
         , 2                                  qry_type
    FROM   qp_list_headers_vl   qlhv
         , oe_agreements_b      oab
    WHERE  qlhv.list_type_code ='AGR' 
    AND    qlhv.active_flag = 'Y' 
    AND    qlhv.list_header_id = oab.price_list_id
;


COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.orig_org_id               IS  'ORIG_ORG_ID';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.price_list_id             IS  'PRICE_LIST_IDID';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.name                      IS  'NAME';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.description               IS  'DESCRIPTION';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.start_date_active         IS  'START_DATE_ACTIVE';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.end_date_active           IS  'END_DATE_ACTIVE';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.qdt_start_date_active     IS  'QDT_START_DATE_ACTIVE';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.qdt_end_date_active       IS  'QDT_END_DATE_ACTIVE';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.currency_code             IS  'CURRENCY_CODE';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.agreement_id              IS  'AGREEMENT_ID';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.sold_to_org_id            IS  'SOLD_TO_ORG_ID';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.source_system_code        IS  'SOURCE_SYSTEM_CODE';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.shareable_flag            IS  'SHAREABLE_FLAG';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.orig_system_header_ref    IS  'ORIG_SYSTEM_HEADER_REF';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.list_source_code          IS  'LIST_SOURCE_CODE';
COMMENT ON  COLUMN  xxcos_qp_pricelists_lov_v.qry_type                  IS  'QRY_TYPE';
COMMENT ON  TABLE   xxcos_qp_pricelists_lov_v                           IS  '価格表LOVビュー';



