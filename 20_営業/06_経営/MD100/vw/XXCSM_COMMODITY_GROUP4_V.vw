CREATE OR REPLACE VIEW XXCSM_COMMODITY_GROUP4_V
(
  opm_item_id
 ,item_cd
 ,item_nm
 ,group4_cd
 ,group4_nm
 ,group1_cd
 ,group1_nm
 ,now_item_cost
 ,now_business_cost
 ,now_unit_price
 ,unit_of_issue
)
AS
  SELECT iimb.item_id                                                opm_item_id                    --OPM�i��ID
        ,iimb.item_no                                                item_cd                        --�i�ڃR�[�h
        ,iimb.item_desc1                                             item_nm                        --�i�ږ���
        ,xicv4.segment1                                              group4_cd                      --����Q�R�[�h(4��)
        ,xicv4.description                                           group4_nm                      --����Q����(4��)
        ,SUBSTRB(xig1v.item_group_cd,1,1)                            group1_cd                      --����Q�R�[�h(1��)
        ,xig1v.item_group_nm                                         group1_nm                      --����Q����(1��)
        ,NVL(iv_cmpcst.cmpnt_cost,NVL(iimb.attribute8,0))            now_cmpnt_cost                 --�W������(�����_)
        ,NVL(iimb.attribute8,0)                                      now_business_cost              --�c�ƌ���(�����_)
        ,NVL(iimb.attribute5,0)                                      now_unit_price                 --�艿(�����_)
        ,iimb.item_um                                                unit_of_issue                  --�P��
  FROM   ic_item_mst_b             iimb                                                             --OPM�i��
        ,gmi_item_categories       gic                                                              --OPM�i�ڃJ�e�S��
        ,xxcsm_item_category_v     xicv4                                                            --���i�Q�ꗗ�r���[(ALL)
        ,xxcmm_system_items_b      xsib                                                             --�A�h�I��Disc�i��
        ,xxcsm_item_group_1_nm_v   xig1v                                                            --���i�Q1������
        ,(SELECT ccmd.item_id          item_id
                ,SUM(ccmd.cmpnt_cost)  cmpnt_cost
          FROM   cm_cmpt_dtl     ccmd
                ,cm_cldr_dtl     ccld
                ,xxcsm_process_date_v   xpcdv
          WHERE  ccmd.calendar_code = ccld.calendar_code
          AND    ccmd.whse_code = '000'                                                             --�����q��
          AND    ccmd.period_code = ccld.period_code
          AND    ccld.start_date <= xpcdv.process_date
          AND    ccld.end_date >= xpcdv.process_date
          GROUP BY ccmd.item_id)   iv_cmpcst                                                        --�i�ڌ����r���[
         ,(SELECT flv.lookup_code   item_status
           FROM   fnd_lookup_values       flv                                                       --�Q�ƃ^�C�v(�i�ڃX�e�[�^�X)
                 ,xxcsm_process_date_v    xpcdv
           WHERE   flv.lookup_type = 'XXCMM_ITM_STATUS'
           AND    flv.enabled_flag = 'Y'
           AND    flv.language = USERENV('LANG')
           AND    flv.attribute3 = 'Y'
           AND    NVL(flv.start_date_active,xpcdv.process_date) <= xpcdv.process_date
           AND    NVL(flv.end_date_active,xpcdv.process_date) >= xpcdv.process_date) iv_is
  WHERE  iimb.item_id = gic.item_id
  AND    gic.category_id = xicv4.category_id
  AND    gic.category_set_id = xicv4.category_set_id
  AND    xicv4.segment1 LIKE REPLACE(xig1v.item_group_cd(+),'*','_')
  AND    iimb.item_id = iv_cmpcst.item_id(+)
  AND    iimb.item_no = xsib.item_code(+)
  AND    xsib.item_status = iv_is.item_status
;
--
COMMENT ON COLUMN xxcsm_commodity_group4_v.opm_item_id           IS 'OPM�i��ID';
COMMENT ON COLUMN xxcsm_commodity_group4_v.item_cd               IS '�i�ڃR�[�h';
COMMENT ON COLUMN xxcsm_commodity_group4_v.item_nm               IS '�i�ږ���';
COMMENT ON COLUMN xxcsm_commodity_group4_v.group4_cd             IS '���i�Q�R�[�h�S';
COMMENT ON COLUMN xxcsm_commodity_group4_v.group4_nm             IS '���i�Q���̂S';
COMMENT ON COLUMN xxcsm_commodity_group4_v.group1_cd             IS '���i�Q�R�[�h�P';
COMMENT ON COLUMN xxcsm_commodity_group4_v.group1_nm             IS '���i�Q���̂P';
COMMENT ON COLUMN xxcsm_commodity_group4_v.now_item_cost         IS '�W������(�����_)';
COMMENT ON COLUMN xxcsm_commodity_group4_v.now_business_cost     IS '�c�ƌ���(�����_)';
COMMENT ON COLUMN xxcsm_commodity_group4_v.now_unit_price        IS '�艿(�����_)';
COMMENT ON COLUMN xxcsm_commodity_group4_v.unit_of_issue         IS '�P��';
--
COMMENT ON TABLE  xxcsm_commodity_group4_v IS '���i�Q�S�r���[';
/
