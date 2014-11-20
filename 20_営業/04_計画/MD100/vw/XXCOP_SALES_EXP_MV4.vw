/************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : XXCOP_SALES_EXP_MV4
 * Description     : �v��_�̔����у}�e���A���C�Y�h�r���[4�i�O�N�x �ΏۑO���O���ѐ��ʁj
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2013-08-15    1.0   SCSK.Nakamura    �V�K�쐬
 *
 ************************************************************************/
CREATE MATERIALIZED VIEW APPS.XXCOP_SALES_EXP_MV4
  TABLESPACE "XXDATA2"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH COMPLETE
  ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
    SELECT /*+ LEADING(xseh xsel xmgic1) */
           TO_CHAR(xseh.delivery_date, 'YYYYMM') AS target_month
         , xsel.delivery_base_code               AS delivery_base_code
         , xsel.item_code                        AS item_code
         , xmgic.group_item_code                 AS group_item_code
         , SUM(xsel.standard_qty)                AS sum_standard_qty
    FROM   xxcos_sales_exp_headers   xseh
         , xxcos_sales_exp_lines     xsel
         , xxcop_mst_group_item_code xmgic
    WHERE  xseh.sales_exp_header_id = xsel.sales_exp_header_id
    AND    xsel.item_code           = xmgic.item_code(+)
    AND    xseh.delivery_date BETWEEN ADD_MONTHS(TRUNC(xxccp_common_pkg2.get_process_date,'MM'),-12)
                              AND     ADD_MONTHS(TRUNC(xxccp_common_pkg2.get_process_date,'MM'),-11) - (1/24/60/60)
    AND    xseh.dlv_invoice_class   IN ( '1', '3' ) -- �ԕi������
    AND NOT EXISTS (
                     SELECT 1
                     FROM   fnd_lookup_values flv
                     WHERE  flv.lookup_type  = 'XXCOS1_NO_INV_ITEM_CODE' -- ��݌ɕi�ڂ�����
                     AND    flv.lookup_code  = xsel.item_code
                     AND    flv.language     = USERENV('LANG')
                     AND    flv.enabled_flag = 'Y'
                     AND    xseh.delivery_date BETWEEN flv.start_date_active
                                               AND     NVL(flv.end_date_active, xseh.delivery_date)
                   )
    GROUP BY
           TO_CHAR(xseh.delivery_date, 'YYYYMM')
         , xsel.delivery_base_code
         , xsel.item_code
         , xmgic.group_item_code
  ;
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV4.TARGET_MONTH       IS '�Ώ۔N��'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV4.DELIVERY_BASE_CODE IS '�[�i���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV4.ITEM_CODE          IS '�i�ڃR�[�h�i�̔����сj'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV4.GROUP_ITEM_CODE    IS '�W��R�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_SALES_EXP_MV4.SUM_STANDARD_QTY   IS '����ʍ��v'
/