/*************************************************************************
 * 
 * View  Name      : XXSKZ_�U�֏��_��{_V
 * Description     : XXSKZ_�U�֏��_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�U�֏��_��{_V
(
 �Ώ۔N��
,�c�ƃu���b�N
,�c�ƃu���b�N��
,���i�敪
,���i�敪��
,�Ǌ����_
,�Ǌ����_��
,�Ǌ����_����
,�n�於
,�U�֐���
,�U�֋��z
,�Ҍ����z
,�^����`
,�^����a
,�^����b
,���̑�
,�˗�NO
,�z����
,�o�Ɍ�
,�o�Ɍ���
,�z����
,�z���於
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�P��
,�v�Z����
,���ې���
,���z
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT 
        TI.target_date                                  --�Ώ۔N��
       ,TI.business_block                               --�c�ƃu���b�N
       ,FLV01.meaning           business_block_name     --�c�ƃu���b�N��
       ,TI.goods_classe                                 --���i�敪
       ,FLV02.meaning           goods_classe_name       --���i�敪��
       ,TI.jurisdicyional_hub                           --�Ǌ����_
       ,XCA2V.party_name        j_hub_name              --�Ǌ����_��
       ,XCA2V.party_short_name  j_hub_short_name        --�Ǌ����_����
       ,TI.area_name                                    --�n�於
       ,TI.transfe_qty                                  --�U�֐���
       ,TI.transfer_amount                              --�U�֋��z
       ,TI.restore_amount                               --�Ҍ����z
       ,TI.shipping_expenses_a                          --�^����`
       ,TI.shipping_expenses_b                          --�^����a
       ,TI.shipping_expenses_c                          --�^����b
       ,TI.etc_amount                                   --���̑�
       ,TI.request_no                                   --�˗�NO
       ,TI.delivery_date                                --�z����
       ,TI.delivery_whs                                 --�o�Ɍ�
       ,XILV.description                                --�o�Ɍ���
       ,TI.ship_to                                      --�z����
       ,XPS2V.party_site_name                           --�z���於
       ,XICV.item_class_code                            --�i�ڋ敪
       ,XICV.item_class_name                            --�i�ڋ敪��
       ,XCCV.crowd_code                                 --�Q�R�[�h
       ,TI.item_code                                    --�i�ڃR�[�h
       ,XIM2V.item_name                                 --�i�ږ�
       ,XIM2V.item_short_name                           --�i�ڗ���
       ,TI.price                                        --�P��
       ,TI.calc_qry                                     --�v�Z����
       ,TI.actual_qty                                   --���ې���
       ,TI.amount                                       --���z
       ,FU_CB.user_name         created_by_name         --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( TI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date           --�쐬����
       ,FU_LU.user_name         last_updated_by_name    --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( TI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date        --�X�V����
       ,FU_LL.user_name         last_update_login_name  --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  (
        SELECT 
             XTI.target_date                            --�Ώ۔N��
            ,XTI.business_block                         --�c�ƃu���b�N
            ,XTI.goods_classe                           --���i�敪
            ,XTI.jurisdicyional_hub                     --�Ǌ����_
            ,XTI.area_name                              --�n�於
            ,XTI.transfe_qty                            --�U�֐���
            ,XTI.transfer_amount                        --�U�֋��z
            ,XTI.restore_amount                         --�Ҍ����z
            ,XTI.shipping_expenses_a                    --�^����`
            ,XTI.shipping_expenses_b                    --�^����a
            ,XTI.shipping_expenses_c                    --�^����b
            ,XTI.etc_amount                             --���̑�
            ,XTFI.request_no                            --�˗�NO
            ,XTFI.delivery_date                         --�z����
            ,XTFI.delivery_whs                          --�o�Ɍ�
            ,XTFI.ship_to                               --�z����
            ,XTFI.item_code                             --�i�ڃR�[�h
            ,XTFI.price                                 --�P��
            ,XTFI.calc_qry                              --�v�Z����
            ,XTFI.actual_qty                            --���ې���
            ,XTFI.amount                                --���z
            ,XTFI.created_by
            ,XTFI.creation_date
            ,XTFI.last_updated_by
            ,XTFI.last_update_date
            ,XTFI.last_update_login
        FROM
             xxwip_transfer_inf         XTI             --�U�֏��A�h�I���C���^�t�F�[�X
            ,xxwip_transfer_fare_inf    XTFI            --�U�։^�����A�h�I���C���^�t�F�[�X
        WHERE
               XTFI.target_date         =  XTI.target_date
          AND  XTFI.goods_classe        =  XTI.goods_classe
          AND  XTFI.jurisdicyional_hub  =  XTI.jurisdicyional_hub
        )   TI                                          --�U�֏��E�U�։^�����
       ,xxskz_cust_accounts2_v          XCA2V           --SKYLINK�p����VIEW ���_�擾VIEW
       ,xxskz_item_locations_v          XILV            --SKYLINK�p����VIEW �o�Ɍ��擾VIEW
       ,xxskz_party_sites2_v            XPS2V           --SKYLINK�p����VIEW �z����擾VIEW
       ,xxskz_item_class_v              XICV            --SKYLINK�p����VIEW �i�ڋ敪�擾VIEW
       ,xxskz_crowd_code_v              XCCV            --SKYLINK�p����VIEW �Q�R�[�h�擾VIEW
       ,xxskz_item_mst2_v               XIM2V           --SKYLINK�p����VIEW �i�ږ��擾VIEW
       ,fnd_lookup_values               FLV01           --�c�ƃu���b�N���擾�p
       ,fnd_lookup_values               FLV02           --���i�敪���擾�p
       ,fnd_user                        FU_CB           --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU           --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL           --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL           --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
    --���_���擾����
        XCA2V.party_number(+)       =  TI.jurisdicyional_hub
   AND  XCA2V.start_date_active(+)  <= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
   AND  XCA2V.end_date_active(+)    >= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
    --�o�Ɍ����擾����
   AND  XILV.segment1(+)            =  TI.delivery_whs
    --�z���於�擾����
   AND  XPS2V.party_site_number(+)  =  TI.ship_to
   AND  XPS2V.start_date_active(+)  <= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
   AND  XPS2V.end_date_active(+)    >= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
    --�i�ږ��擾����
   AND  XIM2V.item_no(+)            =  TI.item_code
   AND  XIM2V.start_date_active(+)  <= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
   AND  XIM2V.end_date_active(+)    >= LAST_DAY(TO_DATE(TI.target_date || '01', 'YYYYMMDD'))
    --�i�ڋ敪�擾����
   AND  XICV.item_id(+)             =  XIM2V.item_id
    --�Q�R�[�h�擾����
   AND  XCCV.item_id(+)             =  XIM2V.item_id
    --�c�ƃu���b�N���擾����
   AND  FLV01.language(+)           =  'JA'
   AND  FLV01.lookup_type(+)        =  'XXCMN_AREA'
   AND  FLV01.lookup_code(+)        =  TI.business_block
   --���i�敪���擾����
   AND  FLV02.language(+)           =  'JA'
   AND  FLV02.lookup_type(+)        =  'XXWIP_ITEM_TYPE'
   AND  FLV02.lookup_code(+)        =  TI.goods_classe
   --WHO�J�����擾
   AND  TI.created_by               =  FU_CB.user_id(+)
   AND  TI.last_updated_by          =  FU_LU.user_id(+)
   AND  TI.last_update_login        =  FL_LL.login_id(+)
   AND  FL_LL.user_id               =  FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�U�֏��_��{_V                     IS 'SKYLINK�p�U�֏��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�Ώ۔N��           IS '�Ώ۔N��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�c�ƃu���b�N       IS '�c�ƃu���b�N'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�c�ƃu���b�N��     IS '�c�ƃu���b�N��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.���i�敪           IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.���i�敪��         IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�Ǌ����_           IS '�Ǌ����_'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�Ǌ����_��         IS '�Ǌ����_��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�Ǌ����_����       IS '�Ǌ����_����'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�n�於             IS '�n�於'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�U�֐���           IS '�U�֐���'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�U�֋��z           IS '�U�֋��z'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�Ҍ����z           IS '�Ҍ����z'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�^����`           IS '�^����`'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�^����a           IS '�^����a'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�^����b           IS '�^����b'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.���̑�             IS '���̑�'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�˗�NO             IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�z����             IS '�z����'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�o�Ɍ�             IS '�o�Ɍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�o�Ɍ���           IS '�o�Ɍ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�z����             IS '�z����'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�z���於           IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�i�ڋ敪           IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�i�ڋ敪��         IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�Q�R�[�h           IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�i�ڃR�[�h         IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�i�ږ�             IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�i�ڗ���           IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�P��               IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�v�Z����           IS '�v�Z����'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.���ې���           IS '���ې���'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.���z               IS '���z'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�U�֏��_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/