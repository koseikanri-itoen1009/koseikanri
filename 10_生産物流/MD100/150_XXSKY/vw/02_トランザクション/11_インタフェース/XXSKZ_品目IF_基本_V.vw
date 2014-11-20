/*************************************************************************
 * 
 * View  Name      : XXSKZ_�i��IF_��{_V
 * Description     : XXSKZ_�i��IF_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�i��IF_��{_V
(
SEQ�ԍ�
,�X�V�敪
,�X�V�敪��
,�i�ڃR�[�h
,�i�ږ�
,�i������
,�i���J�i��
,��_�Q�R�[�h
,�V_�Q�R�[�h
,�Q�R�[�h_�K�p�J�n��
,����Q�R�[�h
,�}�[�P�p�Q�R�[�h
,��_�艿
,�V_�艿
,�艿_�K�p�J�n��
,��_�W������
,�V_�W������
,�W������_�K�p�J�n��
,��_�c�ƌ���
,�V_�c�ƌ���
,�c�ƌ���_�K�p�J�n��
,��_����ŗ�
,�V_����ŗ�
,����ŗ�_�K�p�J�n��
,���敪
,���敪��
,�P�[�X����
,���i���i�敪
,���i���i�敪��
,NET
,�d��_�̐�
,���i�敪
,���i�敪��
,�o�����敪
,�o�����敪��
,�e�i���R�[�h
,�e�i���R�[�h��
,�e�i���R�[�h����
,����Ώۋ敪
,����Ώۋ敪��
,JAN�R�[�h
,���������J�n��
,�p�~�敪
,�p�~�敪��
,�p�~_�������~��
,�����g�p��
,����
,�Đ���
,���ޔ�
,���
,�O���Ǘ���
,�ۊǔ�
,���̑��o��
,�\��
,�\���P
,�\���Q
,�\���R
)
AS
SELECT
 XII.seq_number                      --SEQ�ԍ�
,XII.proc_code                       --�X�V�敪
,CASE XII.proc_code                  --�X�V�敪��
    WHEN 1 THEN '�o�^'
    WHEN 2 THEN '�X�V'
    WHEN 3 THEN '�폜'
 END                                 --�X�V�敪��
,XII.item_code                       --�i�ڃR�[�h
,XII.item_name                       --�i�ږ�
,XII.item_short_name                 --�i������
,XII.item_name_alt                   --�i���J�i��
,XII.old_crowd_code                  --��_�Q�R�[�h
,XII.new_crowd_code                  --�V_�Q�R�[�h
,XII.crowd_start_date                --�Q�R�[�h_�K�p�J�n��
,XII.policy_group_code               --����Q�R�[�h
,XII.marke_crowd_code                --�}�[�P�p�Q�R�[�h
,NVL( TO_NUMBER( XII.old_price ), 0 )
                                     --��_�艿
,NVL( TO_NUMBER( XII.new_price ), 0 )
                                     --�V_�艿
,XII.price_start_date                --�艿_�K�p�J�n��
,NVL( TO_NUMBER( XII.old_standard_cost ), 0 )
                                     --��_�W������
,NVL( TO_NUMBER( XII.new_standard_cost ), 0 )
                                     --�V_�W������
,XII.standard_start_date             --�W������_�K�p�J�n��
,NVL( TO_NUMBER( XII.old_business_cost ), 0 )
                                     --��_�c�ƌ���
,NVL( TO_NUMBER( XII.new_business_cost ), 0 )
                                     --�V_�c�ƌ���
,XII.business_start_date             --�c�ƌ���_�K�p�J�n��
,NVL( TO_NUMBER( XII.old_tax ), 0 )  --��_����ŗ�
,NVL( TO_NUMBER( XII.new_tax ), 0 )  --�V_����ŗ�
,XII.tax_start_date                  --����ŗ�_�K�p�J�n��
,XII.rate_code                       --���敪
,FLV_RIT.meaning                     --���敪��
,NVL( TO_NUMBER( XII.case_num ), 0 ) --�P�[�X����
,XII.product_div_code                --���i���i�敪
,FLV_SSK.meaning                     --���i���i�敪��
,NVL( TO_NUMBER( XII.net ), 0 )      --NET
,NVL( TO_NUMBER( XII.weight_volume ), 0 )
                                     --�d��_�̐�
,XII.arti_div_code                   --���i�敪
,FLV_SK.meaning                      --���i�敪��
,XII.div_tea_code                    --�o�����敪
,FLV_BAR.meaning                     --�o�����敪��
,XII.parent_item_code                --�e�i���R�[�h
,XIMV.item_name                      --�e�i���R�[�h��
,XIMV.item_short_name                --�e�i���R�[�h����
,XII.sale_obj_code                   --����Ώۋ敪
,FLV_URI.meaning                     --����Ώۋ敪��
,XII.jan_code                        --JAN�R�[�h
,XII.sale_start_date                 --���������J�n��
,XII.abolition_code                  --�p�~�敪
,CASE XII.abolition_code             --�p�~�敪��
    WHEN '0' THEN '�戵��'
    WHEN '1' THEN '�p�~'
 END
,XII.abolition_date                  --�p�~_�������~��
,NVL( TO_NUMBER( XII.raw_mate_consumption ), 0 )
                                     --�����g�p��
,NVL( TO_NUMBER( XII.raw_material_cost ), 0 )
                                     --����
,NVL( TO_NUMBER( XII.agein_cost ), 0 )
                                     --�Đ���
,NVL( TO_NUMBER( XII.material_cost ), 0 )
                                     --���ޔ�
,NVL( TO_NUMBER( XII.pack_cost ), 0 )
                                     --���
,NVL( TO_NUMBER( XII.out_order_cost ), 0 )
                                     --�O���Ǘ���
,NVL( TO_NUMBER( XII.safekeep_cost ), 0 )
                                     --�ۊǔ�
,NVL( TO_NUMBER( XII.other_expense_cost ), 0 )
                                     --���̑��o��
,NVL( TO_NUMBER( XII.spare ), 0 )
                                     --�\��
,NVL( TO_NUMBER( XII.spare1 ), 0 )
                                     --�\���P
,NVL( TO_NUMBER( XII.spare2 ), 0 )
                                     --�\���Q
,NVL( TO_NUMBER( XII.spare3 ), 0 )
                                     --�\���R
FROM    xxcmn_item_if       XII      --�i�ڃC���^�t�F�[�X_V
       ,xxskz_item_mst2_v   XIMV     --�e�i�ږ��擾�p
       ,fnd_lookup_values   FLV_RIT  --���敪���擾
       ,fnd_lookup_values   FLV_SSK  --���i���i�敪���擾
       ,fnd_lookup_values   FLV_SK   --���i�敪���擾
       ,fnd_lookup_values   FLV_BAR  --�o�����敪���擾
       ,fnd_lookup_values   FLV_URI  --����Ώۋ敪���擾
WHERE
    XII.parent_item_code = XIMV.item_no(+)      --�e�i�ږ��擾�p����
AND XIMV.start_date_active(+) <= NVL(XII.sale_start_date,SYSDATE)
AND XIMV.end_date_active(+)   >= NVL(XII.sale_start_date,SYSDATE)
AND FLV_RIT.language(+) = 'JA'                  --���敪���擾�p����
AND FLV_RIT.lookup_type(+) = 'XXCMN_RATE'
AND FLV_RIT.lookup_code(+) = XII.rate_code
AND FLV_SSK.language(+) = 'JA'                  --���i���i�敪���擾�p����
AND FLV_SSK.lookup_type(+) = 'XXCMN_PRODUCT_OR_NOT'
AND FLV_SSK.lookup_code(+) = XII.product_div_code
AND FLV_SK.language(+) = 'JA'                   --���i�敪���擾�p����
AND FLV_SK.lookup_type(+) = 'XXWIP_ITEM_TYPE'
AND FLV_SK.lookup_code(+) = XII.arti_div_code
AND FLV_BAR.language(+) = 'JA'                  --�o�����敪���擾�p����
AND FLV_BAR.lookup_type(+) = 'XXCMN_BARACHA'
AND FLV_BAR.lookup_code(+) = XII.div_tea_code
AND FLV_URI.language(+) = 'JA'                  --����Ώۋ敪���擾�p����
AND FLV_URI.lookup_type(+) = 'XXCMN_SALES_TARGET_CLASS'
AND FLV_URI.lookup_code(+) = XII.sale_obj_code
/
COMMENT ON TABLE APPS.XXSKZ_�i��IF_��{_V IS 'XXSKZ_�i��IF (��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.SEQ�ԍ�               IS 'SEQ�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�X�V�敪              IS '�X�V�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�X�V�敪��            IS '�X�V�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�i�ڃR�[�h            IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�i�ږ�                IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�i������              IS '�i������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�i���J�i��            IS '�i���J�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.��_�Q�R�[�h           IS '��_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�V_�Q�R�[�h           IS '�V_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�Q�R�[�h_�K�p�J�n��   IS '�Q�R�[�h_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.����Q�R�[�h          IS '����Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�}�[�P�p�Q�R�[�h      IS '�}�[�P�p�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.��_�艿               IS '��_�艿'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�V_�艿               IS '�V_�艿'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�艿_�K�p�J�n��       IS '�艿_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.��_�W������           IS '��_�W������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�V_�W������           IS '�V_�W������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�W������_�K�p�J�n��   IS '�W������_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.��_�c�ƌ���           IS '��_�c�ƌ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�V_�c�ƌ���           IS '�V_�c�ƌ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�c�ƌ���_�K�p�J�n��   IS '�c�ƌ���_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.��_����ŗ�           IS '��_����ŗ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�V_����ŗ�           IS '�V_����ŗ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.����ŗ�_�K�p�J�n��   IS '����ŗ�_�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���敪                IS '���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���敪��              IS '���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�P�[�X����            IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���i���i�敪          IS '���i���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���i���i�敪��        IS '���i���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.NET                   IS 'NET'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�d��_�̐�             IS '�d��_�̐�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���i�敪              IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���i�敪��            IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�o�����敪            IS '�o�����敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�o�����敪��          IS '�o�����敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�e�i���R�[�h          IS '�e�i���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�e�i���R�[�h��        IS '�e�i���R�[�h��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�e�i���R�[�h����      IS '�e�i���R�[�h����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.����Ώۋ敪          IS '����Ώۋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.����Ώۋ敪��        IS '����Ώۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.JAN�R�[�h             IS 'JAN�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���������J�n��        IS '���������J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�p�~�敪              IS '�p�~�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�p�~�敪��            IS '�p�~�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�p�~_�������~��       IS '�p�~_�������~��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�����g�p��            IS '�����g�p��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.����                  IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�Đ���                IS '�Đ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���ޔ�                IS '���ޔ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���                IS '���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�O���Ǘ���            IS '�O���Ǘ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�ۊǔ�                IS '�ۊǔ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.���̑��o��            IS '���̑��o��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�\��                  IS '�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�\���P                IS '�\���P'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�\���Q                IS '�\���Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�i��IF_��{_V.�\���R                IS '�\���R'
/
