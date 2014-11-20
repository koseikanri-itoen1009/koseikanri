CREATE OR REPLACE VIEW APPS.XXCMM_CHANGE_RSV_V
AS
SELECT      xsibh.item_hst_id,              --�i�ڕύX����ID
            xsibh.item_id,                  --�i��ID
            xsibh.item_code,                --�i�ڃR�[�h
            xoiv.parent_item_id,            --�e�i��ID
            xoiv.item_name,                 --������
            xsibh.apply_date,               --�K�p���i�K�p�J�n���j
            xsibh.apply_flag,               --�K�p�L��
            xsibh.item_status,              --�i�ڃX�e�[�^�X
            itm.item_status_mean,           --�E�v�i�i�ڃX�e�[�^�X�j
-- 2009/04/28 add start by Yutaka.Kuboshima
            xoiv.item_status now_item_status, --���i�ڃX�e�[�^�X
-- 2009/04/28 add end by Yutaka.Kuboshima
            xsibh.policy_group,             --�Q�R�[�h�i����Q�R�[�h�j
            xsibh.fixed_price,              --�艿
            xsibh.discrete_cost,            --�c�ƌ���
-- 2009/06/29 delete start by Yutaka.Kuboshima
--            cmp.standard_cost,              --�W������
-- 2009/06/29 delete end by Yutaka.Kuboshima
            xsibh.first_apply_flag,         --����K�p�t���O
            xsibh.created_by,               --�쐬��
            xsibh.creation_date,            --�쐬��
            xsibh.last_updated_by,          --�ŏI�X�V��
            xsibh.last_update_date,         --�ŏI�X�V��
            xsibh.last_update_login,        --�ŏI�X�V���O�C��
            xsibh.request_id,               --�v��ID
            xsibh.program_application_id,   --�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
            xsibh.program_id,               --�R���J�����g�E�v���O����ID
            xsibh.program_update_date       --�v���O�����ɂ��X�V��
FROM        xxcmm_system_items_b_hst xsibh,
            xxcmm_opmmtl_items_v     xoiv,
-- 2009/06/29 delete start by Yutaka.Kuboshima
--            cm_cldr_dtl              ccc,   -- OPM�����J�����_
-- 2009/06/29 delete end by Yutaka.Kuboshima
          ( SELECT    flv.lookup_code,
                      flv.meaning  item_status_mean
            FROM      fnd_lookup_values_vl flv
            WHERE     flv.lookup_type          = 'XXCMM_ITM_STATUS'
            ORDER BY  flv.lookup_code
          ) itm
-- 2009/06/29 delete start by Yutaka.Kuboshima
--          ( SELECT    SUM(ccd.cmpnt_cost)  AS standard_cost,
--                      ccd.item_id          AS item_id,
--                      ccd.calendar_code    AS calendar_code,
--                      ccd.period_code      AS period_code
--            FROM      cm_cmpt_dtl ccd,     -- OPM����
--                      cm_cldr_dtl ccc      -- OPM�����J�����_ 2009/01/21�ǉ�
--            WHERE     ccd.calendar_code  = ccc.calendar_code
--            AND       ccd.period_code    = ccc.period_code
----2009/01/21 �ǉ�
--            AND       ccc.start_date    <= xxccp_common_pkg2.get_working_day(SYSDATE, 0, NULL)
--            AND       ccc.end_date      >= xxccp_common_pkg2.get_working_day(SYSDATE, 0, NULL)
----2009/01/21 �ǉ�
--            GROUP BY  ccd.item_id,
--                      ccd.calendar_code,
--                      ccd.period_code
--          ) cmp    -- OPM����
-- 2009/06/29 delete end by Yutaka.Kuboshima
WHERE       xsibh.item_code          = xoiv.item_code
AND         xsibh.item_status        = itm.lookup_code(+)
--
-- 2009/08/10 modify start by Yutaka.Kuboshima
--AND         xoiv.start_date_active   <= TRUNC( SYSDATE )
--AND         xoiv.end_date_active     >= TRUNC( SYSDATE )
AND         xoiv.start_date_active   <= xxccp_common_pkg2.get_process_date
AND         xoiv.end_date_active     >= xxccp_common_pkg2.get_process_date
-- 2009/08/10 modify end by Yutaka.Kuboshima
--
-- 2009/06/29 delete start by Yutaka.Kuboshima
--AND         xoiv.item_id             =  cmp.item_id(+)
--AND         cmp.calendar_code        =  ccc.calendar_code(+)
--AND         cmp.period_code          =  ccc.period_code(+)
-- 2009/06/29 delete end by Yutaka.Kuboshima
ORDER BY    xsibh.item_code,
            xsibh.apply_date DESC,
            xsibh.last_update_date DESC
/
COMMENT ON TABLE APPS.XXCMM_CHANGE_RSV_V IS '�ύX�\���ʃr���['
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_HST_ID IS '�i�ڕύX����ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_ID IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_CODE IS '�i���R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.PARENT_ITEM_ID IS '�e�i��ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_NAME IS '������'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.APPLY_DATE IS '�K�p���i�K�p�J�n���j'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.APPLY_FLAG IS '�K�p�L��'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_STATUS IS '�i�ڃX�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.NOW_ITEM_STATUS IS '���݂̕i�ڃX�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.ITEM_STATUS_MEAN IS '�E�v�i�i�ڃX�e�[�^�X�j'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.POLICY_GROUP IS '�Q�R�[�h�i����Q�R�[�h�j'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.FIXED_PRICE IS '�艿'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.DISCRETE_COST IS '�c�ƌ���'
/
-- 2009/06/29 delete start by Yutaka.Kuboshima
--COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.STANDARD_COST IS '�W������'
-- 2009/06/29 delete end by Yutaka.Kuboshima
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.FIRST_APPLY_FLAG IS '����K�p�t���O'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.CREATED_BY IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.CREATION_DATE IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.LAST_UPDATED_BY IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.LAST_UPDATE_DATE IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.LAST_UPDATE_LOGIN IS '�ŏI�X�V���O�C��'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.REQUEST_ID IS '�v��ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.PROGRAM_APPLICATION_ID IS '�R���J�����g�E�v���O�����̃A�v���P�[�V����ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.PROGRAM_ID IS '�R���J�����g�E�v���O����ID'
/
COMMENT ON COLUMN APPS.XXCMM_CHANGE_RSV_V.PROGRAM_UPDATE_DATE IS '�v���O�����ɂ��X�V��'
/
