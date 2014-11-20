CREATE OR REPLACE VIEW APPS.XXSKY_�I��HHTIF_��{_V
(
�񍐕���
,�񍐕�����
,�I����
,�I���q��
,�I���q�ɖ�
,�I���A��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i��
,�i�ږ�
,�i�ڗ���
,���b�gNO
,������
,�ܖ�����
,�ŗL�L��
,�I���P�[�X��
,����
,�I���o��
,���P�[�V����
,���b�NNO�P
,���b�NNO�Q
,���b�NNO�R
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
         XSII.report_post_code                  --�񍐕���
        ,XL2V.location_name                     --�񍐕�����
        ,XSII.invent_date                       --�I����
        ,XSII.invent_whse_code                  --�I���q��
        ,IWM.whse_name                          --�I���q�ɖ�
        ,XSII.invent_seq                        --�I���A��
        ,XPCV.prod_class_code                   --���i�敪
        ,XPCV.prod_class_name                   --���i�敪��
        ,XICV.item_class_code                   --�i�ڋ敪
        ,XICV.item_class_name                   --�i�ڋ敪��
        ,XCCV.crowd_code                        --�Q�R�[�h
        ,XSII.item_code                         --�i��
        ,XIM2V.item_name                        --�i�ږ�
        ,XIM2V.item_short_name                  --�i�ڗ���
        ,XSII.lot_no                            --���b�gNo
        ,XSII.maker_date                        --������
        ,XSII.limit_date                        --�ܖ�����
        ,XSII.proper_mark                       --�ŗL�L��
        ,XSII.case_amt                          --�I���P�[�X��
        ,XSII.content                           --����
        ,XSII.loose_amt                         --�I���o��
        ,XSII.location                          --���P�[�V����
        ,XSII.rack_no1                          --���b�NNo1
        ,XSII.rack_no2                          --���b�NNo2
        ,XSII.rack_no3                          --���b�NNo3
        ,FU_CB.user_name                        --�쐬��
        ,TO_CHAR( XSII.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --�쐬��
        ,FU_LU.user_name                        --�ŏI�X�V��
        ,TO_CHAR( XSII.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --�ŏI�X�V��
        ,FU_LL.user_name                        --�ŏI�X�V���O�C��
  FROM   xxinv_stc_inventory_hht_work   XSII    --HHT�I�����[�N�e�[�u��
        ,xxsky_locations2_v             XL2V    --SKYLINK�p����VIEW ���Ə����VIEW2(������)
        ,ic_whse_mst                    IWM     --�q�Ƀ}�X�^(�q�ɖ�)
        ,xxsky_prod_class_v             XPCV    --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(���i�敪)
        ,xxsky_item_class_v             XICV    --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�i�ڋ敪)
        ,xxsky_crowd_code_v             XCCV    --SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�Q�R�[�h)
        ,xxsky_item_mst2_v              XIM2V   --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ږ�)
        ,fnd_user                       FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
        ,fnd_user                       FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
        ,fnd_user                       FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_logins                     FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XSII.report_post_code           = XL2V.location_code(+)
   AND  XL2V.start_date_active(+)       <= XSII.invent_date
   AND  XL2V.end_date_active(+)         >= XSII.invent_date
   AND  XSII.invent_whse_code           = IWM.whse_code(+)
   AND  XSII.item_code                  = XIM2V.item_no(+)
   AND  XIM2V.start_date_active(+)      <= XSII.invent_date
   AND  XIM2V.end_date_active(+)        >= XSII.invent_date
   AND  XIM2V.item_id                   = XPCV.item_id(+)
   AND  XIM2V.item_id                   = XICV.item_id(+)
   AND  XIM2V.item_id                   = XCCV.item_id(+)
   AND  XSII.created_by                 = FU_CB.user_id(+)
   AND  XSII.last_updated_by            = FU_LU.user_id(+)
   AND  XSII.last_update_login          = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
;
/
COMMENT ON TABLE APPS.XXSKY_�I��HHTIF_��{_V IS 'SKYLINK�pHHT�I���C���^�[�t�F�[�X�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�񍐕���     IS '�񍐕���'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�񍐕�����   IS '�񍐕�����'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�I����       IS '�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�I���q��     IS '�I���q��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�I���q�ɖ�   IS '�I���q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�I���A��     IS '�I���A��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.���i�敪     IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.���i�敪��   IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�i�ڋ敪     IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�i�ڋ敪��   IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�Q�R�[�h     IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�i��         IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�i�ږ�       IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�i�ڗ���     IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.���b�gNO     IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.������       IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�ܖ�����     IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�ŗL�L��     IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�I���P�[�X�� IS '�I���P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.����         IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�I���o��     IS '�I���o��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.���P�[�V���� IS '���P�[�V����'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.���b�NNO�P   IS '���b�NNo�P'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.���b�NNO�Q   IS '���b�NNo�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.���b�NNO�R   IS '���b�NNo�R'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�쐬��       IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�쐬��       IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�ŏI�X�V��   IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�ŏI�X�V��   IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�I��HHTIF_��{_V.�ŏI�X�V���O�C��     IS '�ŏI�X�V���O�C��'
/
