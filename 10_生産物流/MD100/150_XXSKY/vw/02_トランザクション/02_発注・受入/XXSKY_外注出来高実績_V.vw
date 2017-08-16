/************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Table Name      : XXSKY_�O���o��������_V
 * Description     : XXSKY_�O���o��������_V
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *                1.0                    �V�K�쐬
 *  2017/08/10    1.1   S.Yamashita      E_�{�ғ�_14243�Ή�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKY_�O���o��������_V
(
 �����^�C�v
,�����^�C�v��
,���Y��
,�����R�[�h
,����於
,�H��R�[�h
,�H�ꖼ
,�[����R�[�h
,�[���於
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���b�gNO
,������
,�ŗL�L��
,�ܖ�����
,����
,�P�ʃR�[�h
,�o��������
,��������
,�o�����P�ʃR�[�h
,���Z����
,�����쐬�t���O
,�����쐬��
,�E�v
-- Ver1.1 Add Start
,�����ԍ�
-- Ver1.1 Add End
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XVST.txns_type                      --�����^�C�v
       ,FLV.meaning                         --�����^�C�v��
       ,XVST.manufactured_date              --���Y��
       ,XVST.vendor_code                    --�����R�[�h
       ,XVV.vendor_name                     --����於
       ,XVST.factory_code                   --�H��R�[�h
       ,XVSV.vendor_site_name               --�H�ꖼ
       ,XVST.location_code                  --�[����R�[�h
       ,XILV.description                    --�[���於
       ,XVST.item_code                      --�i�ڃR�[�h
       ,XIMV.item_name                      --�i�ږ�
       ,XIMV.item_short_name                --�i�ڗ���
       ,XVST.lot_number                     --���b�gNo
       ,XVST.producted_date                 --������
       ,XVST.koyu_code                      --�ŗL�L��
       ,ILM.attribute3                      --�ܖ�����
       ,XVST.quantity                       --����
       ,XVST.uom                            --�P�ʃR�[�h
       ,XVST.producted_quantity             --�o��������
       ,XVST.corrected_quantity             --��������
       ,XVST.producted_uom                  --�o�����P�ʃR�[�h
       ,XVST.conversion_factor              --���Z����
       ,XVST.order_created_flg              --�����쐬�t���O
       ,XVST.order_created_date             --�����쐬��
       ,XVST.description                    --�E�v
-- Ver1.1 Add Start
       ,xvst.po_number AS po_number         --�����ԍ�
-- Ver1.1 Add End
       ,FU_CB.user_name                     --�쐬��
       ,XVST.creation_date                  --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,XVST.last_update_date               --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
FROM
        xxpo_vendor_supply_txns XVST        --�O���o�������уA�h�I��
       ,fnd_lookup_values       FLV         --�����^�C�v���擾�p
       ,xxsky_vendors2_v        XVV         --������擾�p
       ,xxsky_vendor_sites2_v   XVSV        --�H�ꖼ�擾�p
       ,xxsky_item_locations2_v XILV        --�[���於�擾�p
       ,xxsky_item_mst2_v       XIMV        --�i�ږ��擾�p
       ,ic_lots_mst             ILM         --���b�g���擾�p
       ,fnd_user                FU_CB       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
--�����^�C�v���擾�p����
      FLV.language(+) = 'JA'
  AND FLV.lookup_type(+) = 'XXCMN_PRODUCTION_RESULTS'
  AND FLV.lookup_code(+) = XVST.txns_type
--������擾�p����
  AND XVV.vendor_id(+) = XVST.vendor_id
  AND XVV.start_date_active(+) <= XVST.manufactured_date
  AND XVV.end_date_active(+) >= XVST.manufactured_date
--�H�ꖼ�擾�p����
  AND XVSV.vendor_site_id(+) = XVST.factory_id
  AND XVSV.start_date_active(+) <= XVST.manufactured_date
  AND XVSV.end_date_active(+) >= XVST.manufactured_date
--�[���於�擾�p����
  AND XILV.inventory_location_id(+) = XVST.location_id
--�i�ږ��擾�p����
  AND XIMV.item_id(+) = XVST.item_id
  AND XIMV.start_date_active(+) <= XVST.manufactured_date
  AND XIMV.end_date_active(+) >= XVST.manufactured_date
--���b�g���擾�p����
  AND ILM.item_id(+) = XVST.item_id
  AND ILM.lot_id(+) = XVST.lot_id
--���[�U���擾�p����
  AND  FU_CB.user_id(+)  = XVST.created_by
  AND  FU_LU.user_id(+)  = XVST.last_updated_by
  AND  FL_LL.login_id(+) = XVST.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�O���o��������_V IS 'XXSKY_�O���o�������� VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�����^�C�v IS '�����^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�����^�C�v�� IS '�����^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.���Y�� IS '���Y��'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�����R�[�h IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.����於 IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�H��R�[�h IS '�H��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�H�ꖼ IS '�H�ꖼ'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�[����R�[�h IS '�[����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�[���於 IS '�[���於'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.���b�gNO IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�ŗL�L�� IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�ܖ����� IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�P�ʃR�[�h IS '�P�ʃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�o�������� IS '�o��������'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�������� IS '��������'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�o�����P�ʃR�[�h IS '�o�����P�ʃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.���Z���� IS '���Z����'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�����쐬�t���O IS '�����쐬�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�����쐬�� IS '�����쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�E�v IS '�E�v'
/
-- Ver1.1 Add Start
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�����ԍ� IS '�����ԍ�'
/
-- Ver1.1 Add End
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�O���o��������_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
