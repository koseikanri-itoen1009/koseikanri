CREATE OR REPLACE VIEW APPS.XXSKY_���t����_V
(
 �`�[NO
,�r���i�ڃR�[�h
,�r���i�ږ�
,�r���i�ڗ���
,�r�����b�gNO
,�r�������N����
,�r���ŗL�L��
,�r���ܖ�����
,�d�㐔��
,�d��P��
,���H�P��
,���ɐ�R�[�h
,���ɐ於
,�׈�
,���l
,�W�ׂP����
,�W�ׂP�P��_��
,�W�ׂP�P��_��
,�W�ׂQ����
,�W�ׂQ�P��_��
,�W�ׂQ�P��_��
,����P����
,����P�P��_��
,����P�P��_��
,����Q����
,����Q�P��_��
,����Q�P��_��
,�o�א���
,�o�גP��_��
,�o�גP��_��
,���Y���P�i�ڃR�[�h
,���Y���P�i�ږ�
,���Y���P�i�ڗ���
,���Y���P���b�gNO
,���Y���P�����N����
,���Y���P�ŗL�L��
,���Y���P�ܖ�����
,���Y���P����
,���Y���P�P��
,���Y���Q�i�ڃR�[�h
,���Y���Q�i�ږ�
,���Y���Q�i�ڗ���
,���Y���Q���b�gNO
,���Y���Q�����N����
,���Y���Q�ŗL�L��
,���Y���Q�ܖ�����
,���Y���Q����
,���Y���Q�P��
,���Y���R�i�ڃR�[�h
,���Y���R�i�ږ�
,���Y���R�i�ڗ���
,���Y���R���b�gNO
,���Y���R�����N����
,���Y���R�ŗL�L��
,���Y���R�ܖ�����
,���Y���R����
,���Y���R�P��
,���P�����͊����t���O
,�����R�[�h
,������
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XNPT.entry_number                   --�`�[No
       ,XNPT.aracha_item_code               --�r���i�ڃR�[�h
       ,XIMV_ARA.item_name                  --�r���i�ږ�
       ,XIMV_ARA.item_short_name            --�r���i�ڗ���
       ,XNPT.aracha_lot_number              --�r�����b�gNo
       ,ILM_ARA.attribute1                  --�r�������N����
       ,ILM_ARA.attribute2                  --�r���ŗL�L��
       ,ILM_ARA.attribute3                  --�r���ܖ�����
       ,XNPT.aracha_quantity                --�d�㐔��
       ,XNPT.aracha_uom                     --�d��P��
       ,XNPT.processing_unit_price          --���H�P��
       ,XNPT.location_code                  --���ɐ�R�[�h
       ,XILV_NYUK.description               --���ɐ於
       ,XNPT.nijirushi                      --�׈�
       ,XNPT.description                    --���l
       ,XNPT.collect1_quantity              --�W�ׂP����
       ,XNPT.collect1_temp_unit_price       --�W�ׂP�P��_��
       ,XNPT.collect1_final_unit_price      --�W�ׂP�P��_��
       ,XNPT.collect2_quantity              --�W�ׂQ����
       ,XNPT.collect2_temp_unit_price       --�W�ׂQ�P��_��
       ,XNPT.collect2_final_unit_price      --�W�ׂQ�P��_��
       ,XNPT.receive1_quantity              --����P����
       ,XNPT.receive1_temp_unit_price       --����P�P��_��
       ,XNPT.receive1_final_unit_price      --����P�P��_��
       ,XNPT.receive2_quantity              --����Q����
       ,XNPT.receive2_temp_unit_price       --����Q�P��_��
       ,XNPT.receive2_final_unit_price      --����Q�P��_��
       ,XNPT.shipment_quantity              --�o�א���
       ,XNPT.shipment_temp_unit_price       --�o�גP��_��
       ,XNPT.shipment_final_unit_price      --�o�גP��_��
       ,XNPT.byproduct1_item_code           --���Y���P�i�ڃR�[�h
       ,XIMV_HUK1.item_name                 --���Y���P�i�ږ�
       ,XIMV_HUK1.item_short_name           --���Y���P�i�ڗ���
       ,XNPT.byproduct1_lot_number          --���Y���P���b�gNo
       ,ILM_HUK1.attribute1                 --���Y���P�����N����
       ,ILM_HUK1.attribute2                 --���Y���P�ŗL�L��
       ,ILM_HUK1.attribute3                 --���Y���P�ܖ�����
       ,XNPT.byproduct1_quantity            --���Y���P����
       ,XNPT.byproduct1_uom                 --���Y���P�P��
       ,XNPT.byproduct2_item_code           --���Y���Q�i�ڃR�[�h
       ,XIMV_HUK2.item_name                 --���Y���Q�i�ږ�
       ,XIMV_HUK2.item_short_name           --���Y���Q�i�ڗ���
       ,XNPT.byproduct2_lot_number          --���Y���Q���b�gNo
       ,ILM_HUK2.attribute1                 --���Y���Q�����N����
       ,ILM_HUK2.attribute2                 --���Y���Q�ŗL�L��
       ,ILM_HUK2.attribute3                 --���Y���Q�ܖ�����
       ,XNPT.byproduct2_quantity            --���Y���Q����
       ,XNPT.byproduct2_uom                 --���Y���Q�P��
       ,XNPT.byproduct3_item_code           --���Y���R�i�ڃR�[�h
       ,XIMV_HUK3.item_name                 --���Y���R�i�ږ�
       ,XIMV_HUK3.item_short_name           --���Y���R�i�ڗ���
       ,XNPT.byproduct3_lot_number          --���Y���R���b�gNo
       ,ILM_HUK3.attribute1                 --���Y���R�����N����
       ,ILM_HUK3.attribute2                 --���Y���R�ŗL�L��
       ,ILM_HUK3.attribute3                 --���Y���R�ܖ�����
       ,XNPT.byproduct3_quantity            --���Y���R����
       ,XNPT.byproduct3_uom                 --���Y���R�P��
       ,XNPT.final_unit_price_entered_flg   --���P�����͊����t���O
       ,XNPT.department_code                --�����R�[�h
       ,XLV_TORI.location_name              --������
--       ,XNPT.company_final_unit_price       --�Г��P��_��
       ,FU_CB.user_name                     --�쐬��
       ,XNPT.creation_date                  --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,XNPT.last_update_date               --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
FROM	xxpo_namaha_prod_txns     XNPT		--���t���уA�h�I��
       ,xxsky_item_mst2_v         XIMV_ARA	--�r���i�ږ��擾�p
       ,ic_lots_mst               ILM_ARA	--�r�����b�g���擾�p
       ,xxsky_item_locations2_v   XILV_NYUK --���ɐ於�擾�p
       ,xxsky_item_mst2_v         XIMV_HUK1 --���Y��1�i�ږ��擾�p
       ,ic_lots_mst               ILM_HUK1  --���Y��1���b�g���擾�p
       ,xxsky_item_mst2_v         XIMV_HUK2 --���Y��2�i�ږ��擾�p
       ,ic_lots_mst               ILM_HUK2  --���Y��2���b�g���p
       ,xxsky_item_mst2_v         XIMV_HUK3 --���Y��3�i�ږ��擾�p
       ,ic_lots_mst               ILM_HUK3  --���Y��3���b�g���p
       ,xxsky_locations2_v        XLV_TORI  --�捞�������擾�p
       ,fnd_user                  FU_CB   	--���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                  FU_LU   	--���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                  FU_LL   	--���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                FL_LL   	--���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
--�r���i�ږ��擾�p����
      XIMV_ARA.item_id(+) = XNPT.aracha_item_id
  AND XIMV_ARA.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_ARA.end_date_active(+) >= TRUNC(SYSDATE)
--�r�����b�g���擾�p����
  AND ILM_ARA.item_id(+) = XNPT.aracha_item_id
  AND ILM_ARA.lot_id(+) = XNPT.aracha_lot_id
--���ɐ於�擾�p����
  AND XILV_NYUK.inventory_location_id(+) = XNPT.location_id
--���Y��1�i�ږ��擾�p����
  AND XIMV_HUK1.item_id(+) = XNPT.byproduct1_item_id
  AND XIMV_HUK1.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK1.end_date_active(+) >= TRUNC(SYSDATE)
--���Y��1���b�g���擾�p����
  AND ILM_HUK1.item_id(+) = XNPT.byproduct1_item_id
  AND ILM_HUK1.lot_id(+) = XNPT.byproduct1_lot_id
--���Y��2�i�ږ��擾�p����
  AND XIMV_HUK2.item_id(+) = XNPT.byproduct2_item_id
  AND XIMV_HUK2.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK2.end_date_active(+) >= TRUNC(SYSDATE)
--���Y��2���b�g���p����
  AND ILM_HUK2.item_id(+) = XNPT.byproduct2_item_id
  AND ILM_HUK2.lot_id(+) = XNPT.byproduct2_lot_id
--���Y��3�i�ږ��擾�p����
  AND XIMV_HUK3.item_id(+) = XNPT.byproduct3_item_id
  AND XIMV_HUK3.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK3.end_date_active(+) >= TRUNC(SYSDATE)
--���Y��3���b�g���p����
  AND ILM_HUK3.item_id(+) = XNPT.byproduct3_item_id
  AND ILM_HUK3.lot_id(+) = XNPT.byproduct3_lot_id
--�捞�������擾�p
  AND XLV_TORI.location_code(+) = XNPT.department_code
  AND XLV_TORI.start_date_active(+) <= TRUNC(SYSDATE)
  AND XLV_TORI.end_date_active(+)   >= TRUNC(SYSDATE)
--���[�U�[�}�X�^(CREATED_BY���̎擾�p����)
  AND  FU_CB.user_id(+)  = XNPT.created_by
--���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p����)
  AND  FU_LU.user_id(+)  = XNPT.last_updated_by
--���O�C���}�X�^�E���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p����)
  AND  FL_LL.login_id(+) = XNPT.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_���t����_V IS 'XXSKY_���t���� VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�`�[NO IS '�`�[No'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�r���i�ڃR�[�h IS '�r���i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�r���i�ږ� IS '�r���i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�r���i�ڗ��� IS '�r���i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�r�����b�gNO IS '�r�����b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�r�������N���� IS '�r�������N����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�r���ŗL�L�� IS '�r���ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�r���ܖ����� IS '�r���ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�d�㐔�� IS '�d�㐔��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�d��P�� IS '�d��P��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���H�P�� IS '���H�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���ɐ�R�[�h IS '���ɐ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���ɐ於 IS '���ɐ於'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�׈� IS '�׈�'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���l IS '���l'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�W�ׂP���� IS '�W�ׂP����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�W�ׂP�P��_�� IS '�W�ׂP�P��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�W�ׂP�P��_�� IS '�W�ׂP�P��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�W�ׂQ���� IS '�W�ׂQ����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�W�ׂQ�P��_�� IS '�W�ׂQ�P��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�W�ׂQ�P��_�� IS '�W�ׂQ�P��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.����P���� IS '����P����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.����P�P��_�� IS '����P�P��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.����P�P��_�� IS '����P�P��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.����Q���� IS '����Q����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.����Q�P��_�� IS '����Q�P��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.����Q�P��_�� IS '����Q�P��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�o�א��� IS '�o�א���'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�o�גP��_�� IS '�o�גP��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�o�גP��_�� IS '�o�גP��_��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P�i�ڃR�[�h IS '���Y���P�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P�i�ږ� IS '���Y���P�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P�i�ڗ��� IS '���Y���P�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P���b�gNO IS '���Y���P���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P�����N���� IS '���Y���P�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P�ŗL�L�� IS '���Y���P�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P�ܖ����� IS '���Y���P�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P���� IS '���Y���P����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���P�P�� IS '���Y���P�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q�i�ڃR�[�h IS '���Y���Q�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q�i�ږ� IS '���Y���Q�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q�i�ڗ��� IS '���Y���Q�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q���b�gNO IS '���Y���Q���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q�����N���� IS '���Y���Q�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q�ŗL�L�� IS '���Y���Q�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q�ܖ����� IS '���Y���Q�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q���� IS '���Y���Q����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���Q�P�� IS '���Y���Q�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R�i�ڃR�[�h IS '���Y���R�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R�i�ږ� IS '���Y���R�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R�i�ڗ��� IS '���Y���R�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R���b�gNO IS '���Y���R���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R�����N���� IS '���Y���R�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R�ŗL�L�� IS '���Y���R�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R�ܖ����� IS '���Y���R�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R���� IS '���Y���R����'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���Y���R�P�� IS '���Y���R�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.���P�����͊����t���O IS '���P�����͊����t���O'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�����R�[�h IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���t����_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
