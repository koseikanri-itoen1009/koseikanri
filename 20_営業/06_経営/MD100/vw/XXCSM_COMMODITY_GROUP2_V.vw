CREATE OR REPLACE VIEW XXCSM_COMMODITY_GROUP2_V
(
  opm_item_id
 ,item_cd
 ,item_nm
 ,group2_cd
 ,group2_nm
 ,group1_cd
 ,group1_nm
 ,now_item_cost
 ,now_business_cost
 ,now_unit_price
 ,unit_of_issue
)
AS
  SELECT iimb.item_id                                                opm_item_id                    --OPMiΪID
        ,iimb.item_no                                                item_cd                        --iΪR[h
        ,iimb.item_desc1                                             item_nm                        --iΪΌΜ
        ,xicg2.item_group_cd                                         item_group_cd                  --­τQR[h(2)
        ,xicg2.item_group_nm                                         item_group_nm                  --­τQΌΜ(2)
        ,SUBSTRB(xig1v.item_group_cd,1,1)                            group1_cd                      --­τQR[h(1)
        ,xig1v.item_group_nm                                         group1_nm                      --­τQΌΜ(1)
        ,NVL((SELECT SUM(ccmd.cmpnt_cost)  cmpnt_cost
              FROM   cm_cmpt_dtl     ccmd
                    ,cm_cldr_dtl     ccld
                    ,xxcsm_process_date_v   xpcdv
              WHERE  ccmd.calendar_code = ccld.calendar_code
              AND    ccmd.whse_code     = '000'                                                     --΄ΏqΙ
              AND    ccmd.period_code   = ccld.period_code
              AND    ccld.start_date   <= xpcdv.process_date
              AND    ccld.end_date     >= xpcdv.process_date
              AND    ccmd.item_id       = iimb.item_id)
              ,0)                                                    now_cmpnt_cost                 --W΄Ώ(»_)
        ,NVL(iimb.attribute8,0)                                      now_business_cost              --cΖ΄Ώ(»_)
        ,NVL(iimb.attribute5,0)                                      now_unit_price                 --θΏ(»_)
        ,iimb.item_um                                                unit_of_issue                  --PΚ
  FROM   ic_item_mst_b             iimb                                                             --OPMiΪ
        ,gmi_item_categories       gic                                                              --OPMiΪJeS
        ,xxcsm_item_category_v     xicv4                                                            --€iQκr[(ALL)
        ,xxcsm_item_group_2_nm_v   xicg2                                                            --€iQ2ΌΜr[
        ,xxcmm_system_items_b      xsib                                                             --AhIDisciΪ
        ,xxcsm_item_group_1_nm_v   xig1v                                                            --€iQ1ΌΜ
  WHERE  iimb.item_id = gic.item_id
  AND    gic.category_id = xicv4.category_id
  AND    gic.category_set_id = xicv4.category_set_id
  AND    xicg2.item_group_cd LIKE REPLACE(xig1v.item_group_cd,'*','_')
  AND    xicv4.segment1 LIKE REPLACE(xicg2.item_group_cd,'*','_')
  AND    iimb.item_no = xsib.item_code(+)
  AND    xsib.item_status = '30'
;
--
COMMENT ON COLUMN xxcsm_commodity_group2_v.opm_item_id           IS 'OPMiΪID';
COMMENT ON COLUMN xxcsm_commodity_group2_v.item_cd               IS 'iΪR[h';
COMMENT ON COLUMN xxcsm_commodity_group2_v.item_nm               IS 'iΪΌΜ';
COMMENT ON COLUMN xxcsm_commodity_group2_v.group2_cd             IS '€iQR[hQ';
COMMENT ON COLUMN xxcsm_commodity_group2_v.group2_nm             IS '€iQΌΜQ';
COMMENT ON COLUMN xxcsm_commodity_group2_v.group1_cd             IS '€iQR[hP';
COMMENT ON COLUMN xxcsm_commodity_group2_v.group1_nm             IS '€iQΌΜP';
COMMENT ON COLUMN xxcsm_commodity_group2_v.now_item_cost         IS 'W΄Ώ(»_)';
COMMENT ON COLUMN xxcsm_commodity_group2_v.now_business_cost     IS 'cΖ΄Ώ(»_)';
COMMENT ON COLUMN xxcsm_commodity_group2_v.now_unit_price        IS 'θΏ(»_)';
COMMENT ON COLUMN xxcsm_commodity_group2_v.unit_of_issue         IS 'PΚ';
--
COMMENT ON TABLE  xxcsm_commodity_group2_v IS '€iQQr[';
/
