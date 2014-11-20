/*************************************************************************
 * 
 * View  Name      : XXSKZ_�I�������݌�_��{_V
 * Description     : XXSKZ_�I�������݌�_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�I�������݌�_��{_V
(
 �I���N��
,�q�ɃR�[�h
,�q�ɖ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���b�gNO
,�����N����
,�ŗL�L��
,�ܖ�����
,�����݌ɐ�
,�����݌ɃP�[�X��
,�ϑ����݌ɐ�
,�ϑ����݌ɃP�[�X��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XSIM.invent_ym                                --�I���N��
       ,XSIM.whse_code                                --�q�ɃR�[�h
       ,IWM.whse_name                                 --�q�ɖ�
       ,XPCV.prod_class_code                          --���i�敪
       ,XPCV.prod_class_name                          --���i�敪��
       ,XICV.item_class_code                          --�i�ڋ敪
       ,XICV.item_class_name                          --�i�ڋ敪��
       ,XCCV.crowd_code                               --�Q�R�[�h
       ,XSIM.item_code                                --�i�ڃR�[�h
       ,XIMV.item_name                                --�i�ږ�
       ,XIMV.item_short_name                          --�i�ڗ���
       ,XSIM.lot_no                                   --���b�gNO
       ,ILM.attribute1                                --�����N����
       ,ILM.attribute2                                --�ŗL�L��
       ,ILM.attribute3                                --�ܖ�����
       ,XSIM.monthly_stock                            --�����݌ɐ�
       ,NVL( XSIM.monthly_stock / XIMV.num_of_cases ,0 )
                                                      --�����݌ɃP�[�X��
       ,XSIM.cargo_stock                              --�ϑ����݌ɐ�
       ,NVL( XSIM.cargo_stock / XIMV.num_of_cases ,0 )
                                                      --�ϑ����݌ɃP�[�X��
       ,FU_CB.user_name                               --�쐬��
       ,TO_CHAR( XSIM.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                      --�쐬��
       ,FU_LU.user_name                               --�ŏI�X�V��
       ,TO_CHAR( XSIM.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                      --�ŏI�X�V��
       ,FU_LL.user_name                               --�ŏI�X�V���O�C��
  FROM  xxcmn_stc_inv_month_stck_arc    XSIM          --�I�������݌Ɂi�A�h�I���j�o�b�N�A�b�v
       ,ic_whse_mst                     IWM           --�q�ɖ��擾
       ,xxskz_item_mst2_v               XIMV          --�i�ڎ擾
       ,xxskz_prod_class_v              XPCV          --���i�敪�擾
       ,xxskz_item_class_v              XICV          --�i�ڋ敪�擾
       ,xxskz_crowd_code_v              XCCV          --�Q�R�[�h�擾
       ,ic_lots_mst                     ILM           --���b�g���擾
       ,fnd_user                        FU_CB         --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU         --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL         --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL         --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
   -- �q�ɖ��擾
        XSIM.whse_code = IWM.whse_code(+)
   -- OPM�i�ڏ��擾
   AND  XSIM.item_id = XIMV.item_id(+)
   AND  TO_DATE( XSIM.invent_ym || '01', 'YYYYMMDD' ) >= XIMV.start_date_active(+)
   AND  TO_DATE( XSIM.invent_ym || '01', 'YYYYMMDD' ) <= XIMV.end_date_active(+)
   -- ���i�敪�擾�p����
   AND  XSIM.item_id = XPCV.item_id(+)
   -- �i�ڋ敪�擾�p����
   AND  XSIM.item_id = XICV.item_id(+)
   -- �Q�R�[�h�擾�p����
   AND  XSIM.item_id = XCCV.item_id(+)
   -- ���b�g���擾�p����
   AND  XSIM.item_id = ILM.item_id
   AND  XSIM.lot_id = ILM.lot_id
   -- ���_�쐬�ҁE�ŏI�X�V��
   AND  XSIM.created_by        = FU_CB.user_id(+)
   AND  XSIM.last_updated_by   = FU_LU.user_id(+)
   AND  XSIM.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�I�������݌�_��{_V IS 'SKYLINK�p�I�������݌Ɂi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�I���N��           IS '�I���N��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�q�ɃR�[�h         IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�q�ɖ�             IS '�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.���i�敪           IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.���i�敪��         IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�i�ڋ敪           IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�i�ڋ敪��         IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�Q�R�[�h           IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�i�ڃR�[�h         IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�i�ږ�             IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�i�ڗ���           IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�����N����         IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�ŗL�L��           IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�ܖ�����           IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.���b�gNO           IS '���b�gNO'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�����݌ɐ�         IS '�����݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�����݌ɃP�[�X��   IS '�����݌ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�ϑ����݌ɃP�[�X�� IS '�ϑ����݌ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�ϑ����݌ɐ�       IS '�ϑ����݌ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�I�������݌�_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/
