CREATE OR REPLACE VIEW APPS.XXSKY_�W������IF_��{_V
(
 ���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i��
,�i�ږ�
,�i�ڗ���
,�K�p�J�n��
,��ڋ敪
,��ڋ敪��
,���ڋ敪
,���ڋ敪��
,����i��
,����i�ږ�
,����i�ڗ���
,�P��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XPCV.prod_class_code                --���i�敪
       ,XPCV.prod_class_name                --���i�敪��
       ,XICV.item_class_code                --�i�ڋ敪
       ,XICV.item_class_name                --�i�ڋ敪��
       ,XCCV.crowd_code                     --�Q�R�[�h
       ,XSCI.item_code                      --�i��
       ,XIMV_HIN.item_name                  --�i�ږ�
       ,XIMV_HIN.item_short_name            --�i�ڗ���
       ,XSCI.start_date_active              --�K�p�J�n��
       ,XSCI.expence_item_type              --��ڋ敪
       ,FLV_HI.meaning                      --��ڋ敪��
       ,XSCI.expence_item_detail_type       --���ڋ敪
       ,FLV_KO.meaning                      --���ڋ敪��
       ,XSCI.item_code_detail               --����i��
       ,XIMV_HIN.item_name                  --����i�ږ�
       ,XIMV_HIN.item_short_name            --����i�ڗ���
       ,XSCI.unit_price                     --�P��
       ,FU_CB.user_name                     --�쐬��
       ,TO_CHAR( XSCI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,TO_CHAR( XSCI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
FROM    xxcmn_standard_cost_if  XSCI        --�W�������C���^�t�F�[�X
       ,xxsky_item_mst2_v       XIMV_HIN    --�i�ږ��擾
       ,xxsky_prod_class_v      XPCV        --���i�敪�擾
       ,xxsky_item_class_v      XICV        --�i�ڋ敪�擾
       ,xxsky_crowd_code_v      XCCV        --�Q�R�[�h�擾
       ,fnd_lookup_values       FLV_HI      --��ڋ敪���擾
       ,fnd_lookup_values       FLV_KO      --���ڋ敪���擾
       ,xxsky_item_mst2_v       XIMV_UCH    --����i�ږ��擾
       ,fnd_user                FU_CB       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE  XIMV_HIN.ITEM_NO(+) = XSCI.item_code                     --�i�ږ��擾
  AND  XIMV_HIN.start_date_active(+) <= XSCI.start_date_active  --�i�ږ��擾
  AND  XIMV_HIN.end_date_active(+)   >= XSCI.start_date_active  --�i�ږ��擾
  AND  XIMV_HIN.item_id = XPCV.item_id(+)                       --���i�敪�擾
  AND  XIMV_HIN.item_id = XICV.item_id(+)                       --�i�ڋ敪�擾
  AND  XIMV_HIN.item_id = XCCV.item_id(+)                       --�Q�R�[�h�擾
  AND  FLV_HI.language(+) = 'JA'                                --��ڋ敪�擾
  AND  FLV_HI.lookup_type(+) = 'XXPO_EXPENSE_ITEM_TYPE'         --��ڋ敪�擾
  AND  FLV_HI.attribute1(+) = XSCI.expence_item_type            --��ڋ敪�擾
  AND  FLV_KO.language(+) = 'JA'                                --���ڋ敪���擾
  AND  FLV_KO.lookup_type(+) = 'XXPO_EXPENSE_ITEM_DETAIL_TYPE'  --���ڋ敪���擾
  AND  FLV_KO.attribute1(+) = XSCI.expence_item_detail_type     --���ڋ敪���擾
  AND  XIMV_UCH.ITEM_NO(+) = XSCI.item_code                     --����i�ږ��擾
  AND  XIMV_UCH.start_date_active(+) <= XSCI.start_date_active  --����i�ږ��擾
  AND  XIMV_UCH.end_date_active(+)   >= XSCI.start_date_active  --����i�ږ��擾
  AND  FU_CB.user_id(+)  = XSCI.created_by
  AND  FU_LU.user_id(+)  = XSCI.last_updated_by
  AND  FL_LL.login_id(+) = XSCI.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�W������IF_��{_V IS 'XXSKY_�W������IF(��{) VIEW'
/	
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.���i�敪	        IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.���i�敪��	    IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�i�ڋ敪	        IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�i�ڋ敪��	    IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�Q�R�[�h	        IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�i��	            IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�i�ږ�	        IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�i�ڗ���	        IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�K�p�J�n��	    IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.��ڋ敪	        IS '��ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.��ڋ敪��	    IS '��ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.���ڋ敪	        IS '���ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.���ڋ敪��	    IS '���ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.����i��	        IS '����i��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.����i�ږ�	    IS '����i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.����i�ڗ���	    IS '����i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�P��	            IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�쐬��	        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�쐬��	        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�ŏI�X�V��	    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�ŏI�X�V��	    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�W������IF_��{_V.�ŏI�X�V���O�C��	IS '�ŏI�X�V���O�C��'
/
