/*************************************************************************
 * 
 * View  Name      : XXSKZ_�g���T�r���e�B_��{_V
 * Description     : XXSKZ_�g���T�r���e�B_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�g���T�r���e�B_��{_V
(
�v��ID
,�敪
,�敪��
,���x���ԍ�
,�e�i��_���i�敪
,�e�i��_���i�敪��
,�e�i��_�i�ڋ敪
,�e�i��_�i�ڋ敪��
,�e�i��_�Q�R�[�h
,�e�i�ڃR�[�h
,�e�i�ږ�
,�e�i�ڗ���
,�e���b�gNO
,�e�������
,�q�i��_���i�敪
,�q�i��_���i�敪��
,�q�i��_�i�ڋ敪
,�q�i��_�i�ڋ敪��
,�q�i��_�Q�R�[�h
,�q�i�ڃR�[�h
,�q�i�ږ�
,�q�i�ڗ���
,�q���b�gNO
,�q�������
,�����o�b�`�ԍ�
,������
,�q�ɃR�[�h
,�q�ɖ�
,���C���ԍ�
,������
,�����o�b�`�ԍ�
,�����
,����ԍ�
,�����ԍ�
,�d����R�[�h
,�d���於
,�����Ǝ�
,�����N����
,�ŗL�L��
,�ܖ�����
,����[����
,�ŏI�[����
,�݌ɓ���
,�����敪
,�����敪��
,�N�x
,�Y�n
,�^�C�v
,�^�C�v��
,�����N�P
,�����N�Q
,�����N�R
,���Y�`�[�敪
,���Y�`�[�敪��
,�E�v
,�����˗�NO
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XLT.request_id                      --�v��ID
       ,XLT.division                        --�敪
       ,CASE XLT.division
            WHEN '0' THEN '���b�g�g���[�X�i�����ցj'
            WHEN '1' THEN '�g���[�X�o�b�N�i���i�ցj'
        END                                 --�敪��
       ,XLT.level_num                       --���x���ԍ�
       ,XPCV_OYA.prod_class_code            --�e�i��_���i�敪
       ,XPCV_OYA.prod_class_name            --�e�i��_���i�敪��
       ,XICV_OYA.item_class_code            --�e�i��_�i�ڋ敪
       ,XICV_OYA.item_class_name            --�e�i��_�i�ڋ敪��
       ,XCCV_OYA.crowd_code                 --�e�i��_�Q�R�[�h
       ,XLT.item_code                       --�e�i�ڃR�[�h
       ,XLT.item_name                       --�e�i�ږ�
       ,XIMV_OYA.item_short_name            --�e�i�ڗ���
       ,XLT.lot_num                         --�e���b�gNo
       ,XLT.trans_qty                       --�e�������
       ,XPCV_KO.prod_class_code             --�q�i��_���i�敪
       ,XPCV_KO.prod_class_name             --�q�i��_���i�敪��
       ,XICV_KO.item_class_code             --�q�i��_�i�ڋ敪
       ,XICV_KO.item_class_name             --�q�i��_�i�ڋ敪��
       ,XCCV_KO.crowd_code                  --�q�i��_�Q�R�[�h
       ,XLT.trace_item_code                 --�q�i�ڃR�[�h
       ,XLT.trace_item_name                 --�q�i�ږ�
       ,XIMV_KO.item_short_name             --�q�i�ڗ���
       ,XLT.trace_lot_num                   --�q���b�gNo
       ,XLT.trace_trans_qty                 --�q�������
       ,XLT.batch_num                       --�����o�b�`�ԍ�
       ,XLT.batch_date                      --������
       ,XLT.whse_code                       --�q�ɃR�[�h
       ,IWM.whse_name                       --�q�ɖ�
       ,XLT.line_num                        --���C���ԍ�
       ,XLT.turn_date                       --������
       ,XLT.turn_batch_num                  --�����o�b�`�ԍ�
       ,XLT.receipt_date                    --�����
       ,XLT.receipt_num                     --����ԍ�
       ,XLT.order_num                       --�����ԍ�
       ,XLT.supp_code                       --�d����R�[�h
       ,XLT.supp_name                       --�d���於
       ,XLT.trader_name                     --�����Ǝ�
       ,XLT.lot_date                        --�����N����
       ,XLT.lot_sign                        --�ŗL�L��
       ,XLT.best_bfr_date                   --�ܖ�����
       ,XLT.dlv_date_first                  --����[����
       ,XLT.dlv_date_last                   --�ŏI�[����
       ,XLT.stock_ins_amount                --�݌ɓ���
       ,XLT.tea_period_dev                  --�����敪
       ,FLV_CHA.meaning                     --�����敪��
       ,XLT.product_year                    --�N�x
       ,XLT.product_home                    --�Y�n
       ,XLT.product_type                    --�^�C�v
       ,FLV_TYP.meaning                     --�^�C�v��
       ,XLT.product_ranc_1                  --�����N�P
       ,XLT.product_ranc_2                  --�����N�Q
       ,XLT.product_ranc_3                  --�����N�R
       ,XLT.product_slip_dev                --���Y�`�[�敪
       ,FLV_DEN.meaning                     --���Y�`�[�敪��
       ,XLT.description                     --�E�v
       ,XLT.inspect_req                     --�����˗�No
       ,FU_CB.user_name                     --�쐬��
       ,TO_CHAR( XLT.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,TO_CHAR( XLT.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
FROM    xxcmn_lot_trace         XLT         --���b�g�g���[�X
       ,xxskz_item_mst2_v       XIMV_OYA    --�e�i�ږ��擾
       ,xxskz_prod_class_v      XPCV_OYA    --�e���i�敪�擾
       ,xxskz_item_class_v      XICV_OYA    --�e�i�ڋ敪�擾
       ,xxskz_crowd_code_v      XCCV_OYA    --�e�Q�R�[�h�擾
       ,xxskz_item_mst2_v       XIMV_KO     --�q�i�ږ��擾
       ,xxskz_prod_class_v      XPCV_KO     --�q���i�敪�擾
       ,xxskz_item_class_v      XICV_KO     --�q�i�ڋ敪�擾
       ,xxskz_crowd_code_v      XCCV_KO     --�q�Q�R�[�h�擾
       ,ic_whse_mst             IWM         --�q�ɖ��擾
       ,fnd_lookup_values       FLV_CHA     --�����敪���擾
       ,fnd_lookup_values       FLV_TYP     --�^�C�v���擾
       ,fnd_lookup_values       FLV_DEN     --���Y�`�[�敪����
       ,fnd_user                FU_CB       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
--�e�i�ږ��擾����
      XIMV_OYA.item_no(+) = XLT.item_code
  AND XIMV_OYA.start_date_active(+) <= NVL(XLT.batch_date,XLT.receipt_date)
  AND XIMV_OYA.end_date_active(+)   >= NVL(XLT.batch_date,XLT.receipt_date)
--�e���i�敪�擾����
  AND XPCV_OYA.item_id(+) = XIMV_OYA.item_id
--�e�i�ڋ敪�擾����
  AND XICV_OYA.item_id(+) = XIMV_OYA.item_id
--�e�Q�R�[�h�擾����
  AND XCCV_OYA.item_id(+) = XIMV_OYA.item_id
--�q�i�ږ��擾����
  AND XIMV_KO.item_no(+) = XLT.trace_item_code
  AND XIMV_KO.start_date_active(+) <= NVL(XLT.batch_date,XLT.receipt_date)
  AND XIMV_KO.end_date_active(+)   >= NVL(XLT.batch_date,XLT.receipt_date)
--�q���i�敪�擾����
  AND XPCV_KO.item_id(+) = XIMV_KO.item_id
--�q�i�ڋ敪�擾����
  AND XICV_KO.item_id(+) = XIMV_KO.item_id
--�q�Q�R�[�h�擾����
  AND XCCV_KO.item_id(+) = XIMV_KO.item_id
--�q�ɖ��擾����
  AND XLT.whse_code = IWM.whse_code(+)
--�����敪���擾����
  AND FLV_CHA.language(+) = 'JA'
  AND FLV_CHA.lookup_type(+) = 'XXCMN_L06'
  AND FLV_CHA.lookup_code(+) = XLT.tea_period_dev
--�^�C�v���擾����
  AND FLV_TYP.language(+) = 'JA'
  AND FLV_TYP.lookup_type(+) = 'XXCMN_L08'
  AND FLV_TYP.lookup_code(+) = XLT.product_type
--���Y�`�[�敪���擾����
  AND FLV_DEN.language(+) = 'JA'
  AND FLV_DEN.lookup_type(+) = 'XXCMN_L03'
  AND FLV_DEN.lookup_code(+) = XLT.product_slip_dev
--���[�U�[�}�X�^(CREATED_BY���̎擾�p����)
  AND  FU_CB.user_id(+)  = XLT.created_by
--���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p����)
  AND  FU_LU.user_id(+)  = XLT.last_updated_by
--���O�C���}�X�^�E���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p����)
  AND  FL_LL.login_id(+) = XLT.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�g���T�r���e�B_��{_V IS 'XXSKZ_�g���T�r���e�B (��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�v��ID               IS '�v��ID'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�敪                 IS '�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�敪��               IS '�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.���x���ԍ�           IS '���x���ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�i��_���i�敪      IS '�e�i��_���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�i��_���i�敪��    IS '�e�i��_���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�i��_�i�ڋ敪      IS '�e�i��_�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�i��_�i�ڋ敪��    IS '�e�i��_�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�i��_�Q�R�[�h      IS '�e�i��_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�i�ڃR�[�h         IS '�e�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�i�ږ�             IS '�e�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�i�ڗ���           IS '�e�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e���b�gNO           IS '�e���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�e�������           IS '�e�������'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�i��_���i�敪      IS '�q�i��_���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�i��_���i�敪��    IS '�q�i��_���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�i��_�i�ڋ敪      IS '�q�i��_�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�i��_�i�ڋ敪��    IS '�q�i��_�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�i��_�Q�R�[�h      IS '�q�i��_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�i�ڃR�[�h         IS '�q�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�i�ږ�             IS '�q�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�i�ڗ���           IS '�q�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q���b�gNO           IS '�q���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�������           IS '�q�������'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����o�b�`�ԍ�       IS '�����o�b�`�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.������               IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�ɃR�[�h           IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�q�ɖ�               IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.���C���ԍ�           IS '���C���ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.������               IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����o�b�`�ԍ�       IS '�����o�b�`�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����               IS '�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.����ԍ�             IS '����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����ԍ�             IS '�����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�d����R�[�h         IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�d���於             IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����Ǝ�             IS '�����Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����N����           IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�ŗL�L��             IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�ܖ�����             IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.����[����           IS '����[����'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�ŏI�[����           IS '�ŏI�[����'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�݌ɓ���             IS '�݌ɓ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����敪             IS '�����敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����敪��           IS '�����敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�N�x                 IS '�N�x'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�Y�n                 IS '�Y�n'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�^�C�v               IS '�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�^�C�v��             IS '�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����N�P             IS '�����N�P'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����N�Q             IS '�����N�Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����N�R             IS '�����N�R'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.���Y�`�[�敪         IS '���Y�`�[�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.���Y�`�[�敪��       IS '���Y�`�[�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�E�v                 IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�����˗�NO           IS '�����˗�No'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�g���T�r���e�B_��{_V.�ŏI�X�V���O�C��     IS '�ŏI�X�V���O�C��'
/
