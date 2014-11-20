CREATE OR REPLACE VIEW XXCSM_COMMODITY_GROUP3_V
(
  opm_item_id
 ,item_cd
 ,item_nm
 ,group3_cd
 ,group3_nm
 ,group1_cd
 ,group1_nm
 ,now_item_cost
 ,now_business_cost
 ,now_unit_price
 ,unit_of_issue
)
AS
  SELECT /*+ INDEX(iv_cmpcst.ccmd CM_CMPT_DTL_U1) */
         iimb.item_id                                                opm_item_id                    --OPM品目ID
        ,iimb.item_no                                                item_cd                        --品目コード
        ,iimb.item_desc1                                             item_nm                        --品目名称
        ,xicg3.item_group_cd                                         item_group_cd                  --政策群コード(3桁)
        ,xicg3.item_group_nm                                         item_group_nm                  --政策群名称(3桁)
        ,SUBSTRB(xig1v.item_group_cd,1,1)                            group1_cd                      --政策群コード(1桁)
        ,xig1v.item_group_nm                                         group1_nm                      --政策群名称(1桁)
        ,NVL((SELECT SUM(ccmd.cmpnt_cost)  cmpnt_cost
              FROM   cm_cmpt_dtl     ccmd
                    ,cm_cldr_dtl     ccld
                    ,xxcsm_process_date_v   xpcdv
              WHERE  ccmd.calendar_code = ccld.calendar_code
              AND    ccmd.whse_code     = '000'                                                     --原価倉庫
              AND    ccmd.period_code   = ccld.period_code
              AND    ccld.start_date   <= xpcdv.process_date
              AND    ccld.end_date     >= xpcdv.process_date
              AND    ccmd.item_id       = iimb.item_id)
              ,0)                                                    now_cmpnt_cost                 --標準原価(現時点)
        ,NVL(iimb.attribute8,0)                                      now_business_cost              --営業原価(現時点)
        ,NVL(iimb.attribute5,0)                                      now_unit_price                 --定価(現時点)
        ,iimb.item_um                                                unit_of_issue                  --単位
  FROM   ic_item_mst_b             iimb                                                             --OPM品目
        ,gmi_item_categories       gic                                                              --OPM品目カテゴリ
        ,xxcsm_item_category_v     xicv4                                                            --商品群一覧ビュー(ALL)
        ,xxcsm_item_group_3_nm_v   xicg3                                                            --商品群3桁名称ビュー
        ,xxcmm_system_items_b      xsib                                                             --アドオンDisc品目
        ,xxcsm_item_group_1_nm_v   xig1v                                                            --商品群1桁名称
  WHERE  iimb.item_id = gic.item_id
  AND    gic.category_id = xicv4.category_id
  AND    gic.category_set_id = xicv4.category_set_id
  AND    xicg3.item_group_cd LIKE REPLACE(xig1v.item_group_cd,'*','_')
  AND    xicv4.segment1 LIKE REPLACE(xicg3.item_group_cd,'*','_')
  AND    iimb.item_no = xsib.item_code(+)
  AND    xsib.item_status = '30'
;
--
COMMENT ON COLUMN xxcsm_commodity_group3_v.opm_item_id           IS 'OPM品目ID';
COMMENT ON COLUMN xxcsm_commodity_group3_v.item_cd               IS '品目コード';
COMMENT ON COLUMN xxcsm_commodity_group3_v.item_nm               IS '品目名称';
COMMENT ON COLUMN xxcsm_commodity_group3_v.group3_cd             IS '商品群コード３';
COMMENT ON COLUMN xxcsm_commodity_group3_v.group3_nm             IS '商品群名称３';
COMMENT ON COLUMN xxcsm_commodity_group3_v.group1_cd             IS '商品群コード１';
COMMENT ON COLUMN xxcsm_commodity_group3_v.group1_nm             IS '商品群名称１';
COMMENT ON COLUMN xxcsm_commodity_group3_v.now_item_cost         IS '標準原価(現時点)';
COMMENT ON COLUMN xxcsm_commodity_group3_v.now_business_cost     IS '営業原価(現時点)';
COMMENT ON COLUMN xxcsm_commodity_group3_v.now_unit_price        IS '定価(現時点)';
COMMENT ON COLUMN xxcsm_commodity_group3_v.unit_of_issue         IS '単位';
--
COMMENT ON TABLE  xxcsm_commodity_group3_v IS '商品群３ビュー';
/
