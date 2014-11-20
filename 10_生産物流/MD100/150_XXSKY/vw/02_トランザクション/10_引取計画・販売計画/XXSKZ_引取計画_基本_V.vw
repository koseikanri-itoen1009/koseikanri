/*************************************************************************
 * 
 * View  Name      : XXSKZ_����v��_��{_V
 * Description     : XXSKZ_����v��_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_����v��_��{_V
(
���v�\����
,�\���Z�b�g�R�[�h
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���O�敪
,���O�敪��
,�P�[�X����
,�o�Ɍ��q�ɃR�[�h
,�o�Ɍ��q�ɖ�
,���_�R�[�h
,���_��
,�捞�����R�[�h
,�捞������
,�\����������
,�\�����ݐ���
,���P�[�X����
,���o������
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        MFD.forecast_date                       --���v�\����
       ,MFD.forecast_set                        --�\���Z�b�g�R�[�h
       ,XPCV.prod_class_code                    --���i�敪
       ,XPCV.prod_class_name                    --���i�敪��
       ,XICV.item_class_code                    --�i�ڋ敪
       ,XICV.item_class_name                    --�i�ڋ敪��
       ,XCCV.crowd_code                         --�Q�R�[�h
       ,XIMV.item_no                            --�i�ڃR�[�h
       ,XIMV.item_name                          --�i�ږ�
       ,XIMV.item_short_name                    --�i�ڗ���
       ,XIOCV.inout_class_code                  --���O�敪
       ,XIOCV.inout_class_name                  --���O�敪��
       ,XIMV.num_of_cases                       --�P�[�X����
       ,MFD.attribute2                          --�o�Ɍ��q�ɃR�[�h
       ,XILV.description                        --�o�Ɍ��q�ɖ�
       ,MFD.attribute5                          --���_�R�[�h
       ,XCAV.party_name                         --���_��
       ,MFD.attribute4_tori                     --�捞�����R�[�h
       ,XLV.location_name                       --�捞������
       ,MFD.original_forecast_quantity          --�\����������
       ,MFD.current_forecast_quantity           --�\�����ݐ���
       ,MFD.attribute6_case                     --���P�[�X����
       ,MFD.attribute4_bara                     --���o������
       ,FU_CB.user_name                         --�쐬��
       ,TO_CHAR( MFD.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --�쐬��
       ,FU_LU.user_name                         --�ŏI�X�V��
       ,TO_CHAR( MFD.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                --�ŏI�X�V��
       ,FU_LL.user_name                         --�ŏI�X�V���O�C��
FROM
       (SELECT
            MFDT.forecast_date                  --���v�\����
           ,MFDT.inventory_item_id              --���iID
           ,MFDS.forecast_set                   --�\���Z�b�g�R�[�h
           ,MFDS.attribute2                     --�o�Ɍ��q�ɃR�[�h
           ,MFDT.attribute5                     --���_�R�[�h
           ,MFDS.attribute4 AS attribute4_tori  --�捞�����R�[�h
           ,MFDT.original_forecast_quantity     --�\����������
           ,MFDT.current_forecast_quantity      --�\�����ݐ���
           ,NVL(TO_NUMBER(MFDT.attribute6), 0) AS attribute6_case  --���P�[�X����
           ,NVL(TO_NUMBER(MFDT.attribute4), 0) AS attribute4_bara  --���o������
           ,MFDT.created_by                     --�쐬��
           ,MFDT.creation_date                  --�쐬��
           ,MFDT.last_update_date               --�ŏI�X�V��
           ,MFDT.last_updated_by                --�ŏI�X�V��
           ,MFDT.last_update_login              --�ŏI�X�V���O�C��
       FROM
            mrp_forecast_dates          MFDT    --�t�H�[�L���X�g���t
           ,mrp_forecast_designators    MFDS    --�t�H�[�L���X�gDESIGNATOR
       WHERE
            --�t�H�[�L���X�g���t�E�t�H�[�L���X�gDESIGNATOR ��������
                  MFDT.organization_id = fnd_profile.value('XXCMN_MASTER_ORG_ID')
              AND MFDS.forecast_designator = MFDT.forecast_designator
              AND MFDS.attribute1 = '01'        --attribute1=01:����v��
       )                                MFD     --�t�H�[�L���X�g���t�E�t�H�[�L���X�gDESIGNATOR
       ,xxskz_item_mst2_v               XIMV    --�i�ږ��擾�p
       ,xxskz_prod_class_v              XPCV    --���i�敪�擾�p
       ,xxskz_crowd_code_v              XCCV    --�Q�R�[�h�擾�p
       ,xxskz_item_class_v              XICV    --�i�ڋ敪�擾�p
       ,xxskz_inout_class_v             XIOCV   --���O�敪�擾�p
       ,xxskz_item_locations2_v         XILV    --�o�ɑq�ɖ��擾�p
       ,xxskz_cust_accounts2_v          XCAV    --���_���擾�p
       ,xxskz_locations2_v              XLV     --���Ə��擾�p
       ,fnd_user                        FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
--�i�ږ��擾����
  XIMV.inventory_item_id = MFD.inventory_item_id
  AND XIMV.start_date_active(+) <= MFD.forecast_date
  AND XIMV.end_date_active(+)   >= MFD.forecast_date
--���i�敪�擾�����i��i�ږ��擾��Ŏ擾�����i��ID���g�p�j
  AND XPCV.item_id(+) = XIMV.item_id            
--�Q�R�[�h�擾�����i��i�ږ��擾��Ŏ擾�����i��ID���g�p�j
  AND XCCV.item_id(+) = XIMV.item_id
--�i�ڋ敪�擾�����i��i�ږ��擾��Ŏ擾�����i��ID���g�p�j
  AND XICV.item_id(+) = XIMV.item_id
--���O�敪�擾�����i��i�ږ��擾��Ŏ擾�����i��ID���g�p�j
  AND XIOCV.item_id(+) = XIMV.item_id
--�o�ɑq�ɖ��擾����
  AND XILV.segment1(+) = MFD.attribute2
--���_���擾����
  AND XCAV.party_number(+) = MFD.attribute5
  AND XCAV.start_date_active(+) <= MFD.forecast_date
  AND XCAV.end_date_active(+)   >= MFD.forecast_date
--���Ə��擾����
  AND XLV.location_code(+) = MFD.attribute4_tori
  AND XLV.start_date_active(+) <= MFD.forecast_date
  AND XLV.end_date_active(+)   >= MFD.forecast_date
--���[�U�[�}�X�^(CREATED_BY���̎擾�p����)
  AND  FU_CB.user_id(+)  = MFD.created_by
--���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p����)
  AND  FU_LU.user_id(+)  = MFD.last_updated_by
--���O�C���}�X�^�E���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p����)
  AND  FL_LL.login_id(+) = MFD.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_����v��_��{_V IS 'XXSKZ_����v�� (��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���v�\����          IS '���v�\����'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�\���Z�b�g�R�[�h    IS '�\���Z�b�g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���i�敪            IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���i�敪��          IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�i�ڋ敪            IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�i�ڋ敪��          IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�Q�R�[�h            IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�i�ڃR�[�h          IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�i�ږ�              IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�i�ڗ���            IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���O�敪            IS '���O�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���O�敪��          IS '���O�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�P�[�X����          IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�o�Ɍ��q�ɃR�[�h    IS '�o�Ɍ��q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�o�Ɍ��q�ɖ�        IS '�o�Ɍ��q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���_�R�[�h          IS '���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���_��              IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�捞�����R�[�h      IS '�捞�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�捞������          IS '�捞������'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�\����������        IS '�\����������'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�\�����ݐ���        IS '�\�����ݐ���'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���P�[�X����        IS '���P�[�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.���o������          IS '���o������'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�쐬��              IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�쐬��              IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�ŏI�X�V��          IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�ŏI�X�V��          IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_����v��_��{_V.�ŏI�X�V���O�C��    IS '�ŏI�X�V���O�C��'
/
